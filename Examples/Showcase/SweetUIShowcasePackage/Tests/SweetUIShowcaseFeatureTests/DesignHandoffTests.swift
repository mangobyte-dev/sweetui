import Foundation
import Testing
@testable import SweetUIDesignSurface

/// The hand-off is the one file an agent needs to put the device's design
/// into source: it must carry the theme both ways, the chosen variant even
/// after the chips stop matching, every moved knob, only the open notes,
/// only the named checkpoints, and the knobs that differ from the shipped
/// theme, with ISO dates in the file.
struct DesignHandoffTests {
    @Test func `Captures the design and what the agent must act on`() throws {
        var tuning = try #require(ThemeTuning(presetCode: "a74hGF01CVunaG0vzZJG"))
        tuning.cardRadius = 20
        var variants = DesignVariants(variants: [.init(name: "Warm", code: "a74hGF01CVunaG0vzZJG")])
        variants.chosen = "Warm"
        var done = DesignNote(text: "Done one", item: "card", chain: ["card"], screen: "Catalog", tokens: [], knobs: [:], frame: nil, presetCode: "a0")
        done.resolved = true
        var open = DesignNote(text: "Taller", item: "button", chain: ["button"], screen: "button", tokens: ["accent"], knobs: [:], frame: nil, presetCode: "a0")
        open.screenshot = "notes/x.png"
        var history = DesignHistory()
        history.record(DesignHistory.Design(code: "a13GkaOXWwIF"), author: .you, origin: .first)
        history.name("Launch")
        history.record(DesignHistory.Design(code: tuning.presetCode, knobs: ["button": ["height": 40]]), author: .you, origin: .edit)

        let handoff = DesignHandoff.capture(
            tuning: tuning, knobs: ["button": ["height": 40]], variants: variants, notes: [done, open],
            history: history, screenshot: "notes/handoff.png")
        #expect(handoff.presetCode == tuning.presetCode)
        #expect(handoff.swift.contains("RegistryTheme("))
        #expect(handoff.chosenVariant == "Warm", "The pick survives a knob moved after it.")
        #expect(handoff.knobs == ["button": ["height": 40]])
        #expect(handoff.openNotes.map(\.text) == ["Taller"])
        #expect(handoff.openNotes.first?.screenshot == "notes/x.png")
        #expect(handoff.checkpoints.map(\.name) == ["Launch"])
        #expect(handoff.differences.contains { $0.key == "cardRadius" && $0.to == "20" })

        let data = try DesignNote.fileEncoder.encode(handoff)
        let document = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect((document["sentAt"] as? String)?.hasSuffix("Z") == true)
        #expect((document["differences"] as? [[String: Any]])?.first?["key"] != nil)
    }
}
