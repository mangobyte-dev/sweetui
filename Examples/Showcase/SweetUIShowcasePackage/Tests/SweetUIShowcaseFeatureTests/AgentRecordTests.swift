import Foundation
import Testing
@testable import SweetUIDesignSurface

/// The files the agent writes and the history's decisions, as the real MCP
/// server and Tune wrote them on the iPhone Duo. The root suite decodes the
/// same bytes, so a shape change on either side fails where it was made.
enum SharedFixture {
    static func data(_ name: String) throws -> Data {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { url.deleteLastPathComponent() }
        return try Data(contentsOf: url.appending(path: "Tests/SweetUIKitTests/Fixtures/\(name)"))
    }
}

/// Tune reads the agent's file it never writes. It must read what MCP wrote
/// whole, an empty file as no record, and a proposal's delta must merge to
/// the design the device recorded when it tried it.
struct AgentRecordTests {
    @Test func `The captured agent file and history decode to the states the device showed`() throws {
        let record = try AgentRecord.decode(SharedFixture.data("design-agent.json"))
        let history = try DesignNote.fileDecoder.decode(DesignHistory.self, from: SharedFixture.data("design-history.json"))
        let warm = try #require(record.proposals.first)
        let mango = try #require(record.proposals.last)
        #expect(warm.tokens == ["accent": .string("orange"), "cardRadius": .number(24)])
        #expect(warm.state(in: history) == .kept)
        #expect(mango.state(in: history) == .discarded)
        #expect(!warm.needsTry(in: history) && !mango.needsTry(in: history), "A decided proposal is never tried again.")
        #expect(mango.knobs?["card"]?["elevation"] == .some(nil), "A null knob decodes as the default, not as 0.")
        #expect(record.read.notes.count == 1 && record.read.handoffs.count == 1)

        let tried = try #require(history.entries.first { $0.origin == .proposal(id: warm.id) })
        let base = try #require(history.entry(tried.parent))
        #expect(try warm.design(over: base.design) == tried.design, "Tune's merge reproduces the version the device recorded.")

        let shipped = try #require(history.shipped)
        #expect(record.answers[shipped.handoff.uuidString]?.changedFiles == shipped.changedFiles)
        #expect(history.entry(history.current)?.design == DesignHistory.Design(), "Shipped cleared to Source.")
    }

    /// Sharing creates the file it watches with no bytes before the agent's
    /// first write, and decodes it again on every change.
    @Test func `A 0-byte agent file is an empty record`() throws {
        #expect(try AgentRecord.decode(Data()) == AgentRecord())
        #expect(try AgentRecord.decode(Data("{}".utf8)) == AgentRecord(), "Missing parts read as empty.")
        #expect(throws: (any Error).self) { try AgentRecord.decode(Data("{".utf8)) }
    }

    @Test func `A delta merges over Source as over Default, and an unknown key cannot be tried`() throws {
        let teal = Proposal(id: "P", date: .now, name: "Teal", tokens: ["accent": .string("teal")])
        let overSource = try teal.design(over: DesignHistory.Design())
        #expect(ThemeTuning(presetCode: overSource.code)?.accent == .teal)
        #expect(ThemeTuning(presetCode: overSource.code)?.cardRadius == ThemeTuning.default.cardRadius)

        let unknown = Proposal(id: "Q", date: .now, name: "Bad", tokens: ["cornerRadius": .number(4)])
        #expect(throws: Proposal.Unreadable.self) { try unknown.design(over: DesignHistory.Design()) }
        let badCode = Proposal(id: "R", date: .now, name: "Bad", code: "zzz")
        #expect(throws: Proposal.Unreadable.self) { try badCode.design(over: DesignHistory.Design()) }

        let knobs = Proposal(id: "S", date: .now, name: "Knobs", knobs: ["button": ["height": nil, "radius": 12]])
        let design = try knobs.design(over: DesignHistory.Design(code: "a13GkaOXWwIF", knobs: ["button": ["height": 44]]))
        #expect(design == DesignHistory.Design(code: "a13GkaOXWwIF", knobs: ["button": ["radius": 12]]), "A knobs-only proposal keeps the theme.")
    }

    /// The version a try records must equal what the theme file then holds,
    /// or Tune reads its own write as an edit and keeps the proposal unasked.
    /// A `b` code whose appended fields are all at their defaults is valid,
    /// and the file writes it back as `a`.
    @Test func `A valid code in a form Tune does not write is stored as Tune writes it`() throws {
        let mango = "a74hGF01CVunaG0vzZJG"
        let written = "b" + mango.dropFirst()
        #expect(ThemeTuning(presetCode: written)?.presetCode == mango, "The file writes this b code back as a.")
        let proposal = Proposal(id: "M", date: .now, name: "Mango", code: "--preset \(written)")
        #expect(try proposal.design(over: DesignHistory.Design()).code == mango)
    }

    /// An error says what to do next: a proposal Tune cannot try is answered
    /// by asking the agent for another.
    @Test func `An unreadable proposal says to reply for another`() {
        let badCode = Proposal(id: "R", date: .now, name: "Bad", code: "zzz")
        #expect(throws: Proposal.Unreadable("Its code is not one Tune can read. Reply to ask the agent for another.")) {
            try badCode.design(over: DesignHistory.Design())
        }
    }
}
