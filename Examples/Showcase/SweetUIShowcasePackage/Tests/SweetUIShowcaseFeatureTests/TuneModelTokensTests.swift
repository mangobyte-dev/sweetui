import Dependencies
import DependenciesTestSupport
import Foundation
import Sharing
import SwiftUI
import SweetUIFoundations
import Testing
@testable import SweetUIDesignSurface

/// Selecting is how a person asks "what is this", and a token row is how they
/// change it: the place a pick lands on must follow where Select came from,
/// a stray tap must not throw the selection away, and each row action must
/// be exactly one version, so Undo takes back what the person did.
extension TuneModelTests {
    /// A screen with a card inside a dashboard and a button below them.
    @MainActor
    static func screen() -> DesignSurfaceState {
        let stage = DesignSurfaceState()
        stage.stage = CGRect(x: 0, y: 0, width: 393, height: 852)
        stage.screenAppeared("Components")
        stage.report(RegistryItemReport(id: UUID(), name: "dashboard", frame: CGRect(x: 0, y: 100, width: 393, height: 400)))
        stage.report(RegistryItemReport(
            id: UUID(), name: "card", frame: CGRect(x: 16, y: 120, width: 180, height: 120), ancestors: ["dashboard"]))
        stage.report(RegistryItemReport(id: UUID(), name: "button", frame: CGRect(x: 16, y: 600, width: 120, height: 44)))
        return stage
    }

    static func token(_ key: String) throws -> TokenCatalog.Token {
        try #require(TokenCatalog.theme.first { $0.key == key })
    }

    @MainActor
    @Suite struct Selecting {
        @Test func `A pick from Tokens or Versions shows Tokens with the Item section and only the reaching tokens`() throws {
            let model = TuneModelTests.launched(TuneModelTests.screen())
            #expect(model.selectedItem == nil)
            #expect(model.scopedTokens.count == TokenCatalog.theme.count, "Nothing selected shows every token.")

            model.place = .versions
            model.selectButtonTapped()
            #expect(model.stage.selection.isSelecting)
            model.selectingTapped(["card", "dashboard"])

            #expect(!model.stage.selection.isSelecting)
            #expect(model.place == .tokens)
            let item = try #require(model.selectedItem)
            #expect(item.name == "card")
            #expect(item.container == "dashboard")
            #expect(item.instances == 1)
            #expect(item.frame == CGRect(x: 16, y: 120, width: 180, height: 120))
            let keys = model.scopedTokens.map(\.key)
            #expect(keys == TokenCatalog.reaching("card").map(\.key))
            #expect(!keys.contains("compactSpacing"), "A token the card does not read stays out.")

            model.selectButtonTapped()
            model.selectingTapped(["button"])
            #expect(model.place == .tokens, "From Tokens a pick stays on Tokens.")
            #expect(model.selectedItem?.name == "button")
        }

        @Test func `A pick from Notes stays on Notes and becomes the composer's subject`() {
            let model = TuneModelTests.launched(TuneModelTests.screen())
            model.place = .notes
            model.selectButtonTapped()
            model.selectingTapped(["button"])

            #expect(model.place == .notes)
            #expect(model.stage.selection.item == "button")
            #expect(model.composerSubject == "button")
            #expect(!model.composerFocused, "A pick from Notes does not focus the composer; Note does.")
        }

        @Test func `A host page is pushed from Tokens and never over the composer on Notes`() {
            let stage = TuneModelTests.screen()
            stage.hostPage = { $0 == "dashboard" ? AnyView(Text(verbatim: "Dashboard")) : nil }
            let model = TuneModelTests.launched(stage)

            model.place = .notes
            model.selectButtonTapped()
            model.selectingTapped(["card", "dashboard"])
            #expect(model.hostPageToPush == nil, "The pushed page has no composer, so Notes would lose it.")
            #expect(model.hostPageItem == "dashboard", "Tokens still links the page.")

            model.clearSelectionTapped()
            model.noteButtonTapped()
            model.selectingTapped(["card", "dashboard"])
            #expect(model.hostPageToPush == nil, "Note's pick returns to the composer, not to a page.")
            #expect(model.composerFocused)

            model.place = .versions
            model.selectButtonTapped()
            model.selectingTapped(["card", "dashboard"])
            #expect(model.place == .tokens)
            #expect(model.hostPageToPush == "dashboard", "The innermost item with a page is pushed.")
        }

        @Test func `A tap on nothing or Cancel keeps the selection`() {
            let model = TuneModelTests.launched(TuneModelTests.screen())
            model.itemMenuSelected("card")
            model.place = .versions

            model.selectButtonTapped()
            model.selectingTapped([])
            #expect(model.stage.selection.item == "card")
            #expect(model.stage.selection.chain == ["card", "dashboard"])
            #expect(!model.stage.selection.isSelecting)
            #expect(model.place == .versions, "Nothing picked, so the card returns where it left.")

            model.selectButtonTapped()
            model.cancelSelectingTapped()
            #expect(model.stage.selection.item == "card")
            #expect(!model.stage.selection.isSelecting)
        }

        @Test func `Note with nothing selected arms Selecting and returns to the focused composer`() {
            let model = TuneModelTests.launched(TuneModelTests.screen())
            model.noteButtonTapped()
            #expect(model.place == .notes)
            #expect(model.stage.selection.isSelecting)
            #expect(!model.composerFocused, "The composer waits for the pick.")

            model.selectingTapped(["card", "dashboard"])
            #expect(!model.stage.selection.isSelecting)
            #expect(model.place == .notes)
            #expect(model.composerFocused)
            #expect(model.composerSubject == "card")

            // With an item selected, Note focuses the composer at once.
            model.composerFocused = false
            model.place = .tokens
            model.noteButtonTapped()
            #expect(!model.stage.selection.isSelecting)
            #expect(model.composerFocused)
        }

        @Test func `The item menu selects an item with its containers, a container from the chain, and says when it is off screen`() throws {
            let stage = TuneModelTests.screen()
            let model = TuneModelTests.launched(stage)
            #expect(model.itemMenuTitle == "Components · 3 items")

            model.itemMenuSelected("card")
            #expect(stage.selection.chain == ["card", "dashboard"])
            #expect(model.itemMenuTitle == "card in dashboard")

            model.itemMenuSelected("dashboard")
            #expect(stage.selection.chain == ["dashboard"], "A container from the chain is selected alone.")

            model.itemMenuSelected("card")
            model.containerTapped()
            #expect(stage.selection.item == "dashboard")

            model.itemMenuSelected("button")
            let button = try #require(stage.frames.first { $0.value.name == "button" }?.key)
            stage.forget(button)
            #expect(model.itemMenuTitle == "button is not on this screen")
            #expect(model.composerSubject == "Components", "The composer falls back to the screen.")

            model.clearSelectionTapped()
            #expect(model.selectedItem == nil)
        }

        @Test func `A held token outlines only the items it reaches and counts them`() throws {
            let model = TuneModelTests.launched(TuneModelTests.screen())
            let radius = try TuneModelTests.token("cardRadius")
            #expect(model.reach(radius) == 2, "The card and the dashboard read the card radius; the button does not.")

            model.tokenHeld(radius, true)
            #expect(model.stage.reachOutlines == ["card", "dashboard"])
            model.tokenHeld(radius, false)
            #expect(model.stage.reachOutlines == nil)
        }
    }

    @MainActor
    @Suite struct TokenRows {
        @Test func `Reset token records one version and touches its token alone`() async throws {
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.tuningEdit.fontDesign = .rounded
            model.tuningEdit.cardRadius = 24
            await Task.megaYield()
            let before = model.history.entries.count

            model.resetTokenTapped(try TuneModelTests.token("cardRadius"))
            await Task.megaYield()
            #expect(model.history.entries.count == before + 1)
            #expect(model.current?.author == .you)
            #expect(model.tuning.cardRadius == ThemeTuning.default.cardRadius)
            #expect(model.tuning.fontDesign == .rounded)
        }

        @Test func `Use the Light value clears only the Dark value as one version`() async throws {
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let light = ThemeTuning.RGB(red: 1, green: 0.9, blue: 0.8)
            var tuned = model.tuning
            tuned.background = light
            tuned.backgroundDark = .init(red: 0.1, green: 0.1, blue: 0.1)
            tuned.foregroundDark = .init(red: 0.9, green: 0.9, blue: 0.9)
            tuned.foreground = .init(red: 0, green: 0, blue: 0)
            model.tuningEdit = tuned
            await Task.megaYield()
            let before = model.history.entries.count

            model.useLightValueTapped(try TuneModelTests.token("background"))
            await Task.megaYield()
            #expect(model.history.entries.count == before + 1)
            #expect(model.tuning.background == light)
            #expect(model.tuning.backgroundDark == nil)
            #expect(model.tuning.foregroundDark != nil, "Another token's Dark value stays.")
        }

        @Test func `Fix label switches the label as one version`() async {
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.tuningEdit.accent = .yellow
            await Task.megaYield()
            #expect(ContrastAudit.betterLabel(for: model.tuning) == true)
            let before = model.history.entries.count

            model.fixLabelTapped()
            await Task.megaYield()
            #expect(model.history.entries.count == before + 1)
            #expect(model.tuning.darkLabelOnAccent)
            #expect(ContrastAudit.betterLabel(for: model.tuning) == nil, "Nothing better is left to offer.")
        }

        @Test func `Ask the agent drafts the pair and its ratios and moves to Notes`() throws {
            let model = TuneModelTests.launched()
            let pair = try #require(ContrastAudit(model.tuning).pair(.labelOnAccent))
            #expect(pair.verdict == .fails, "The default's white label fails in dark.")
            let before = model.history.entries.count

            model.askAgentTapped(pair)
            #expect(model.place == .notes)
            #expect(model.composerFocused)
            #expect(model.noteDraft.hasPrefix("Label on accent fails: \(pair.ratios)."))
            #expect(model.history.entries.count == before, "Asking changes no token.")
        }

        @Test func `Ask the agent keeps the draft the person was writing`() throws {
            let model = TuneModelTests.launched()
            let pair = try #require(ContrastAudit(model.tuning).pair(.labelOnAccent))
            model.noteDraft = "The badge looks cramped."

            model.askAgentTapped(pair)
            #expect(model.noteDraft.hasPrefix("The badge looks cramped.\nLabel on accent fails: \(pair.ratios)."))
        }
    }
}
