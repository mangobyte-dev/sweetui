import Foundation
import Testing
@testable import SweetUIDesignSurface

/// The history is what makes an agent's live write safe and a person's
/// exploration reversible: every settled state is kept once, Undo and Redo
/// walk them, a change after an Undo drops the redo tail, a name survives
/// trimming, and the comparison to the shipped theme lists each knob that
/// moved and nothing else.
struct DesignHistoryTests {
    private static let indigo = DesignHistory.State(code: "a13GkaOXWwIF", knobs: [:])
    private static let mango = DesignHistory.State(code: "a74hGF01CVunaG0vzZJG", knobs: [:])
    private static let tall = DesignHistory.State(code: "a74hGF01CVunaG0vzZJG", knobs: ["button": ["height": 40]])

    @Test func `Records settled states once and walks them`() {
        var history = DesignHistory()
        history.record(Self.indigo, source: .shipped)
        history.record(Self.indigo, source: .person)
        #expect(history.entries.count == 1, "A rewrite that moved nothing is not an entry.")
        history.record(Self.mango, source: .variant)
        history.record(Self.tall, source: .agent)
        #expect(history.entries.map(\.source) == [.shipped, .variant, .agent])
        #expect(history.cursor == 2)

        #expect(history.undo()?.state == Self.mango)
        #expect(history.undo()?.state == Self.indigo)
        #expect(history.undo() == nil, "Nothing before the first entry.")
        #expect(history.redo()?.state == Self.mango)
        #expect(history.canRedo)

        // A new change after an Undo drops the redo tail.
        history.record(Self.tall, source: .person)
        #expect(history.entries.map(\.state) == [Self.indigo, Self.mango, Self.tall])
        #expect(!history.canRedo)
    }

    @Test func `Names a checkpoint, restores it, and keeps it through trimming`() {
        var history = DesignHistory()
        history.record(Self.indigo, source: .shipped)
        history.name("  Launch look ")
        #expect(history.named.map(\.name) == ["Launch look"])
        let launch = history.entries[0].id
        for step in 0..<(DesignHistory.capacity + 20) {
            history.record(DesignHistory.State(code: "a13GkaOXWwIF", knobs: ["button": ["height": Double(step)]]), source: .person)
        }
        #expect(history.entries.count == DesignHistory.capacity)
        #expect(history.entries.first?.name == "Launch look", "The named entry outlives the unnamed ones.")
        #expect(history.restore(launch)?.state == Self.indigo)
        #expect(history.cursor == 0)
        #expect(history.restore(UUID()) == nil)
        history.name("")
        #expect(history.named.isEmpty)
    }

    @Test func `The file round-trips with ISO dates`() throws {
        var history = DesignHistory()
        history.record(Self.tall, source: .agent)
        history.name("Taller buttons")
        let data = try DesignNote.fileEncoder.encode(history)
        let document = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let entry = try #require((document["entries"] as? [[String: Any]])?.first)
        #expect((entry["date"] as? String)?.hasSuffix("Z") == true)
        #expect(entry["source"] as? String == "agent")
        #expect(document["cursor"] as? Int == 0)
        let decoded = try DesignNote.fileDecoder.decode(DesignHistory.self, from: data)
        #expect(decoded.current?.name == "Taller buttons")
        #expect(decoded.current?.knobs == ["button": ["height": 40]])
    }

    @Test func `Compare to shipped lists each moved knob and nothing else`() throws {
        #expect(ThemeTuning.default.differences(from: .default).isEmpty)
        var tuning = ThemeTuning.default
        tuning.accent = .green
        tuning.cardRadius = 20
        tuning.fontDesign = .rounded
        tuning.appearance = .dark
        let differences = tuning.differences(from: .default)
        #expect(differences.map(\.key) == ["accent", "cardRadius", "fontDesign"], "Switches are not knobs: \(differences)")
        #expect(differences[0].from == "indigo" && differences[0].to == "green")
        #expect(differences[1].from == "16" && differences[1].to == "20")
        let mango = try #require(ThemeTuning(presetCode: "a74hGF01CVunaG0vzZJG"))
        let fromDefault = mango.differences(from: .default)
        #expect(fromDefault.contains { $0.key == "customAccent" && $0.to == "#FFA033" })
        #expect(fromDefault.contains { $0.key == "customAccentDark" && $0.from == "none" && $0.to == "#FFB84D" })
    }
}
