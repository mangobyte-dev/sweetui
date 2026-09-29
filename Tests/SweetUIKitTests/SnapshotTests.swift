import Dependencies
import Foundation
import Synchronization
import Testing

@testable import SweetUIKit

private let cacheRoot = "/home/test/Library/Caches/sweetui"
private let snapshotDirectory = cacheRoot + "/registries/" + RegistryRelease.version
private let notice =
  "\nsweetui 0.6.0 is available. Run 'brew update && brew upgrade sweetui' to install.\n"

/// An empty working directory outside any clone, so resolution reaches the snapshot.
private func workspace() throws -> InMemoryFileSystem {
  let fs = InMemoryFileSystem()
  try fs.createDirectory("/work")
  fs.workingDirectory.withLock { $0 = "/work" }
  return fs
}

private func withSnapshot<R>(
  _ fs: InMemoryFileSystem, download: RegistryDownloader, extract: RegistryArchive,
  _ body: () throws -> R
) rethrows -> R {
  try withDependencies {
    $0.registryFileSystem = fs.fileSystem
    $0.registrySource = .local
    $0.registrySourceMerger = .git
    $0.uuid = .incrementing
    $0.date = .constant(fixedNow)
    $0.registryDownloader = download
    $0.registryArchive = extract
  } operation: {
    try body()
  }
}

extension Commands {
  @Test func explicitPathAndEnclosingCloneWinBeforeTheSnapshot() throws {
    let fs = try fixture()
    try fs.createDirectory("/registry/Sources/Feature")
    fs.workingDirectory.withLock { $0 = "/registry/Sources/Feature" }
    let downloads = Mutex(0)
    let refused = RegistryDownloader { _ in
      downloads.withLock { $0 += 1 }
      throw RegistryError("unexpected download")
    }
    try withSnapshot(fs, download: refused, extract: RegistryArchive { _, _ in }) {
      let source = RegistrySource.local
      #expect(try source.repositoryRoot(override: "/registry", refresh: true) == "/registry")
      #expect(try source.repositoryRoot(override: nil, refresh: false) == "/registry")
      #expect(try source.repositoryRoot(override: nil, refresh: true) == "/registry")
      let validated = try command(["validate", "--refresh"])
      #expect(validated.code == 0)
      #expect(validated.stdout == "Registry validation passed: full catalog\n")
      #expect(validated.stderr.isEmpty)
    }
    #expect(downloads.withLock { $0 } == 0)
    #expect(!fs.exists(cacheRoot))
  }

  @Test func snapshotIsFetchedOnceThenReusedAndRefreshedOnRequest() throws {
    let fs = try workspace()
    let downloads = Mutex<[String]>([])
    let download = RegistryDownloader { url in
      downloads.withLock { $0.append(url) }
      return Data("tarball".utf8)
    }
    let extract = RegistryArchive { data, directory in
      #expect(data == Data("tarball".utf8))
      try populateRegistry(fs, at: directory)
    }
    let fetching =
      "Fetching the sweetui \(RegistryRelease.version) registry snapshot from \(RegistryRelease.archiveURL) into \(snapshotDirectory)\n"
    try withSnapshot(fs, download: download, extract: extract) {
      let validated = try command(["validate"])
      #expect(validated.code == 0)
      #expect(validated.stdout == "Registry validation passed: full catalog\n")
      #expect(validated.stderr == fetching)
      #expect(downloads.withLock { $0 } == [RegistryRelease.archiveURL])
      #expect(
        try readText(fs.fileSystem, snapshotDirectory + "/snapshot.json") == """
          {
            "fetchedAt": "\(fixedNow.formatted(.iso8601))",
            "url": "\(RegistryRelease.archiveURL)",
            "version": "\(RegistryRelease.version)"
          }

          """)
      #expect(try fs.children(cacheRoot + "/registries") == [snapshotDirectory])
      // The cache serves every later command without a download.
      let planned = try command([
        "install", "example", "--destination", "/work/Components", "--plan",
      ])
      #expect(planned.code == 0)
      #expect(planned.stderr.isEmpty)
      #expect(planned.stdout.contains("closure:\n  example 0.1.0 (component)\n"))
      #expect(try command(["search", "test", "--format", "names"]).stdout == "example\n")
      #expect(downloads.withLock { $0 }.count == 1)
      // --refresh downloads again and the manifest carries the new clock reading.
      let later = fixedNow.addingTimeInterval(3600)
      try withDependencies {
        $0.date = .constant(later)
      } operation: {
        let refreshed = try command(["validate", "--refresh"])
        #expect(refreshed.code == 0)
        #expect(refreshed.stderr == fetching)
      }
      #expect(downloads.withLock { $0 }.count == 2)
      let manifest = try readText(fs.fileSystem, snapshotDirectory + "/snapshot.json")
      #expect(manifest.contains(later.formatted(.iso8601)))
      #expect(try fs.children(cacheRoot + "/registries") == [snapshotDirectory])
    }
  }

  @Test func staleOrDamagedCachesAreReplaced() throws {
    for damage in ["version", "index"] {
      let fs = try workspace()
      try populateRegistry(fs, at: snapshotDirectory)
      if damage == "version" {
        try fs.put(snapshotDirectory + "/snapshot.json", "{\"version\": \"0.0.9\"}")
      } else {
        try fs.put(
          snapshotDirectory + "/snapshot.json", "{\"version\": \"\(RegistryRelease.version)\"}")
        try fs.remove(snapshotDirectory + "/Registry/registry.json")
      }
      let downloads = Mutex(0)
      let download = RegistryDownloader { _ in
        downloads.withLock { $0 += 1 }
        return Data()
      }
      let extract = RegistryArchive { _, directory in try populateRegistry(fs, at: directory) }
      try withSnapshot(fs, download: download, extract: extract) {
        let validated = try command(["validate"])
        #expect(validated.code == 0, "\(damage)")
        #expect(downloads.withLock { $0 } == 1, "\(damage)")
        #expect(ReleaseSnapshot().isValid, "\(damage)")
      }
    }
  }

  @Test func snapshotFailuresAreReadableAndLeaveNoPartialCache() throws {
    let fs = try workspace()
    let url = RegistryRelease.archiveURL
    let offline = RegistryDownloader { _ in throw RegistryError("offline") }
    try withSnapshot(fs, download: offline, extract: RegistryArchive { _, _ in }) {
      let result = try command(["validate"])
      #expect(result.code == 2)
      #expect(
        result.stderr.hasSuffix(
          "No registry clone was found, and the \(RegistryRelease.version) snapshot could not be downloaded from \(url): offline. Pass --registry <path to a clone>\n"
        ))
    }
    let online = RegistryDownloader { _ in Data("tarball".utf8) }
    let empty = RegistryArchive { _, _ in }
    try withSnapshot(fs, download: online, extract: empty) {
      let result = try command(["install", "example", "--destination", "/work/Components"])
      #expect(result.code == 2)
      #expect(
        result.stderr.hasSuffix(
          "The \(RegistryRelease.version) snapshot from \(url) could not be unpacked: it does not contain Registry/registry.json. Pass --registry <path to a clone>\n"
        ))
      #expect(!fs.exists("/work/Components"))
    }
    let broken = RegistryArchive { _, _ in
      throw RegistryError("tar exited 1: gzip: (stdin): not in gzip format")
    }
    try withSnapshot(fs, download: online, extract: broken) {
      let result = try command(["validate"])
      #expect(result.code == 2)
      #expect(result.stderr.contains("could not be unpacked: tar exited 1: gzip"))
    }
    #expect(try fs.children(cacheRoot + "/registries").isEmpty)
    #expect(!fs.exists(snapshotDirectory))
  }

  @Test func updateNoticeFollowsTheTapTagsAndThrottlesByTheClock() throws {
    let fs = try fixture()
    let requests = Mutex(0)
    let tags = Mutex(["sweetui-0.6.0", "sweetui-" + RegistryRelease.version])
    let stamp = cacheRoot + "/update-check.json"
    func install(at date: Date, _ extra: [String] = []) throws -> CommandOutput {
      try withDependencies {
        $0.date = .constant(date)
        $0.releaseTags = ReleaseTags { url in
          #expect(url == RegistryRelease.tagsURL)
          requests.withLock { $0 += 1 }
          return tags.withLock { $0 }
        }
      } operation: {
        try command(["install", "example", "--destination", "/app"] + extra)
      }
    }
    try withFixture(fs) {
      let first = try install(at: fixedNow)
      #expect(first.code == 0)
      #expect(first.stdout == "installed example: /app/Example.swift\n" + notice)
      #expect(requests.withLock { $0 } == 1)
      #expect(
        try readText(fs.fileSystem, stamp) == """
          {
            "checkedAt": "\(fixedNow.formatted(.iso8601))",
            "latest": "0.6.0"
          }

          """)
      // Within a day the stamp answers and the tap is not asked again.
      let second = try install(at: fixedNow.addingTimeInterval(3600))
      #expect(second.stdout == "up-to-date: example\n" + notice)
      #expect(requests.withLock { $0 } == 1)
      // A day later it asks again; the current version prints nothing.
      tags.withLock { $0 = ["sweetui-" + RegistryRelease.version] }
      let third = try install(at: fixedNow.addingTimeInterval(25 * 3600))
      #expect(third.stdout == "up-to-date: example\n")
      #expect(requests.withLock { $0 } == 2)
      // --refresh asks regardless of the stamp.
      tags.withLock { $0 = ["sweetui-0.7.0", "sweetui-0.6.0"] }
      let forced = try install(at: fixedNow.addingTimeInterval(25 * 3600 + 60), ["--refresh"])
      #expect(
        forced.stdout.hasSuffix(
          "\nsweetui 0.7.0 is available. Run 'brew update && brew upgrade sweetui' to install.\n"
        ))
      #expect(requests.withLock { $0 } == 3)
      // Tags without the tool's prefix mean no release; the stamp records that.
      tags.withLock { $0 = ["pfw-1.0.0"] }
      let unrelated = try install(at: fixedNow.addingTimeInterval(3 * 86_400))
      #expect(unrelated.stdout == "up-to-date: example\n")
      #expect(requests.withLock { $0 } == 4)
      #expect(try readText(fs.fileSystem, stamp).contains("\"latest\": null"))
      // A failed request is silent and leaves the stamp alone; plan never asks.
      let before = try readText(fs.fileSystem, stamp)
      let failing = try withDependencies {
        $0.date = .constant(fixedNow.addingTimeInterval(5 * 86_400))
        $0.releaseTags = ReleaseTags { _ in throw RegistryError("offline") }
      } operation: {
        try command(["install", "example", "--destination", "/app"])
      }
      #expect(failing.code == 0)
      #expect(failing.stdout == "up-to-date: example\n")
      #expect(try readText(fs.fileSystem, stamp) == before)
      tags.withLock { $0 = ["sweetui-0.9.0"] }
      let planned = try withDependencies {
        $0.date = .constant(fixedNow.addingTimeInterval(9 * 86_400))
        $0.releaseTags = ReleaseTags { _ in
          requests.withLock { $0 += 1 }
          return tags.withLock { $0 }
        }
      } operation: {
        try command(["install", "example", "--destination", "/app", "--plan"])
      }
      #expect(planned.code == 0)
      #expect(!planned.stdout.contains("is available"))
      #expect(requests.withLock { $0 } == 4)
    }
  }

  @Test func updateNoticeNeverAdvertisesATapTagThatIsNotNewer() throws {
    // A tap still on the previous release is below the running tool, so an install must not
    // prompt an upgrade to an older version. A tag equal to the current version is silent too.
    let older = "0.4.0"
    #expect(RegistryRelease.version == "0.5.0")
    for tag in [older, RegistryRelease.version] {
      let fs = try fixture()
      let result = try withDependencies {
        $0.date = .constant(fixedNow)
        $0.releaseTags = ReleaseTags { _ in ["sweetui-" + tag] }
      } operation: {
        try withFixture(fs) {
          try command(["install", "example", "--destination", "/app"])
        }
      }
      #expect(result.code == 0)
      #expect(result.stdout == "installed example: /app/Example.swift\n")
      #expect(!result.stdout.contains("is available"))
    }
  }
}

@Test func liveArchiveStripsTheTagDirectoryAndReportsBadInput() throws {
  try withTemporaryDirectory { directory in
    let tree = directory + "/sweetui-" + RegistryRelease.version + "/Registry"
    try FileManager.default.createDirectory(atPath: tree, withIntermediateDirectories: true)
    try "{}\n".write(toFile: tree + "/registry.json", atomically: true, encoding: .utf8)
    let pack = Process()
    pack.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
    pack.arguments = [
      "czf", directory + "/archive.tgz", "-C", directory,
      "sweetui-" + RegistryRelease.version,
    ]
    try pack.run()
    pack.waitUntilExit()
    #expect(pack.terminationStatus == 0)
    let data = try fileData(directory + "/archive.tgz")
    try withDependencies {
      $0.uuid = .incrementing
    } operation: {
      try RegistryArchive.tar.extract(data, directory + "/out")
      #expect(try fileText(directory + "/out/Registry/registry.json") == "{}\n")
      let failed = #expect(throws: RegistryError.self) {
        try RegistryArchive.tar.extract(Data("not a tarball".utf8), directory + "/bad")
      }
      #expect(failed?.description.hasPrefix("tar exited") == true)
    }
  }
}

@Test func liveDownloaderReadsFileURLsAndReportsFailures() throws {
  try withTemporaryDirectory { directory in
    try "bytes".write(toFile: directory + "/payload", atomically: true, encoding: .utf8)
    #expect(
      try RegistryDownloader.live.fetch("file://" + directory + "/payload") == Data("bytes".utf8))
    #expect(throws: (any Error).self) {
      try RegistryDownloader.live.fetch("file://" + directory + "/missing")
    }
    #expect(throws: (any Error).self) { try RegistryDownloader.live.fetch("not a url") }
  }
}
