import CustomDump
import Foundation
import InlineSnapshotTesting
import Testing

@testable import SweetUIKit

struct PresetVector: Decodable, Sendable, CustomTestStringConvertible {
  var name: String
  var code: String
  var tuning: JSON
  var testDescription: String { name }
}
struct PresetVectors: Decodable { var vectors: [PresetVector] }
let presetVectors = try! JSONDecoder().decode(
  PresetVectors.self,
  from: Data(
    contentsOf: Bundle.module.url(
      forResource: "preset_vectors", withExtension: "json", subdirectory: "Fixtures")!)
).vectors

extension Commands {
  @Test(arguments: presetVectors) func presetVectorsAndFiles(_ vector: PresetVector) throws {
    let fs = try fixture()
    try withFixture(fs) {
      #expect(try Preset.encode(vector.tuning) == vector.code)
      expectNoDifference(Preset.decode(vector.code), vector.tuning)
      #expect(
        try Preset.encode(Preset.parseSwift(Preset.swiftSource(vector.tuning))) == vector.code)
      let description = try command(["preset", "decode", vector.code, "--json"])
      #expect(description.code == 0)
      expectNoDifference(try JSON.read(Data(description.stdout.utf8))["tuning"], vector.tuning)
      let applied = try command(["preset", "apply", vector.code, "--destination", "/app"])
      #expect(applied.code == 0)
      #expect(
        applied.stdout
          == "wrote /app/RegistryTheme+App.swift\napply once at the scene root: ContentView().registryTheme(.app)\n"
      )
      let resolved = try command(["preset", "resolve", "/app", "--json"])
      #expect(resolved.stdout == description.stdout)
      #expect(try command(["preset", "url", vector.code]).stdout == Preset.url(vector.code) + "\n")
    }
  }
  @Test func presetOwnershipAndRandom() throws {
    let fs = try fixture()
    try withFixture(fs) {
      let path = "/app/RegistryTheme+App.swift"
      #expect(try command(["preset", "apply", "a13GkaOXWwIa", "--destination", "/app"]).code == 0)
      let source = String(decoding: try fs.read(path), as: UTF8.self)
      try fs.put(path, source.replacingOccurrences(of: "cardRadius: 16", with: "cardRadius: 20"))
      let before = fs.snapshot()
      let refused = try command(["preset", "apply", "a13GkaOXWwIF", "--destination", "/app"])
      #expect(refused.code == 2)
      #expect(refused.stderr.contains("edited since it was written"))
      #expect(fs.snapshot() == before)
      #expect(
        try command(["preset", "apply", "a13GkaOXWwIF", "--destination", "/app", "--force"]).code
          == 0)
      #expect(try Preset.resolveFile(path) == "a13GkaOXWwIF")
      let random = try command(["preset", "random", "--seed", "3"])
      #expect(random.code == 0)
      assertInlineSnapshot(of: random.stdout, as: .lines) {
        """
        a1Pz4vBgXG0h

        """
      }
      let invalid = try command(["preset", "decode", "nope"])
      #expect(invalid.code == 2)
      assertInlineSnapshot(of: invalid.stderr, as: .lines) {
        """
        invalid preset code: nope

        """
      }
    }
  }
}

@Test func presetBoundsAndParser() throws {
  for code in [
    "", "a", "c13GkaOXWwIC", "a13GkaOXWwI-", "a" + String(repeating: "z", count: 48), "aF",
  ] { #expect(Preset.decode(code) == nil) }
  // A b code with the same digits as an a code is valid: it reads the a portion,
  // then the absent appended bits as their defaults.
  #expect(Preset.decode("b13GkaOXWwIC") != nil)
  #expect(Preset.code(in: "--preset a13GkaOXWwIC") == "a13GkaOXWwIC")
  var tuning = Preset.defaultTuning
  tuning["cardRadius"] = 18.3
  tuning["surfaceOpacity"] = 0.9
  tuning["compactSpacing"] = 1
  let decoded = try #require(Preset.decode(Preset.encode(tuning)))
  #expect(decoded["cardRadius"] == 18)
  #expect(decoded["surfaceOpacity"] == 0.2)
  #expect(decoded["compactSpacing"] == 4)
  #expect(throws: RegistryError.self) { try Preset.parseSwift("nothing here") }
  #expect(throws: RegistryError.self) { try Preset.parseSwift("RegistryTheme(accent: .magenta)") }
  let parsed = try Preset.parseSwift(
    "RegistryTheme(accent: .rose, disabledOpacity: 0.3, metrics: RegistryMetrics(cardRadius: 20))")
  #expect(parsed["accent"] == "pink")
  #expect(parsed["cardRadius"] == 20)
  #expect(parsed["standardSpacing"] == 16)
  for seed in 0..<200 {
    let code = try Preset.random(seed: Int64(seed))
    #expect(try Preset.encode(#require(Preset.decode(code))) == code)
  }
}
