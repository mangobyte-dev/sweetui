#if canImport(UIKit)
import Foundation

/// Versions: Undo, Redo, Restore, names, and the hand-off.
extension TuneModel {
    /// Makes the parent current (the base while a proposal is on trial).
    func undoButtonTapped() {
        step { $0.undo() }
    }

    /// Makes the newest child current.
    func redoButtonTapped() {
        step { $0.redo() }
    }

    /// Makes a past version current, deleting nothing.
    func restore(_ id: UUID) {
        step { $0.restore(id) }
    }

    /// The version Undo lands on, for its hint; `nil` at a root.
    var undoTarget: DesignHistory.Entry? {
        var copy = history
        return copy.undo()
    }

    var redoTarget: DesignHistory.Entry? {
        var copy = history
        return copy.redo()
    }

    /// A version by its name, or by when it was made.
    func label(_ entry: DesignHistory.Entry) -> String {
        entry.name ?? "the version from \(entry.date.formatted(date: .omitted, time: .shortened))"
    }

    /// Names Current; a blank name clears it.
    func nameButtonTapped() {
        $history.withLock { $0.name(versionName) }
        versionName = ""
    }

    /// Writes the hand-off with a screenshot: the design, the open notes,
    /// and the named versions, for the agent to put into source.
    func handOffButtonTapped() {
        flush()
        let screenshot = outbox.saveScreenshot("handoff", selectedFrame)
        var handoff = DesignHandoff.capture(
            tuning: tuning, knobs: stage.knobs.values, variants: variants, notes: notes, history: history,
            screenshot: screenshot)
        handoff.sentAt = now
        if outbox.writeHandOff(handoff) { handOffSentAt = handoff.sentAt }
    }

    /// Moves Current with `move` after a held edit settles, then puts the
    /// version it lands on on the device.
    private func step(_ move: (inout DesignHistory) -> DesignHistory.Entry?) {
        flush()
        var landed: DesignHistory.Entry?
        $history.withLock { landed = move(&$0) }
        guard let entry = landed else { return }
        apply(entry.design)
        refreshContext()
    }
}
#endif
