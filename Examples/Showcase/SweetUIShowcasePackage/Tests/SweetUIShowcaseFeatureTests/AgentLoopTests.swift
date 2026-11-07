import Dependencies
import DependenciesTestSupport
import Foundation
@_spi(Internals) import Sharing
import SwiftUI
import SweetUIFoundations
import Testing
@testable import SweetUIDesignSurface

/// MCP's side of `design-agent.json` in a test: a write through the same
/// reference Tune reads, as the file watch delivers it on the device.
@MainActor
func agentWrites(_ change: (inout AgentRecord) -> Void) {
    let agent = Shared(
        wrappedValue: AgentRecord(),
        .fileStorage(AgentRecord.fileURL, decode: AgentRecord.decode, encode: AgentRecord.encode))
    agent.withLock(change)
}

extension TuneModelTests {
    /// The loop with the agent: it proposes, Tune tries, the person keeps or
    /// discards, and the agent reads the decision. The device must show the
    /// decided design or exactly one proposal on top of it, a decision must
    /// follow what the person did (Keep, an edit, Undo, Redo), and Tune must
    /// never write the agent's file, or one of the two would lose a write.
    @MainActor
    @Suite struct AgentLoop {
        static let now = Date(timeIntervalSince1970: 1_800_000_000)
        static let knob = ItemKnob("height", in: 24...60, shipped: 36)

        static func proposal(
            _ id: String, _ name: String, minute: Double = 0, note: String? = nil, code: String? = nil,
            tokens: [String: TokenValue]? = nil, knobs: [String: [String: Double?]]? = nil, apply: Bool = false
        ) -> Proposal {
            Proposal(
                id: id, date: now.addingTimeInterval(minute * 60), name: name, note: note, code: code, tokens: tokens,
                knobs: knobs, apply: apply)
        }

        static func stage() -> DesignSurfaceState {
            let stage = DesignSurfaceState()
            stage.knobs.register(["button": [knob]])
            return stage
        }

        @Test func `Try A, Try B, Discard puts the base back exactly`() async throws {
            let stage = Self.stage()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Mango")
            model.knobChanged("button", Self.knob, to: 44)
            let base = try #require(model.current)
            let baseTuning = model.tuning
            agentWrites {
                $0.proposals = [
                    Self.proposal("A", "Teal", tokens: ["accent": .string("teal")]),
                    Self.proposal("B", "Round", minute: 1, tokens: ["cardRadius": .number(30)], knobs: ["button": ["height": nil]]),
                ]
            }
            await Task.megaYield()
            #expect(model.history.trial == nil, "A proposal that does not ask to be applied waits as Offered.")

            model.tryButtonTapped("A")
            #expect(model.tuning.accent == .teal)
            model.tryButtonTapped("B")
            #expect(model.tuning.accent == baseTuning.accent, "B is merged over the base, not stacked on A.")
            #expect(model.tuning.cardRadius == 30)
            #expect(stage.knobs.values.isEmpty, "A null knob returns it to its default.")
            #expect(model.proposal("A")?.state(in: model.history) == .offered, "A replaced on trial is offered again.")

            model.discardButtonTapped()
            #expect(model.tuning == baseTuning, "Discard must put the base's theme back exactly.")
            #expect(stage.knobs.values == ["button": ["height": 44]], "Discard must put the base's knobs back.")
            #expect(model.current?.id == base.id)
            #expect(model.proposal("B")?.state(in: model.history) == .discarded)
            #expect(model.stripMessage == "Discarded Round.")
        }

        /// Start from leaves a proposal, as Undo and Restore do: what it
        /// applies goes over the base, so a token the person never chose
        /// must not stay on the device or be listed as their change.
        @Test func `Apply while a proposal is trying discards it first, so none of its tokens or knobs stay`() async throws {
            let stage = Self.stage()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Rose")
            let base = try #require(model.current)
            agentWrites {
                $0.proposals = [
                    Self.proposal("W", "Warm", tokens: ["cardRadius": .number(20)], knobs: ["button": ["height": 50]], apply: true)
                ]
            }
            await Task.megaYield()
            #expect(model.trying?.id == "W")
            #expect(model.tuning.cardRadius == 20)

            model.presetChipTapped("Emerald")
            #expect(model.history.decisions["W"]?.state == .discarded)
            #expect(model.history.trial == nil)
            #expect(model.tuning.cardRadius == ThemeTuning.default.cardRadius, "Warm's radius must leave with Warm.")
            #expect(stage.knobs.values.isEmpty, "Warm's knob must leave with Warm.")
            let emerald = try #require(model.current)
            #expect(emerald.parent == base.id, "The preset is a child of the base, not of Warm's version.")
            #expect(emerald.origin == .preset(name: "Emerald"))
            #expect(
                model.changesFromParent(emerald)?.map(\.title) == ["Accent"],
                "Only the preset's accent is the person's change.")

            agentWrites { $0.proposals.append(Self.proposal("X", "Round", minute: 1, tokens: ["cardRadius": .number(28)], apply: true)) }
            await Task.megaYield()
            model.defaultButtonTapped()
            #expect(model.history.decisions["X"]?.state == .discarded)
            #expect(model.tuning.cardRadius == ThemeTuning.default.cardRadius)

            agentWrites { $0.proposals.append(Self.proposal("Y", "Round", minute: 2, tokens: ["cardRadius": .number(28)], apply: true)) }
            await Task.megaYield()
            model.codeDraft = "--preset a74hGF01CVunaG0vzZJG"
            model.applyCodeButtonTapped()
            #expect(model.history.decisions["Y"]?.state == .discarded)
            #expect(model.current?.origin == .code)
            #expect(model.current?.design.code == "a74hGF01CVunaG0vzZJG", "The pasted code applies over the base.")
        }

        /// The device holds a proposal's code as the theme file writes it,
        /// so a valid code in another form must not read as the person's edit.
        @Test func `A proposal whose code Tune writes in another form stays trying`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            agentWrites { $0.proposals = [Self.proposal("M", "Mango", code: "b74hGF01CVunaG0vzZJG", apply: true)] }
            await Task.megaYield()
            await Task.megaYield()
            #expect(model.trying?.id == "M", "Tune's own write of the code is not an edit that keeps it.")
            #expect(model.history.decisions["M"]?.state == .tried)
            #expect(model.current?.design.code == "a74hGF01CVunaG0vzZJG")
            #expect(model.tryingLine(try #require(model.trying)).hasSuffix("changes."), "Past three titles the strip counts.")
        }

        @Test func `A proposal that asks to be applied is tried on arrival, card closed, and an edit keeps it`() async throws {
            let stage = Self.stage()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            #expect(!stage.isPresented)
            agentWrites { $0.proposals = [Self.proposal("A", "Teal", tokens: ["accent": .string("teal")], apply: true)] }
            await Task.megaYield()
            let trial = try #require(model.history.trial)
            #expect(model.trying?.id == "A")
            #expect(model.tuning.accent == .teal)
            #expect(model.tryingLine(try #require(model.trying)) == "Trying Teal. Accent.")
            #expect(model.current?.author == .agent)

            model.tuningEdit.fontDesign = .serif
            #expect(model.history.decisions["A"]?.state == .kept, "Building on a proposal keeps it.")
            #expect(model.current?.parent == trial.version, "The edit sits on top of the proposal.")
            #expect(model.stripMessage == "Kept Teal. Your change is on top.")
            await Task.megaYield()
            #expect(model.history.trial == nil, "A kept proposal is never tried again on the next write.")
        }

        @Test func `Undo while trying records discarded, and Redo onto the trial version re-enters Trying`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Rose")
            let base = try #require(model.current)
            agentWrites { $0.proposals = [Self.proposal("A", "Teal", tokens: ["accent": .string("teal")], apply: true)] }
            await Task.megaYield()
            let version = try #require(model.history.trial?.version)

            model.undoButtonTapped()
            #expect(model.history.decisions["A"]?.state == .discarded, "Undo while trying is a Discard.")
            #expect(model.current?.id == base.id)
            #expect(model.tuning.accent == .pink)
            await Task.megaYield()
            #expect(model.history.trial == nil, "A discarded proposal is not tried again by the next write.")

            model.redoButtonTapped()
            #expect(model.current?.id == version)
            #expect(model.trying?.id == "A", "Redo onto the trial version re-enters Trying.")
            #expect(model.tuning.accent == .teal)
            #expect(model.showsStrip)
        }

        @Test func `Keep discards the offered siblings and leaves other notes' proposals offered`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            agentWrites {
                $0.proposals = [
                    Self.proposal("A", "Teal", note: "N1", tokens: ["accent": .string("teal")]),
                    Self.proposal("B", "Mint", minute: 1, note: "N1", tokens: ["accent": .string("mint")]),
                    Self.proposal("C", "Round", minute: 2, note: "N2", tokens: ["cardRadius": .number(30)]),
                ]
            }
            await Task.megaYield()
            model.tryButtonTapped("A")
            model.keepButtonTapped()
            #expect(model.proposal("A")?.state(in: model.history) == .kept)
            #expect(model.proposal("B")?.state(in: model.history) == .discarded, "Keeping one answer to a note turns down the others.")
            #expect(model.proposal("C")?.state(in: model.history) == .offered)
            #expect(model.stripMessage == "Kept Teal.")
            #expect(
                model.changes(try #require(model.proposal("A"))).map(\.words) == ["Accent: indigo to teal"],
                "A kept proposal still says what it changed, though Current is its own version.")
            #expect(model.changes(try #require(model.proposal("C"))).map(\.words) == ["Card radius: 16 to 30 pt"])

            model.discardOfferedTapped("C")
            #expect(model.proposal("C")?.state(in: model.history) == .discarded)
            #expect(model.tuning.accent == .teal, "Discard on an offered row leaves the device as it is.")
        }

        /// Keep answers one note: a proposal that answers none has no
        /// siblings, so keeping it must leave every other proposal to the
        /// person, loose ones and a note's alike.
        @Test func `Keep on a proposal that answers no note turns down no other proposal`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            agentWrites {
                $0.proposals = [
                    Self.proposal("A", "Teal", tokens: ["accent": .string("teal")]),
                    Self.proposal("B", "Mint", minute: 1, tokens: ["accent": .string("mint")]),
                    Self.proposal("C", "Round", minute: 2, note: "N1", tokens: ["cardRadius": .number(30)]),
                ]
            }
            await Task.megaYield()
            model.tryButtonTapped("A")
            model.keepButtonTapped()
            #expect(model.proposal("A")?.state(in: model.history) == .kept)
            #expect(model.proposal("B")?.state(in: model.history) == .offered, "A loose proposal is no sibling of another.")
            #expect(model.proposal("C")?.state(in: model.history) == .offered)
        }

        @Test func `A proposal arriving during a held slider is tried after release on top of the new version`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }

            model.sliderEditingChanged(true)
            model.tuningEdit.cardRadius = 24
            agentWrites { $0.proposals = [Self.proposal("A", "Teal", tokens: ["accent": .string("teal")], apply: true)] }
            await Task.megaYield()
            #expect(model.history.trial == nil, "A held slider is never interrupted by a try.")
            #expect(model.tuning.cardRadius == 24)

            model.sliderEditingChanged(false)
            let trial = try #require(model.history.trial, "The release tries the proposal that waited.")
            let base = try #require(model.history.entry(trial.base))
            #expect(base.author == .you, "The slider's version is the base.")
            #expect(ThemeTuning(presetCode: base.design.code)?.cardRadius == 24)
            #expect(model.tuning.cardRadius == 24, "The delta merges over the new version.")
            #expect(model.tuning.accent == .teal)
        }

        @Test func `Reply sets inReplyTo and the subject`() async throws {
            @Dependency(\.outboxRecord) var record
            let stage = Self.stage()
            let model = TuneModelTests.launched(stage)
            let note = DesignNote(
                id: UUID(), createdAt: Self.now, text: "Taller", item: "button", chain: ["button", "card"],
                screen: "Catalog", tokens: [], knobs: [:], frame: nil, presetCode: "")
            model.$notes.withLock { $0 = [note] }
            stage.selection = ItemSelection(item: "badge", chain: ["badge"])

            model.replyButtonTapped(note: note)
            #expect(model.composerFocused)
            #expect(
                model.composerSubject == "Button, on Catalog",
                "A reply is about its note's subject, not the selection, and says the item is on another screen.")
            model.noteDraft = "Still too short."
            model.sendButtonTapped()
            let reply = try #require(model.notes.last)
            #expect(reply.inReplyTo == note.id.uuidString)
            #expect(reply.item == "button")
            #expect(reply.chain == ["button", "card"])
            #expect(reply.screen == "Catalog")
            #expect(model.replyTarget == nil)
            #expect(model.noteDraft.isEmpty)
            #expect(record.screenshots.value.last == reply.id.uuidString)
            #expect(model.threads.map(\.rows.count) == [2], "The reply threads under its note.")
            #expect(model.replyLine(reply) == "Reply to your note", "A reply says what it follows.")
            #expect(model.replyLine(note) == nil)

            agentWrites { $0.proposals = [Self.proposal("P1", "Teal", note: note.id.uuidString, tokens: ["accent": .string("teal")])] }
            model.replyButtonTapped(proposal: try #require(model.proposal("P1")))
            model.noteDraft = "Teal is too bright."
            model.sendButtonTapped()
            #expect(model.notes.last?.inReplyTo == "P1")
            #expect(model.notes.last?.item == "button", "A reply to a proposal is about its note's subject.")
            #expect(model.replyLine(try #require(model.notes.last)) == "Reply to Teal")
            let first = model.notes[1].id.uuidString
            let second = try #require(model.notes.last).id.uuidString
            #expect(
                model.threads.first?.rows.map(\.id) == [
                    "note.\(note.id.uuidString)", "proposal.P1", "note.\(second)", "note.\(first)",
                ],
                "The note, the proposals that answer it with their replies, then the note's replies.")

            model.replyButtonTapped(note: note)
            model.noteDraft = "A draft"
            model.cancelReplyTapped()
            #expect(model.replyTarget == nil)
            #expect(model.noteDraft == "A draft", "Cancel keeps the draft.")
            #expect(model.composerSubject == "this screen", "The selected badge is not on this screen, so the note is about the screen.")

            model.replyButtonTapped(note: note)
            model.noteButtonTapped()
            #expect(model.replyTarget == nil, "Note writes a new note about the selection, not the reply left open.")
        }

        @Test func `A hand-off answer with files sets Shipped and clears the overrides, and one without files does not`() async throws {
            let stage = Self.stage()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Mango")
            model.knobChanged("button", Self.knob, to: 44)
            let mango = model.tuning.presetCode
            model.handOffButtonTapped()
            let handOff = try #require(model.handOff)
            let id = handOff.id.uuidString
            #expect(handOff.presetCode == mango)
            #expect(model.handOffStatus == .sent(Self.now))
            #expect(model.handOffStatus?.text.hasPrefix("Handed off at") == true)

            agentWrites { $0.read.handoffs[id] = Self.now.addingTimeInterval(60) }
            await Task.megaYield()
            #expect(model.handOffStatus == .read(Self.now.addingTimeInterval(60)))

            agentWrites { $0.answers[id] = .init(reply: "Nothing to change.", date: Self.now) }
            await Task.megaYield()
            #expect(model.history.shipped == nil, "A reply alone is not Shipped.")
            #expect(model.tuning.presetCode == mango)
            #expect(stage.knobs.values == ["button": ["height": 44]])
            #expect(model.handOffStatus == .answered("Nothing to change."))

            agentWrites {
                $0.answers[id] = .init(reply: "Put MANGO into source.", changedFiles: ["RegistryTheme+App.swift"], date: Self.now)
            }
            await Task.megaYield()
            #expect(model.history.shipped?.handoff == handOff.id)
            #expect(model.history.shipped?.design == handOff.design)
            #expect(model.current?.design == DesignHistory.Design(), "Shipped clears to Source.")
            #expect(model.current?.author == .agent)
            #expect(stage.knobs.values.isEmpty, "Tune's knob overrides are cleared so the source shows.")
            #expect(model.liveDesign.code.isEmpty, "Tune's theme overrides are cleared so the source shows.")
            #expect(model.handOffStatus == .shipped(Self.now, files: ["RegistryTheme+App.swift"]))

            model.presetChipTapped("Rose")
            agentWrites { $0.read.notes["N"] = Self.now }
            await Task.megaYield()
            #expect(model.tuning.accent == .pink, "A hand-off ships once; a later write must not wipe the person's edit.")
        }

        /// Shipped means the design is in source. Rose was never handed off,
        /// so an answer to the Mango hand-off must not take Rose off the device.
        @Test func `An answer to a hand-off whose design the device no longer shows records Shipped and keeps Current`() async throws {
            let stage = Self.stage()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Mango")
            model.handOffButtonTapped()
            let handOff = try #require(model.handOff)
            model.presetChipTapped("Rose")
            model.knobChanged("button", Self.knob, to: 44)
            let rose = try #require(model.current)

            agentWrites {
                $0.answers[handOff.id.uuidString] = .init(reply: "MANGO.", changedFiles: ["A.swift"], date: Self.now)
            }
            await Task.megaYield()
            #expect(model.history.shipped?.handoff == handOff.id, "The answer is still Shipped.")
            #expect(model.current?.id == rose.id, "Rose is in no source, so it stays current.")
            #expect(model.tuning.accent == .pink, "Rose stays on the device.")
            #expect(stage.knobs.values == ["button": ["height": 44]])
            #expect(model.handOffStatus == .shipped(Self.now, files: ["A.swift"]))
        }

        @Test func `The previous hand-off still ships, and never after a newer one shipped`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Mango")
            model.handOffButtonTapped()
            let first = try #require(model.handOff)
            model.presetChipTapped("Rose")
            model.handOffButtonTapped()
            let second = try #require(model.handOff)
            #expect(second.previous?.id == first.id)

            agentWrites { $0.answers[first.id.uuidString] = .init(reply: "MANGO.", changedFiles: ["A.swift"], date: Self.now) }
            await Task.megaYield()
            #expect(model.history.shipped?.handoff == first.id)
            #expect(model.history.shipped?.design == first.design)
            #expect(model.tuning.accent == .pink, "The device shows Rose, not the Mango that shipped, so it stays.")
            #expect(
                model.previousHandOffLine?.hasPrefix("The hand-off before, at") == true
                    && model.previousHandOffLine?.contains("Shipped at") == true,
                "The answer to the hand-off before shows under the status: \(model.previousHandOffLine ?? "none")")
            agentWrites { $0.answers[second.id.uuidString] = .init(reply: "Rose.", changedFiles: ["A.swift"], date: Self.now) }
            await Task.megaYield()
            #expect(model.history.shipped?.handoff == second.id)

            model.presetChipTapped("Amber")
            agentWrites { $0.read.notes["N"] = Self.now }
            await Task.megaYield()
            #expect(model.history.shipped?.handoff == second.id, "The older answer must not ship again over the newer one.")
            #expect(model.tuning.accent == .yellow)
        }

        @Test func `New answers and proposals count until Notes is seen, across a relaunch`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let note = DesignNote(
                id: UUID(), createdAt: Self.now, text: "Taller", item: nil, chain: [], screen: nil, tokens: [], knobs: [:],
                frame: nil, presetCode: "")
            model.$notes.withLock { $0 = [note] }
            #expect(model.unseen == 0)
            agentWrites {
                $0.answers[note.id.uuidString] = .init(reply: "Raised it.", date: Self.now)
                $0.proposals = [Self.proposal("A", "Teal", tokens: ["accent": .string("teal")])]
            }
            await Task.megaYield()
            #expect(model.unseen == 2)
            #expect(model.title(.notes) == "Notes (2)")
            #expect(model.status(note) == "Answered")

            model.place = .notes
            #expect(model.unseen == 0)
            #expect(model.title(.notes) == "Notes")
            #expect(TuneModel(stage: DesignSurfaceState()).unseen == 0, "What the person saw stays seen after a relaunch.")

            // A proposal decided from the strip before Notes shows is no news.
            model.place = .tokens
            agentWrites { $0.proposals.append(Self.proposal("B", "Mint", minute: 1, tokens: ["accent": .string("mint")], apply: true)) }
            await Task.megaYield()
            #expect(model.title(.notes) == "Notes (1)")
            model.keepButtonTapped()
            #expect(model.unseen == 0, "Kept from the strip, it no longer counts.")
            #expect(model.title(.notes) == "Notes")
        }

        /// An answer to a hand-off is news from the agent like an answer to a
        /// note, but it shows in Versions: it counts on the button and on the
        /// Versions segment, where it is, until Versions is shown.
        @Test func `A hand-off answer counts as new until Versions is shown`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.place = .tokens
            model.presetChipTapped("Mango")
            model.handOffButtonTapped()
            let handOff = try #require(model.handOff)
            #expect(model.unseen == 0)

            agentWrites {
                $0.answers[handOff.id.uuidString] = .init(
                    reply: "Put MANGO into source.", changedFiles: ["RegistryTheme+App.swift"], date: Self.now)
            }
            await Task.megaYield()
            #expect(model.unseen == 1)
            #expect(model.title(.versions) == "Versions (1)", "The answer counts where it shows.")
            #expect(model.title(.notes) == "Notes", "Notes has nothing new to show.")
            model.place = .notes
            #expect(model.unseen == 1, "Notes does not show the hand-off's answer, so it stays new.")
            model.place = .versions
            #expect(model.unseen == 0)
            #expect(model.title(.versions) == "Versions")

            let relaunched = TuneModel(stage: DesignSurfaceState())
            relaunched.handOff = handOff
            #expect(relaunched.unseen == 0, "What the person saw stays seen after a relaunch.")
        }

        /// VoiceOver announces an answer's first sentence, so a file name in
        /// it must not end the sentence early.
        @Test func `An answer's first sentence keeps a file name whole`() {
            #expect(
                TuneModel.firstSentence(of: "Put MANGO into RegistryTheme+App.swift. Then rebuilt.")
                    == "Put MANGO into RegistryTheme+App.swift.")
            #expect(TuneModel.firstSentence(of: "Raised it") == "Raised it")
        }

        /// The panel never saves the agent's file: Sharing would throttle and
        /// coalesce its own saves over the agent's, and the agent's write
        /// would be lost. A run of every model action must leave its bytes.
        nonisolated static let files = LockIsolated<[URL: Data]>([:])

        @Test(.dependency(\.defaultFileStorage, .inMemory(fileSystem: AgentLoop.files)))
        func `A scripted run of every model action never changes design-agent.json`() async throws {
            let seeded = try SharedFixture.data("design-agent.json")
            Self.files.withValue { $0 = [AgentRecord.fileURL: seeded] }
            let stage = Self.stage()
            stage.report(RegistryItemReport(id: UUID(), name: "button", frame: CGRect(x: 16, y: 200, width: 120, height: 36)))
            stage.stage = CGRect(x: 0, y: 0, width: 393, height: 852)
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            #expect(model.agent.proposals.count == 2, "The seeded file is the one Tune reads.")
            let warm = try #require(model.agent.proposals.first).id
            let mango = try #require(model.agent.proposals.last).id
            #expect(model.trying?.id == warm, "Launch tried the proposal that asks to be applied.")

            model.keepButtonTapped()
            model.tryButtonTapped(mango)
            model.discardButtonTapped()
            model.tryButtonTapped(mango)
            model.stripNameTapped()
            model.discardOfferedTapped(warm)
            model.noteButtonTapped()
            model.noteDraft = "Taller"
            model.sendButtonTapped()
            let note = try #require(model.notes.last)
            model.replyButtonTapped(note: note)
            model.cancelReplyTapped()
            model.replyButtonTapped(proposal: try #require(model.proposal(mango)))
            model.noteDraft = "Shorter"
            model.sendButtonTapped()
            model.subjectTapped(note)
            model.notesSeen()
            model.deleteNote(note.id)
            model.undoButtonTapped()
            model.redoButtonTapped()
            model.restore(try #require(model.history.entries.first?.id))
            model.versionName = "Launch"
            model.nameSubmitted()
            model.checksLineTapped()
            model.openNotesLineTapped()
            model.versionsSeen()
            model.handOffButtonTapped()
            model.presetChipTapped("Mango")
            model.defaultButtonTapped()
            model.sourceButtonTapped()
            model.codeDraft = "--preset a74hGF01CVunaG0vzZJG"
            model.applyCodeButtonTapped()
            model.codeDraft = "nope"
            model.applyCodeButtonTapped()
            model.knobChanged("button", Self.knob, to: 50)
            model.resetKnobsButtonTapped("button")
            model.sliderEditingChanged(true)
            model.tuningEdit.cardRadius = 22
            model.sliderEditingChanged(false)
            model.colorEdit.customAccentColor = .orange
            await model.colorSettle?.value
            model.appearance = .dark
            model.textSize = .accessibility
            model.direction = .rightToLeft
            model.showsOutlines = true
            model.showsGuides = true
            model.selectButtonTapped()
            model.selectButtonTapped()
            model.selectButtonTapped()
            model.selectingTapped(["button"])
            model.selectButtonTapped()
            model.cancelSelectingTapped()
            model.itemMenuSelected("button")
            model.containerTapped()
            model.notesAboutTapped()
            model.clearSelectionTapped()
            let radius = try #require(TokenCatalog.theme.first { $0.key == "cardRadius" })
            let background = try #require(TokenCatalog.theme.first { $0.key == "background" })
            model.tokenHeld(radius, true)
            model.tuningEdit.cardRadius = 18
            model.tokenHeld(radius, false)
            model.resetTokenTapped(radius)
            model.useLightValueTapped(background)
            model.fixLabelTapped()
            model.askAgentTapped(try #require(ContrastAudit(model.tuning).pairs.first))
            model.place = .versions
            model.place = .tokens
            model.screenChanged()
            model.keyboardHid()
            model.cardClosed()
            await model.contextCapture?.value
            await Task.megaYield()

            #expect(Self.files.value[AgentRecord.fileURL] == seeded, "Tune wrote the agent's file.")
        }
    }
}
