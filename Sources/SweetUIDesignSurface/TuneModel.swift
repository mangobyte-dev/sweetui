#if canImport(UIKit)
import Combine
import Dependencies
import Foundation
import Sharing
import SweetUIFoundations

/// Tune's one model: the design on the device, the place the card shows,
/// and one intent method per affordance. Each settled gesture records one
/// version, and the call site names its author: release for a slider or a
/// stepper, at once for a menu or a switch, 0.6 s after the last change for
/// a color; a place change, Select, and a collapse settle a held edit first.
/// A change from outside Tune's controls (the host's own strip, the agent's
/// writes) records one version by whoever the agent's last record names.
@MainActor
@Observable
final class TuneModel {
    typealias Place = DesignSurface.Place
    typealias Design = DesignHistory.Design

    /// Where the last place is remembered between launches.
    static let placeStorageKey = "designSurface.place"
    static let codeError = "That is not a code Tune can read. Copy one from sweetui.dev/create."

    let stage: DesignSurfaceState

    /// The text under Start from's Paste a code, and why it did not apply.
    var codeDraft = ""
    var codeError: String?
    /// The composer's text and focus.
    var noteDraft = ""
    var composerFocused = false
    /// The name typed for Current.
    var versionName = ""
    var handOffSentAt: Date?

    @ObservationIgnored @Shared(.designTokens) var tuning
    @ObservationIgnored @Shared(.designHistory) var history
    @ObservationIgnored @Shared(.designNotes) var notes
    @ObservationIgnored @Shared(.designVariants) var variants
    @ObservationIgnored @Shared(.agentChange) var agentChange
    /// The host's defaults, where the last place is remembered.
    @ObservationIgnored @Dependency(\.defaultAppStorage) private var defaults
    @ObservationIgnored @Dependency(\.continuousClock) private var clock
    @ObservationIgnored @Dependency(\.date.now) var now
    @ObservationIgnored @Dependency(\.uuid) var uuid
    @ObservationIgnored @Dependency(\.designOutbox) var outbox

    /// A slider or a stepper is down: its steps wait for the release.
    @ObservationIgnored private(set) var isHoldingSlider = false
    /// The pending settle of the last color change, and the screenshot pass
    /// of the last context write, kept so a test can await them.
    @ObservationIgnored private(set) var colorSettle: Task<Void, Never>?
    @ObservationIgnored private(set) var contextCapture: Task<Void, Never>?
    @ObservationIgnored private var contextScreenshot: (path: String, code: String)?
    private var shownPlace = Place.tokens

    init(stage: DesignSurfaceState) {
        self.stage = stage
        shownPlace = defaults.string(forKey: Self.placeStorageKey).flatMap(Place.init(rawValue:)) ?? .tokens
    }

    // MARK: Places

    /// The place the card shows; a held edit settles before it changes.
    var place: Place {
        get { shownPlace }
        set {
            guard newValue != shownPlace else { return }
            flush()
            shownPlace = newValue
            defaults.set(newValue.rawValue, forKey: Self.placeStorageKey)
        }
    }

    /// Start from applies themes, so a host that paints the items from its
    /// own tokens has none.
    var showsStartFrom: Bool { stage.tunesTheme }

    // MARK: The design

    var current: DesignHistory.Entry? { history.entry(history.current) }

    /// The design the value files hold now.
    var liveDesign: Design { history.design(code: tuning.presetCode, knobs: stage.knobs.values) }

    /// The tuning a control edits: a change records a version at once, or on
    /// the release while a slider or a stepper is held.
    var tuningEdit: ThemeTuning {
        get { tuning }
        set {
            write(newValue)
            if !isHoldingSlider { settle() }
        }
    }

    /// The tuning a color picker edits: the version settles 0.6 s after the
    /// last change, so a drag across the wheel is one version.
    var colorEdit: ThemeTuning {
        get { tuning }
        set {
            write(newValue)
            colorSettle?.cancel()
            colorSettle = Task { [weak self, clock] in
                do { try await clock.sleep(for: .seconds(0.6)) } catch { return }
                self?.settle()
            }
        }
    }

    /// A slider's or a stepper's touch went down or came up.
    func sliderEditingChanged(_ editing: Bool) {
        isHoldingSlider = editing
        if !editing { settle() }
    }

    /// Records the live design as one version by you when it moved.
    func settle() {
        colorSettle?.cancel()
        colorSettle = nil
        record(liveDesign, author: .you, origin: .edit)
    }

    /// Settles a held edit or a color still waiting, for an affordance that
    /// takes the person away from the control.
    func flush() {
        isHoldingSlider = false
        settle()
    }

    /// The card closed, by Collapse or by the host's own trigger.
    func cardClosed() {
        flush()
    }

    func write(_ tuning: ThemeTuning) {
        $tuning.withLock { $0 = tuning }
    }

    /// Records a version as a child of Current and refreshes the agent's
    /// context; nothing when the design is Current's.
    func record(_ design: Design, author: DesignHistory.Author, origin: DesignHistory.Origin) {
        guard design != current?.design else { return }
        $history.withLock { $0.record(design, author: author, origin: origin) }
        refreshContext()
    }

    /// Puts a version's design on the device: its code over the tuning (the
    /// Preview stays), the default theme for Source, and its knobs.
    func apply(_ design: Design) {
        let code = design.code.isEmpty ? ThemeTuning.default.presetCode : design.code
        if let tuned = ThemeTuning(presetCode: code, base: tuning) { write(tuned) }
        stage.knobs.replaceAll(design.knobs)
    }

    /// Reconciles the history with the value files, then records each change
    /// made outside Tune's controls until the surface goes away.
    func task() async {
        $history.withLock { $0.reconcile(values: liveDesign) }
        refreshContext()
        // The maps are Sendable, so not isolated to the main actor: the loop
        // asks for the next value off it, and a value buffered by two quick
        // writes runs the map there, which traps an isolated closure.
        let changes = Publishers.Merge(
            $tuning.publisher.map { @Sendable _ in }, stage.knobs.$values.publisher.map { @Sendable _ in })
        for await _ in changes.values {
            outsideChange()
        }
    }

    /// A change Tune's controls did not make: the host's own strip, or the
    /// agent's write. The agent's record or a staged variant names it the
    /// agent's; anything else is yours.
    private func outsideChange() {
        guard !isHoldingSlider, colorSettle == nil else { return }
        let design = liveDesign
        guard design != current?.design else { return }
        if agentChange?.code == design.code {
            record(design, author: .agent, origin: .edit)
        } else if let variant = variants.matching(tuning) {
            record(design, author: .agent, origin: .proposal(id: variant.id))
        } else {
            record(design, author: .you, origin: .edit)
        }
    }

    // MARK: The agent's context

    /// The frame of the selected item's first instance on screen.
    var selectedFrame: CGRect? {
        stage.selection.item.flatMap { item in stage.visibleItems.first { $0.name == item }?.frame }
    }

    /// Writes the agent's view of the screen now, then, once the app has
    /// drawn, saves `notes/context.png` and writes it again naming the code
    /// that screenshot shows. Nothing while the surface is off, and no
    /// screenshot while Selecting, when the app is outlined for the tap.
    func refreshContext() {
        guard stage.isEnabled else { return }
        outbox.writeContext(context)
        contextCapture?.cancel()
        contextCapture = nil
        guard !stage.selection.isSelecting else { return }
        contextCapture = Task { [weak self, clock] in
            do { try await clock.sleep(for: .milliseconds(300)) } catch { return }
            guard let self, !stage.selection.isSelecting else { return }
            let code = liveDesign.code
            guard let path = outbox.saveScreenshot("context", selectedFrame) else { return }
            contextScreenshot = (path, code)
            outbox.writeContext(context)
        }
    }

    /// The context names the design's code, empty under Source: the theme
    /// file then holds the default theme, but the app shows its own.
    private var context: DesignContext {
        var context = DesignContext.capture(
            state: stage, tuning: tuning, screenshot: contextScreenshot?.path, screenshotCode: contextScreenshot?.code)
        context.presetCode = liveDesign.code
        return context
    }

    /// The screen, its items, or the selection changed.
    func screenChanged() {
        refreshContext()
    }

    /// The keyboard went down, so the app is drawn as the person sees it again.
    func keyboardHid() {
        refreshContext()
    }
}

extension DesignHistory {
    /// The design the value files hold for a theme code and knob values. The
    /// theme file cannot say Source, so the default theme read while Current
    /// is Source (or before any version) is Source.
    func design(code: String, knobs: [String: [String: Double]]) -> Design {
        let underSource = entry(current).map { $0.design.code.isEmpty } ?? true
        return Design(code: underSource && code == ThemeTuning.default.presetCode ? "" : code, knobs: knobs)
    }
}

extension DesignSurface {
    /// Tune's three places.
    public enum Place: String, CaseIterable, Identifiable, Sendable {
        case tokens, notes, versions
        public var id: String { rawValue }

        var title: String {
            switch self {
            case .tokens: "Tokens"
            case .notes: "Notes"
            case .versions: "Versions"
            }
        }
    }
}
#endif
