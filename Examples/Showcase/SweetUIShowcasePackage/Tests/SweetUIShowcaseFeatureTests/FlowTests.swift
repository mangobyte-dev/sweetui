import Dependencies
import DependenciesTestSupport
import Foundation
import SweetUIFoundations
import Testing
@testable import SweetUIDesignSurface

extension TuneModelTests {
    /// The tap targets per job (`docs/design-surface.md`, Flows and targets).
    /// Each flow is driven through the intents the card's controls call, one
    /// count per tap, from the card opening to the job done, and each must
    /// reach its goal in exactly that many: a flow that needs another tap, or
    /// a tap that no longer gets there, fails. A menu that only opens is a
    /// tap of the view's own, with no model call. Typing and dragging are
    /// not taps.
    @MainActor
    @Suite struct Flows {
        static let now = Date(timeIntervalSince1970: 1_800_000_000)
        static let padding = ItemKnob("padding", in: 8...32, shipped: 16)

        /// The person's taps in one flow.
        @MainActor
        final class Taps {
            private(set) var count = 0

            /// A control that calls the model.
            func tap(_ intent: () -> Void) {
                count += 1
                intent()
            }

            /// A menu opening, which the view handles alone.
            func openMenu() {
                count += 1
            }
        }

        /// A card inside a dashboard on the Components screen, as the
        /// Showcase shows them, with a knob on the card.
        static func stage() -> DesignSurfaceState {
            let stage = DesignSurfaceState()
            stage.stage = CGRect(x: 0, y: 0, width: 393, height: 852)
            stage.screenAppeared("Components")
            stage.report(RegistryItemReport(id: UUID(), name: "dashboard", frame: CGRect(x: 0, y: 96, width: 393, height: 420)))
            stage.report(RegistryItemReport(
                id: UUID(), name: "card", frame: CGRect(x: 16, y: 120, width: 361, height: 132), ancestors: ["dashboard"]))
            stage.knobs.register(["card": [padding]])
            return stage
        }

        /// What the capture layer resolves a tap on the card to.
        static func tapOnCard(_ stage: DesignSurfaceState) -> [String] {
            ItemSelection.chain(reports: Array(stage.frames.values), at: CGPoint(x: 40, y: 150))
        }

        @Test func `J1: Color's tokens are there at 0 taps, any other group's at 1, and each edit is one version`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            #expect(model.place == .tokens, "The first open shows Tokens.")
            #expect(model.openGroups == [.color], "Color is open; the other groups are collapsed headers.")

            // Color: the swatch is on screen, so the edit is the first tap.
            let before = model.history.entries.count
            model.tuningEdit.accent = .teal
            #expect(model.history.entries.count == before + 1)

            // Shape: its header, then a drag on Card radius.
            let taps = Taps()
            taps.tap { model.openGroups.insert(.shape) }
            #expect(taps.count == 1)
            #expect(model.openGroups.contains(.shape))
            let radius = try #require(TokenCatalog.theme.first { $0.key == "cardRadius" })
            #expect(radius.group == .shape)
            model.tokenHeld(radius, true)
            for value in [18.0, 20, 22] { model.tuningEdit.cardRadius = value }
            model.tokenHeld(radius, false)
            await Task.megaYield()
            #expect(model.history.entries.count == before + 2, "The drag is one version.")
            #expect(model.tuning.cardRadius == 22)
        }

        @Test func `J2: Select and a tap on the item show its section, knobs, and only its tokens in 2 taps`() throws {
            let stage = Self.stage()
            let model = TuneModelTests.launched(stage)
            let taps = Taps()
            taps.tap { model.selectButtonTapped() }
            #expect(stage.selection.isSelecting)
            taps.tap { model.selectingTapped(Self.tapOnCard(stage)) }

            #expect(taps.count == 2)
            #expect(model.place == .tokens)
            let item = try #require(model.selectedItem)
            #expect(item.name == "card", "The innermost item under the tap wins.")
            #expect(item.container == "dashboard")
            #expect(stage.knobs.knobs(for: "card") == [Self.padding], "Its knobs show under the Item section.")
            #expect(model.scopedTokens.map(\.key) == TokenCatalog.reaching("card").map(\.key))
            #expect(model.scopedTokens.count < TokenCatalog.theme.count, "Only the tokens that reach it.")

            // The item menu is 2 taps as well: open it, choose the item.
            model.clearSelectionTapped()
            let byMenu = Taps()
            byMenu.openMenu()
            byMenu.tap { model.itemMenuSelected("card") }
            #expect(byMenu.count == 2)
            #expect(model.selectedItem?.name == "card")
            #expect(model.selectedItem?.container == "dashboard", "The menu selects the chain around it too.")
        }

        @Test func `J3: Note, the item, Send, and Keep direct the agent in 4 taps`() async throws {
            let stage = Self.stage()
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let taps = Taps()

            taps.tap { model.noteButtonTapped() }
            #expect(stage.selection.isSelecting, "With nothing selected, Note arms Selecting.")
            taps.tap { model.selectingTapped(Self.tapOnCard(stage)) }
            #expect(model.place == .notes)
            #expect(model.composerFocused, "The tap returns to the focused composer.")
            #expect(model.composerSubject == "card")
            model.noteDraft = "The card sits flat on the background."
            taps.tap { model.sendButtonTapped() }
            let note = try #require(model.notes.last)
            #expect(note.item == "card")
            #expect(model.status(note) == "Not read yet")

            // The agent lists the note and proposes a design that asks to be applied.
            agentWrites {
                $0.read.notes[note.id.uuidString] = Self.now
                $0.proposals = [
                    Proposal(
                        id: "warm", date: Self.now, name: "Warm", note: note.id.uuidString,
                        tokens: ["cardRadius": .number(20)], apply: true),
                ]
            }
            await Task.megaYield()
            #expect(model.status(note) == "Read")
            #expect(model.trying?.id == "warm", "The strip shows with no tap.")
            #expect(model.showsStrip)

            taps.tap { model.keepButtonTapped() }
            #expect(taps.count == 4)
            #expect(model.proposal("warm")?.state(in: model.history) == .kept)
            #expect(model.stripMessage == "Kept Warm.")
            #expect(model.tuning.cardRadius == 20)
        }

        @Test func `J4: the Checks at 0 taps, Fix label at 1, and Dark, a text size, and a direction at 2 each`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            // A design to check: white on green fails in both appearances.
            model.tuningEdit.accent = .green
            let taps = Taps()

            #expect(model.place == .tokens && model.openGroups.contains(.color), "The Checks lead the open Color group.")
            #expect(!model.tokenActions.isSource, "Tune measures a design it sets.")
            #expect(ContrastAudit(model.tuning).pair(.labelOnAccent)?.verdict == .fails)
            #expect(ContrastAudit.betterLabel(for: model.tuning) != nil, "Fix label is offered.")

            taps.tap { model.fixLabelTapped() }
            #expect(ContrastAudit(model.tuning).pair(.labelOnAccent)?.verdict == .passes)
            let versions = model.history.entries.count

            taps.openMenu()
            taps.tap { model.appearance = .dark }
            taps.openMenu()
            taps.tap { model.textSize = .accessibility }
            taps.openMenu()
            taps.tap { model.direction = .rightToLeft }
            await Task.megaYield()

            #expect(taps.count == 7)
            #expect(model.previewOverrides == ["Dark", "AX3", "RTL"])
            #expect(model.history.entries.count == versions, "Preview is never a version.")
        }

        @Test func `J5: Versions and Hand off ship in 2 taps, and Shipped lands with 0 more`() async throws {
            let model = TuneModel(stage: Self.stage())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            // A design to ship.
            model.presetChipTapped("Mango")
            let taps = Taps()

            taps.tap { model.place = .versions }
            taps.tap { model.handOffButtonTapped() }
            #expect(taps.count == 2)
            let handOff = try #require(model.handOff)
            #expect(model.handOffStatus == .sent(handOff.sentAt))

            // The agent reads the hand-off, puts the design into source, and answers.
            agentWrites { $0.read.handoffs[handOff.id.uuidString] = Self.now }
            await Task.megaYield()
            #expect(model.handOffStatus == .read(Self.now))
            agentWrites {
                $0.answers[handOff.id.uuidString] = .init(
                    reply: "Put MANGO into source.", changedFiles: ["RegistryTheme+App.swift"], date: Self.now)
            }
            await Task.megaYield()

            #expect(model.handOffStatus == .shipped(Self.now, files: ["RegistryTheme+App.swift"]))
            #expect(model.place == .versions, "Shipped shows where the person already is.")
            #expect(model.liveDesign == DesignHistory.Design(), "Tune clears its overrides, so the source shows.")
            #expect(model.label(try #require(model.current)) == "Shipped")
        }
    }
}
