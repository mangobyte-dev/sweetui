import Foundation
import Testing
@testable import SweetUIDesignSurface

/// The hand-off is the one file an agent needs to put the device's design
/// into source: it must carry its id and the previous one's (both take an
/// answer), the theme both ways, every moved knob, only the notes the agent
/// has not answered, and the changes from Default, with ISO dates. Under
/// Source it carries no theme, since the app shows its own.
struct DesignHandoffTests {
    @Test func `Captures the design and what the agent must act on`() throws {
        var tuning = try #require(ThemeTuning(presetCode: "a74hGF01CVunaG0vzZJG"))
        tuning.cardRadius = 20
        let done = DesignNote(text: "Done one", item: "card", chain: ["card"], screen: "Catalog", tokens: [], knobs: [:], frame: nil, presetCode: "a0")
        var open = DesignNote(text: "Taller", item: "button", chain: ["button"], screen: "button", tokens: ["accent"], knobs: [:], frame: nil, presetCode: "a0")
        open.screenshot = "notes/x.png"
        let design = DesignHistory.Design(code: tuning.presetCode, knobs: ["button": ["height": 40]])
        let first = DesignHandoff.capture(
            id: UUID(), sentAt: .now, design: design, tuning: tuning, version: nil, notes: [], answers: [:],
            screenshot: nil, previous: nil)

        let handoff = DesignHandoff.capture(
            id: UUID(), sentAt: .now, design: design, tuning: tuning, version: UUID(), notes: [done, open],
            answers: [done.id.uuidString: .init(reply: "Raised it.", date: .now)],
            screenshot: "notes/handoff.png", previous: first)
        #expect(handoff.presetCode == tuning.presetCode)
        #expect(handoff.swift.contains("RegistryTheme("))
        #expect(handoff.knobs == ["button": ["height": 40]])
        #expect(handoff.openNotes.map(\.text) == ["Taller"], "An answered note is not open.")
        #expect(handoff.openNotes.first?.screenshot == "notes/x.png")
        #expect(handoff.differences.contains { $0.key == "cardRadius" && $0.to == "20" })
        #expect(handoff.previous?.id == first.id, "The previous hand-off still takes an answer.")
        #expect(handoff.previous?.presetCode == first.presetCode)

        let data = try DesignNote.fileEncoder.encode(handoff)
        let document = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect((document["sentAt"] as? String)?.hasSuffix("Z") == true)
        #expect(document["id"] as? String == handoff.id.uuidString)
        #expect(document["chosenVariant"] == nil && document["checkpoints"] == nil, "Named versions stay in Versions.")
    }

    @Test func `Under Source the hand-off carries no theme`() {
        let handoff = DesignHandoff.capture(
            id: UUID(), sentAt: .now, design: DesignHistory.Design(knobs: ["button": ["height": 40]]),
            tuning: .default, version: nil, notes: [], answers: [:], screenshot: nil, previous: nil)
        #expect(handoff.presetCode == "")
        #expect(handoff.swift == "")
        #expect(handoff.differences.isEmpty)
        #expect(handoff.knobs == ["button": ["height": 40]], "Knob-only designs still hand off.")
    }
}
