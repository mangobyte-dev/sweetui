import Foundation
import SweetUIKit
import Synchronization

/// The storage behind an in-memory `FileSystem`; `fileSystem` is the value a test installs.
final class InMemoryFileSystem: Sendable {
  var fileSystem: FileSystem {
    FileSystem(
      currentDirectory: { self.currentDirectory }, resolve: resolve, expandUser: expandUser,
      exists: exists, isFile: isFile, isDirectory: isDirectory, read: read,
      write: { try self.write($0, to: $1) }, createDirectory: createDirectory, remove: remove,
      replace: replace, children: children)
  }
  enum Entry: Equatable, Sendable {
    case directory
    case file(Data)
    case link(String)
  }
  let storage = Mutex<[String: Entry]>(["/": .directory])
  let workingDirectory = Mutex("/registry")
  var currentDirectory: String { workingDirectory.withLock { $0 } }
  func expandUser(_ path: String) -> String {
    if path == "~" { return "/home/test" }
    return path.hasPrefix("~/") ? "/home/test/" + path.dropFirst(2) : path
  }
  func resolve(_ path: String) -> String {
    var components: [String] = []
    let path = path.hasPrefix("/") ? path : currentDirectory + "/" + path
    for part in path.split(separator: "/") {
      if part == "." { continue }
      if part == ".." {
        if !components.isEmpty { components.removeLast() }
        continue
      }
      components.append(String(part))
      let prefix = "/" + components.joined(separator: "/")
      if case .link(let destination) = storage.withLock({ $0[prefix] }) {
        components = destination.split(separator: "/").map(String.init)
      }
    }
    return "/" + components.joined(separator: "/")
  }
  func exists(_ path: String) -> Bool {
    let key = resolve(path)
    return storage.withLock { $0[key] != nil }
  }
  func isDirectory(_ path: String) -> Bool {
    let key = resolve(path)
    return storage.withLock { $0[key] == .directory }
  }
  func isFile(_ path: String) -> Bool {
    let key = resolve(path)
    return storage.withLock { if case .file = $0[key] { true } else { false } }
  }
  func read(_ path: String) throws -> Data {
    let key = resolve(path)
    return try storage.withLock {
      guard case .file(let data) = $0[key] else { throw RegistryError("Missing file: \(key)") }
      return data
    }
  }
  func write(_ data: Data, to path: String) throws {
    let key = resolve(path)
    guard isDirectory((key as NSString).deletingLastPathComponent) else {
      throw RegistryError("Missing parent: \(key)")
    }
    storage.withLock { $0[key] = .file(data) }
  }
  func createDirectory(_ path: String) throws {
    let key = resolve(path)
    if key != "/" { try createDirectory((key as NSString).deletingLastPathComponent) }
    try storage.withLock {
      if let value = $0[key], value != .directory { throw RegistryError("Not a directory: \(key)") }
      $0[key] = .directory
    }
  }
  func remove(_ path: String) throws {
    let key = resolve(path)
    storage.withLock { $0 = $0.filter { $0.key != key && !$0.key.hasPrefix(key + "/") } }
  }
  func replace(_ source: String, _ target: String) throws {
    let from = resolve(source)
    let to = resolve(target)
    try storage.withLock { entries in
      guard entries[from] != nil else { throw RegistryError("Missing file: \(from)") }
      for (key, value) in entries where key == from || key.hasPrefix(from + "/") {
        entries[to + key.dropFirst(from.count)] = value
        entries.removeValue(forKey: key)
      }
    }
  }
  func children(_ path: String) throws -> [String] {
    let key = resolve(path)
    guard isDirectory(key) else { throw RegistryError("Missing directory: \(key)") }
    return storage.withLock {
      $0.keys.filter { ($0 as NSString).deletingLastPathComponent == key && $0 != key }.sorted()
    }
  }
  func put(_ path: String, _ text: String) throws {
    try createDirectory((resolve(path) as NSString).deletingLastPathComponent)
    try write(Data(text.utf8), to: path)
  }
  func snapshot(_ root: String = "/app") -> String {
    let entries = storage.withLock { $0.filter { $0.key == root || $0.key.hasPrefix(root + "/") } }
    return entries.keys.sorted().map { path in
      let relative = path == root ? "." : String(path.dropFirst(root.count + 1))
      switch entries[path]! {
      case .directory: return relative + "/"
      case .file(let data):
        return relative + "\n"
          + String(decoding: data, as: UTF8.self).split(
            separator: "\n", omittingEmptySubsequences: false
          ).map { "  " + $0 }.joined(separator: "\n")
      case .link(let target): return relative + " -> " + target
      }
    }.joined(separator: "\n")
  }
}

extension RegistrySource {
  static let inMemory = RegistrySource { override, _ in override ?? "/registry" }
}
