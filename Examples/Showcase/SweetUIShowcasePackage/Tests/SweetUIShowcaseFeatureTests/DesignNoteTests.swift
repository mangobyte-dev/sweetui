import Foundation
import Testing
@testable import SweetUIDesignSurface

/// `design-notes.json` is the hand-off from a person looking at the screen
/// to an agent that cannot see it, so a note must carry what the agent
/// needs without the panel: the item and its chain, the tokens the item
/// reads, its moved knobs, its frame, the design's code, the note it
/// follows, and dates a shell can read. A note taken with nothing selected
/// is about the screen. Tune is the file's one writer: answers live in the
/// agent's file, so a note never carries one.
@MainActor
struct DesignNoteTests {
    @Test func `A note about an item carries its chain, tokens, and the design's code`() throws {
        let state = DesignSurfaceState.shared
        state.knobs.register(["button": [ItemKnob("height", in: 24...60, shipped: 36)]])
        let selection = ItemSelection(item: "button", chain: ["button", "card"])
        var tuning = ThemeTuning.default
        tuning.accent = .green
        let note = DesignNote.take("Too much padding", selection: selection, code: tuning.presetCode, state: state)

        #expect(note.item == "button")
        #expect(note.chain == ["button", "card"])
        #expect(note.tokens == RegistryItemTokens.tokens(for: "button"))
        #expect(!note.tokens.isEmpty, "The generated map must know the button.")
        #expect(note.presetCode == tuning.presetCode)
        // A knob at its shipped default is not an override.
        #expect(note.knobs.isEmpty)
        #expect(note.inReplyTo == nil)
    }

    /// Under Source the theme file holds the default theme while the app
    /// shows its own, so naming the default code would describe a theme the
    /// person never saw.
    @Test func `Under Source a note names no code`() {
        let note = DesignNote.take("Crowded", selection: ItemSelection(), code: "", state: .shared)
        #expect(note.presetCode == "")
        #expect(note.item == nil)
        #expect(note.chain.isEmpty)
        #expect(note.tokens.isEmpty)
        #expect(note.frame == nil)
    }

    @Test func `The file spells dates in ISO 8601 and round-trips a reply`() throws {
        var note = DesignNote(
            text: "Lift the card", item: "card", chain: ["card"], screen: "Catalog",
            tokens: ["cardRadius"], knobs: ["elevation": 2], frame: .init(x: 16, y: 120, width: 361, height: 80),
            presetCode: "a0")
        note.inReplyTo = "P1"
        let data = try DesignNote.fileEncoder.encode([note])
        let entry = try #require((try JSONSerialization.jsonObject(with: data) as? [[String: Any]])?.first)
        let date = try #require(entry["createdAt"] as? String)
        #expect(date.hasSuffix("Z"), "An agent reading the file with a shell expects ISO 8601: \(date)")
        #expect(entry["inReplyTo"] as? String == "P1")
        #expect(entry["resolved"] == nil, "Answers live in the agent's file.")
        #expect((entry["frame"] as? [String: Any])?["width"] as? Double == 361)

        let decoded = try DesignNote.fileDecoder.decode([DesignNote].self, from: data)
        #expect(decoded.map(\.id) == [note.id])
        #expect(decoded.first?.knobs == ["elevation": 2])
        #expect(decoded.first?.inReplyTo == "P1")
        #expect(abs(decoded.first!.createdAt.timeIntervalSince(note.createdAt)) < 1)
    }

    /// A device updated from the answers-in-notes shape keeps every note.
    @Test func `A notes file from before the agent's file still loads`() throws {
        let file = #"""
            [{
              "chain" : ["card"], "changedFiles" : ["Sources/App/Theme.swift"],
              "createdAt" : "2026-11-07T00:11:49Z", "id" : "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1",
              "item" : "card", "knobs" : {}, "presetCode" : "a13GkaOXWwIF",
              "reply" : "Raised the card's elevation to high.", "resolved" : true,
              "resolvedAt" : "2026-11-07T00:30:00Z", "screen" : "Catalog",
              "text" : "Lift the card off the background", "tokens" : ["cardRadius"]
            }]
            """#
        let notes = try DesignNote.fileDecoder.decode([DesignNote].self, from: Data(file.utf8))
        #expect(notes.map(\.text) == ["Lift the card off the background"])
        #expect(notes.first?.item == "card")
    }
}
