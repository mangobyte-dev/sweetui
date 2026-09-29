import Dependencies
import Foundation
import Synchronization

/// The pinned release the tool resolves against when no clone is at hand.
public enum RegistryRelease {
  public static let version = "0.4.0"
  public static let repository = "mangobyte-dev/sweetui"
  public static let tap = "mangobyte-dev/homebrew-tap"
  /// Tap tags are `sweetui-<version>`, the convention measured from pfw's `pfw-<version>`.
  public static let tagPrefix = "sweetui-"
  public static let archiveURL =
    "https://github.com/\(repository)/archive/refs/tags/\(version).tar.gz"
  public static let tagsURL = "https://api.github.com/repos/\(tap)/tags"
  public static let cacheDirectory = "~/Library/Caches/sweetui"
}

/// Fetching bytes from a URL is an effect; tests supply fixed bytes or failures.
public struct RegistryDownloader: Sendable {
  public var fetch: @Sendable (String) throws -> Data
  public init(fetch: @escaping @Sendable (String) throws -> Data) { self.fetch = fetch }
  public static let live = RegistryDownloader { url in
    guard let target = URL(string: url) else { throw RegistryError("invalid URL: \(url)") }
    let outcome = Mutex<Result<Data, any Error>?>(nil)
    let finished = DispatchSemaphore(value: 0)
    // An ephemeral session keeps URLCache out of the tool's cache directory and never serves
    // a remembered 404 once the tag is published.
    URLSession(configuration: .ephemeral).dataTask(with: target) { data, response, error in
      outcome.withLock {
        if let error {
          $0 = .failure(error)
        } else if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
          $0 = .failure(RegistryError("HTTP \(http.statusCode) from \(url)"))
        } else {
          $0 = .success(data ?? Data())
        }
      }
      finished.signal()
    }.resume()
    finished.wait()
    return try outcome.withLock { $0 }!.get()
  }
}

/// Unpacking a release tarball into a directory; the live version shells out to tar.
public struct RegistryArchive: Sendable {
  public var extract: @Sendable (Data, String) throws -> Void
  public init(extract: @escaping @Sendable (Data, String) throws -> Void) {
    self.extract = extract
  }
  /// A GitHub tag archive wraps the tree in `<repository>-<version>/`, which is stripped.
  public static let tar = RegistryArchive { data, directory in
    @Dependency(\.uuid) var uuid
    let archive = FileManager.default.temporaryDirectory
      .appendingPathComponent("sweetui-" + uuid().uuidString + ".tar.gz")
    try data.write(to: archive)
    defer { try? FileManager.default.removeItem(at: archive) }
    try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
    process.arguments = ["-xzf", archive.path, "-C", directory, "--strip-components=1"]
    let errors = Pipe()
    process.standardOutput = FileHandle.nullDevice
    process.standardError = errors
    try process.run()
    let message = errors.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw RegistryError(
        "tar exited \(process.terminationStatus): "
          + String(decoding: message, as: UTF8.self).trimmingCharacters(
            in: .whitespacesAndNewlines))
    }
  }
}

/// Tag names of a GitHub repository, newest first, as the tags API lists them.
public struct ReleaseTags: Sendable {
  public var names: @Sendable (String) throws -> [String]
  public init(names: @escaping @Sendable (String) throws -> [String]) { self.names = names }
  public static let live = ReleaseTags { url in
    struct Tag: Decodable { var name: String }
    return try JSONDecoder().decode([Tag].self, from: RegistryDownloader.live.fetch(url))
      .map(\.name)
  }
}

private enum RegistryDownloaderKey: DependencyKey {
  static let liveValue = RegistryDownloader.live
  static let testValue = RegistryDownloader { url in
    throw RegistryError("no network in tests: \(url)")
  }
}
private enum RegistryArchiveKey: DependencyKey {
  static let liveValue = RegistryArchive.tar
  static let testValue = RegistryArchive { _, directory in
    throw RegistryError("no archive extraction in tests: \(directory)")
  }
}
private enum ReleaseTagsKey: DependencyKey {
  static let liveValue = ReleaseTags.live
  static let testValue = ReleaseTags { url in throw RegistryError("no network in tests: \(url)") }
}
extension DependencyValues {
  public var registryDownloader: RegistryDownloader {
    get { self[RegistryDownloaderKey.self] }
    set { self[RegistryDownloaderKey.self] = newValue }
  }
  public var registryArchive: RegistryArchive {
    get { self[RegistryArchiveKey.self] }
    set { self[RegistryArchiveKey.self] = newValue }
  }
  public var releaseTags: ReleaseTags {
    get { self[ReleaseTagsKey.self] }
    set { self[ReleaseTagsKey.self] = newValue }
  }
}

/// The cached copy of the pinned release, fetched once and reused until refreshed.
public struct ReleaseSnapshot {
  @Dependency(\.registryFileSystem) var fs
  @Dependency(\.registryDownloader) var downloader
  @Dependency(\.registryArchive) var archive
  @Dependency(\.registryConsole) var console
  @Dependency(\.date.now) var now
  @Dependency(\.uuid) var uuid
  public init() {}
  static let manifestName = "snapshot.json"
  public var cacheRoot: String { fs.expandUser(RegistryRelease.cacheDirectory) }
  public var directory: String { cacheRoot + "/registries/" + RegistryRelease.version }
  /// A cache is valid when its manifest names the pinned version and the index is present.
  public var isValid: Bool {
    guard fs.isFile(directory + "/Registry/registry.json"),
      let manifest = try? JSON.read(fs.read(directory + "/" + Self.manifestName))
    else { return false }
    return manifest["version"].text == RegistryRelease.version
  }
  public func root(refresh: Bool) throws -> String {
    if !refresh && isValid { return directory }
    let version = RegistryRelease.version
    let url = RegistryRelease.archiveURL
    console.stderr(
      "Fetching the sweetui \(version) registry snapshot from \(url) into \(directory)\n")
    let data: Data
    do {
      data = try downloader.fetch(url)
    } catch {
      throw RegistryError(
        "No registry clone was found, and the \(version) snapshot could not be downloaded from \(url): \(describe(error)). Pass --registry <path to a clone>"
      )
    }
    let staging = cacheRoot + "/registries/.staging-" + uuid().uuidString
    do {
      try fs.createDirectory(staging)
      try archive.extract(data, staging)
      guard fs.isFile(staging + "/Registry/registry.json") else {
        throw RegistryError("it does not contain Registry/registry.json")
      }
    } catch {
      try? fs.remove(staging)
      throw RegistryError(
        "The \(version) snapshot from \(url) could not be unpacked: \(describe(error)). Pass --registry <path to a clone>"
      )
    }
    try fs.remove(directory)
    try fs.replace(staging, directory)
    let manifest: JSON = [
      "version": .string(version), "url": .string(url),
      "fetchedAt": .string(now.formatted(.iso8601)),
    ]
    try fs.write(Data((manifest.rendered() + "\n").utf8), to: directory + "/" + Self.manifestName)
    return directory
  }
}

/// The best-effort newer-release notice after an install, as measured from pfw: the tap's
/// tags decide, and any failure is silent. The clock throttles the request to one a day.
public struct UpdateNotice {
  @Dependency(\.registryFileSystem) var fs
  @Dependency(\.releaseTags) var tags
  @Dependency(\.date.now) var now
  public init() {}
  static let interval: TimeInterval = 24 * 60 * 60
  var stampPath: String { fs.expandUser(RegistryRelease.cacheDirectory) + "/update-check.json" }
  public func message(force: Bool = false) -> String? {
    let stamp = try? JSON.read(fs.read(stampPath))
    var latest = stamp?["latest"].string
    let checkedAt = stamp?["checkedAt"].string.flatMap { try? Date($0, strategy: .iso8601) }
    let recent = checkedAt.map { (0..<Self.interval).contains(now.timeIntervalSince($0)) } ?? false
    if force || !recent {
      guard let names = try? tags.names(RegistryRelease.tagsURL) else { return nil }
      latest = names.first { $0.hasPrefix(RegistryRelease.tagPrefix) }
        .map { String($0.dropFirst(RegistryRelease.tagPrefix.count)) }
      let record: JSON = [
        "checkedAt": .string(now.formatted(.iso8601)), "latest": latest.map(JSON.string) ?? .null,
      ]
      try? fs.createDirectory(fs.expandUser(RegistryRelease.cacheDirectory))
      try? fs.write(Data((record.rendered() + "\n").utf8), to: stampPath)
    }
    guard let latest, Self.isNewer(latest, than: RegistryRelease.version) else { return nil }
    return
      "\nsweetui \(latest) is available. Run 'brew update && brew upgrade sweetui' to install."
  }

  /// A tap tag prompts an upgrade only when it is strictly newer than the running tool, so a tap
  /// still on an older tag never advertises a downgrade. Numeric fields compare after zero-padding,
  /// as the platform floors do; an unparseable tag is treated as not newer and stays silent.
  static func isNewer(_ candidate: String, than current: String) -> Bool {
    func fields(_ value: String) -> [Int]? {
      let parts = value.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
      guard (1...3).contains(parts.count), parts.allSatisfy({ ($0 ?? -1) >= 0 }) else { return nil }
      return parts.map { $0! } + Array(repeating: 0, count: 3 - parts.count)
    }
    guard let candidate = fields(candidate), let current = fields(current) else { return false }
    return current.lexicographicallyPrecedes(candidate)
  }
}

func describe(_ error: any Error) -> String {
  (error as? RegistryError)?.description ?? error.localizedDescription
}
