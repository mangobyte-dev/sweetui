import ArgumentParser
import Dependencies
import Foundation
import SweetUIKit

@main
struct SweetUI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "sweetui",
    abstract: "Install and inspect source-owned SwiftUI registry items.",
    version: RegistryRelease.version,
    subcommands: [
      Validate.self, Search.self, Describe.self, Install.self, Info.self, PresetCommand.self,
      Generate.self, MCP.self,
    ]
  )
}

struct RegistryOptions: ParsableArguments {
  @Option(help: "Path to a registry clone.") var registry: String?
  @Flag(
    help:
      "Download the pinned registry snapshot again and ask the release tags again, even when the cache is valid. The snapshot is not used with --registry or inside a clone."
  ) var refresh = false
  func root() throws -> String {
    @Dependency(\.registrySource) var source
    return try source.repositoryRoot(override: registry, refresh: refresh)
  }
}

func refusal<R>(_ body: () throws -> R) throws -> R {
  do { return try body() } catch let error as RegistryError {
    writeError(error.description + "\n")
    throw ExitCode(2)
  }
}

struct Validate: ParsableCommand {
  @OptionGroup var options: RegistryOptions
  @Argument var items: [String] = []
  func run() throws {
    let root = try refusal { try options.root() }
    let validator = RegistryValidator()
    let issues =
      items.isEmpty
      ? validator.validate(root: root) : items.flatMap { validator.validate(root: root, item: $0) }
    if !issues.isEmpty {
      writeError(
        "Registry validation failed with \(issues.count) issue(s):\n"
          + issues.map { "- \($0)\n" }.joined())
      throw ExitCode(1)
    }
    print(
      "Registry validation passed: "
        + (items.isEmpty ? "full catalog" : items.joined(separator: ", ")))
  }
}

struct Search: ParsableCommand {
  enum Kind: String, ExpressibleByArgument { case component, block, flow, recipe }
  enum Format: String, ExpressibleByArgument { case json, names }
  @OptionGroup var options: RegistryOptions
  @Argument var query: [String] = []
  @Option var kind: Kind?
  @Option var platform: String?
  @Option var targetVersion: String?
  @Option var format: Format = .json
  func run() throws {
    try refusal {
      let result = try Registry(root: options.root()).search(
        query.joined(separator: " "), kind: kind?.rawValue, platform: platform,
        targetVersion: targetVersion)
      if format == .names {
        for item in result { print(item["name"].text) }
        // Every term must match a name, alias, tag, or description word; say so instead of
        // printing nothing.
        if result.isEmpty {
          let terms = query.joined(separator: " ")
          writeError("No item matches \(terms); try fewer or broader terms\n")
        }
      } else {
        print(JSON.array(result).rendered())
      }
    }
  }
}

struct Install: ParsableCommand {
  @OptionGroup var options: RegistryOptions
  @Argument var item: String
  @Option var destination: String
  @Flag var force = false
  @Flag var update = false
  @Flag var plan = false
  @Flag var diff = false
  func validate() throws {
    if [force, update, plan, diff].filter({ $0 }).count > 1 {
      throw ValidationError("--force, --update, --plan, and --diff are mutually exclusive")
    }
  }
  func run() throws {
    try refusal {
      let installer = try Installer(root: options.root())
      do {
        if plan {
          try printPlan(installer)
          return
        }
        if diff {
          var differences = false
          for entry in try installer.diff(item, destination: destination) {
            if entry.diff.isEmpty {
              print("identical \(entry.file.item): \(entry.file.target)")
            } else {
              print(entry.diff, terminator: "")
              differences = true
            }
          }
          if differences { throw ExitCode(1) }
          return
        }
        if update {
          for result in try installer.update(item, destination: destination) {
            print("\(result.status.rawValue) \(result.file.item): \(result.file.target)")
          }
        } else {
          let files = try installer.install(item, destination: destination, force: force)
          for file in files { print("installed \(file.item): \(file.target)") }
          if files.isEmpty { print("up-to-date: \(item)") }
          for dependency in try installer.registry.packageRequirements(item) {
            print("requires: " + Registry.dependencyInstruction(dependency))
            let snippet = Registry.dependencyManifest(dependency)
            if !snippet.isEmpty {
              print("copy into Package.swift:")
              for line in snippet { print(line.isEmpty ? "" : "  " + line) }
              print(Registry.dependencyXcode(dependency))
            }
          }
        }
        if let notice = UpdateNotice().message(force: options.refresh) { print(notice) }
      } catch let guidance as RecipeGuidance {
        print(guidance.guidance)
        if plan {
          print("plan: \(guidance.name) is a recipe; native guidance only; nothing installs")
        } else {
          writeError("\(guidance.name): recipe items are native guidance; nothing to install\n")
          throw ExitCode(2)
        }
      }
    }
  }
  private func printPlan(_ installer: Installer) throws {
    @Dependency(\.registryFileSystem) var fs
    let entries = try installer.inspectPlan(item, destination: destination)
    print("plan: \(item)\ndestination: \(fs.resolve(destination))\nclosure:")
    for name in try installer.registry.resolve(item) {
      let member = installer.registry.items[name]!
      print("  \(name) \(member["version"].text) (\(member["kind"].text))")
    }
    print("files:")
    for entry in entries {
      print("  \(entry.status.rawValue) \(entry.file.item): \(entry.file.target)")
    }
    print("packages:")
    let requirements = try installer.registry.packageRequirements(item)
    for dependency in requirements {
      print("  requires: " + Registry.dependencyInstruction(dependency))
    }
    if requirements.isEmpty { print("  none") }
    let blocked = entries.filter { $0.status == .modifiedWouldRequireForce }
    let stale = entries.filter { $0.status == .wouldMerge }
    print("preflight:")
    if blocked.isEmpty && stale.isEmpty {
      print("  ok: no collisions; install writes new targets and skips up-to-date targets")
    }
    for entry in blocked {
      print(
        "  collision: \(entry.file.target) differs from its receipt; install refuses without --force"
      )
    }
    for entry in stale {
      print("  stale: registry source for \(entry.file.target) changed since install; run --update")
    }
    print("next steps:")
    print(
      "  1. Add each package requirement above to the consuming project; the installer never edits project files"
    )
    print("  2. Ensure the destination folder is a member of the consuming build target")
    print("  3. Run: sweetui install \(item) --destination \(destination)")
    print("plan only: nothing was written")
  }
}

func print(_ text: String, terminator: String = "\n") {
  @Dependency(\.registryConsole) var console
  console.stdout(text + terminator)
}
func writeError(_ text: String) {
  @Dependency(\.registryConsole) var console
  console.stderr(text)
}
