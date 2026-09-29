import ArgumentParser
import Foundation
import SweetUIKit

struct PresetCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "preset",
    subcommands: [Decode.self, URLCommand.self, Apply.self, Resolve.self, Random.self])
  struct Decode: ParsableCommand {
    @Argument var code: String
    @Flag var json = false
    func run() throws { try refusal { print(try Preset.description(code, json: json)) } }
  }
  struct URLCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "url")
    @Argument var code: String
    func run() throws {
      try refusal {
        guard Preset.isCode(code) else { throw RegistryError("invalid preset code: \(code)") }
        print(Preset.url(code))
      }
    }
  }
  struct Apply: ParsableCommand {
    @Argument var code: String
    @Option var destination: String
    @Flag var force = false
    func run() throws {
      try refusal {
        let path = try Preset.apply(code, destination: destination, force: force)
        print("wrote \(path)\napply once at the scene root: ContentView().registryTheme(.app)")
      }
    }
  }
  struct Resolve: ParsableCommand {
    @Argument var path: String
    @Flag var json = false
    func run() throws {
      try refusal { print(try Preset.description(Preset.resolveFile(path), json: json)) }
    }
  }
  struct Random: ParsableCommand {
    @Option(parsing: .unconditional) var seed: String?
    func run() throws { try refusal { print(try Preset.random(seedText: seed)) } }
  }
}
