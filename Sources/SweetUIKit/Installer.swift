import CryptoKit
import Dependencies
import Foundation

public struct PlannedFile: Equatable, Sendable {
  public var item: String
  public var source: String
  public var target: String
}
/// A file's status, generic over which vocabulary produced it: `plan`/`update`
/// share the `(file, status)` shape but never the same set of cases.
public struct FileStatus<Status: Equatable & Sendable>: Equatable, Sendable {
  public var file: PlannedFile
  public var status: Status
}
public enum PlanFileStatus: String, Equatable, Sendable {
  case new
  case upToDate = "up-to-date"
  case wouldMerge = "would-merge"
  case modifiedWouldRequireForce = "modified-would-require-force"
}
public enum UpdateFileStatus: String, Equatable, Sendable {
  case unchanged
  case updated
  case locallyModified = "locally-modified"
  case merged
}
public struct FileDiff: Equatable, Sendable {
  public var file: PlannedFile
  public var diff: String
}

public struct Installer {
  public var registry: Registry
  @Dependency(\.registryFileSystem) var fs
  @Dependency(\.registrySourceMerger) var merger
  public init(registry: Registry) { self.registry = registry }
  public init(root: String) throws { registry = try Registry(root: root) }

  public func plan(_ name: String, destination: String) throws -> [PlannedFile] {
    let destination = fs.resolve(destination)
    var planned: [PlannedFile] = []
    var targets = Set<String>()
    for member in try registry.resolve(name) {
      for file in registry.items[member]!["files"].array ?? [] {
        let source = try safeJoin(registry.root + "/Registry", file["source"].text, fs: fs)
        let target = try safeJoin(destination, file["target"].text, fs: fs)
        guard fs.isFile(source) else { throw RegistryError("Missing source file: \(source)") }
        guard targets.insert(target).inserted else {
          throw RegistryError("Multiple files target \(target)")
        }
        planned.append(.init(item: member, source: source, target: target))
      }
    }
    return planned
  }
  public func inspectPlan(_ name: String, destination: String) throws -> [FileStatus<
    PlanFileStatus
  >] {
    let destination = fs.resolve(destination)
    let files = try plan(name, destination: destination)
    let receipt = try readReceipt(destination)
    return try files.map { file in
      let record = receipt["files"][key(file, destination)]
      let status: PlanFileStatus
      if !fs.exists(file.target) {
        status = .new
      } else if try matchesReceipt(file, record, destination) {
        status = .upToDate
      } else if let base = record["base"].string,
        let path = Optional(try safeJoin(metadata(destination), base, fs: fs)), fs.isFile(path),
        try fs.read(path) != fs.read(file.source)
      {
        status = .wouldMerge
      } else {
        status = .modifiedWouldRequireForce
      }
      return .init(file: file, status: status)
    }
  }
  public func diff(_ name: String, destination: String) throws -> [FileDiff] {
    let destination = fs.resolve(destination)
    let receipt = try readReceipt(fs.resolve(destination), required: true)
    return try plan(name, destination: destination).map { file in
      let key = key(file, destination)
      guard receipt["files"][key].object != nil else {
        throw RegistryError("No receipt entry for \(file.target); install \(file.item) first")
      }
      guard fs.isFile(file.target) else {
        throw RegistryError("Installed source is missing: \(file.target)")
      }
      let owned = try fs.read(file.target)
      let incoming = try fs.read(file.source)
      return .init(
        file: file,
        diff: owned == incoming
          ? ""
          : unifiedDiff(
            owned, incoming, from: "owned/" + key,
            to: "incoming/" + String(file.source.dropFirst((registry.root + "/Registry/").count))))
    }
  }
  public func install(_ name: String, destination: String, force: Bool = false) throws
    -> [PlannedFile]
  {
    let destination = fs.resolve(destination)
    let files = try plan(name, destination: destination)
    var receipt = try readReceipt(destination)
    var conflicts: [String] = []
    for file in files where fs.exists(file.target) && !force {
      if try !matchesReceipt(file, receipt["files"][key(file, destination)], destination) {
        conflicts.append(file.target)
      }
    }
    if !conflicts.isEmpty {
      throw RegistryError(
        "Refusing to overwrite owned source:\n" + conflicts.joined(separator: "\n")
          + "\nInspect local changes with --diff, merge registry changes with --update, or replace the files with --force"
      )
    }
    var installed: [PlannedFile] = []
    for file in files {
      let content = try fs.read(file.source)
      if !fs.exists(file.target) || force {
        try fs.createDirectory((file.target as NSString).deletingLastPathComponent)
        try fs.write(content, to: file.target)
        installed.append(file)
      }
      try recordFile(&receipt, file, destination, base: content, installed: fs.read(file.target))
      try fs.remove(conflictPath(file, destination))
    }
    try recordItems(&receipt, name)
    try writeReceipt(receipt, destination)
    return installed
  }
  public func update(_ name: String, destination: String) throws -> [FileStatus<
    UpdateFileStatus
  >] {
    let destination = fs.resolve(destination)
    let files = try plan(name, destination: destination)
    var receipt = try readReceipt(destination, required: true)
    var decisions: [(PlannedFile, Data, Data, UpdateFileStatus)] = []
    var conflicts: [(PlannedFile, Data)] = []
    for file in files {
      let record = receipt["files"][key(file, destination)]
      guard record.object != nil else {
        throw RegistryError("No valid receipt entry for \(file.target); install it first")
      }
      guard fs.isFile(file.target) else {
        throw RegistryError("Installed source is missing: \(file.target)")
      }
      guard let baseValue = record["base"].string else {
        throw RegistryError("Invalid receipt base for \(file.target)")
      }
      let basePath = try safeJoin(metadata(destination), baseValue, fs: fs)
      guard fs.isFile(basePath) else { throw RegistryError("Receipt base is missing: \(basePath)") }
      let current = try fs.read(file.target)
      let base = try fs.read(basePath)
      let incoming = try fs.read(file.source)
      guard Self.digest(base) == record["sourceDigest"].text else {
        throw RegistryError("Receipt base digest mismatch for \(file.target)")
      }
      if current == base {
        decisions.append((file, incoming, incoming, incoming == base ? .unchanged : .updated))
      } else if incoming == base {
        decisions.append((file, current, base, .locallyModified))
      } else {
        let merged = try merger.merge(current, base, incoming, key(file, destination))
        if merged.hasConflict {
          conflicts.append((file, merged.content))
        } else {
          decisions.append((file, merged.content, incoming, .merged))
        }
      }
    }
    if !conflicts.isEmpty {
      try fs.createDirectory(metadata(destination) + "/conflicts")
      for (file, data) in conflicts { try fs.write(data, to: conflictPath(file, destination)) }
      throw RegistryError(
        "Update has merge conflicts; owned source was not changed:\n"
          + conflicts.map { conflictPath($0.0, destination) }.joined(separator: "\n"))
    }
    for (file, target, base, _) in decisions {
      try fs.write(target, to: file.target)
      try recordFile(&receipt, file, destination, base: base, installed: target)
      try fs.remove(conflictPath(file, destination))
    }
    try recordItems(&receipt, name)
    try writeReceipt(receipt, destination)
    return decisions.map { .init(file: $0.0, status: $0.3) }
  }

  private func matchesReceipt(_ file: PlannedFile, _ record: JSON, _ destination: String) throws
    -> Bool
  {
    guard record.object != nil, fs.isFile(file.target), let base = record["base"].string else {
      return false
    }
    let source = try fs.read(file.source)
    let current = try fs.read(file.target)
    let path = try safeJoin(metadata(destination), base, fs: fs)
    return try fs.isFile(path) && Self.digest(source) == record["sourceDigest"].text
      && Self.digest(current) == record["installedDigest"].text && fs.read(path) == source
  }
  private func recordItems(_ receipt: inout JSON, _ name: String) throws {
    for member in try registry.resolve(name) {
      let item = registry.items[member]!
      receipt["items"][member] = [
        "version": item["version"], "registryDependencies": item["registryDependencies"],
        "packageDependencies": item["packageDependencies"],
      ]
    }
  }
  private func recordFile(
    _ receipt: inout JSON, _ file: PlannedFile, _ destination: String, base: Data, installed: Data
  ) throws {
    let key = key(file, destination)
    let relative = "bases/" + Self.identifier(key) + ".base"
    try fs.createDirectory(metadata(destination) + "/bases")
    try fs.write(base, to: metadata(destination) + "/" + relative)
    receipt["files"][key] = [
      "item": .string(file.item), "version": registry.items[file.item]!["version"],
      "sourceDigest": .string(Self.digest(base)),
      "installedDigest": .string(Self.digest(installed)), "base": .string(relative),
    ]
  }
  private func readReceipt(_ destination: String, required: Bool = false) throws -> JSON {
    let path = metadata(destination) + "/receipt.json"
    if !fs.exists(path) {
      if required { throw RegistryError("Installation receipt is missing: \(path)") }
      return ["schemaVersion": 1, "registry": .string(registry.name), "items": [:], "files": [:]]
    }
    let receipt: JSON
    do { receipt = try JSON.read(fs.read(path)) } catch {
      throw RegistryError("Cannot read \(path): \(error)")
    }
    guard receipt.object != nil else { throw RegistryError("Expected a JSON object in \(path)") }
    guard receipt["schemaVersion"] == 1 else {
      throw RegistryError("Unsupported receipt schema version in \(path)")
    }
    guard receipt["registry"].text == registry.name else {
      throw RegistryError("Receipt belongs to another registry: \(path)")
    }
    guard receipt["items"].object != nil, receipt["files"].object != nil else {
      throw RegistryError("Invalid receipt structure in \(path)")
    }
    return receipt
  }
  private func writeReceipt(_ receipt: JSON, _ destination: String) throws {
    let root = metadata(destination)
    try fs.createDirectory(root)
    try fs.write(Data((receipt.rendered() + "\n").utf8), to: root + "/receipt.json.tmp")
    try fs.replace(root + "/receipt.json.tmp", root + "/receipt.json")
  }
  private func metadata(_ destination: String) -> String { destination + "/.sweetui" }
  private func key(_ file: PlannedFile, _ destination: String) -> String {
    String(file.target.dropFirst(destination.count + 1))
  }
  private func conflictPath(_ file: PlannedFile, _ destination: String) -> String {
    metadata(destination) + "/conflicts/" + Self.identifier(key(file, destination)) + ".merge"
  }
  public static func identifier(_ target: String) -> String {
    SHA256.hash(data: Data(target.utf8)).map { String(format: "%02x", $0) }.joined()
  }
  public static func digest(_ data: Data) -> String {
    "sha256:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}
