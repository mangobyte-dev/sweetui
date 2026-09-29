import Dependencies
import Foundation
import InlineSnapshotTesting
import Testing

@testable import SweetUIKit

extension Commands {
  @Test(arguments: ["../Escape.swift", "/Escape.swift", ".", ""])
  func unsafeTargets(_ target: String) throws {
    let fs = try fixture()
    var item = example
    item["files"] = [["source": "sources/Example.swift", "target": .string(target)]]
    try fs.put("/registry/Registry/items/example.json", item.rendered())
    try withFixture(fs) {
      let result = try command(["install", "example", "--destination", "/app"])
      #expect(result.code == 2)
      #expect(result.stderr == "Unsafe registry path: \(target)\n")
      #expect(!fs.exists("/app"))
    }
  }
  @Test func duplicateTargetsAndSymlinks() throws {
    let fs = try fixture()
    var item = example
    item["files"] = .array([item["files"].array![0], item["files"].array![0]])
    try fs.put("/registry/Registry/items/example.json", item.rendered())
    try withFixture(fs) {
      let result = try command(["install", "example", "--destination", "/app"])
      #expect(result.code == 2)
      #expect(result.stderr == "Multiple files target /app/Example.swift\n")
      #expect(!fs.exists("/app"))
    }
    item = example
    item["files"] = [["source": "sources/Example.swift", "target": "linked/Example.swift"]]
    try fs.put("/registry/Registry/items/example.json", item.rendered())
    try fs.createDirectory("/app")
    try fs.createDirectory("/outside")
    fs.storage.withLock { $0["/app/linked"] = .link("/outside") }
    try withFixture(fs) {
      let result = try command(["install", "example", "--destination", "/app"])
      #expect(result.code == 2)
      #expect(
        result.stderr == "Registry path escapes through a symbolic link: linked/Example.swift\n")
      #expect(!fs.exists("/outside/Example.swift"))
    }
  }
  @Test(arguments: ["--diff", "--update"])
  func missingReceipts(_ mode: String) throws {
    let fs = try fixture()
    try withFixture(fs) {
      let result = try command(["install", "example", "--destination", "/app", mode])
      #expect(result.code == 2)
      #expect(
        result.stderr == "Installation receipt is missing: /app/.sweetui/receipt.json\n")
      #expect(!fs.exists("/app"))
    }
  }
  @Test(arguments: [
    "schema", "registry", "items", "files", "record", "base", "missing-base", "digest",
    "missing-target",
  ])
  func damagedReceipt(_ defect: String) throws {
    let fs = try fixture()
    try withFixture(fs) {
      #expect(try command(["install", "example", "--destination", "/app"]).code == 0)
      let path = "/app/.sweetui/receipt.json"
      var receipt = try JSON.read(fs.read(path))
      let base = "/app/.sweetui/" + receipt["files"]["Example.swift"]["base"].text
      let expected: String
      switch defect {
      case "schema":
        receipt["schemaVersion"] = 2
        expected = "Unsupported receipt schema version"
      case "registry":
        receipt["registry"] = "Other"
        expected = "Receipt belongs to another registry"
      case "items":
        receipt["items"] = []
        expected = "Invalid receipt structure"
      case "files":
        receipt["files"] = []
        expected = "Invalid receipt structure"
      case "record":
        receipt["files"] = [:]
        expected = "No valid receipt entry"
      case "base":
        receipt["files"]["Example.swift"]["base"] = .null
        expected = "Invalid receipt base"
      case "missing-base":
        try fs.remove(base)
        expected = "Receipt base is missing"
      case "digest":
        try fs.put(base, "tampered\n")
        expected = "Receipt base digest mismatch"
      default:
        try fs.remove("/app/Example.swift")
        expected = "Installed source is missing"
      }
      try fs.put(path, receipt.rendered())
      let before = fs.snapshot()
      let result = try command(["install", "example", "--destination", "/app", "--update"])
      #expect(result.code == 2)
      #expect(result.stderr.contains(expected))
      #expect(fs.snapshot() == before)
    }
  }
  @Test func untrackedCollision() throws {
    let fs = try fixture()
    try fs.put("/app/Example.swift", "source\n")
    try withFixture(fs) {
      let before = fs.snapshot()
      let result = try command(["install", "example", "--destination", "/app"])
      #expect(result.code == 2)
      #expect(result.stderr.contains("Refusing to overwrite owned source"))
      #expect(fs.snapshot() == before)
    }
  }
  @Test func concurrentMergeAndConflictPreflight() throws {
    let base = "consumer = false\nline2\nline3\nline4\nline5\nregistry = false\n"
    let fs = try fixture(base)
    var item = example
    item["files"] = .array(
      item["files"].array! + [["source": "sources/Other.swift", "target": "Other.swift"]])
    try fs.put("/registry/Registry/items/example.json", item.rendered())
    try fs.put("/registry/Registry/sources/Other.swift", "other = base\n")
    try withFixture(fs) {
      #expect(try command(["install", "example", "--destination", "/app"]).code == 0)
      try fs.put(
        "/app/Example.swift",
        base.replacingOccurrences(of: "consumer = false", with: "consumer = true"))
      try fs.put(
        "/registry/Registry/sources/Example.swift",
        base.replacingOccurrences(of: "registry = false", with: "registry = true"))
      let result = try command(["install", "example", "--destination", "/app", "--update"])
      #expect(result.code == 0)
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        """
        merged example: /app/Example.swift
        unchanged example: /app/Other.swift

        """
      }
      #expect(
        try fs.read("/app/Example.swift")
          == Data(base.replacingOccurrences(of: "false", with: "true").utf8))
      assertInlineSnapshot(of: fs.snapshot(), as: .lines) {
        """
        ./
        .sweetui/
        .sweetui/bases/
        .sweetui/bases/459712c6281425eee11a4d9025885b6d0bb6111d445a867253a96451e0b6a3d7.base
          other = base
        \u{20}\u{20}
        .sweetui/bases/cbaa6d22a0c35cb115d1c3c78b066d71e7e85287affb80d98ede0c592f927053.base
          consumer = false
          line2
          line3
          line4
          line5
          registry = true
        \u{20}\u{20}
        .sweetui/receipt.json
          {
            "files": {
              "Example.swift": {
                "base": "bases/cbaa6d22a0c35cb115d1c3c78b066d71e7e85287affb80d98ede0c592f927053.base",
                "installedDigest": "sha256:005f0cedd348f676bcb5bf8daef881bf4484f9249791e92a1cd91e24401cf707",
                "item": "example",
                "sourceDigest": "sha256:1a495c20e8fc6155c0fa93d26af48fe26af9d2175c94d96630f0a7885e26a404",
                "version": "0.1.0"
              },
              "Other.swift": {
                "base": "bases/459712c6281425eee11a4d9025885b6d0bb6111d445a867253a96451e0b6a3d7.base",
                "installedDigest": "sha256:d7322af89ae3d0daa7a989401476a031dd78d66421aef8798704c0fec65d244c",
                "item": "example",
                "sourceDigest": "sha256:d7322af89ae3d0daa7a989401476a031dd78d66421aef8798704c0fec65d244c",
                "version": "0.1.0"
              }
            },
            "items": {
              "example": {
                "packageDependencies": [],
                "registryDependencies": [],
                "version": "0.1.0"
              }
            },
            "registry": "TestRegistry",
            "schemaVersion": 1
          }
        \u{20}\u{20}
        Example.swift
          consumer = true
          line2
          line3
          line4
          line5
          registry = true
        \u{20}\u{20}
        Other.swift
          other = base
        \u{20}\u{20}
        """
      }
      try fs.put("/app/Example.swift", "value = consumer\n")
      try fs.put("/registry/Registry/sources/Example.swift", "value = registry\n")
      try fs.put("/registry/Registry/sources/Other.swift", "other = registry\n")
      let receiptBefore = try fs.read("/app/.sweetui/receipt.json")
      let failed = try command(["install", "example", "--destination", "/app", "--update"])
      #expect(failed.code == 2)
      #expect(failed.stderr.contains("owned source was not changed"))
      #expect(try fs.read("/app/Other.swift") == Data("other = base\n".utf8))
      #expect(try fs.read("/app/.sweetui/receipt.json") == receiptBefore)
      assertInlineSnapshot(of: fs.snapshot(), as: .lines) {
        """
        ./
        .sweetui/
        .sweetui/bases/
        .sweetui/bases/459712c6281425eee11a4d9025885b6d0bb6111d445a867253a96451e0b6a3d7.base
          other = base
        \u{20}\u{20}
        .sweetui/bases/cbaa6d22a0c35cb115d1c3c78b066d71e7e85287affb80d98ede0c592f927053.base
          consumer = false
          line2
          line3
          line4
          line5
          registry = true
        \u{20}\u{20}
        .sweetui/conflicts/
        .sweetui/conflicts/cbaa6d22a0c35cb115d1c3c78b066d71e7e85287affb80d98ede0c592f927053.merge
          <<<<<<< Example.swift
          value = consumer
          =======
          value = registry
          >>>>>>> registry incoming
        \u{20}\u{20}
        .sweetui/receipt.json
          {
            "files": {
              "Example.swift": {
                "base": "bases/cbaa6d22a0c35cb115d1c3c78b066d71e7e85287affb80d98ede0c592f927053.base",
                "installedDigest": "sha256:005f0cedd348f676bcb5bf8daef881bf4484f9249791e92a1cd91e24401cf707",
                "item": "example",
                "sourceDigest": "sha256:1a495c20e8fc6155c0fa93d26af48fe26af9d2175c94d96630f0a7885e26a404",
                "version": "0.1.0"
              },
              "Other.swift": {
                "base": "bases/459712c6281425eee11a4d9025885b6d0bb6111d445a867253a96451e0b6a3d7.base",
                "installedDigest": "sha256:d7322af89ae3d0daa7a989401476a031dd78d66421aef8798704c0fec65d244c",
                "item": "example",
                "sourceDigest": "sha256:d7322af89ae3d0daa7a989401476a031dd78d66421aef8798704c0fec65d244c",
                "version": "0.1.0"
              }
            },
            "items": {
              "example": {
                "packageDependencies": [],
                "registryDependencies": [],
                "version": "0.1.0"
              }
            },
            "registry": "TestRegistry",
            "schemaVersion": 1
          }
        \u{20}\u{20}
        Example.swift
          value = consumer
        \u{20}\u{20}
        Other.swift
          other = base
        \u{20}\u{20}
        """
      }
      let artifact =
        "/app/.sweetui/conflicts/" + Installer.identifier("Example.swift") + ".merge"
      assertInlineSnapshot(of: String(decoding: try fs.read(artifact), as: UTF8.self), as: .lines) {
        """
        <<<<<<< Example.swift
        value = consumer
        =======
        value = registry
        >>>>>>> registry incoming

        """
      }
      #expect(try fs.read("/app/Example.swift") == Data("value = consumer\n".utf8))
      #expect(try command(["install", "example", "--destination", "/app", "--force"]).code == 0)
      #expect(!fs.exists(artifact))
    }
  }
}

struct DiffCase: Decodable, Sendable, CustomTestStringConvertible {
  var owned: String
  var incoming: String
  var diff: String
  var testDescription: String {
    "\(owned.utf8.count) owned bytes, \(incoming.utf8.count) incoming bytes"
  }
}
let diffCases = try! JSONDecoder().decode(
  [DiffCase].self,
  from: Data(
    contentsOf: Bundle.module.url(
      forResource: "diff-cases", withExtension: "json", subdirectory: "Fixtures")!))
@Test(arguments: diffCases) func pythonUnifiedDiff(_ test: DiffCase) {
  #expect(
    unifiedDiff(
      Data(test.owned.utf8), Data(test.incoming.utf8), from: "owned/File.swift",
      to: "incoming/File.swift") == test.diff)
}
