import Foundation
import Testing
@testable import SweetUIDesignSurface

/// Versions are the person's safety net and the agent's record of what the
/// person decided. Nothing the person named or the loop depends on may be
/// lost: not by an edit after Undo, not by trimming, not by an update from
/// the list-shaped file, and a proposal must leave the base exactly as it was.
struct DesignHistoryTests {
    private typealias Design = DesignHistory.Design

    private static let indigo = Design(code: "a13GkaOXWwIF")
    private static let mango = Design(code: "a74hGF01CVunaG0vzZJG")
    private static let tall = Design(code: "a74hGF01CVunaG0vzZJG", knobs: ["button": ["height": 40]])

    /// The history as the next launch reads it back from the file.
    private static func relaunched(_ history: DesignHistory) throws -> DesignHistory {
        try DesignNote.fileDecoder.decode(DesignHistory.self, from: DesignNote.fileEncoder.encode(history))
    }

    /// A name is the person's bookmark. Exploring from an earlier version
    /// must branch beside it and never delete it, through a relaunch too.
    /// Stray spaces are not part of a name, and a blank one clears it.
    @Test func `A named version survives an edit after Undo`() throws {
        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        let a = try #require(history.current)
        history.record(Self.mango, author: .you, origin: .edit)
        let b = try #require(history.current)
        history.name("  Warm \n")
        #expect(history.undo()?.id == a)
        history.record(Self.tall, author: .you, origin: .edit)
        history.name("Draft")
        history.name("  ")
        #expect(history.entry(history.current)?.name == nil, "A blank name clears the one there.")

        let reopened = try Self.relaunched(history)
        #expect(reopened.entry(b)?.name == "Warm", "The edit after Undo deleted the named version.")
        #expect(reopened.entry(b)?.design == Self.mango)
        #expect(reopened.named.map(\.id) == [b])
        let c = try #require(reopened.entry(reopened.current))
        #expect(c.design == Self.tall)
        #expect(c.parent == a, "The edit branches from the version Undo landed on.")
    }

    /// Undo and Redo walk the tree the way the person moved: back to the
    /// parent, forward to the newest child, so Redo replays the latest branch
    /// and not an older one.
    @Test func `Undo goes to the parent and Redo to the newest child`() throws {
        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        let a = try #require(history.current)
        history.record(Self.mango, author: .you, origin: .edit)
        history.undo()
        history.record(Self.tall, author: .agent, origin: .edit)
        let c = try #require(history.current)
        #expect(history.entries.filter { $0.parent == a }.count == 2, "A keeps both branches.")

        #expect(history.undo()?.id == a)
        #expect(history.canRedo)
        #expect(history.redo()?.id == c, "Redo takes the newest child, not the first one.")
        #expect(!history.canRedo)
        #expect(history.redo() == nil)
    }

    /// A device that ran the list-shaped history keeps every version and
    /// every name after the update, and Undo still walks back as it did.
    @Test func `A legacy file with a cursor undoes linearly and keeps its names`() throws {
        let json = """
            {
              "cursor" : 2,
              "entries" : [
                { "id" : "6F1C2A10-0000-4000-8000-000000000001", "date" : "2026-10-01T09:00:00Z",
                  "code" : "a13GkaOXWwIF", "knobs" : {}, "source" : "shipped" },
                { "id" : "6F1C2A10-0000-4000-8000-000000000002", "date" : "2026-10-01T09:05:00Z",
                  "code" : "a74hGF01CVunaG0vzZJG", "knobs" : {}, "source" : "variant", "name" : "Mango" },
                { "id" : "6F1C2A10-0000-4000-8000-000000000003", "date" : "2026-10-01T09:10:00Z",
                  "code" : "a74hGF01CVunaG0vzZJG", "knobs" : { "button" : { "height" : 40 } }, "source" : "person" },
                { "id" : "6F1C2A10-0000-4000-8000-000000000004", "date" : "2026-10-01T09:15:00Z",
                  "code" : "a13GkaOXWwIF", "knobs" : {}, "source" : "agent" }
              ]
            }
            """
        var history = try DesignNote.fileDecoder.decode(DesignHistory.self, from: Data(json.utf8))
        let ids = history.entries.map(\.id)
        try #require(ids.count == 4)
        #expect(history.current == ids[2])
        #expect(history.entries.map(\.parent) == [nil, ids[0], ids[1], ids[2]])
        #expect(history.entries.map(\.author) == [.you, .agent, .you, .agent])
        #expect(history.entries.map(\.origin) == [.first, .proposal(id: ""), .edit, .edit])
        #expect(history.entries[2].design == Self.tall)
        #expect(history.named.map(\.name) == ["Mango"])

        #expect(history.undo()?.name == "Mango")
        #expect(history.undo()?.id == ids[0])
        #expect(history.undo() == nil, "Nothing before the first version.")
        #expect(history.redo()?.id == ids[1])
        #expect(history.redo()?.id == ids[2])
        #expect(history.redo()?.id == ids[3])
    }

    /// Trimming keeps the file small without losing what the person or the
    /// loop depends on: a named version, the one on the device, the base a
    /// trial returns to, and the one Shipped version. The tree stays whole.
    /// Going back to the shipped design later makes ordinary versions, or
    /// the file would grow past its cap.
    @Test func `Trimming never drops named, current, base, or Shipped versions`() throws {
        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        history.name("Launch")
        let launch = try #require(history.current)
        history.record(Self.mango, author: .you, origin: .edit)
        let shipped = try #require(history.current)
        history.ship(handoff: UUID(), design: Self.mango, files: ["RegistryTheme+App.swift"])
        let source = try #require(history.current)
        #expect(history.entry(source)?.design == Design(), "Shipped clears to Source.")
        history.record(Self.tall, author: .you, origin: .edit)
        let oldest = try #require(history.current)
        var step = 0.0
        while history.entries.count < DesignHistory.capacity {
            step += 1
            history.record(Design(code: Self.indigo.code, knobs: ["button": ["height": step]]), author: .you, origin: .edit)
        }
        let child = history.entries[4]
        #expect(child.parent == oldest)

        history.restore(source)
        history.tryProposal("P1", design: Self.indigo)
        #expect(history.entries.count == DesignHistory.capacity)
        let kept = Set(history.entries.map(\.id))
        #expect(kept.isSuperset(of: [launch, shipped, source]), "A named, Shipped, or base version was dropped.")
        #expect(!kept.contains(oldest), "The oldest version that may drop is the one that went.")
        #expect(history.entry(child.id)?.parent == source, "The dropped version's child takes its parent.")
        #expect(history.entry(history.current)?.origin == .proposal(id: "P1"))

        var full = DesignHistory()
        for step in 0..<DesignHistory.capacity {
            full.record(Design(code: Self.indigo.code, knobs: ["button": ["height": Double(step)]]), author: .you, origin: .edit)
            full.name("Look \(step)")
        }
        full.record(Self.tall, author: .you, origin: .edit)
        #expect(full.entries.count == DesignHistory.capacity + 1, "With every older version named, the history runs over.")
        #expect(full.entry(full.current)?.design == Self.tall, "Trimming dropped the version on the device.")

        var toggled = DesignHistory()
        toggled.record(Self.indigo, author: .you, origin: .first)
        toggled.record(Self.mango, author: .you, origin: .edit)
        let handedOff = try #require(toggled.current)
        toggled.ship(handoff: UUID(), design: Self.mango, files: ["RegistryTheme+App.swift"])
        for _ in 0..<DesignHistory.capacity {
            toggled.record(Self.tall, author: .you, origin: .edit)
            toggled.record(Self.mango, author: .you, origin: .edit)
        }
        #expect(toggled.entries.count == DesignHistory.capacity, "Returning to the shipped design grew the history past its cap.")
        #expect(toggled.entry(handedOff) != nil, "The Shipped version was dropped.")
    }

    /// Trying proposals one after another must never stack them: each is a
    /// child of the same base, Discard puts the base back exactly, and the
    /// decisions tell the agent which one the person turned down. With no
    /// version yet there is no base to put back, so nothing is tried.
    @Test func `Try, Try, Discard restores the base exactly`() throws {
        var empty = DesignHistory()
        #expect(empty.tryProposal("P0", design: Self.mango) == nil, "A trial needs a base to return to.")
        #expect(empty.trial == nil && empty.entries.isEmpty && !empty.canUndo)

        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        let base = try #require(history.current)
        history.tryProposal("P1", design: Self.mango)
        let p1 = try #require(history.current)
        history.tryProposal("P2", design: Self.tall)
        let p2 = try #require(history.current)
        #expect(history.entry(p1)?.parent == base)
        #expect(history.entry(p2)?.parent == base, "The second try builds on the base, not on the first proposal.")
        #expect(history.entry(p2)?.author == .agent)
        #expect(history.trial?.proposal == "P2")

        history.discard()
        #expect(history.current == base)
        #expect(history.entry(history.current)?.design == Self.indigo)
        #expect(history.trial == nil)
        let reopened = try Self.relaunched(history)
        #expect(reopened.decisions.mapValues(\.state) == ["P1": .tried, "P2": .discarded])
        #expect(reopened.entries.count == 3, "Both tries stay in the tree.")
    }

    /// The agent learns what the person decided from the decisions: Keep
    /// marks the proposal kept and its Offered siblings discarded, an edit on
    /// top keeps it too, and Undo while trying is a Discard.
    @Test func `Keep and Undo during a trial record decisions`() throws {
        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        history.tryProposal("P1", design: Self.mango)
        let p1 = try #require(history.current)
        history.keep(discarding: ["P2"])
        #expect(history.decisions["P1"]?.state == .kept)
        #expect(history.decisions["P2"]?.state == .discarded, "Keep turns the Offered siblings down.")
        #expect(history.current == p1)
        #expect(history.trial == nil)

        history.tryProposal("P3", design: Self.tall)
        #expect(history.canUndo)
        #expect(history.undo()?.id == p1, "Undo while trying goes back to the base.")
        #expect(history.decisions["P3"]?.state == .discarded)
        #expect(history.trial == nil)

        history.tryProposal("P4", design: Self.tall)
        let p4 = try #require(history.current)
        history.record(Design(code: Self.tall.code, knobs: ["button": ["height": 44]]), author: .you, origin: .edit)
        #expect(history.decisions["P4"]?.state == .kept, "An edit on top of a proposal keeps it.")
        #expect(history.entry(history.current)?.parent == p4)
        #expect(history.trial == nil)
    }

    /// The tree decides a proposal's state, so the person can change their
    /// mind with Undo and Redo alone: going forward onto a discarded
    /// proposal's version puts it back on trial, and going back past a kept
    /// one tells the agent it was turned down after all.
    @Test func `Redo onto a trial version re-enters Trying and Undo past Kept records Discarded`() throws {
        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        let base = try #require(history.current)
        history.tryProposal("P1", design: Self.mango)
        let p1 = try #require(history.current)
        history.undo()
        #expect(history.decisions["P1"]?.state == .discarded)
        #expect(history.trial == nil)

        #expect(history.redo()?.id == p1)
        #expect(history.trial == DesignHistory.Trial(proposal: "P1", version: p1, base: base), "Redo onto the trial version is Trying again.")
        #expect(history.decisions["P1"]?.state == .tried)

        history.keep()
        #expect(history.decisions["P1"]?.state == .kept)
        history.undo()
        #expect(history.current == base)
        #expect(history.decisions["P1"]?.state == .discarded, "Undo past a kept proposal is a Discard the agent must read.")
        #expect(history.trial == nil)

        history.record(Self.tall, author: .you, origin: .edit)
        let edit = try #require(history.current)
        #expect(history.restore(p1)?.id == p1)
        #expect(history.trial?.proposal == "P1", "Restore onto a proposal's version is Trying too.")
        #expect(history.trial?.base == base, "Its base is its parent, not the version Restore left.")
        history.keep()
        history.restore(edit)
        history.restore(p1)
        #expect(history.trial == nil, "A kept proposal's version is the decided design, not a trial.")
        #expect(history.decisions["P1"]?.state == .kept)
    }

    /// Discard on an offered row turns the proposal down without touching
    /// the device; it must never discard the one trying.
    @Test func `Discarding an offered proposal leaves the device and the trial alone`() throws {
        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        history.tryProposal("P1", design: Self.mango)
        let p1 = try #require(history.current)
        history.discard(offered: "P2")
        #expect(history.decisions["P2"]?.state == .discarded)
        #expect(history.current == p1)
        history.discard(offered: "P1")
        #expect(history.trial?.proposal == "P1", "The trying proposal is decided by Keep or Discard, not by an offered row.")
        #expect(history.decisions["P1"]?.state == .tried)
    }

    /// Restore is a jump the person can take back: Undo right after it
    /// returns to the version they left, not to the restored one's parent.
    @Test func `Undo right after Restore returns to the version it left`() throws {
        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        history.record(Self.mango, author: .you, origin: .edit)
        let b = try #require(history.current)
        history.record(Self.tall, author: .you, origin: .edit)
        let c = try #require(history.current)

        #expect(history.restore(b)?.design == Self.mango)
        #expect(history.entries.count == 3, "Restore deletes nothing.")
        #expect(history.undo()?.id == c, "Undo returns to the version left, not to the parent of the one restored.")
        #expect(history.undo()?.id == b, "After that, Undo walks parents again.")
        #expect(history.restore(UUID()) == nil)
    }

    /// Restore onto a proposal's version that is not kept puts it on trial,
    /// but the person jumped there from somewhere else: Undo must take them
    /// back to that version, not to the proposal's base, and the agent must
    /// read the proposal turned down.
    @Test func `Undo right after Restore onto a trial version returns to the version left and discards it`() throws {
        var history = DesignHistory()
        history.record(Self.indigo, author: .you, origin: .first)
        let base = try #require(history.current)
        history.tryProposal("P1", design: Self.mango)
        let p1 = try #require(history.current)
        history.discard()
        history.record(Self.tall, author: .you, origin: .edit)
        let left = try #require(history.current)

        history.restore(p1)
        #expect(history.trial?.proposal == "P1", "Restore onto a proposal's version that is not kept is Trying.")
        #expect(history.undo()?.id == left, "Undo returns to the version Restore left, not to the proposal's base.")
        #expect(history.current == left)
        #expect(history.decisions["P1"]?.state == .discarded, "Leaving a trial is a Discard the agent must read.")
        #expect(history.trial == nil)
        #expect(history.undo()?.id == base, "After that, Undo walks parents again.")
        #expect(history.entries.count == 3, "Restore and Undo create nothing.")
    }

    /// On launch the value files are the truth: a save the history lost to a
    /// kill comes back as one edit, and a launch that changed nothing adds
    /// nothing, so relaunching never floods Versions. A trial whose save was
    /// lost shows the base, so the agent must read it discarded, not kept.
    @Test func `Reconcile records one edit when the values moved and nothing when equal`() throws {
        var history = DesignHistory()
        history.reconcile(values: Self.indigo)
        #expect(history.entries.map(\.origin) == [.first])
        let a = try #require(history.current)
        history.reconcile(values: Self.indigo)
        #expect(history.entries.count == 1, "Equal values add nothing.")

        history.reconcile(values: Self.tall)
        history.reconcile(values: Self.tall)
        #expect(history.entries.count == 2)
        let edit = try #require(history.entry(history.current))
        #expect(edit.design == Self.tall)
        #expect(edit.origin == .edit)
        #expect(edit.parent == a)

        history.tryProposal("P1", design: Self.mango)
        history.reconcile(values: Self.tall)
        #expect(history.current == edit.id, "The values show the base, so the base is current.")
        #expect(history.decisions["P1"]?.state == .discarded, "A lost save is not the person keeping the proposal.")
        #expect(history.trial == nil)
        #expect(history.entries.count == 3, "A lost save records no version.")
    }
}
