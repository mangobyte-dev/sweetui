#if canImport(UIKit)
import Combine
import Dependencies
import Foundation
import Sharing
import SwiftUI
import SweetUIFoundations

/// Tune's one model: the design on the device, the place the card shows,
/// and one intent method per affordance. Each settled gesture records one
/// version, and the call site names its author: release for a slider or a
/// stepper, at once for a menu or a switch, 0.6 s after the last change for
/// a color; a place change, Select, and a collapse settle a held edit first.
/// A change from outside Tune's controls (the host's own strip) records one
/// version by you. The agent never writes the value files: it proposes, and
/// Tune tries a proposal that asks to be applied as soon as it arrives.
@MainActor
@Observable
final class TuneModel {
    typealias Place = DesignSurface.Place
    typealias Design = DesignHistory.Design

    /// Where the last place is remembered between launches.
    static let placeStorageKey = "designSurface.place"
    /// The answers and proposals the person has seen on Notes.
    static let seenStorageKey = "designSurface.seen"
    static let codeError = "That is not a code Tune can read. Copy one from sweetui.dev/create."

    let stage: DesignSurfaceState

    /// The text under Start from's Paste a code, and why it did not apply.
    var codeDraft = ""
    var codeError: String?
    /// The composer's text and focus.
    var noteDraft = ""
    var composerFocused = false
    /// The note or proposal the composer replies to; `nil` writes a new note.
    var replyTarget: ReplyTarget?
    /// The row Notes scrolls to next: a proposal the strip named, or the newest.
    var scrollTarget: String?
    /// The name typed for Current.
    var versionName = ""
    /// The last hand-off written, read back at launch for its status.
    var handOff: DesignHandoff?
    var handOffError: String?
    /// What the strip says for 2 s after a proposal is kept or discarded.
    var stripMessage: String?
    /// Why the last note did not save; the draft stays.
    var noteSaveError: String?
    /// The answers and proposals the person saw on Notes, by key.
    var seen: Set<String> = []
    /// The Tokens groups open for this launch.
    var openGroups: Set<TokenCatalog.Token.Group> = [.color]
    /// The innermost item in the selection's chain the host has a page for,
    /// and that page while it waits for the card to push it.
    var hostPageItem: String?
    var hostPageToPush: String?
    /// Note armed Selecting: the pick returns to the focused composer.
    @ObservationIgnored var composesAfterSelecting = false

    @ObservationIgnored @Shared(.designTokens) var tuning
    @ObservationIgnored @Shared(.designHistory) var history
    @ObservationIgnored @Shared(.designNotes) var notes
    /// The agent's file; read only, so a write to it does not compile.
    @ObservationIgnored @SharedReader(.designAgent) var agent
    /// The host's defaults, where the last place is remembered.
    @ObservationIgnored @Dependency(\.defaultAppStorage) var defaults
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
    /// The agent wrote while a control was held: its proposals are tried,
    /// and a shipped hand-off cleared, on release.
    @ObservationIgnored private var agentWaits = false
    /// The answers already announced, so a relaunch announces none again.
    @ObservationIgnored private var announced: Set<String>?
    @ObservationIgnored private(set) var stripClear: Task<Void, Never>?
    private var shownPlace = Place.tokens

    init(stage: DesignSurfaceState) {
        self.stage = stage
        shownPlace = defaults.string(forKey: Self.placeStorageKey).flatMap(Place.init(rawValue:)) ?? .tokens
        seen = Set(defaults.stringArray(forKey: Self.seenStorageKey) ?? [])
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
            if newValue == .notes { notesSeen() }
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

    /// A slider's or a stepper's touch went down or came up; a release
    /// takes a held token's outlines away.
    func sliderEditingChanged(_ editing: Bool) {
        isHoldingSlider = editing
        guard !editing else { return }
        stage.reachOutlines = nil
        settle()
    }

    /// Records the live design as one version by you when it moved, then
    /// tries a proposal that arrived while the control was held, on top.
    func settle() {
        colorSettle?.cancel()
        colorSettle = nil
        record(liveDesign, author: .you, origin: .edit)
        if agentWaits {
            agentWaits = false
            shipAnswered()
            tryArrivals()
        }
    }

    /// Settles a held edit or a color still waiting, for an affordance that
    /// takes the person away from the control.
    func flush() {
        isHoldingSlider = false
        stage.reachOutlines = nil
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
    /// context; nothing when the design is Current's. While a proposal is
    /// trying, an edit keeps it and anything else discards it first.
    func record(_ design: Design, author: DesignHistory.Author, origin: DesignHistory.Origin) {
        guard design != current?.design else { return }
        changeHistory(edited: origin == .edit) { $0.record(design, author: author, origin: origin) }
        refreshContext()
    }

    /// Changes the history and says what became of a proposal that was
    /// trying: kept, or discarded, in the strip for 2 s and to VoiceOver.
    func changeHistory(edited: Bool = false, _ change: (inout DesignHistory) -> Void) {
        let before = history.trial
        $history.withLock(change)
        if let after = history.trial, after.proposal != before?.proposal {
            announce("Trying \(proposal(after.proposal)?.name ?? "a proposal").")
        }
        guard let before, history.trial?.proposal != before.proposal else { return }
        let name = proposal(before.proposal)?.name ?? "the proposal"
        switch history.decisions[before.proposal]?.state {
        case .kept: showStrip(edited ? "Kept \(name). Your change is on top." : "Kept \(name).")
        case .discarded: showStrip("Discarded \(name).")
        case .tried, nil: break
        }
    }

    /// Shows a message in the strip for 2 s and announces it.
    func showStrip(_ message: String) {
        stripMessage = message
        announce(message)
        stripClear?.cancel()
        stripClear = Task { [weak self, clock] in
            do { try await clock.sleep(for: .seconds(2)) } catch { return }
            self?.stripMessage = nil
        }
    }

    func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }

    /// Puts a version's design on the device: its code over the tuning (the
    /// Preview stays), the default theme for Source, and its knobs.
    func apply(_ design: Design) {
        let code = design.code.isEmpty ? ThemeTuning.default.presetCode : design.code
        if let tuned = ThemeTuning(presetCode: code, base: tuning) { write(tuned) }
        stage.knobs.replaceAll(design.knobs)
    }

    /// Reconciles the history with the value files, then records each change
    /// made outside Tune's controls and follows the agent's file until the
    /// surface goes away.
    func task() async {
        handOff = outbox.readHandOff()
        $history.withLock { $0.reconcile(values: liveDesign) }
        refreshContext()
        // The maps are Sendable, so not isolated to the main actor: the loop
        // asks for the next value off it, and a value buffered by two quick
        // writes runs the map there, which traps an isolated closure. Each
        // publisher sends its current value first, so the agent's file is
        // read once at launch.
        let changes = Publishers.Merge3(
            $tuning.publisher.map { @Sendable _ in Change.values },
            stage.knobs.$values.publisher.map { @Sendable _ in Change.values },
            $agent.publisher.map { @Sendable _ in Change.agent })
        for await change in changes.values {
            switch change {
            case .values: outsideChange()
            case .agent: agentChanged()
            }
        }
    }

    private enum Change { case values, agent }

    /// A change Tune's controls did not make, such as the host's own strip:
    /// one version by you.
    private func outsideChange() {
        guard !isHoldingSlider, colorSettle == nil else { return }
        record(liveDesign, author: .you, origin: .edit)
    }

    /// The agent wrote its file: a new answer is announced, a hand-off
    /// answered with files ships, and a proposal that asks to be applied is
    /// tried; the last two wait for the release while a control is held.
    func agentChanged() {
        announceAnswers()
        if stage.isPresented && place == .notes { notesSeen() }
        if isHoldingSlider || colorSettle != nil {
            agentWaits = true
        } else {
            shipAnswered()
            tryArrivals()
        }
    }

    /// Announces the first sentence of each answer that is new since launch.
    private func announceAnswers() {
        let keys = Set(agent.answers.map { "\($0.key) \($0.value.date.timeIntervalSince1970)" })
        defer { announced = keys }
        guard let announced else { return }
        for (id, answer) in agent.answers where !announced.contains("\(id) \(answer.date.timeIntervalSince1970)") {
            let sentence = answer.reply.split(separator: ".", maxSplits: 1).first.map { String($0) + "." } ?? answer.reply
            announce("The agent answered: \(sentence)")
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
        context.trying = trying.map { DesignContext.Trying(id: $0.id, name: $0.name) }
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
