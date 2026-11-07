import Foundation
import Testing
@testable import SweetUIDesignSurface

/// `design-notes.json` is the hand-off from a person looking at the screen
/// to an agent that cannot see it, so a note must carry what the agent
/// needs without the panel: the item and its chain, the tokens the item
/// reads, its moved knobs, its frame, the preset code, and dates a shell
/// can read. A note taken with nothing selected is about the screen.
@MainActor
struct DesignNoteTests {
    private static func document(_ notes: [DesignNote]) throws -> [[String: Any]] {
        let data = try DesignNote.fileEncoder.encode(notes)
        return try JSONSerialization.jsonObject(with: data) as! [[String: Any]]
    }

    @Test func `A note about an item carries its chain, tokens, and preset code`() throws {
        let state = DesignSurfaceState.shared
        state.knobs.register(["button": [ItemKnob("height", in: 24...60, shipped: 36)]])
        let selection = ItemSelection(item: "button", chain: ["button", "card"])
        var tuning = ThemeTuning.default
        tuning.accent = .green
        let note = DesignNote.take("Too much padding", selection: selection, tuning: tuning, state: state)

        #expect(note.item == "button")
        #expect(note.chain == ["button", "card"])
        #expect(note.tokens == RegistryItemTokens.tokens(for: "button"))
        #expect(!note.tokens.isEmpty, "The generated map must know the button.")
        #expect(note.presetCode == tuning.presetCode)
        // A knob at its shipped default is not an override.
        #expect(note.knobs.isEmpty)
        #expect(note.resolved == false)
    }

    @Test func `A note with nothing selected is about the screen`() {
        let note = DesignNote.take("Crowded", selection: ItemSelection(), tuning: .default, state: .shared)
        #expect(note.item == nil)
        #expect(note.chain.isEmpty)
        #expect(note.tokens.isEmpty)
        #expect(note.frame == nil)
    }

    @Test func `The file spells dates in ISO 8601 and round-trips`() throws {
        let note = DesignNote(
            text: "Lift the card", item: "card", chain: ["card"], screen: "Catalog",
            tokens: ["cardRadius"], knobs: ["elevation": 2], frame: .init(x: 16, y: 120, width: 361, height: 80),
            presetCode: "a0")
        let document = try Self.document([note])
        let entry = try #require(document.first)
        let date = try #require(entry["createdAt"] as? String)
        #expect(date.hasSuffix("Z"), "An agent reading the file with a shell expects ISO 8601: \(date)")
        #expect(entry["resolved"] as? Bool == false)
        #expect((entry["frame"] as? [String: Any])?["width"] as? Double == 361)

        let decoded = try DesignNote.fileDecoder.decode([DesignNote].self, from: DesignNote.fileEncoder.encode([note]))
        #expect(decoded.map(\.id) == [note.id])
        #expect(decoded.first?.knobs == ["elevation": 2])
        #expect(abs(decoded.first!.createdAt.timeIntervalSince(note.createdAt)) < 1)
    }

    @Test func `An answered note reads the agent's reply and can be reopened`() throws {
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
        var notes = try DesignNote.fileDecoder.decode([DesignNote].self, from: Data(file.utf8))
        let note = try #require(notes.first)
        #expect(note.resolved)
        #expect(note.reply == "Raised the card's elevation to high.")
        #expect(note.changedFiles == ["Sources/App/Theme.swift"])
        #expect(note.resolvedAt != nil)

        notes[0].reopen()
        #expect(!notes[0].resolved)
        #expect(notes[0].resolvedAt == nil)
        #expect(notes[0].reply == "Raised the card's elevation to high.", "The thread so far stays.")
        let document = try JSONSerialization.jsonObject(with: DesignNote.fileEncoder.encode(notes)) as! [[String: Any]]
        #expect(document[0]["resolved"] as? Bool == false)
        #expect(document[0]["resolvedAt"] == nil)
    }
}
