import ArgumentParser
import Dependencies
import Foundation
import SweetUIKit

struct Describe: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Print an item's metadata, usage, dependency closure, and file targets.")
  enum Format: String, ExpressibleByArgument { case text, json }
  @OptionGroup var options: RegistryOptions
  @Argument var item: String
  @Option var format: Format = .text
  @Flag(help: "Append each installable file's canonical source under the file targets.")
  var source = false
  func run() throws {
    try refusal {
      @Dependency(\.registryFileSystem) var fs
      let root = try options.root()
      let registry = try Registry(root: root)
      if format == .json {
        print(try describeItem(item, registry: registry, fs: fs, root: root).rendered())
        return
      }
      guard let member = registry.items[item] else {
        throw RegistryError("Unknown registry item: \(item)")
      }
      var out = "\(member["name"].text) (\(member["kind"].text) \(member["version"].text))\n"
      out += member["description"].text + "\n\n"
      out += "Usage:\n"
      for line in member["usage"].text.components(separatedBy: "\n") { out += "  " + line + "\n" }
      let payload = try describeItem(item, registry: registry, fs: fs, root: root)
      let signatures = payload["signatures"].array ?? []
      if !signatures.isEmpty {
        out += "Signatures:\n"
        for signature in signatures { out += "  " + (signature.string ?? "") + "\n" }
      }
      out += "Accessibility:\n"
      for note in member["accessibility"].strings { out += "- " + note + "\n" }
      if member["kind"] == "recipe" {
        out += "Nothing to install. Native guidance:\n"
        out += member["docs"].text + "\n"
      } else {
        out += "Install order:\n"
        for name in try registry.resolve(item) { out += "  " + name + "\n" }
        out += "Package requirements:\n"
        for dependency in try registry.packageRequirements(item) {
          out += "  " + Registry.dependencyInstruction(dependency) + "\n"
        }
        out += "Files:\n"
        for file in member["files"].array ?? [] { out += "  " + file["target"].text + "\n" }
        if source {
          for file in payload["files"].array ?? [] {
            out += "--- \(file["target"].string ?? "") ---\n"
            out += file["content"].string ?? ""
          }
        }
      }
      print(out, terminator: "")
    }
  }
}

struct Info: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Report the installed items and file status in a destination from its receipt.")
  enum Format: String, ExpressibleByArgument { case text, json }
  @Option var destination: String
  @Option var format: Format = .text
  func run() throws {
    try refusal {
      let report = try inventory(destination: destination)
      if format == .json {
        let payload: OrderedJSON = [
          "destination": .string(report.destination),
          "registry": OrderedJSON(report.registry),
          "items": .array(
            report.items.map { item in
              OrderedJSON.object([
                ("name", .string(item.name)),
                ("version", .string(item.version)),
                ("registryDependencies", .array(item.registryDependencies.map(OrderedJSON.string))),
                (
                  "files",
                  .array(
                    item.files.map {
                      OrderedJSON.object([
                        ("target", .string($0.target)), ("status", .string($0.status.rawValue)),
                      ])
                    })
                ),
              ])
            }),
          "summary": OrderedJSON.object([
            ("items", .scalar(.number(Double(report.items.count)))),
            ("upToDate", .scalar(.number(Double(report.upToDate)))),
            ("modified", .scalar(.number(Double(report.modified)))),
            ("missing", .scalar(.number(Double(report.missing)))),
          ]),
        ]
        print(payload.rendered())
        return
      }
      var out = "Installed items in \(report.destination):\n"
      for item in report.items {
        out += "\(item.name) \(item.version)\n"
        for file in item.files { out += "  \(file.target)  \(file.status.rawValue)\n" }
      }
      out +=
        "\(report.items.count) items, \(report.upToDate) files up-to-date, "
        + "\(report.modified) modified, \(report.missing) missing\n"
      print(out, terminator: "")
    }
  }
}
