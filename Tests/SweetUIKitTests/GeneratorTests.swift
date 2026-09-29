import CustomDump
import Dependencies
import Foundation
import InlineSnapshotTesting
import Testing

@testable import SweetUIKit

extension Commands {
  @Test func generatorCommands() throws {
    let fs = try fixture()
    try fs.createDirectory("/registry/Examples/Showcase/SweetUIShowcaseUITests")
    try fs.put("/catalog/stale.md", "stale")
    try fs.put("/catalog/keep.txt", "keep")
    try fs.put("/registry/docs/images/items/example-light.png", "image bytes")
    try fs.put("/images/items/stale.png", "stale")
    try fs.put("/images/themes/stale.png", "stale")
    try withFixture(fs) {
      let catalog = try command(["generate", "catalog", "--output", "/catalog"])
      #expect(catalog.code == 0)
      #expect(catalog.stderr.isEmpty)
      assertInlineSnapshot(of: catalog.stdout, as: .lines) {
        """
        wrote /catalog/example.md
        wrote /catalog/index.md

        """
      }
      #expect(!fs.exists("/catalog/stale.md"))
      #expect(try fs.read("/catalog/keep.txt") == Data("keep".utf8))
      let original = try fs.read("/catalog/example.md")
      #expect(try command(["generate", "catalog", "--output", "/catalog"]).code == 0)
      #expect(try fs.read("/catalog/example.md") == original)
      let manifest = try command(["generate", "showcase-manifest", "--output", "/manifest.swift"])
      #expect(manifest.code == 0)
      #expect(manifest.stderr.isEmpty)
      assertInlineSnapshot(of: manifest.stdout, as: .lines) {
        """
        wrote /manifest.swift
        wrote /registry/Examples/Showcase/SweetUIShowcaseUITests/RegistryItemNames.swift

        """
      }
      let site = try command([
        "generate", "site-data", "--output", "/site.json", "--images", "/images",
      ])
      #expect(site.code == 0)
      #expect(site.stderr.isEmpty)
      assertInlineSnapshot(of: site.stdout, as: .lines) {
        """
        wrote /site.json
        copied 1 images to /images

        """
      }
      #expect(!fs.exists("/images/items/stale.png"))
      #expect(!fs.exists("/images/themes"))
      #expect(try fs.read("/images/items/example-light.png") == Data("image bytes".utf8))
      let checks = try command(["generate", "usage-checks", "--output", "/checks.swift"])
      #expect(checks.code == 0)
      #expect(checks.stderr.isEmpty)
      assertInlineSnapshot(of: checks.stdout, as: .lines) {
        """
        wrote /checks.swift

        """
      }
      var item = example
      item["name"] = "index"
      try fs.put("/registry/Registry/items/example.json", item.rendered())
      let refused = try command(["generate", "catalog", "--output", "/refused"])
      #expect(refused.code == 2)
      assertInlineSnapshot(of: refused.stderr, as: .lines) {
        """
        An item named 'index' would collide with the catalog index page; rename the item

        """
      }
      #expect(!fs.exists("/refused"))
    }
  }

  @Test func usageChecksRendering() {
    // A comment attaches to the statement below it; declarations become stored
    // members, views fill `body`, and the lone assignment lands in `statements()`.
    let usage = """
      // A short note about the counter.
      @State private var count = 0
      @State private var flag = false

      CounterView(count: $count)

      Toggle("Flag", isOn: $flag)

      count = 0
      """
    assertInlineSnapshot(
      of: UsageChecksGenerator.snippetStruct(name: "sample-item", usage: usage), as: .lines
    ) {
      """
      // MARK: sample-item
      private struct UsageSnippet_SampleItem: View {
          // A short note about the counter.
          @State private var count = 0
          @State private var flag = false
          var body: some View {
              CounterView(count: $count)
              Toggle("Flag", isOn: $flag)
          }
          private func statements() {
              count = 0
          }
      }

      """
    }
    // A single view with no declarations renders no `statements()` function.
    let solo = UsageChecksGenerator.snippetStruct(name: "solo", usage: "SoloView()")
    #expect(!solo.contains("func statements()"))
    assertInlineSnapshot(of: solo, as: .lines) {
      """
      // MARK: solo
      private struct UsageSnippet_Solo: View {
          var body: some View {
              SoloView()
          }
      }

      """
    }
  }

  @Test func generatedOutputsMatchCanonicalBytes() throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent().path
    let fs = InMemoryFileSystem()
    let live = FileSystem.local
    func copy(_ relative: String) throws {
      let source = root + "/" + relative
      if live.isDirectory(source) {
        try fs.createDirectory("/registry/" + relative)
        for child in try live.children(source) {
          try copy(relative + "/" + (child as NSString).lastPathComponent)
        }
      } else {
        try fs.write(live.read(source), to: "/registry/" + relative)
      }
    }
    try copy("Registry")
    try copy("docs/images")
    for doc in SiteDataGenerator.docs { try copy(doc.source) }
    try fs.createDirectory("/registry/Examples/Showcase/SweetUIShowcaseUITests")
    try withFixture(fs) {
      for generator in ["catalog", "showcase-manifest", "site-data", "item-tokens", "usage-checks"]
      {
        let result = try command(["generate", generator])
        #expect(result.code == 0, "\(generator): \(result.stderr)")
        #expect(result.stderr.isEmpty)
      }
      func compare(_ relative: String) throws {
        let expected = root + "/" + relative
        let actual = "/registry/" + relative
        if live.isDirectory(expected) {
          let names = try live.children(expected).map { ($0 as NSString).lastPathComponent }
          #expect(try fs.children(actual).map { ($0 as NSString).lastPathComponent } == names)
          for name in names { try compare(relative + "/" + name) }
        } else {
          let generated = try fs.read(actual)
          let canonical = try live.read(expected)
          // Text drift shows as a line diff; an image only as a mismatch.
          if let generatedText = String(validating: generated, as: UTF8.self),
            let canonicalText = String(validating: canonical, as: UTF8.self)
          {
            expectNoDifference(generatedText, canonicalText, "Generated text differs: \(relative)")
          } else {
            #expect(generated == canonical, "Generated bytes differ: \(relative)")
          }
        }
      }
      for path in [
        "docs/catalog", ShowcaseManifestGenerator.outputPath, ShowcaseManifestGenerator.namesPath,
        SiteDataGenerator.outputPath, SiteDataGenerator.imagesPath, SiteDataGenerator.docsPath,
        ItemTokensGenerator.outputPath, UsageChecksGenerator.outputPath,
      ] { try compare(path) }
      let manifest = try readText(
        fs.fileSystem, "/registry/" + ShowcaseManifestGenerator.outputPath)
      let registry = try Registry(root: "/registry")
      for (name, item) in registry.items {
        #expect(manifest.components(separatedBy: "name: \"\(name)\",").count == 2)
        #expect(manifest.contains(ShowcaseManifestGenerator.swiftString(item["usage"].text)))
      }
      let site = try JSON.read(fs.read("/registry/" + SiteDataGenerator.outputPath))
      let items = try #require(site["items"].array)
      #expect(items.map { $0["name"].text } == registry.items.keys.sorted())
      for item in items {
        #expect(!item["usage"].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        if item["kind"] == "recipe" {
          #expect(item["source"] == .null)
          #expect(item["installOrder"] == [])
          #expect(!item["docs"].text.isEmpty)
        } else {
          #expect(!item["source"].text.isEmpty)
          #expect(item["installOrder"].array?.last?["name"] == item["name"])
          #expect(!(item["requirements"].array ?? []).isEmpty)
          #expect(item["screenshots"]["light"].string != nil)
          #expect(item["screenshots"]["dark"].string != nil)
        }
      }
    }
  }
}
