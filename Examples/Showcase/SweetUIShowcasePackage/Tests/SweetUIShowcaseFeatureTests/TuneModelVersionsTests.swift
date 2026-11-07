import Dependencies
import DependenciesTestSupport
import Foundation
import Sharing
import SwiftUI
import SweetUIFoundations
import Testing
@testable import SweetUIDesignSurface

/// Versions is where the person moves through what the device showed and
/// hands it to the agent. Each Start from apply must add exactly one version
/// under Current, so Undo takes back exactly what was applied; Restore is a
/// jump that deletes nothing and that Undo takes back; a code Tune cannot
/// read changes nothing; and a hand-off is exactly the record its capture
/// makes, or says why it did not save.
extension TuneModelTests {
    @MainActor
    @Suite struct Versions {
        static let now = Date(timeIntervalSince1970: 1_800_000_000)
        static let knob = ItemKnob("height", in: 24...60, shipped: 36)
        static let mango = "a74hGF01CVunaG0vzZJG"

        static func stage() -> DesignSurfaceState {
            let stage = DesignSurfaceState()
            stage.knobs.register(["button": [knob]])
            return stage
        }

        static func note(_ text: String) -> DesignNote {
            DesignNote(
                id: UUID(), createdAt: now, text: text, item: nil, chain: [], screen: "Catalog", tokens: [], knobs: [:],
                frame: nil, presetCode: "")
        }

        @Test func `Apply makes exactly one child of Current with its origin, and Source clears the knobs too`() async throws {
            let stage = Self.stage()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.knobChanged("button", Self.knob, to: 44)
            await Task.megaYield()

            let applies: [(DesignHistory.Origin, () -> Void)] = [
                (.preset(name: "Mango"), { model.presetChipTapped("Mango") }),
                (.defaultTheme, { model.defaultButtonTapped() }),
                (.code, {
                    model.codeDraft = "--preset \(Self.mango)"
                    model.applyCodeButtonTapped()
                }),
                (.source, { model.sourceButtonTapped() }),
            ]
            for (origin, apply) in applies {
                let before = try #require(model.current)
                let count = model.history.entries.count
                apply()
                await Task.megaYield()
                #expect(model.history.entries.count == count + 1, "\(origin) must be one version, not one per file.")
                let version = try #require(model.current)
                #expect(version.parent == before.id, "\(origin) must be a child of Current.")
                #expect(version.origin == origin)
                #expect(version.author == .you)
                #expect(version.design == model.liveDesign, "The version is what the device shows.")
                if origin == .defaultTheme {
                    #expect(version.design.knobs == ["button": ["height": 44]], "Default keeps the knobs.")
                }
            }
            #expect(model.current?.design == DesignHistory.Design(), "Source clears every token override.")
            #expect(stage.knobs.values.isEmpty, "Source clears the knob overrides too.")
            #expect(model.label(try #require(model.current)) == "Source")
        }

        @Test func `Restore moves Current and creates nothing, and Undo right after it returns to the version left`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Mango")
            let mango = try #require(model.current)
            model.presetChipTapped("Rose")
            model.tuningEdit.cardRadius = 30
            let left = try #require(model.current)
            let count = model.history.entries.count

            model.restore(mango.id)
            #expect(model.history.entries.count == count, "Restore deletes nothing and adds nothing.")
            #expect(model.current?.id == mango.id)
            #expect(model.tuning.presetCode == mango.design.code, "The restored version is on the device.")
            #expect(model.undoTarget?.id == left.id, "Undo's hint names the version Restore left.")

            model.undoButtonTapped()
            #expect(model.current?.id == left.id, "Undo returns to the version left, not to Mango's parent.")
            #expect(model.tuning.cardRadius == 30)
            #expect(model.history.entries.count == count)

            // Onto a proposal's version that is not kept: Restore tries it again,
            // and Undo leaves it for the version Restore left.
            agentWrites { $0.proposals = [Proposal(id: "P", date: Self.now, name: "Teal", tokens: ["accent": .string("teal")], apply: false)] }
            await Task.megaYield()
            model.tryButtonTapped("P")
            let trial = try #require(model.history.trial)
            model.discardButtonTapped()
            model.tuningEdit.cardRadius = 24
            let edit = try #require(model.current)
            let total = model.history.entries.count

            model.restore(trial.version)
            #expect(model.trying?.id == "P", "Restore onto a proposal's version is Trying.")
            #expect(model.tuning.accent == .teal)
            model.undoButtonTapped()
            #expect(model.current?.id == edit.id, "Undo returns to the version Restore left, not to the proposal's base.")
            #expect(model.history.decisions["P"]?.state == .discarded)
            #expect(model.history.trial == nil)
            #expect(model.tuning.cardRadius == 24)
            #expect(model.tuning.accent == .pink, "The device shows the version left, without the proposal.")
            #expect(model.stripMessage == "Discarded Teal.")
            #expect(model.history.entries.count == total)
        }

        @Test func `A code Tune cannot read says so and records nothing`() throws {
            let model = TuneModelTests.launched(Self.stage())
            let history = model.history
            let tuning = model.tuning

            // Return on the field after an Apply cleared it (seen on the iPhone Duo).
            model.codeDraft = " "
            model.applyCodeButtonTapped()
            #expect(model.codeError == nil, "A blank field is not a bad code.")
            #expect(model.history == history)

            model.codeDraft = "--preset not-a-code"
            model.applyCodeButtonTapped()
            #expect(model.codeError == TuneModel.codeError)
            #expect(model.history == history, "A bad code records no version.")
            #expect(model.tuning == tuning, "A bad code changes nothing on the device.")
            #expect(model.codeDraft == "--preset not-a-code", "The draft stays to be fixed.")

            // As iOS smart punctuation types "--preset" (seen on the iPhone Duo).
            model.codeDraft = "\u{2014}preset \(Self.mango)"
            model.applyCodeButtonTapped()
            #expect(model.codeError == nil)
            #expect(model.current?.origin == .code)
            #expect(model.current?.design.code == Self.mango)
        }

        @Test(.dependency(\.uuid, .constant(UUID(uuidString: "6F1C2A10-0000-4000-8000-0000000000D1")!)))
        func `Hand off gives the outbox exactly the record its capture makes`() async throws {
            @Dependency(\.outboxRecord) var record
            let stage = Self.stage()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let answered = Self.note("The cards sit flat.")
            let open = Self.note("Taller buttons.")
            model.$notes.withLock { $0 = [answered, open] }
            agentWrites { $0.answers[answered.id.uuidString] = .init(reply: "Raised them.", date: Self.now) }
            await Task.megaYield()
            model.presetChipTapped("Mango")
            model.knobChanged("button", Self.knob, to: 44)
            #expect(model.openNotesLine == "1 open note goes with the hand-off.")

            model.handOffButtonTapped()
            let written = try #require(record.handOffs.value.last)
            let expected = DesignHandoff.capture(
                id: UUID(uuidString: "6F1C2A10-0000-4000-8000-0000000000D1")!, sentAt: Self.now, design: model.liveDesign,
                tuning: model.tuning, version: model.history.current, notes: model.notes, answers: model.agent.answers,
                screenshot: "notes/handoff.png", previous: nil)
            #expect(written == expected)
            #expect(written.openNotes.map(\.id) == [open.id], "Only the note the agent has not answered goes.")
            #expect(written.knobs == ["button": ["height": 44]])
            #expect(record.screenshots.value.last == "handoff")
            #expect(model.handOff == written)
            #expect(model.handOffStatus == .sent(Self.now))
        }

        /// Whether the outbox below saves a hand-off.
        nonisolated static let saves = LockIsolated(true)

        @Test(
            .dependency(
                \.designOutbox,
                DesignOutbox(
                    writeContext: { _ in }, writeHandOff: { _ in Versions.saves.value }, readHandOff: { nil },
                    saveScreenshot: { name, _ in "notes/\(name).png" })))
        func `A hand-off that did not save says why and shows no time`() throws {
            let saves = Self.saves
            saves.setValue(true)
            let model = TuneModelTests.launched(Self.stage())
            model.handOffButtonTapped()
            let first = try #require(model.handOff)

            saves.setValue(false)
            model.handOffButtonTapped()
            let status = try #require(model.handOffStatus)
            #expect(status == .notSaved("The hand-off did not save, so the agent cannot read it. Hand off again."))
            #expect(!status.text.contains("Handed off at"), "An unsaved hand-off shows no time.")
            #expect(model.handOff == first, "The last saved hand-off still takes its answer.")

            saves.setValue(true)
            model.handOffButtonTapped()
            #expect(model.handOffStatus == .sent(Self.now), "Handing off again clears the error.")
            #expect(model.handOff?.previous?.id == first.id)
        }

        @Test func `Hand off while trying keeps the proposal first`() async throws {
            @Dependency(\.outboxRecord) var record
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Rose")
            agentWrites { $0.proposals = [Proposal(id: "P", date: Self.now, name: "Teal", tokens: ["accent": .string("teal")])] }
            await Task.megaYield()
            let trial = try #require(model.history.trial)

            model.handOffButtonTapped()
            #expect(model.history.decisions["P"]?.state == .kept, "A hand-off carries a decided design.")
            #expect(model.history.trial == nil)
            #expect(model.stripMessage == "Kept Teal.")
            let written = try #require(record.handOffs.value.last)
            #expect(written.version == trial.version, "The hand-off carries the proposal's version.")
            #expect(ThemeTuning(presetCode: written.presetCode)?.accent == .teal)
        }

        @Test func `Current says what it changed and how the Checks stand, and the history marks a branch`() async throws {
            let stage = TuneModelTests.screen()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let first = try #require(model.current)
            #expect(model.label(first) == "First version")
            #expect(model.changesFromParent(first) == nil, "The first version came from nothing.")
            #expect(
                model.checksLine == ContrastAudit.unmeasuredUnderSource,
                "Under Source the app shows its own colors, so the line must not measure Default.")

            model.presetChipTapped("Rose")
            model.tuningEdit.cardRadius = 20
            let edit = try #require(model.current)
            #expect(model.label(edit) == "Edit")
            #expect(model.changesFromParent(edit)?.map(\.words) == ["Card radius: 16 to 20 pt"])
            #expect(model.changesFromDefault.contains { $0.words == "Card radius: 16 to 20 pt" })
            #expect(model.checksLine != ContrastAudit.unmeasuredUnderSource, "A set theme is measured.")

            model.versionName = "  Warm "
            model.nameSubmitted()
            #expect(model.label(try #require(model.current)) == "Warm")
            #expect(model.versionName == "Warm", "The field shows Current's name.")

            model.undoButtonTapped()
            model.tuningEdit.cardRadius = 24
            let rows = model.historyRows
            #expect(rows.map(\.entry.id).first == model.history.current, "Newest first.")
            #expect(rows.first?.branch?.id == edit.parent, "A version beside a newer branch names the one it came from.")
            #expect(rows.dropFirst().allSatisfy { $0.branch == nil }, "A straight line names no parent.")

            stage.selection = ItemSelection(item: "card", chain: ["card", "dashboard"])
            model.openGroups = []
            model.place = .versions
            model.checksLineTapped()
            #expect(model.place == .tokens)
            #expect(model.openGroups.contains(.color))
            #expect(model.stage.selection.item == nil, "The Checks show only with nothing selected.")

            stage.tunesTheme = false
            #expect(model.checksLine == nil, "A host that does not tune the theme has no Checks.")
        }

        @Test func `The open notes line goes to Notes at the oldest open note`() async throws {
            let model = TuneModelTests.launched(Self.stage())
            #expect(model.openNotesLine == nil)
            let a = Self.note("One")
            let b = Self.note("Two")
            model.$notes.withLock { $0 = [a, b] }
            #expect(model.openNotesLine == "2 open notes go with the hand-off.")
            model.openNotesLineTapped()
            #expect(model.place == .notes)
            #expect(model.scrollTarget == "note.\(a.id.uuidString)")
        }
    }
}
