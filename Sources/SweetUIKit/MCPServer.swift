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
        "describe_preset", "apply_preset",
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
  private func perform(_ tool: String, _ arguments: JSON) throws -> OrderedJSON {
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
