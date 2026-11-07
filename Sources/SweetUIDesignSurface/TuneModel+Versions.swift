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

    /// Writes the hand-off with a screenshot: the design and the open
    /// notes, for the agent to put into source. A proposal trying is kept
    /// first, so the design handed off is a decided one.
    func handOffButtonTapped() {
        flush()
        if history.trial != nil { keepButtonTapped() }
        let screenshot = outbox.saveScreenshot("handoff", selectedFrame)
        let handoff = DesignHandoff.capture(
            id: uuid(), sentAt: now, design: liveDesign, tuning: tuning, version: history.current, notes: notes,
            answers: agent.answers, screenshot: screenshot, previous: handOff)
        if outbox.writeHandOff(handoff) {
            handOff = handoff
            handOffError = nil
        } else {
            handOffError = "The hand-off did not save, so the agent cannot read it. Hand off again."
        }
    }

    /// Where the last hand-off stands, from the agent's file.
    enum HandOffStatus: Equatable {
        case notSaved(String)
        case sent(Date)
        case read(Date)
        case shipped(Date, files: [String])
        case answered(String)

        var text: String {
            func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }
            return switch self {
            case .notSaved(let reason): reason
            case .sent(let date): "Handed off at \(time(date)). Not read yet."
            case .read(let date): "Read by the agent at \(time(date))."
            case .shipped(let date, let files): "Shipped at \(time(date)). Changed \(files.joined(separator: ", "))."
            case .answered(let reply): "The agent answered: \(reply)"
            }
        }
    }

    var handOffStatus: HandOffStatus? {
        if let handOffError { return .notSaved(handOffError) }
        guard let handOff else { return nil }
        let id = handOff.id.uuidString
        if let answer = agent.answers[id] {
            return answer.changedFiles.isEmpty ? .answered(answer.reply) : .shipped(answer.date, files: answer.changedFiles)
        }
        return agent.read.handoffs[id].map(HandOffStatus.read) ?? .sent(handOff.sentAt)
    }

    /// A hand-off the agent answered with changed files is Shipped: its
    /// design now lives in source, so Tune clears its token and knob
    /// overrides and the source shows. The current hand-off and the one
    /// before it take an answer; each ships once, and never after a later one.
    func shipAnswered() {
        guard let handOff else { return }
        var sent: [(id: UUID, design: Design)] = []
        if let previous = handOff.previous {
            sent.append((previous.id, Design(code: previous.presetCode, knobs: previous.knobs)))
        }
        sent.append((handOff.id, handOff.design))
        for (index, hand) in sent.enumerated() {
            guard let answer = agent.answers[hand.id.uuidString], !answer.changedFiles.isEmpty else { continue }
            if let shipped = history.shipped?.handoff, sent[index...].contains(where: { $0.id == shipped }) { continue }
            changeHistory { $0.ship(handoff: hand.id, design: hand.design, files: answer.changedFiles) }
            apply(Design())
            refreshContext()
        }
    }

    /// Moves Current with `move` after a held edit settles, then puts the
    /// version it lands on on the device.
    private func step(_ move: (inout DesignHistory) -> DesignHistory.Entry?) {
        flush()
        var landed: DesignHistory.Entry?
        changeHistory { landed = move(&$0) }
        guard let entry = landed else { return }
        apply(entry.design)
        refreshContext()
    }
}
#endif
