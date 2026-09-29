import CustomDump
import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import SweetUIKit

/// A recipe built from the one-item fixture: empty files, native guidance in docs, no preview.
private func recipeFixture() throws -> InMemoryFileSystem {
  let fs = try fixture()
  var recipe = example
  recipe["kind"] = "recipe"
  recipe["files"] = []
  recipe["docs"] = "Use the native control directly."
  var fields = recipe.object!
  fields.removeValue(forKey: "preview")
  recipe = .object(fields)
  try fs.put("/registry/Registry/items/example.json", recipe.rendered())
  return fs
}

@Suite(.serialized, .dependencies) struct DescribeAndInfo {
  // describe hands an agent the closure, usage, and file targets without touching the destination.
  @Test func describeTextReportsClosureUsageAndFileTargets() throws {
    try withFixture(try fixture()) {
      let result = try command(["describe", "example"])
      #expect(result.code == 0)
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        """
        example (component 0.1.0)
        Test item.

        Usage:
          Example()
        Accessibility:
        Install order:
          example
        Package requirements:
        Files:
          Example.swift

        """
      }
    }
  }

  // The JSON view is the shared MCP payload, so agents parse one contract from either surface.
  @Test func describeJSONRendersTheSharedPayloadInDocumentOrder() throws {
    try withFixture(try fixture()) {
      let result = try command(["describe", "example", "--format", "json"])
      #expect(result.code == 0)
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        #"""
        {
          "name": "example",
          "kind": "component",
          "version": "0.1.0",
          "description": "Test item.",
          "usage": "Example()",
          "docs": null,
          "tags": [
            "test"
          ],
          "aliases": null,
          "platforms": [
            {
              "minimumVersion": "26.0",
              "name": "iOS"
            }
          ],
          "accessibility": [],
          "registryDependencies": [],
          "installs": true,
          "installOrder": [
            "example"
          ],
          "packageRequirements": [],
          "signatures": [],
          "files": [
            {
              "source": "sources/Example.swift",
              "target": "Example.swift",
              "content": "source\n"
            }
          ]
        }

        """#
      }
    }
  }

  // --source is what lets an agent read the exact code before committing to an install.
  @Test func describeSourceAppendsCanonicalFileContentOnlyWhenAsked() throws {
    try withFixture(try fixture()) {
      let plain = try command(["describe", "example"])
      #expect(!plain.stdout.contains("--- "), "\(plain.stdout)")
      let sourced = try command(["describe", "example", "--source"])
      #expect(sourced.code == 0)
      assertInlineSnapshot(of: sourced.stdout, as: .lines) {
        """
        example (component 0.1.0)
        Test item.

        Usage:
          Example()
        Accessibility:
        Install order:
          example
        Package requirements:
        Files:
          Example.swift
        --- Example.swift ---
        source

        """
      }
    }
  }

  // A recipe installs nothing, so describe must steer the agent to the native control instead.
  @Test func describeReportsNativeGuidanceForARecipe() throws {
    try withFixture(try recipeFixture()) {
      let text = try command(["describe", "example"])
      #expect(text.code == 0)
      assertInlineSnapshot(of: text.stdout, as: .lines) {
        """
        example (recipe 0.1.0)
        Test item.

        Usage:
          Example()
        Accessibility:
        Nothing to install. Native guidance:
        Use the native control directly.

        """
      }
      let json = try command(["describe", "example", "--format", "json"])
      let decoded = try JSON.read(Data(json.stdout.utf8))
      #expect(decoded["installs"] == false, "\(json.stdout)")
    }
  }

  // Describing an item that does not exist must refuse, not print an empty or partial record.
  @Test func describeRefusesAnUnknownItemWithExitTwo() throws {
    try withFixture(try fixture()) {
      let result = try command(["describe", "absent"])
      #expect(result.code == 2)
      #expect(result.stderr == "Unknown registry item: absent\n", "\(result.stderr)")
      #expect(result.stdout.isEmpty, "\(result.stdout)")
    }
  }

  // info is how a consumer confirms an installation is intact against its receipt.
  @Test func infoReportsUpToDateFilesAfterAnInstall() throws {
    try withFixture(try fixture()) {
      #expect(try command(["install", "example", "--destination", "/app"]).code == 0)
      let result = try command(["info", "--destination", "/app"])
      #expect(result.code == 0)
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        """
        Installed items in /app:
        example 0.1.0
          Example.swift  up-to-date
        1 items, 1 files up-to-date, 0 modified, 0 missing

        """
      }
    }
  }

  // A local edit must surface as modified so a consumer knows an --update would merge, not skip.
  @Test func infoReportsModifiedWhenAnOwnedFileIsEdited() throws {
    let fs = try fixture()
    try withFixture(fs) {
      #expect(try command(["install", "example", "--destination", "/app"]).code == 0)
      try fs.put("/app/Example.swift", "consumer\n")
      let result = try command(["info", "--destination", "/app"])
      #expect(result.code == 0)
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        """
        Installed items in /app:
        example 0.1.0
          Example.swift  modified
        1 items, 0 files up-to-date, 1 modified, 0 missing

        """
      }
    }
  }

  // A deleted owned file must read as missing, distinct from modified, so the gap is diagnosable.
  @Test func infoReportsMissingWhenAnOwnedFileIsDeleted() throws {
    let fs = try fixture()
    try withFixture(fs) {
      #expect(try command(["install", "example", "--destination", "/app"]).code == 0)
      try fs.remove("/app/Example.swift")
      let result = try command(["info", "--destination", "/app"])
      #expect(result.code == 0)
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        """
        Installed items in /app:
        example 0.1.0
          Example.swift  missing
        1 items, 0 files up-to-date, 0 modified, 1 missing

        """
      }
    }
  }

  // Without a receipt there is nothing to report, so info must refuse like the installer's --diff.
  @Test func infoRefusesWhenTheReceiptIsMissingWithExitTwo() throws {
    try withFixture(try fixture()) {
      let result = try command(["info", "--destination", "/nowhere"])
      #expect(result.code == 2)
      #expect(
        result.stderr
          == "Installation receipt is missing: /nowhere/.sweetui/receipt.json\n",
        "\(result.stderr)")
    }
  }

  // Stable key order lets a machine reader depend on the JSON shape, not just its contents.
  @Test func infoJSONKeepsTheFourTopLevelKeysInOrder() throws {
    try withFixture(try fixture()) {
      #expect(try command(["install", "example", "--destination", "/app"]).code == 0)
      let result = try command(["info", "--destination", "/app", "--format", "json"])
      #expect(result.code == 0)
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        """
        {
          "destination": "/app",
          "registry": "TestRegistry",
          "items": [
            {
              "name": "example",
              "version": "0.1.0",
              "registryDependencies": [],
              "files": [
                {
                  "target": "Example.swift",
                  "status": "up-to-date"
                }
              ]
            }
          ],
          "summary": {
            "items": 1,
            "upToDate": 1,
            "modified": 0,
            "missing": 0
          }
        }

        """
      }
    }
  }
}

extension DescribeAndInfo {
  // A composer needs labels, types, the owning type, and enum cases; the snippet alone shows
  // none. Private members, switch cases, the body, and default values must not leak into or cut
  // off a signature.
  @Test func describeListsThePublicSignaturesOfTheSource() throws {
    let source = """
      import SwiftUI

      public struct Example: View {
          public init(
              _ title: LocalizedStringResource,
              value: Text,
              detail: Text? = nil
          ) { self.title = title }
          public var body: some View { Text("x") }
          public func registryVariant(_ variant: Int) -> Example where Int == Int { self }
          public static var registry: Example { Example("x", value: Text("")) }
          public static let shared = Example("x", value: Text(""))
          private func hidden(_ secret: Int = 1) {}
          public enum Tone: Sendable {
              case neutral
              case positive(Double)
              var label: String {
                  switch self {
                  case .neutral: "n"
                  case .positive: "p"
                  }
              }
          }
          enum Hidden { case secret }
      }

      public extension View where Self == Example {
          func registryExample(_ tone: Example.Tone = .neutral) -> some View { self }
      }
      """
    try withFixture(try fixture(source)) {
      let json = try command(["describe", "example", "--format", "json"])
      let decoded = try JSON.read(Data(json.stdout.utf8))
      expectNoDifference(
        decoded["signatures"].strings,
        [
          "Example: init(_ title: LocalizedStringResource, value: Text, detail: Text? = nil)",
          "Example: func registryVariant(_ variant: Int) -> Example where Int == Int",
          "Example: static var registry: Example",
          "Example: static let shared",
          "Example.Tone: enum { case neutral; case positive(Double) }",
          "View: func registryExample(_ tone: Example.Tone = .neutral) -> some View",
        ])
      let text = try command(["describe", "example"])
      #expect(
        text.stdout.contains(
          "Signatures:\n  Example: init(_ title: LocalizedStringResource, value: Text, detail: Text? = nil)\n"
        ))
      #expect(!text.stdout.contains("hidden"))
      #expect(!text.stdout.contains("secret"))
    }
  }

  @Test func describeOmitsTheSignaturesHeadingWhenTheSourceHasNoPublicMember() throws {
    try withFixture(try fixture("struct Example {}\n")) {
      let text = try command(["describe", "example"])
      #expect(!text.stdout.contains("Signatures:"))
    }
  }
}
