import Dependencies
import Foundation

public struct SiteDataGenerator {
  let registry: Registry
  let root: String
  @Dependency(\.registryFileSystem) var fs
  public static let outputPath = "Website/content/registry.json"
  public static let imagesPath = "Website/public/images"
  /// The repository's markdown the site's Docs section renders, copied beside
  /// the data so the site reads generated files only: the changelog and the
  /// contract documents, each under the slug its page uses.
  public static let docsPath = "Website/content/docs"
  public static let docs: [(source: String, slug: String)] = [
    ("CHANGELOG.md", "changelog"),
    ("docs/philosophy.md", "philosophy"),
    ("docs/architecture.md", "architecture"),
    ("docs/registry-spec.md", "registry-spec"),
    ("docs/mango.md", "mango"),
    ("docs/visual-testing.md", "visual-testing"),
    ("docs/case-studies.md", "case-studies"),
  ]
  static let repositoryURL = "https://github.com/mangobyte-dev/sweetui"
  public init(root: String) throws {
    self.root = root
    registry = try Registry(root: root)
  }

  public func render() throws -> String {
    let items = try registry.items.keys.sorted().map { name -> OrderedJSON in
      let item = registry.items[name]!
      let recipe = item["kind"] == "recipe"
      let preview = item["preview"]
      let screenshots = preview["screenshots"].strings
      let source = item["files"].array?.first?["source"].string
      var result = OrderedJSON.fields(
        item, ["name", "kind", "version", "description", "usage", "docs", "tags"])
      result["aliases"] = OrderedJSON(item.object?["aliases"] ?? [])
      result["platforms"] = .array(
        (item["platforms"].array ?? []).map {
          .string("\($0["name"].text) \($0["minimumVersion"].text)+")
        })
      result["dependencies"] = OrderedJSON(item["registryDependencies"])
      result["installOrder"] = .array(
        try recipe
          ? []
          : registry.resolve(name).map {
            OrderedJSON.fields(registry.items[$0]!, ["name", "version"])
          })
      result["accessibility"] = OrderedJSON(item["accessibility"])
      result["sourcePath"] = source.map { .string("Registry/" + $0) } ?? nil
      result["sourceURL"] =
        source.map { .string(Self.repositoryURL + "/blob/main/Registry/" + $0) } ?? nil
      result["source"] =
        try source.map { .string(try readText(fs, root + "/Registry/" + $0)) } ?? nil
      result["previewName"] = OrderedJSON(preview["name"])
      result["screenshots"] = .object(
        ["light", "dark"].map { appearance in
          (
            appearance,
            screenshots.first { $0.hasSuffix("-\(appearance).png") }.map {
              .string("/images/items/" + ($0 as NSString).lastPathComponent)
            } ?? nil
          )
        })
      result["wideScreenshots"] = imagePaths(folder: "ipad", stem: name + "-ipad")
      result["requirements"] = .array(
        try recipe ? [] : registry.packageRequirements(name).map(packageDescription))
      return result
    }
    // Name, slug, blurb, and the preset code pinned for that preset in
    // Registry/preset_vectors.json (GeneratorTests checks the codes agree).
    let presets: [(String, String, String, String)] = [
      ("System", "system", "Inherits the app tint. The default.", "a13GkaOXWwIC"),
      ("Graphite", "graphite", "Ink on paper: primary accent, background label.", "a13GkaOXWxLl"),
      ("Indigo", "indigo", "The Showcase's own accent.", "a13GkaOXWwIF"),
      ("Rose", "rose", "Warm and friendly.", "a13GkaOXWwIH"),
      ("Emerald", "emerald", "Growth and confirmation.", "a13GkaOXWwIL"),
      ("Amber", "amber", "A light accent that proves the on-accent token.", "a13GkaOXWwIa"),
      (
        "Mango", "mango",
        "MangoByte's sample design system: strokeless, generous, one warm accent.",
        "a74hGF01CVunaG0vzZJG"
      ),
    ]
    let output: OrderedJSON = [
      "name": .string(registry.name), "repositoryURL": .string(Self.repositoryURL),
      "counts": .object(
        ["component", "block", "recipe"].map { kind in
          (
            kind,
            OrderedJSON(
              .number(Double(registry.items.values.filter { $0["kind"].text == kind }.count)))
          )
        }),
      "items": .array(items),
      "presets": .array(
        presets.map { name, slug, blurb, code in
          [
            "name": .string(name), "slug": .string(slug), "blurb": .string(blurb),
            "code": .string(code),
            "screenshots": imagePaths(folder: "themes", stem: slug),
            // A preset with its own Showcase scene (MANGO) captured through
            // `capture_previews.py --scene <slug>-demo`; empty for the rest.
            "demoScreenshots": imagePaths(folder: "themes", stem: slug + "-demo"),
          ]
        }),
    ]
    return output.rendered(ascii: false) + "\n"
  }
  private func imagePaths(folder: String, stem: String) -> OrderedJSON {
    .object(
      ["light", "dark"].map { appearance in
        let file = "\(folder)/\(stem)-\(appearance).png"
        return (
          appearance, fs.isFile(root + "/docs/images/" + file) ? .string("/images/" + file) : nil
        )
      })
  }
  public func generate(output: String, images: String) throws -> Int {
    let text = try render()
    try fs.createDirectory(parentDirectory(output))
    try fs.write(Data(text.utf8), to: output)
    try copyDocs(beside: output)
    var count = 0
    for folder in ["items", "themes", "ipad", "comparison", "design-surface", "case-studies"] {
      let source = root + "/docs/images/" + folder
      let target = images + "/" + folder
      try fs.remove(target)
      if !fs.isDirectory(source) { continue }
      try fs.createDirectory(target)
      for image in try fs.children(source) where image.hasSuffix(".png") {
        try fs.write(fs.read(image), to: target + "/" + (image as NSString).lastPathComponent)
        count += 1
      }
    }
    return count
  }

  /// Writes each listed markdown file as `docs/<slug>.md` beside the data
  /// file, byte for byte, and drops anything else in that folder. A source
  /// the checkout lacks is skipped, so a fixture without a changelog still
  /// generates.
  func copyDocs(beside output: String) throws {
    let target = parentDirectory(output) + "/docs"
    try fs.remove(target)
    try fs.createDirectory(target)
    for doc in Self.docs where fs.isFile(root + "/" + doc.source) {
      try fs.write(fs.read(root + "/" + doc.source), to: target + "/" + doc.slug + ".md")
    }
  }
}

func packageDescription(_ entry: JSON) -> OrderedJSON {
  [
    "instruction": .string(Registry.dependencyInstruction(entry)),
    "manifest": .string(Registry.dependencyManifest(entry).joined(separator: "\n")),
    "xcode": .string(Registry.dependencyXcode(entry)),
  ]
}

func readText(_ fs: FileSystem, _ path: String) throws -> String {
  let data = try fs.read(path)
  guard let text = String(data: data, encoding: .utf8) else {
    throw RegistryError("Cannot decode UTF-8: \(path)")
  }
  return text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
    of: "\r", with: "\n")
}
