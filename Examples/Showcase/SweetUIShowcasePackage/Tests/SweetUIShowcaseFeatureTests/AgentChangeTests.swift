import Foundation
import Testing
@testable import SweetUIDesignSurface

/// `design-agent-change.json` is how the panel knows the agent, not the
/// person, moved the theme: it must read what the engine writes, and Undo
/// must restore exactly the previous theme or knobs while leaving the
/// environment switches and the other items alone.
@MainActor
struct AgentChangeTests {
    @Test func `Reads the engine's record and undoes a theme change`() throws {
        let file = #"""
            {
              "changedAt" : "2026-11-07T00:50:00Z",
              "code" : "a74hGF01CVunaG0vzZJG",
              "previousCode" : "a13GkaOXWwIF",
              "what" : "tuning"
            }
            """#
        let change = try DesignNote.fileDecoder.decode(AgentChange.self, from: Data(file.utf8))
        #expect(change.what == .tuning)
        #expect(change.summary.contains("theme"))

        var tuning = try #require(ThemeTuning(presetCode: "a74hGF01CVunaG0vzZJG"))
        tuning.appearance = .dark
        change.undo(tuning: &tuning, knobs: KnobStore())
        #expect(tuning.presetCode == "a13GkaOXWwIF")
        #expect(tuning.appearance == .dark, "Undo never touches the switches.")
    }

    @Test func `A theme change with no previous code undoes to the default`() throws {
        let change = try DesignNote.fileDecoder.decode(
            AgentChange.self,
            from: Data(#"{"changedAt":"2026-11-07T00:50:00Z","code":"a74hGF01CVunaG0vzZJG","previousCode":null,"what":"tuning"}"#.utf8))
        var tuning = try #require(ThemeTuning(presetCode: "a74hGF01CVunaG0vzZJG"))
        change.undo(tuning: &tuning, knobs: KnobStore())
        #expect(tuning.presetCode == ThemeTuning.default.presetCode)
    }

    @Test func `Undoing a knobs change restores the item's previous values only`() throws {
        let change = try DesignNote.fileDecoder.decode(
            AgentChange.self,
            from: Data(#"{"changedAt":"2026-11-07T00:50:00Z","item":"button","knobs":{"radius":12},"previousKnobs":{"height":40},"what":"knobs"}"#.utf8))
        let knobs = KnobStore()
        let radius = ItemKnob("radius", in: 0...20, shipped: 8)
        let elevation = ItemKnob("elevation", in: 0...4, shipped: 0)
        knobs.register(["button": [radius, ItemKnob("height", in: 24...60, shipped: 36)], "card": [elevation]])
        knobs.set("button", radius, to: 12)
        knobs.set("card", elevation, to: 2)
        defer { knobs.reset("button"); knobs.reset("card") }

        var tuning = ThemeTuning.default
        change.undo(tuning: &tuning, knobs: knobs)
        #expect(knobs.values["button"] == ["height": 40])
        #expect(knobs.values["card"] == ["elevation": 2], "Another item's knobs stay.")
        #expect(tuning == .default)
    }
}
