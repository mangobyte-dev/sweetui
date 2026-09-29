import Dependencies
import Foundation

/// A read-only view of an installed destination, built from its receipt and the files on disk.
/// Independent of any registry clone: `info` reports what a consumer already owns.
public enum InventoryFileStatus: String, Equatable, Sendable {
  case missing
  case upToDate = "up-to-date"
  case modified
}
public struct InstalledInventory: Sendable {
  public struct File: Sendable, Equatable {
    public var target: String
    public var status: InventoryFileStatus
  }
  public struct Item: Sendable, Equatable {
    public var name: String
    public var version: String
    public var registryDependencies: [String]
    public var files: [File]
  }
  public var destination: String
  public var registry: JSON
  public var items: [Item]
  public var upToDate: Int
  public var modified: Int
  public var missing: Int
}

/// Read `<destination>/.sweetui/receipt.json` and compare each owned file on disk against
/// the digest the receipt recorded: `up-to-date` when they match, `modified` when they differ,
/// `missing` when the file is gone. Refuses with the installer's missing-receipt wording when the
/// receipt itself is absent.
public func inventory(destination: String) throws -> InstalledInventory {
  @Dependency(\.registryFileSystem) var fs
  let destination = fs.resolve(destination)
  let path = destination + "/.sweetui/receipt.json"
  guard fs.exists(path) else {
    throw RegistryError("Installation receipt is missing: \(path)")
  }
  let receipt: JSON
  do { receipt = try JSON.read(fs.read(path)) } catch {
    throw RegistryError("Cannot read \(path): \(error)")
  }
  var status: [String: InventoryFileStatus] = [:]
  var upToDate = 0
  var modified = 0
  var missing = 0
  for (key, record) in receipt["files"].object ?? [:] {
    let target = destination + "/" + key
    let state: InventoryFileStatus
    if !fs.isFile(target) {
      state = .missing
      missing += 1
    } else if try Installer.digest(fs.read(target)) == record["installedDigest"].text {
      state = .upToDate
      upToDate += 1
    } else {
      state = .modified
      modified += 1
    }
    status[key] = state
  }
  let filesByItem = Dictionary(grouping: (receipt["files"].object ?? [:]).keys) {
    receipt["files"][$0]["item"].text
  }
  let items = (receipt["items"].object ?? [:]).keys.sorted().map {
    name -> InstalledInventory.Item in
    let record = receipt["items"][name]
    let files = (filesByItem[name] ?? []).sorted().map {
      InstalledInventory.File(target: $0, status: status[$0] ?? .missing)
    }
    return InstalledInventory.Item(
      name: name, version: record["version"].text,
      registryDependencies: record["registryDependencies"].strings, files: files)
  }
  return InstalledInventory(
    destination: destination, registry: receipt["registry"], items: items, upToDate: upToDate,
    modified: modified, missing: missing)
}
