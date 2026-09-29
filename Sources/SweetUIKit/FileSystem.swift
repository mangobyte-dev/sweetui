import Dependencies
import Foundation
import IssueReporting

/// The file system as a struct of closures, the shape of every other effect here: one value per
/// context, no protocol. `write(_:to:)` keeps its label through a method over the closure.
public struct FileSystem: Sendable {
  public var currentDirectory: @Sendable () -> String
  public var resolve: @Sendable (String) -> String
  public var expandUser: @Sendable (String) -> String
  public var exists: @Sendable (String) -> Bool
  public var isFile: @Sendable (String) -> Bool
  public var isDirectory: @Sendable (String) -> Bool
  public var read: @Sendable (String) throws -> Data
  public var write: @Sendable (Data, String) throws -> Void
  public var createDirectory: @Sendable (String) throws -> Void
  public var remove: @Sendable (String) throws -> Void
  public var replace: @Sendable (String, String) throws -> Void
  public var children: @Sendable (String) throws -> [String]

  public init(
    currentDirectory: @escaping @Sendable () -> String,
    resolve: @escaping @Sendable (String) -> String,
    expandUser: @escaping @Sendable (String) -> String,
    exists: @escaping @Sendable (String) -> Bool,
    isFile: @escaping @Sendable (String) -> Bool,
    isDirectory: @escaping @Sendable (String) -> Bool,
    read: @escaping @Sendable (String) throws -> Data,
    write: @escaping @Sendable (Data, String) throws -> Void,
    createDirectory: @escaping @Sendable (String) throws -> Void,
    remove: @escaping @Sendable (String) throws -> Void,
    replace: @escaping @Sendable (String, String) throws -> Void,
    children: @escaping @Sendable (String) throws -> [String]
  ) {
    self.currentDirectory = currentDirectory
    self.resolve = resolve
    self.expandUser = expandUser
    self.exists = exists
    self.isFile = isFile
    self.isDirectory = isDirectory
    self.read = read
    self.write = write
    self.createDirectory = createDirectory
    self.remove = remove
    self.replace = replace
    self.children = children
  }

  public func write(_ data: Data, to path: String) throws { try write(data, path) }
}

extension FileSystem {
  /// The disk under the process, through `FileManager` and `realpath`.
  public static let local: FileSystem = {
    @Sendable func exists(_ path: String) -> Bool { FileManager.default.fileExists(atPath: path) }
    @Sendable func isDirectory(_ path: String) -> Bool {
      var flag = ObjCBool(false)
      return FileManager.default.fileExists(atPath: path, isDirectory: &flag) && flag.boolValue
    }
    @Sendable func resolve(_ path: String) -> String {
      if let resolved = realpath(path, nil) {
        defer { free(resolved) }
        return String(cString: resolved)
      }
      func walk(_ path: String, depth: Int) -> String {
        let absolute =
          path.hasPrefix("/") ? path : FileManager.default.currentDirectoryPath + "/" + path
        var parts: [String] = []
        for part in absolute.split(separator: "/") {
          if part == "." { continue }
          if part == ".." {
            if !parts.isEmpty { parts.removeLast() }
            continue
          }
          let parent = "/" + parts.joined(separator: "/")
          parts.append(String(part))
          if depth < 40,
            let link = try? FileManager.default.destinationOfSymbolicLink(
              atPath: "/" + parts.joined(separator: "/"))
          {
            let target = walk(link.hasPrefix("/") ? link : parent + "/" + link, depth: depth + 1)
            parts = target.split(separator: "/").map(String.init)
          }
        }
        return "/" + parts.joined(separator: "/")
      }
      return walk(path, depth: 0)
    }
    return FileSystem(
      currentDirectory: { FileManager.default.currentDirectoryPath },
      resolve: resolve,
      expandUser: { ($0 as NSString).expandingTildeInPath },
      exists: exists,
      isFile: { exists($0) && !isDirectory($0) },
      isDirectory: isDirectory,
      read: { try Data(contentsOf: URL(fileURLWithPath: $0)) },
      write: { try $0.write(to: URL(fileURLWithPath: $1)) },
      createDirectory: {
        try FileManager.default.createDirectory(atPath: $0, withIntermediateDirectories: true)
      },
      remove: { if exists($0) { try FileManager.default.removeItem(atPath: $0) } },
      replace: { source, target in
        guard rename(source, target) == 0 else {
          throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
      },
      children: { path in
        try FileManager.default.contentsOfDirectory(atPath: path).sorted().map { path + "/" + $0 }
      }
    )
  }()

  /// The test default: a test that forgets its override fails at the boundary instead of
  /// reaching the disk. The members that can throw do; the queries cannot, so each reports
  /// an issue and answers as an empty file system would.
  public static let unimplemented: FileSystem = {
    @Sendable func report(_ member: StaticString) {
      reportIssue("Unimplemented: @Dependency(\\.registryFileSystem).\(member)")
    }
    @Sendable func unimplemented(_ member: StaticString) -> RegistryError {
      RegistryError("no file system in tests: \(member)")
    }
    return FileSystem(
      currentDirectory: {
        report("currentDirectory")
        return "/"
      },
      resolve: {
        report("resolve")
        return $0
      },
      expandUser: {
        report("expandUser")
        return $0
      },
      exists: { _ in
        report("exists")
        return false
      },
      isFile: { _ in
        report("isFile")
        return false
      },
      isDirectory: { _ in
        report("isDirectory")
        return false
      },
      read: { _ in throw unimplemented("read") },
      write: { _, _ in throw unimplemented("write") },
      createDirectory: { _ in throw unimplemented("createDirectory") },
      remove: { _ in throw unimplemented("remove") },
      replace: { _, _ in throw unimplemented("replace") },
      children: { _ in throw unimplemented("children") }
    )
  }()
}

private enum FileSystemKey: DependencyKey {
  static let liveValue = FileSystem.local
  static let testValue = FileSystem.unimplemented
}
extension DependencyValues {
  public var registryFileSystem: FileSystem {
    get { self[FileSystemKey.self] }
    set { self[FileSystemKey.self] = newValue }
  }
}

/// Where the registry lives for this run. `repositoryRoot(override:refresh:)` keeps its labels
/// through a method over the closure.
public struct RegistrySource: Sendable {
  public var repositoryRoot: @Sendable (_ override: String?, _ refresh: Bool) throws -> String
  public init(
    repositoryRoot: @escaping @Sendable (_ override: String?, _ refresh: Bool) throws -> String
  ) {
    self.repositoryRoot = repositoryRoot
  }
  public func repositoryRoot(override: String?, refresh: Bool = false) throws -> String {
    try repositoryRoot(override, refresh)
  }
}

extension RegistrySource {
  /// Resolution order: the explicit path, a clone enclosing the working directory, then the
  /// cached release snapshot. `refresh` reaches only the snapshot.
  public static let local = RegistrySource { override, refresh in
    @Dependency(\.registryFileSystem) var fs
    if let override { return fs.resolve(override) }
    var candidate = fs.resolve(fs.currentDirectory())
    while true {
      if fs.isFile(candidate + "/Registry/registry.json") { return candidate }
      let parent = (candidate as NSString).deletingLastPathComponent
      if candidate == parent { break }
      candidate = parent
    }
    return try ReleaseSnapshot().root(refresh: refresh)
  }

  public static let unimplemented = RegistrySource { _, _ in
    throw RegistryError("no registry source in tests")
  }
}
private enum RegistrySourceKey: DependencyKey {
  static let liveValue = RegistrySource.local
  static let testValue = RegistrySource.unimplemented
}
extension DependencyValues {
  public var registrySource: RegistrySource {
    get { self[RegistrySourceKey.self] }
    set { self[RegistrySourceKey.self] = newValue }
  }
}

func safeJoin(_ root: String, _ value: String, fs: FileSystem) throws -> String {
  let parts = value.split(separator: "/")
  guard !value.isEmpty, !value.hasPrefix("/"), !parts.contains(".."),
    parts.contains(where: { $0 != "." })
  else {
    throw RegistryError("Unsafe registry path: \(value)")
  }
  let root = fs.resolve(root)
  let candidate = fs.resolve(root + "/" + value)
  guard candidate == root || candidate.hasPrefix(root + "/") else {
    throw RegistryError("Registry path escapes through a symbolic link: \(value)")
  }
  return candidate
}

func parentDirectory(_ path: String) -> String {
  let parent = (path as NSString).deletingLastPathComponent
  return parent.isEmpty ? "." : parent
}
