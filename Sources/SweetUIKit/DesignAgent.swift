import Dependencies
import Foundation

/// `design-agent.json` beside Tune's files, the one file the agent writes:
/// `read` (note and hand-off ids to the dates the agent read them), `answers`
/// keyed by note or hand-off id, and `proposals`. Tune only reads it, so a
/// write here is never lost to the panel's own saves.
public enum DesignAgentFile {
  public static let fileName = "design-agent.json"

  /// The record at `path`, every part present. A missing or 0-byte file is
  /// an empty record: Sharing creates the file it watches before the agent
  /// writes it.
  public static func read(_ path: String) throws -> [String: JSON] {
    @Dependency(\.registryFileSystem) var fs
    var record: [String: JSON] = [:]
    if fs.isFile(path) {
      let data = try fs.read(path)
      if !data.isEmpty {
        guard let object = (try? JSON.read(data))?.object else {
          throw RegistryError("\(path) is not a design-agent record")
        }
        record = object
      }
    }
    var read = record["read"]?.object ?? [:]
    read["notes"] = .object(read["notes"]?.object ?? [:])
    read["handoffs"] = .object(read["handoffs"]?.object ?? [:])
    record["read"] = .object(read)
    record["answers"] = .object(record["answers"]?.object ?? [:])
    record["proposals"] = .array(record["proposals"]?.array ?? [])
    return record
  }

  /// Reads the record, changes it, and writes it back in one atomic
  /// replace, so Tune never reads half a file.
  @discardableResult
  public static func update<R>(_ path: String, _ change: (inout [String: JSON]) throws -> R) throws
    -> R
  {
    @Dependency(\.registryFileSystem) var fs
    var record = try read(path)
    let result = try change(&record)
    let temporary = path + ".writing"
    try fs.write(Data(JSON.object(record).rendered().utf8), to: temporary)
    try fs.replace(temporary, path)
    return result
  }

  /// Stamps a read date per id, under `notes` or `handoffs`.
  static func stampRead(_ ids: [String], as kind: String, in path: String) throws {
    guard !ids.isEmpty else { return }
    @Dependency(\.date.now) var now
    let date = JSON.string(ISO8601DateFormatter().string(from: now))
    try update(path) { record in
      var read = record["read"]?.object ?? [:]
      var stamped = read[kind]?.object ?? [:]
      for id in ids { stamped[id] = date }
      read[kind] = .object(stamped)
      record["read"] = .object(read)
    }
  }

  /// Writes an answer under its note's or hand-off's id and returns it.
  static func writeAnswer(id: String, reply: String, changedFiles: [String], in path: String)
    throws -> JSON
  {
    @Dependency(\.date.now) var now
    let answer: JSON = [
      "reply": .string(reply), "changedFiles": .array(changedFiles.map(JSON.string)),
      "date": .string(ISO8601DateFormatter().string(from: now)),
    ]
    try update(path) { record in
      var answers = record["answers"]?.object ?? [:]
      answers[id] = answer
      record["answers"] = .object(answers)
    }
    return answer
  }

  /// The path of a file beside `file`, in the same Documents folder.
  static func beside(_ file: String, _ name: String) -> String {
    (file as NSString).deletingLastPathComponent + "/" + name
  }
}

/// Designs the agent offers the person: appended to `design-agent.json`,
/// tried by Tune when `apply` is true, and decided by the person (kept or
/// discarded) in `design-history.json`. A proposal carries a full code or
/// tokens as a delta over the version it is tried on, and knobs with `null`
/// for a knob's default. Nothing here writes the panel's value files.
public enum DesignProposals {
  public struct Input: Sendable {
    public var name: String
    public var reason: String?
    public var note: String?
    public var code: String?
    public var tokens: JSON?
    public var knobs: JSON?
    public var apply: Bool

    public init(
      name: String, reason: String? = nil, note: String? = nil, code: String? = nil,
      tokens: JSON? = nil, knobs: JSON? = nil, apply: Bool = true
    ) {
      self.name = name
      self.reason = reason
      self.note = note
      self.code = code
      self.tokens = tokens
      self.knobs = knobs
      self.apply = apply
    }
  }

  /// The keys a code decodes to, the only keys a token delta may name.
  public static let tokenKeys: [String] =
    ["accent", "darkLabelOnAccent"] + Preset.fields.map(\.key)
    + ["customAccent", "customAccentDark", "fontDesign", "surfaceStep", "chartPalette"]
    + Preset.colorPairs.flatMap { [$0.0, $0.1] }

  /// Validates the proposal and appends it to the agent's file at `file`;
  /// returns it as written. Refuses code and tokens when the context beside
  /// it says the host does not tune the theme, and a note id the notes file
  /// does not hold. Writes nothing on a refusal.
  public static func propose(_ input: Input, file: String) throws -> JSON {
    @Dependency(\.registryFileSystem) var fs
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { throw RegistryError("name must not be empty") }
    if input.code != nil, input.tokens != nil {
      throw RegistryError("give code or tokens, not both")
    }
    var proposal: [String: JSON] = [
      "id": .string(uuid().uuidString), "date": .string(ISO8601DateFormatter().string(from: now)),
      "name": .string(name), "apply": .bool(input.apply),
    ]
    if let reason = input.reason, !reason.isEmpty { proposal["reason"] = .string(reason) }
    if let text = input.code {
      guard let code = Preset.code(in: text), Preset.decode(code) != nil else {
        throw RegistryError("invalid preset code: \(text)")
      }
      proposal["code"] = .string(code)
    }
    if let tokens = input.tokens {
      guard let delta = tokens.object, !delta.isEmpty else {
        throw RegistryError("tokens must be an object of describe_preset keys to values")
      }
      try validate(tokens: delta)
      proposal["tokens"] = tokens
    }
    if let knobs = input.knobs {
      try validate(knobs: knobs)
      proposal["knobs"] = knobs
    }
    guard proposal["code"] != nil || proposal["tokens"] != nil || proposal["knobs"] != nil else {
      throw RegistryError("give code, tokens, or knobs: a proposal must change something")
    }
    if proposal["code"] != nil || proposal["tokens"] != nil {
      let context = DesignAgentFile.beside(file, DesignContext.fileName)
      if fs.isFile(context), (try? JSON.read(fs.read(context)))?["tunesTheme"] == false {
        throw RegistryError(
          "this host does not tune the theme (tunesTheme is false in \(DesignContext.fileName)); propose knobs only"
        )
      }
    }
    if let note = input.note {
      let notes = try DesignNotes.notes(DesignAgentFile.beside(file, DesignNotes.fileName))
      guard let id = DesignNotes.id(note, in: notes) else {
        throw RegistryError("no note \(note) in \(DesignNotes.fileName)")
      }
      proposal["note"] = .string(id)
    }
    let written = JSON.object(proposal)
    try DesignAgentFile.update(file) { record in
      record["proposals"] = .array((record["proposals"]?.array ?? []) + [written])
    }
    return written
  }

  /// Each key is one a code decodes to, with a value of its kind.
  static func validate(tokens: [String: JSON]) throws {
    for (key, value) in tokens.sorted(by: { $0.key < $1.key }) {
      func word(_ words: [String]) throws {
        guard let text = value.string, words.contains(text) else {
          throw RegistryError("\(key) must be one of \(words.joined(separator: ", "))")
        }
      }
      switch key {
      case "accent": try word(Preset.accents)
      case "fontDesign": try word(Preset.fontDesigns)
      case "chartPalette": try word(Preset.chartPalettes)
      case "darkLabelOnAccent":
        guard case .bool = value else { throw RegistryError("\(key) must be true or false") }
      case "customAccent":
        guard let color = value.string, matches(color, "^#[0-9A-Fa-f]{6}$") else {
          throw RegistryError("\(key) must be #RRGGBB")
        }
      case _
      where Preset.colorPairs.contains(where: { $0.0 == key || $0.1 == key })
        || key == "customAccentDark":
        guard value == .null || value.string.map({ matches($0, "^#[0-9A-Fa-f]{6}$") }) == true
        else { throw RegistryError("\(key) must be #RRGGBB or null") }
      case _ where tokenKeys.contains(key):
        guard let number = value.number, number.isFinite else {
          throw RegistryError("\(key) must be a number")
        }
        try onGrid(key, number)
      default:
        throw RegistryError(
          "\(key) is not a token; give describe_preset keys: \(tokenKeys.joined(separator: ", "))")
      }
    }
  }

  /// A number a code can carry exactly: a step of its field's grid, or one of
  /// the surface steps. A code rounds any other value, so the device would
  /// show a value the agent's file does not hold.
  static func onGrid(_ key: String, _ number: Double) throws {
    func text(_ value: Double, _ decimals: Int) -> String {
      var text = String(format: "%.\(decimals)f", value)
      while text.contains("."), text.hasSuffix("0") || text.hasSuffix(".") { text.removeLast() }
      return text
    }
    if key == "surfaceStep" {
      guard Preset.surfaceSteps.contains(where: { abs($0 - number) < 1e-9 }) else {
        let steps = Preset.surfaceSteps.sorted().map { text($0, 2) }
        throw RegistryError(
          "surfaceStep must be one of \(steps.joined(separator: ", ")), not \(text(number, 4))")
      }
      return
    }
    guard let field = Preset.fields.first(where: { $0.key == key }) else { return }
    let index = (number - field.minimum) / field.step
    let maximum = field.minimum + Double(field.count - 1) * field.step
    guard abs(index - index.rounded()) < 1e-6, index.rounded() >= 0,
      index.rounded() < Double(field.count)
    else {
      throw RegistryError(
        "\(key) must be on its grid, \(text(field.minimum, field.decimals)) to \(text(maximum, field.decimals)) "
          + "in steps of \(text(field.step, field.decimals)), not \(text(number, field.decimals + 2))"
      )
    }
  }

  /// `{item: {knob: number or null}}`, null returning a knob to its default.
  static func validate(knobs: JSON) throws {
    guard let items = knobs.object, !items.isEmpty else {
      throw RegistryError("knobs must be an object of item names to {knob: number or null}")
    }
    for (item, values) in items {
      guard let values = values.object, !values.isEmpty else {
        throw RegistryError("knobs.\(item) must be an object of knob names to numbers or null")
      }
      for (knob, value) in values where value != .null {
        guard let number = value.number, number.isFinite else {
          throw RegistryError("knob \(item).\(knob) must be a finite number or null")
        }
      }
    }
  }
}
