#if canImport(UIKit)
import Foundation
import SwiftUI

/// Tokens: Start from, the tokens, item knobs, the selection, and Preview.
extension TuneModel {
    // MARK: Start from

    /// Applies a preset's accent (Mango's whole theme) as a new version.
    func presetChipTapped(_ name: String) {
        flush()
        var tuned = tuning
        tuned.apply(presetNamed: name)
        write(tuned)
        recordApplied(.preset(name: name))
    }

    /// Applies Default, the values Changes compare against; knobs stay.
    func defaultButtonTapped() {
        flush()
        if let tuned = ThemeTuning(presetCode: ThemeTuning.default.presetCode, base: tuning) { write(tuned) }
        recordApplied(.defaultTheme)
    }

    /// Clears every token and knob override, so the app's own theme shows.
    func sourceButtonTapped() {
        flush()
        apply(Design())
        record(Design(), author: .you, origin: .source)
    }

    /// Applies a pasted code or `RegistryTheme(...)` initializer; a text Tune
    /// cannot read changes nothing and says so, and a blank one does nothing.
    func applyCodeButtonTapped() {
        guard !codeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let parsed = ThemeTuning.parse(codeDraft, into: tuning) else {
            codeError = Self.codeError
            return
        }
        flush()
        write(parsed)
        codeDraft = ""
        codeError = nil
        recordApplied(.code)
    }

    /// Records what Start from applied, its theme as a code even when it is
    /// the default one, so Default under Source is a version of its own.
    private func recordApplied(_ origin: DesignHistory.Origin) {
        record(Design(code: tuning.presetCode, knobs: stage.knobs.values), author: .you, origin: origin)
    }

    // MARK: Knobs

    func knobValue(_ item: String, _ knob: ItemKnob) -> Double {
        stage.knobs.value(item, knob)
    }

    /// Sets a knob: a switch or a choice records a version at once, a slider
    /// on its release.
    func knobChanged(_ item: String, _ knob: ItemKnob, to value: Double) {
        stage.knobs.set(item, knob, to: value)
        if !isHoldingSlider { settle() }
    }

    func resetKnobsButtonTapped(_ item: String) {
        stage.knobs.reset(item)
        settle()
    }

    // MARK: Tokens

    /// The tokens Tokens shows: every one, or those that reach the selection.
    var scopedTokens: [TokenCatalog.Token] {
        stage.selection.item.map(TokenCatalog.reaching) ?? TokenCatalog.theme
    }

    /// How many items on this screen the token reaches.
    func reach(_ token: TokenCatalog.Token) -> Int {
        stage.visibleItemNames.filter { TokenCatalog.reaches(token, $0.name) }.count
    }

    /// A token's slider went down or came up; while it is held the items it
    /// reaches are outlined, and its steps wait for the release.
    func tokenHeld(_ token: TokenCatalog.Token, _ editing: Bool) {
        sliderEditingChanged(editing)
        if editing {
            stage.reachOutlines = Set(stage.visibleItemNames.map(\.name).filter { TokenCatalog.reaches(token, $0) })
        }
    }

    /// Puts a token back to Default as one version.
    func resetTokenTapped(_ token: TokenCatalog.Token) {
        flush()
        var tuned = tuning
        token.reset(&tuned)
        tuningEdit = tuned
    }

    /// Clears a color's Dark value, so dark shows the Light one, as one version.
    func useLightValueTapped(_ token: TokenCatalog.Token) {
        flush()
        var tuned = tuning
        token.useLightValue(&tuned)
        tuningEdit = tuned
    }

    /// Switches the label on the accent to the one that measures better.
    func fixLabelTapped() {
        flush()
        guard let dark = ContrastAudit.betterLabel(for: tuning) else { return }
        tuningEdit.darkLabelOnAccent = dark
    }

    /// Goes to Notes with the check's pair and ratios drafted for the agent,
    /// on a new line under a draft the person was writing.
    func askAgentTapped(_ pair: ContrastAudit.Pair) {
        let ask = "\(pair.title) \(pair.verdictWord.lowercased()): \(pair.ratios). "
            + "Text needs \(ContrastAudit.minimum.formatted()):1 in light and dark. Find colors that pass."
        noteDraft = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ask : noteDraft + "\n" + ask
        replyTarget = nil
        place = .notes
        composerFocused = true
    }

    /// What Tokens' rows do: each records one version.
    var tokenActions: TokenActions {
        TokenActions(
            hold: tokenHeld, reset: resetTokenTapped, useLightValue: useLightValueTapped, fixLabel: fixLabelTapped,
            ask: askAgentTapped, reach: reach, isSource: liveDesign.code.isEmpty)
    }

    // MARK: Selection

    /// Arms the next tap on the app to select the item under it, or disarms it.
    func selectButtonTapped() {
        flush()
        stage.selection.isSelecting.toggle()
        if !stage.selection.isSelecting { composesAfterSelecting = false }
    }

    /// The tap while Selecting: the innermost item under it and its chain.
    /// A tap on nothing keeps the selection.
    func selectingTapped(_ chain: [String]) {
        if !chain.isEmpty { select(chain) }
        endSelecting()
    }

    /// Back to the place the card left, the selection unchanged.
    func cancelSelectingTapped() {
        endSelecting()
    }

    /// Ends Selecting; when Note armed it, the composer takes the focus.
    private func endSelecting() {
        stage.selection.isSelecting = false
        guard composesAfterSelecting else { return }
        composesAfterSelecting = false
        place = .notes
        composerFocused = true
    }

    /// Selects an item and the items around it, innermost first. Tokens shows
    /// it and pushes its host page, unless the card is on Notes, where it is
    /// the composer's subject and a page would cover the composer.
    func select(_ chain: [String]) {
        stage.selection.item = chain.first
        stage.selection.chain = chain
        hostPageItem = stage.hostPage.flatMap { page in chain.first { page($0) != nil } }
        hostPageToPush = place == .notes ? nil : hostPageItem
        if place != .notes { place = .tokens }
    }

    /// An item from the item menu: a container in the selection's chain, or
    /// an item on this screen with the items around its first instance.
    func itemMenuSelected(_ name: String) {
        if let index = stage.selection.chain.firstIndex(of: name) {
            select(Array(stage.selection.chain[index...]))
            return
        }
        var chain = [name]
        for ancestor in stage.visibleItems.first(where: { $0.name == name })?.ancestors.reversed() ?? []
        where !chain.contains(ancestor) {
            chain.append(ancestor)
        }
        select(chain)
    }

    func clearSelectionTapped() {
        stage.selection = ItemSelection()
        hostPageItem = nil
        hostPageToPush = nil
    }

    /// Inside: the container around the selection, selected.
    func containerTapped() {
        guard stage.selection.chain.count > 1 else { return }
        select(Array(stage.selection.chain.dropFirst()))
    }

    /// Notes, scrolled to the newest note about the selection.
    func notesAboutTapped() {
        guard let item = stage.selection.item, let note = notes.last(where: { $0.item == item }) else { return }
        place = .notes
        scrollTarget = Row.note(note).id
    }

    /// The item menu's label: the selection and its container, the screen and
    /// how many items are on it, or a selection that is not on this screen.
    var itemMenuTitle: String {
        if let item = stage.selection.item {
            let title = stage.title(item)
            guard isOnScreen(item) else { return "\(title) is not on this screen" }
            guard stage.selection.chain.count > 1 else { return title }
            return "\(title) in \(stage.title(stage.selection.chain[1]))"
        }
        let count = stage.visibleItemNames.count
        let screen = stage.screen ?? "This screen"
        return count == 0 ? "\(screen) · no items" : "\(screen) · \(count) \(count == 1 ? "item" : "items")"
    }

    func isOnScreen(_ item: String) -> Bool {
        stage.visibleItemNames.contains { $0.name == item }
    }

    /// The Item section: what the selection is, where it sits, and what is
    /// said about it.
    struct ItemDetails: Equatable {
        var name: String
        var title: String
        /// The first instance's frame on screen; `nil` when it is not on it.
        var frame: CGRect?
        var instances: Int
        /// The item around it, by name.
        var container: String?
        var notes: Int
    }

    var selectedItem: ItemDetails? {
        guard let name = stage.selection.item else { return nil }
        let instances = stage.visibleItems.filter { $0.name == name }
        return ItemDetails(
            name: name, title: stage.title(name), frame: instances.first?.frame, instances: instances.count,
            container: stage.selection.chain.dropFirst().first, notes: notes.filter { $0.item == name }.count)
    }

    // MARK: Preview

    var appearance: ThemeTuning.Appearance {
        get { tuning.appearance }
        set { previewChanged { $0.appearance = newValue } }
    }

    var textSize: ThemeTuning.TextSize {
        get { tuning.textSize }
        set { previewChanged { $0.textSize = newValue } }
    }

    var direction: ThemeTuning.Direction {
        get { tuning.direction }
        set { previewChanged { $0.direction = newValue } }
    }

    var showsOutlines: Bool {
        get { stage.showsOutlines }
        set { stage.showsOutlines = newValue }
    }

    /// The 8 pt grid, the 24 pt lines, and the margins together.
    var showsGuides: Bool {
        get { !stage.guides.isEmpty }
        set { stage.guides = newValue ? [.grid, .lines, .margins] : [] }
    }

    /// Preview's active overrides in short words, "Dark · AX3 · RTL"; empty
    /// when none is set.
    var previewOverrides: [String] {
        var words: [String] = []
        if tuning.appearance != .system { words.append(tuning.appearance.title) }
        switch tuning.textSize {
        case .system: break
        case .large: words.append("XXXL")
        case .accessibility: words.append("AX3")
        }
        switch tuning.direction {
        case .system: break
        case .leftToRight: words.append("LTR")
        case .rightToLeft: words.append("RTL")
        }
        if stage.showsOutlines { words.append("Outlines") }
        if !stage.guides.isEmpty { words.append("Guides") }
        return words
    }

    /// Preview is never part of a version; the context names it, so it is
    /// written again.
    private func previewChanged(_ change: (inout ThemeTuning) -> Void) {
        $tuning.withLock(change)
        refreshContext()
    }
}
#endif
