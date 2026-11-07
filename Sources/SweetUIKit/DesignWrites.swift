import Dependencies
import Foundation

/// The agent's hand on the device: writes to the design surface's files
/// that the Tune panel follows live through its file watch, with the
/// previous values recorded in `design-agent-change.json` so the panel can
/// offer Undo. No rebuild: a preset code and a knob value apply at runtime.
public enum DesignWrites {
  public static let tokensFileName = "registry-tokens.json"
  public static let knobsFileName = "design-knobs.json"
  public static let changeFileName = "design-agent-change.json"

  /// Writes a theme as its preset code: `code` as given, or `tuning` (any
  /// subset of the decode keys) merged over the code the file carries now.
  /// The environment switches in the file stay. Returns the code written.
  public static func setTuning(code: String?, tuning: JSON?, file: String) throws -> String {
    @Dependency(\.registryFileSystem) var fs
    let current = fs.isFile(file) ? try JSON.read(fs.read(file)) : [:]
    let currentCode = current["code"].string
    let written: String
    if let code {
      guard let found = Preset.code(in: code) else {
        throw RegistryError("invalid preset code: \(code)")
      }
      written = found
    } else if let tuning, var merged = tuning.object {
      guard
        var base = (currentCode.flatMap(Preset.decode) ?? Preset.decode("a13GkaOXWwIF"))?.object
      else { throw RegistryError("the file's code does not decode: \(currentCode ?? "")") }
      for (key, value) in merged { base[key] = value }
      merged = base
      written = try Preset.encode(.object(merged))
    } else {
      throw RegistryError("give code, or a tuning object")
    }
    var document: [String: JSON] = [
      "code": .string(written), "version": .string(String(written.prefix(1))),
    ]
    if let environment = current.object?["environment"] { document["environment"] = environment }
    try fs.createDirectory((file as NSString).deletingLastPathComponent)
    try fs.write(Data(JSON.object(document).rendered().utf8), file)
    try recordChange(
      [
        "what": "tuning", "previousCode": currentCode.map(JSON.string) ?? .null,
        "code": .string(written),
      ],
      beside: file)
    return written
  }

  /// Merges knob values into `design-knobs.json`: `values` maps a knob name
  /// to a number, or to `null` to return it to its shipped default.
  public static func setKnobs(item: String, values: JSON, file: String) throws -> JSON {
    @Dependency(\.registryFileSystem) var fs
    guard let updates = values.object, !updates.isEmpty else {
      throw RegistryError("values must be an object of knob names to numbers or null")
    }
    var knobs = fs.isFile(file) ? (try JSON.read(fs.read(file)).object ?? [:]) : [:]
    let previous = knobs[item] ?? .null
    var current = knobs[item]?.object ?? [:]
    for (name, value) in updates {
      switch value {
      case .null: current[name] = nil
      case .number(let number) where number.isFinite: current[name] = .number(number)
      default: throw RegistryError("knob \(name) must be a finite number or null")
      }
    }
    knobs[item] = current.isEmpty ? nil : .object(current)
    try fs.createDirectory((file as NSString).deletingLastPathComponent)
    try fs.write(Data(JSON.object(knobs).rendered().utf8), file)
    try recordChange(
      [
        "what": "knobs", "item": .string(item), "previousKnobs": previous,
        "knobs": knobs[item] ?? .null,
      ],
      beside: file)
    return knobs[item] ?? [:]
  }

  /// `design-agent-change.json` beside the file written: what changed and
  /// what it was, so the panel can show the change and undo it.
  private static func recordChange(_ change: [String: JSON], beside file: String) throws {
    @Dependency(\.registryFileSystem) var fs
    @Dependency(\.date.now) var now
    var record = change
    record["changedAt"] = .string(ISO8601DateFormatter().string(from: now))
    let path = (file as NSString).deletingLastPathComponent + "/" + changeFileName
    try fs.write(Data(JSON.object(record).rendered().utf8), path)
  }
}
