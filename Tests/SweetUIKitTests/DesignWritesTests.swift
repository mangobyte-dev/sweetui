import Foundation
import Testing

@testable import SweetUIKit

/// The agent's writes to the device: a theme as a preset code the panel
/// decodes, knob values the items read, and the previous values recorded
/// beside them so the person can undo. A bad code or a bad knob value must
/// be refused before anything is written.
struct DesignWritesTests {
  @Test func setsATheme() throws {
    let fs = try fixture()
    try fs.createDirectory("/app")
    try fs.write(
      Data(#"{"code":"a13GkaOXWwIF","environment":{"appearance":"dark"}}"#.utf8),
      to: "/app/registry-tokens.json")
    try withFixture(fs) {
      let code = try DesignWrites.setTuning(
        code: "--preset a74hGF01CVunaG0vzZJG", tuning: nil, file: "/app/registry-tokens.json")
      #expect(code == "a74hGF01CVunaG0vzZJG")
      let written = try JSON.read(fs.read("/app/registry-tokens.json"))
      #expect(written["code"] == "a74hGF01CVunaG0vzZJG")
      #expect(written["environment"]["appearance"] == "dark", "The switches stay.")
      let change = try JSON.read(fs.read("/app/design-agent-change.json"))
      #expect(change["what"] == "tuning")
      #expect(change["previousCode"] == "a13GkaOXWwIF")
      #expect(change["changedAt"].string?.hasSuffix("Z") == true)
    }
  }

  @Test func mergesATuningObjectOverTheCurrentCode() throws {
    let fs = try fixture()
    try fs.createDirectory("/app")
    try withFixture(fs) {
      // No file yet: the default indigo is the base.
      let code = try DesignWrites.setTuning(
        code: nil, tuning: ["accent": "green", "cardRadius": 20], file: "/app/registry-tokens.json")
      let decoded = try #require(Preset.decode(code))
      #expect(decoded["accent"] == "green")
      #expect(decoded["cardRadius"] == 20)
      #expect(decoded["standardSpacing"] == 16, "Unnamed knobs keep their values.")
      let change = try JSON.read(fs.read("/app/design-agent-change.json"))
      #expect(change["previousCode"] == .null)
    }
  }

  @Test func refusesABadCodeAndWritesNothing() throws {
    let fs = try fixture()
    try fs.createDirectory("/app")
    try withFixture(fs) {
      #expect(throws: RegistryError.self) {
        try DesignWrites.setTuning(code: "nope", tuning: nil, file: "/app/registry-tokens.json")
      }
      #expect(throws: RegistryError.self) {
        try DesignWrites.setTuning(
          code: nil, tuning: ["accent": "plaid"], file: "/app/registry-tokens.json")
      }
      #expect(!fs.exists("/app/registry-tokens.json"))
      #expect(!fs.exists("/app/design-agent-change.json"))
    }
  }

  @Test func setsAndClearsKnobs() throws {
    let fs = try fixture()
    try fs.createDirectory("/app")
    try fs.write(
      Data(#"{"button":{"height":40},"card":{"elevation":2}}"#.utf8), to: "/app/design-knobs.json")
    try withFixture(fs) {
      let knobs = try DesignWrites.setKnobs(
        item: "button", values: ["height": .null, "radius": 12], file: "/app/design-knobs.json")
      #expect(knobs == ["radius": 12])
      let written = try JSON.read(fs.read("/app/design-knobs.json"))
      #expect(written["button"] == ["radius": 12])
      #expect(written["card"]["elevation"] == 2, "Other items keep their knobs.")
      let change = try JSON.read(fs.read("/app/design-agent-change.json"))
      #expect(change["what"] == "knobs")
      #expect(change["previousKnobs"] == ["height": 40])
      #expect(throws: RegistryError.self) {
        try DesignWrites.setKnobs(
          item: "button", values: ["height": "tall"], file: "/app/design-knobs.json")
      }
      #expect(throws: RegistryError.self) {
        try DesignWrites.setKnobs(item: "button", values: [:], file: "/app/design-knobs.json")
      }
    }
  }
}
