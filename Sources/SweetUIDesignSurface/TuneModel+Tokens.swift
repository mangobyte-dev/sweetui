#if canImport(UIKit)
import Foundation
import SwiftUI

/// Tokens: Start from, item knobs, the selection, and Preview.
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
    /// cannot read changes nothing and says so.
    func applyCodeButtonTapped() {
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

    // MARK: Selection

    /// Arms the next tap on the app to select the item under it, or disarms it.
    func selectButtonTapped() {
        flush()
        stage.selection.isSelecting.toggle()
    }

    /// An item from the item menu: selected, and Tokens shows it unless the
    /// card is on Notes, where it becomes the composer's subject.
    func itemMenuSelected(_ name: String) {
        stage.selection = ItemSelection(item: name, chain: [name])
        if place != .notes { place = .tokens }
    }

    func clearSelectionTapped() {
        stage.selection = ItemSelection()
    }

    /// The item menu's label: the selection and its container, or the screen
    /// and how many items are on it.
    var itemMenuTitle: String {
        if let item = stage.selection.item {
            let title = stage.title(item)
            guard stage.selection.chain.count > 1 else { return title }
            return "\(title) in \(stage.title(stage.selection.chain[1]))"
        }
        let count = stage.visibleItemNames.count
        let screen = stage.screen ?? "This screen"
        return count == 0 ? "\(screen) · no items" : "\(screen) · \(count) \(count == 1 ? "item" : "items")"
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
