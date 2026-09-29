import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import SweetUIKit

/// Base suite for the command/CLI/snapshot surface: every file that extends `Commands`
/// (Snapshot, Generator, InstallerSafety, MCP, Preset, RegistryContract, Validation tests)
/// inherits `.serialized` and `.dependencies`, so their fixtures run isolated and in the
/// `.test` `DependencyContext` — an un-overridden effectful dependency fails loudly instead
/// of silently reaching its live implementation.
@Suite(.serialized, .dependencies) struct Commands {
  @Test func validateAndSearch() throws {
    let fs = try fixture()
    try withFixture(fs) {
      let validated = try command(["validate"])
      #expect(validated.code == 0)
      assertInlineSnapshot(of: validated.stdout, as: .lines) {
        """
        Registry validation passed: full catalog

        """
      }
      let found = try command(["search", "test", "--format", "names"])
      #expect(found.code == 0)
      assertInlineSnapshot(of: found.stdout, as: .lines) {
        """
        example

        """
      }
      #expect(
        try command([
          "search", "test", "--platform", "iOS", "--target-version", "25.0", "--format", "names",
        ]).stdout.isEmpty)
      #expect(
        try command([
          "search", "test", "--platform", "iOS", "--target-version", "26", "--format", "names",
        ]).stdout == "example\n")
      // Zero matches say so on stderr, so an empty names list is never mistaken for a failure.
      let absent = try command(["search", "absent", "--format", "names"])
      #expect(absent.code == 0)
      #expect(absent.stdout.isEmpty)
      #expect(absent.stderr == "No item matches absent; try fewer or broader terms\n")
      #expect(found.stderr.isEmpty)
      #expect(
        try command(["search", "--platform", "iOS", "--target-version", "26.beta"]).code == 2)
    }
  }

  @Test func installationAndOwnership() throws {
    let fs = try fixture()
    try withFixture(fs) {
      let planned = try command(["install", "example", "--destination", "/app", "--plan"])
      #expect(planned.code == 0)
      assertInlineSnapshot(of: planned.stdout, as: .lines) {
        """
        plan: example
        destination: /app
        closure:
          example 0.1.0 (component)
        files:
          new example: /app/Example.swift
        packages:
          none
        preflight:
          ok: no collisions; install writes new targets and skips up-to-date targets
        next steps:
          1. Add each package requirement above to the consuming project; the installer never edits project files
          2. Ensure the destination folder is a member of the consuming build target
          3. Run: sweetui install example --destination /app
        plan only: nothing was written

        """
      }
      #expect(!fs.exists("/app"))
      let installed = try command(["install", "example", "--destination", "/app"])
      #expect(installed.code == 0)
      assertInlineSnapshot(of: installed.stdout, as: .lines) {
        """
        installed example: /app/Example.swift

        """
      }
      assertInlineSnapshot(of: fs.snapshot(), as: .lines) {
        """
        ./
        .sweetui/
        .sweetui/bases/
        .sweetui/bases/cbaa6d22a0c35cb115d1c3c78b066d71e7e85287affb80d98ede0c592f927053.base
          source
        \u{20}\u{20}
        .sweetui/receipt.json
          {
            "files": {
              "Example.swift": {
                "base": "bases/cbaa6d22a0c35cb115d1c3c78b066d71e7e85287affb80d98ede0c592f927053.base",
                "installedDigest": "sha256:b8bb034f9b63bd0254fbc7c157cae746c75853f4643d6cea844dc48ddb57f522",
                "item": "example",
                "sourceDigest": "sha256:b8bb034f9b63bd0254fbc7c157cae746c75853f4643d6cea844dc48ddb57f522",
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
          source
        \u{20}\u{20}
        """
      }
      let before = fs.snapshot()
      #expect(
        try command(["install", "example", "--destination", "/app"]).stdout
          == "up-to-date: example\n")
      #expect(
        try command(["install", "example", "--destination", "/app", "--diff"]).stdout
          == "identical example: /app/Example.swift\n")
      #expect(fs.snapshot() == before)
      try fs.put("/app/Example.swift", "consumer\n")
      let edited = fs.snapshot()
      let refused = try command(["install", "example", "--destination", "/app"])
      #expect(refused.code == 2)
      assertInlineSnapshot(of: refused.stderr, as: .lines) {
        """
        Refusing to overwrite owned source:
        /app/Example.swift
        Inspect local changes with --diff, merge registry changes with --update, or replace the files with --force

        """
      }
      #expect(fs.snapshot() == edited)
      let diff = try command(["install", "example", "--destination", "/app", "--diff"])
      #expect(diff.code == 1)
      assertInlineSnapshot(of: diff.stdout, as: .lines) {
        """
        --- owned/Example.swift
        +++ incoming/sources/Example.swift
        @@ -1 +1 @@
        -consumer
        +source

        """
      }
      #expect(fs.snapshot() == edited)
      let updated = try command(["install", "example", "--destination", "/app", "--update"])
      #expect(updated.code == 0)
      assertInlineSnapshot(of: updated.stdout, as: .lines) {
        """
        locally-modified example: /app/Example.swift

        """
      }
      let receipt = fs.snapshot()
      for _ in 0..<2 {
        #expect(try command(["install", "example", "--destination", "/app"]).code == 0)
        #expect(fs.snapshot() == receipt)
      }
      #expect(try command(["install", "example", "--destination", "/app", "--force"]).code == 0)
      #expect(try fs.read("/app/Example.swift") == Data("source\n".utf8))
    }
  }

  @Test func recipeRefusal() throws {
    let fs = try fixture()
    var recipe = example
    recipe["kind"] = "recipe"
    recipe["files"] = []
    recipe["docs"] = "Use the native control directly."
    var fields = recipe.object!
    fields.removeValue(forKey: "preview")
    recipe = .object(fields)
    try fs.put("/registry/Registry/items/example.json", recipe.rendered())
    try withFixture(fs) {
      let result = try command(["install", "example", "--destination", "/app"])
      #expect(result.code == 2)
      assertInlineSnapshot(of: result.stdout + result.stderr, as: .lines) {
        """
        Example()

        Use the native control directly.
        example: recipe items are native guidance; nothing to install

        """
      }
      #expect(!fs.exists("/app"))
      #expect(try command(["install", "example", "--destination", "/app", "--plan"]).code == 0)
      #expect(!fs.exists("/app"))
    }
  }
}
