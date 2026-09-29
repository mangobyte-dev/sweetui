import ArgumentParser
import SweetUIKit

struct Generate: ParsableCommand {
  static let configuration = CommandConfiguration(subcommands: [
    Catalog.self, ShowcaseManifest.self, SiteData.self, ItemTokens.self, UsageChecks.self,
  ])
  struct Catalog: ParsableCommand {
    @OptionGroup var options: RegistryOptions
    @Option var output: String?
    func run() throws {
      try refusal {
        let root = try options.root()
        for path in try CatalogGenerator(root: root).generate(
          output: outputPath(output ?? root + "/docs/catalog"))
        { print("wrote \(path)") }
      }
    }
  }
  struct ShowcaseManifest: ParsableCommand {
    @OptionGroup var options: RegistryOptions
    @Option var output: String?
    func run() throws {
      try refusal {
        let root = try options.root()
        for path in try ShowcaseManifestGenerator(root: root).generate(
          output: outputPath(output ?? root + "/" + ShowcaseManifestGenerator.outputPath),
          namesOutput: root + "/" + ShowcaseManifestGenerator.namesPath)
        { print("wrote \(path)") }
      }
    }
  }
  struct SiteData: ParsableCommand {
    @OptionGroup var options: RegistryOptions
    @Option var output: String?
    @Option var images: String?
    func run() throws {
      try refusal {
        let root = try options.root()
        let output = outputPath(output ?? root + "/" + SiteDataGenerator.outputPath)
        let images = outputPath(images ?? root + "/" + SiteDataGenerator.imagesPath)
        let count = try SiteDataGenerator(root: root).generate(output: output, images: images)
        print("wrote \(output)\ncopied \(count) images to \(images)")
      }
    }
  }
  struct ItemTokens: ParsableCommand {
    @OptionGroup var options: RegistryOptions
    @Option var output: String?
    func run() throws {
      try refusal {
        let root = try options.root()
        let path = try ItemTokensGenerator(root: root).generate(
          output: outputPath(output ?? root + "/" + ItemTokensGenerator.outputPath))
        print("wrote \(path)")
      }
    }
  }
  struct UsageChecks: ParsableCommand {
    @OptionGroup var options: RegistryOptions
    @Option var output: String?
    func run() throws {
      try refusal {
        let root = try options.root()
        for path in try UsageChecksGenerator(root: root).generate(
          output: outputPath(output ?? root + "/" + UsageChecksGenerator.outputPath))
        { print("wrote \(path)") }
      }
    }
  }
}

// pathlib.Path normalizes separators and dot components without resolving symlinks or '..'.
private func outputPath(_ path: String) -> String {
  let parts = path.split(separator: "/").filter { $0 != "." }.joined(separator: "/")
  let prefix =
    path.hasPrefix("//") && !path.hasPrefix("///") ? "//" : path.hasPrefix("/") ? "/" : ""
  return prefix + parts == "" ? "." : prefix + parts
}
