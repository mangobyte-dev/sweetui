import Dependencies
import Foundation

public struct MCPServer {
  let root: String
  @Dependency(\.registryFileSystem) var fs
  @Dependency(\.registryConsole) var console
  @Dependency(\.registryInput) var input
  public init(root: String) { self.root = root }
  public func serve() throws {
    while let line = try input.nextLine() {
      if let response = try response(to: line) { console.stdout(response + "\n") }
    }
  }
  public func response(to line: Data) throws -> String? {
    if line.allSatisfy({ [9, 10, 13, 32].contains($0) }) { return nil }
    guard let message = try? JSON.read(line) else {
      return error(id: .null, code: -32700, message: "Parse error").rendered(pretty: false)
    }
    guard let method = message["method"].string else { return nil }
    let identifier = message["id"]
    let params = message["params"]
    let result: OrderedJSON
    do {
      switch method {
      case "initialize":
        let requested = params["protocolVersion"].text
        let version =
          ["2025-06-18", "2025-03-26", "2024-11-05"].contains(requested) ? requested : "2025-06-18"
        result = [
          "protocolVersion": .string(version), "capabilities": ["tools": ["listChanged": false]],
          "serverInfo": [
            "name": "sweetui", "title": "SweetUI",
            "version": .string(RegistryRelease.version),
          ],
          "instructions": .string(Self.instructions),
        ]
      case "ping": result = [:]
      case "tools/list": result = ["tools": Self.tools]
      case "tools/call": result = try call(params)
      default:
        if method.hasPrefix("notifications/") { return nil }
        return error(id: identifier, code: -32601, message: "Method not found: \(method)").rendered(
          pretty: false)
      }
    } catch let invalid as InvalidParams {
      return error(id: identifier, code: -32602, message: invalid.message).rendered(pretty: false)
    }
    if identifier == .null { return nil }
    let response: OrderedJSON = ["jsonrpc": "2.0", "id": OrderedJSON(identifier), "result": result]
    return response.rendered(pretty: false)
  }
  private struct InvalidParams: Error { let message: String }
  private struct InvalidArgument: Error { let message: String }
  private func error(id: JSON, code: Int, message: String) -> OrderedJSON {
    [
      "jsonrpc": "2.0", "id": OrderedJSON(id),
      "error": ["code": OrderedJSON(.number(Double(code))), "message": .string(message)],
    ]
  }
  private func toolError(_ message: String) -> OrderedJSON {
    ["content": [["type": "text", "text": .string(message)]], "isError": true]
  }
  private func call(_ params: JSON) throws -> OrderedJSON {
    let name = params["name"].string
    var arguments = params["arguments"]
    if arguments == .null || arguments == false || arguments == 0 || arguments == ""
      || arguments == []
    {
      arguments = [:]
    }
    guard arguments.object != nil else {
      throw InvalidParams(message: "arguments must be an object")
    }
    guard let name,
      [
        "search_items", "describe_item", "plan_install", "diff_item", "install_item",
        "describe_preset", "apply_preset", "list_design_notes", "answer_design_note",
        "propose_design", "get_design_context", "read_handoff", "answer_handoff",
      ].contains(name)
    else {
      throw InvalidParams(message: "Unknown tool: \(params["name"].string ?? "None")")
    }
    let structured: OrderedJSON
    do {
      structured = try perform(name, arguments)
    } catch let recipe as RecipeGuidance {
      structured = [
        "item": .string(recipe.name), "kind": "recipe", "installs": false,
        "guidance": .string(recipe.guidance),
      ]
    } catch let invalid as InvalidArgument {
      return toolError("Invalid arguments: " + invalid.message)
    } catch let error as RegistryError { return toolError(error.description) }
    return [
      "content": [["type": "text", "text": .string(structured.rendered())]],
      "structuredContent": structured, "isError": false,
    ]
  }
  private func string(_ arguments: JSON, _ key: String, default fallback: String? = nil) throws
    -> String
  {
    if arguments.object?[key] == nil, let fallback { return fallback }
    guard let value = arguments[key].string else {
      throw InvalidArgument(message: "\(key) must be a string")
    }
    return value
  }
  private func optional(_ arguments: JSON, _ key: String) throws -> String? {
    arguments[key] == .null ? nil : try string(arguments, key)
  }
  private func force(_ arguments: JSON) throws -> Bool {
    if arguments.object?["force"] == nil { return false }
    guard case .bool(let value) = arguments["force"] else {
      throw InvalidArgument(message: "force must be a boolean")
    }
    return value
  }
  private func destination(_ arguments: JSON) throws -> String {
    fs.expandUser(try string(arguments, "destination"))
  }
  private func presetCode(_ arguments: JSON) throws -> String {
    let text = try string(arguments, "code")
    guard let code = Preset.code(in: text) else {
      throw RegistryError("invalid preset code: \(pythonRepr(text))")
    }
    return code
  }
  private func bool(_ arguments: JSON, _ key: String, default fallback: Bool) throws -> Bool {
    if arguments.object?[key] == nil { return fallback }
    guard case .bool(let value) = arguments[key] else {
      throw InvalidArgument(message: "\(key) must be a boolean")
    }
    return value
  }
  private func changedFiles(_ arguments: JSON) throws -> [String] {
    let changed = arguments["changedFiles"]
    if changed == .null { return [] }
    guard let files = changed.array, files.allSatisfy({ $0.string != nil }) else {
      throw InvalidArgument(message: "changedFiles must be an array of strings")
    }
    return changed.strings
  }
  private func object(_ arguments: JSON, _ key: String) throws -> JSON? {
    let value = arguments[key]
    if value == .null { return nil }
    guard value.object != nil else { throw InvalidArgument(message: "\(key) must be an object") }
    return value
  }
  /// A design tool's file: `file` as given, or `name` in the simulator app container.
  private func designFile(_ name: String, _ arguments: JSON) throws -> String {
    try AppContainer.locate(
      name, file: optional(arguments, "file"), udid: optional(arguments, "udid"),
      bundleId: optional(arguments, "bundleId"))
  }
  private func perform(_ tool: String, _ arguments: JSON) throws -> OrderedJSON {
    if tool == "list_design_notes" {
      let includeAnswered = try bool(arguments, "includeAnswered", default: false)
      let file = try designFile(DesignNotes.fileName, arguments)
      let listed = try DesignNotes.list(file: file, includeAnswered: includeAnswered)
      return [
        "file": .string(file), "notes": .array(listed.notes.map { OrderedJSON($0) }),
        "proposals": .array(listed.proposals.map { OrderedJSON($0) }),
        "nextSteps": [
          "A note names its subject and the tokens the item reads; act on it in source, or offer a design with propose_design and its note id",
          "Answer each note with answer_design_note; a reply note follows the note or proposal named by inReplyTo",
          "A proposal's state is the person's decision: offered, trying, kept, or discarded",
        ],
      ]
    }
    if tool == "answer_design_note" {
      let file = try designFile(DesignNotes.fileName, arguments)
      let answered = try DesignNotes.answer(
        id: string(arguments, "id"), reply: string(arguments, "reply"),
        changedFiles: changedFiles(arguments), file: file)
      return ["file": .string(file), "note": OrderedJSON(answered)]
    }
    if tool == "propose_design" {
      let file = try designFile(DesignAgentFile.fileName, arguments)
      let proposal = try DesignProposals.propose(
        .init(
          name: string(arguments, "name"), reason: optional(arguments, "reason"),
          note: optional(arguments, "note"), code: optional(arguments, "code"),
          tokens: object(arguments, "tokens"), knobs: object(arguments, "knobs"),
          apply: bool(arguments, "apply", default: true)),
        file: file)
      return [
        "file": .string(file), "proposal": OrderedJSON(proposal),
        "nextSteps": [
          proposal["apply"] == true
            ? "Tune tries it on the device at once, merged over the current design version; call get_design_context and read its screenshot to check it"
            : "It waits in Tune's Notes for the person to try",
          "list_design_notes reports whether the person kept or discarded it",
        ],
      ]
    }
    if tool == "read_handoff" {
      let file = try designFile(DesignHandoffs.fileName, arguments)
      let handoff = try DesignHandoffs.read(file: file)
      let code = handoff["presetCode"].text
      return [
        "file": .string(file), "handoff": OrderedJSON(handoff),
        "nextSteps": [
          .string(
            code.isEmpty
              ? "The design is Source, the app's own theme: leave the theme in source as it is"
              : "Write the theme into source: apply_preset with code \(code) and the app's destination, or paste the swift field at the scene root"
          ),
          "Write each knob under knobs as the item's new shipped default in its source",
          "Act on each open note (read its screenshotPath), then answer_design_note with its id",
          .string(
            "Then answer_handoff with id \(handoff["id"].text) and the changedFiles; Tune clears its token and knob overrides so the source shows"
          ),
        ],
      ]
    }
    if tool == "answer_handoff" {
      let file = try designFile(DesignHandoffs.fileName, arguments)
      let answered = try DesignHandoffs.answer(
        id: string(arguments, "id"), reply: string(arguments, "reply"),
        changedFiles: changedFiles(arguments), file: file)
      var result: OrderedJSON = [
        "file": .string(file), "id": .string(answered.id), "answer": OrderedJSON(answered.answer),
      ]
      if let newer = answered.newer {
        result["newer"] = OrderedJSON(newer)
        result["nextSteps"] = [
          .string(
            "A newer hand-off waits (\(newer["id"].text)); call read_handoff to read it")
        ]
      }
      return result
    }
    if tool == "get_design_context" {
      let file = try designFile(DesignContext.fileName, arguments)
      return ["file": .string(file), "context": OrderedJSON(try DesignContext.read(file: file))]
    }
    if tool == "describe_preset" {
      return try OrderedJSON.read(Data(Preset.description(presetCode(arguments), json: true).utf8))
    }
    if tool == "apply_preset" {
      let code = try presetCode(arguments)
      let forced = try force(arguments)
      let path = try Preset.apply(code, destination: destination(arguments), force: forced)
      return [
        "code": .string(code), "file": .string(path),
        "nextSteps": [
          "Ensure the destination folder is a member of the consuming build target",
          "Apply the theme once at the scene root: ContentView().registryTheme(.app)",
        ],
      ]
    }
    // Reload and validate on every call so metadata edits are visible without a restart.
    let installer = try Installer(root: root)
    let registry = installer.registry
    if tool == "search_items" {
      let matches = try registry.search(
        string(arguments, "query", default: ""), kind: optional(arguments, "kind"),
        platform: optional(arguments, "platform"),
        targetVersion: optional(arguments, "targetVersion"))
      return [
        "items": .array(
          matches.map {
            .fields(
              $0,
              [
                "name", "kind", "version", "description", "score", "registryDependencies", "tags",
                "aliases",
              ])
          })
      ]
    }
    let name = try string(arguments, "name")
    if tool == "describe_item" {
      return try describeItem(name, registry: registry, fs: fs, root: root)
    }
    if tool == "install_item" {
      let forced = try force(arguments)
      let installed = try installer.install(
        name, destination: destination(arguments), force: forced)
      return [
        "item": .string(name),
        "installed": .array(
          installed.map { ["item": .string($0.item), "target": .string($0.target)] }),
        "upToDate": .scalar(.bool(installed.isEmpty)),
        "packageRequirements": .array(
          try registry.packageRequirements(name).map(packageDescription)),
      ]
    }
    let destination = try destination(arguments)
    if tool == "diff_item" {
      let entries = try installer.diff(name, destination: destination)
      return [
        "item": .string(name), "identical": .scalar(.bool(entries.allSatisfy { $0.diff.isEmpty })),
        "files": .array(
          entries.map {
            [
              "item": .string($0.file.item), "target": .string($0.file.target),
              "diff": .string($0.diff),
            ]
          }),
      ]
    }
    let entries = try installer.inspectPlan(name, destination: destination)
    return [
      "item": .string(name), "destination": .string(fs.resolve(destination)),
      "closure": .array(
        try registry.resolve(name).map {
          .fields(registry.items[$0]!, ["name", "version", "kind"])
        }),
      "files": .array(
        entries.map {
          [
            "item": .string($0.file.item), "target": .string($0.file.target),
            "status": .string($0.status.rawValue),
          ]
        }),
      "packageRequirements": .array(
        try registry.packageRequirements(name).map { .string(Registry.dependencyInstruction($0)) }),
      "collisions": .array(
        entries.filter { $0.status == .modifiedWouldRequireForce }.map {
          .string($0.file.target)
        }),
      "stale": .array(
        entries.filter { $0.status == .wouldMerge }.map { .string($0.file.target) }),
      "nextSteps": [
        "Add each package requirement to the consuming project; the installer never edits project files",
        "Ensure the destination folder is a member of the consuming build target",
        .string("Call install_item with name \(name) and this destination"),
      ],
    ]
  }
}

private func pythonRepr(_ text: String) -> String {
  let quote = text.contains("'") && !text.contains("\"") ? "\"" : "'"
  let body = text.replacingOccurrences(of: "\\", with: "\\\\")
    .replacingOccurrences(of: quote, with: "\\" + quote)
    .replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r")
    .replacingOccurrences(of: "\t", with: "\\t")
  return quote + body + quote
}
