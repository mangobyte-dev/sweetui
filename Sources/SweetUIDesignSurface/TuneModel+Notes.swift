#if canImport(UIKit)
import Foundation

/// Notes: the composer, the notes, the agent's last change, and its variants.
extension TuneModel {
    /// Goes to Notes with the composer focused on the selection or the screen.
    func noteButtonTapped() {
        place = .notes
        composerFocused = true
    }

    /// What the composer's note is about.
    var composerSubject: String {
        stage.selection.item.map(stage.title) ?? stage.screen ?? "this screen"
    }

    var canSend: Bool {
        !noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Saves the note with a screenshot of the app, the selected item
    /// outlined, then clears the field and puts the keyboard down.
    func sendButtonTapped() {
        let text = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        var note = DesignNote.take(text, selection: stage.selection, tuning: tuning, state: stage)
        note.id = uuid()
        note.createdAt = now
        note.screenshot = outbox.saveScreenshot(note.id.uuidString, selectedFrame)
        $notes.withLock { $0.append(note) }
        noteDraft = ""
        composerFocused = false
    }

    func deleteNote(_ id: UUID) {
        $notes.withLock { $0.removeAll { $0.id == id } }
    }

    /// Puts an answered note back in the agent's queue.
    func reopenNote(_ id: UUID) {
        $notes.withLock { notes in
            if let index = notes.firstIndex(where: { $0.id == id }) { notes[index].reopen() }
        }
    }

    // MARK: From the agent

    /// Restores what the agent's last write replaced, as a version by you.
    func undoAgentChangeTapped() {
        guard let change = agentChange else { return }
        var tuned = tuning
        change.undo(tuning: &tuned, knobs: stage.knobs)
        write(tuned)
        $agentChange.withLock { $0 = nil }
        settle()
    }

    func keepAgentChangeTapped() {
        $agentChange.withLock { $0 = nil }
    }

    /// Applies a staged variant as a version by the agent and records the pick.
    func variantChipTapped(_ variant: DesignVariants.Variant) {
        guard let picked = variants.tuning(for: variant, base: tuning) else { return }
        flush()
        write(picked)
        $variants.withLock { $0.chosen = variant.name }
        record(Design(code: tuning.presetCode, knobs: stage.knobs.values), author: .agent, origin: .proposal(id: variant.id))
    }
}
#endif
