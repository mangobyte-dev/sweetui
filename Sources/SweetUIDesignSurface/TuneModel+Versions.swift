#if canImport(UIKit)
import Foundation

/// Versions: Current with its changes, Hand off with its status, and the
/// history with Restore; Undo and Redo in the bottom bar.
extension TuneModel {
    /// One row of the history, newest first: a version and, when it did not
    /// come from the version listed under it, the version it came from.
    struct HistoryRow: Identifiable {
        var entry: DesignHistory.Entry
        var branch: DesignHistory.Entry?
        var id: UUID { entry.id }
    }

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

    // MARK: Labels

    /// A version by its name, or by what it came from; an edit by the titles
    /// it changed, "Card radius" or "Accent and 2 more".
    func label(_ entry: DesignHistory.Entry) -> String {
        if let name = entry.name { return name }
        return switch entry.origin {
        case .first: "First version"
        case .edit: editLabel(entry)
        case .preset(let name): name
        case .proposal(let id): proposal(id)?.name ?? "A proposal"
        case .defaultTheme: "Default"
        case .source: entry.author == .agent ? "Shipped" : "Source"
        case .code: "Pasted code"
        }
    }

    private func editLabel(_ entry: DesignHistory.Entry) -> String {
        let titles = changesFromParent(entry)?.map(\.title) ?? []
        return switch titles.count {
        case 0: "Edit"
        case 1: titles[0]
        case 2: "\(titles[0]) and \(titles[1])"
        default: "\(titles[0]) and \(titles.count - 1) more"
        }
    }

    func time(_ entry: DesignHistory.Entry) -> String {
        entry.date.formatted(date: .omitted, time: .shortened)
    }

    /// What Undo and Redo go to: "Makes Mango at 10:42 current."
    func hint(_ entry: DesignHistory.Entry) -> String {
        "Makes \(label(entry)) at \(time(entry)) current."
    }

    /// Undo's hint: what it discards while a proposal is trying, and that
    /// there is nothing to undo at a root.
    var undoHint: String {
        guard let target = undoTarget else { return "Nothing to undo." }
        guard let trying else { return hint(target) }
        return "Discards \(trying.name) and makes \(label(target)) at \(time(target)) current."
    }

    var redoHint: String {
        redoTarget.map(hint) ?? "Nothing to redo."
    }

    // MARK: Current

    /// Every token and knob `to` moves from `from`, in words, items and
    /// knobs as the host titles them, a switch as on or off and a choice as
    /// its option.
    func changes(from: Design, to: Design) -> [DesignChanges.Change] {
        let knobs = stage.knobs
        func knob(_ item: String, _ name: String) -> ItemKnob? { knobs.knobs(for: item).first { $0.name == name } }
        return DesignChanges.between(
            from, to, title: stage.title, knobTitle: { knob($0, $1)?.title ?? $1 },
            knobValue: { item, name, value in
                knob(item, name)?.word(for: value) ?? ThemeTuning.RGB.format(value, minimum: 0)
            })
    }

    /// What a version changed from the one it came from; `nil` for a root.
    /// Under Source only its knobs, and `nil` without one: Source is a
    /// state the label and `sourceLine` name, not a count of Default values.
    func changesFromParent(_ entry: DesignHistory.Entry) -> [DesignChanges.Change]? {
        history.entry(entry.parent).flatMap { orSourceState(entry, changes(from: $0.design, to: entry.design)) }
    }

    /// What Current changes from Default; under Source only its knobs, and
    /// `nil` without one.
    var changesFromDefault: [DesignChanges.Change]? {
        current.flatMap { orSourceState($0, changes(from: Design(), to: $0.design)) }
    }

    /// "Tokens: source, the app's own theme." while Current sets no token,
    /// since Tune does not know the values the app shows; `nil` otherwise.
    var sourceLine: String? {
        current.map(isSource) == true ? "Tokens: source, the app's own theme." : nil
    }

    /// Whether a version sets no token, so the app's own theme shows. A host
    /// that does not tune the theme has knob versions only, never Source.
    private func isSource(_ entry: DesignHistory.Entry) -> Bool {
        stage.tunesTheme && entry.design.code.isEmpty
    }

    private func orSourceState(_ entry: DesignHistory.Entry, _ changes: [DesignChanges.Change]) -> [DesignChanges.Change]? {
        isSource(entry) && changes.isEmpty ? nil : changes
    }

    /// The Checks in one line: under Source they cannot measure, since the
    /// app shows its own colors. `nil` for a host that does not tune the theme.
    var checksLine: String? {
        guard stage.tunesTheme else { return nil }
        guard !liveDesign.code.isEmpty else { return ContrastAudit.unmeasuredUnderSource }
        let audit = ContrastAudit(tuning)
        return switch audit.failures {
        case 0: "Every check passes."
        case 1: "1 of \(audit.pairs.count) checks fails."
        case let failures: "\(failures) of \(audit.pairs.count) checks fail."
        }
    }

    /// Tokens with Color open. With an item selected Tokens hides the Checks,
    /// so the selection is cleared.
    func checksLineTapped() {
        if stage.selection.item != nil { clearSelectionTapped() }
        openGroups.insert(.color)
        place = .tokens
    }

    /// The notes the agent has not answered, which go with the next hand-off.
    var openNotes: [DesignNote] {
        DesignHandoff.openNotes(notes, answers: agent.answers)
    }

    /// "2 open notes go with the hand-off."; `nil` with none.
    var openNotesLine: String? {
        switch openNotes.count {
        case 0: nil
        case 1: "1 open note goes with the hand-off."
        case let count: "\(count) open notes go with the hand-off."
        }
    }

    /// Notes, scrolled to the oldest open note.
    func openNotesLineTapped() {
        place = .notes
        scrollTarget = openNotes.first.map { Row.note($0).id }
    }

    /// Names the version the Name field showed with its text, on Return or
    /// when the field loses focus; a blank one clears the name.
    func nameSubmitted() {
        let id = nameFieldVersion ?? history.current
        let name = versionName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name != (history.entry(id)?.name ?? "") {
            $history.withLock { $0.name(name, of: id) }
            announce(name.isEmpty ? "Name cleared." : "Named \(name).")
        }
        showCurrentName()
    }

    /// Current moved, or Versions appeared: the Name field shows Current's
    /// name, so Return keeps it and a cleared field clears it. A name being
    /// typed stays, so a proposal tried meanwhile does not take the draft.
    func currentChanged() {
        guard versionName == (history.entry(nameFieldVersion)?.name ?? "") else { return }
        showCurrentName()
    }

    private func showCurrentName() {
        versionName = current?.name ?? ""
        nameFieldVersion = history.current
    }

    // MARK: History

    /// Every version, newest first. A version that did not come from the
    /// one listed under it names the one it came from.
    var historyRows: [HistoryRow] {
        let newest = Array(history.entries.reversed())
        return newest.indices.map { index in
            let entry = newest[index]
            let older = newest.indices.contains(index + 1) ? newest[index + 1].id : nil
            let branch = entry.parent == older ? nil : history.entry(entry.parent)
            return HistoryRow(entry: entry, branch: branch)
        }
    }

    // MARK: Hand off

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
        do {
            try outbox.writeHandOff(handoff)
            handOff = handoff
            handOffError = nil
            announce(HandOffStatus.sent(handoff.sentAt).text)
        } catch {
            handOffError = "The hand-off did not save, so the agent cannot read it. \(error.localizedDescription) Hand off again."
            announce(handOffError ?? "")
        }
    }

    /// Where the last hand-off stands, from the agent's file.
    enum HandOffStatus: Equatable {
        case notSaved(String)
        case sent(Date)
        case read(Date)
        case shipped(Date, files: [String])
        case answered(String)

        var isNotSaved: Bool {
            if case .notSaved = self { return true }
            return false
        }

        var text: String {
            func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }
            return switch self {
            case .notSaved(let reason): reason
            case .sent(let date): "Handed off at \(time(date)). Not read yet. Ask the agent to read it."
            case .read(let date): "Read by the agent at \(time(date))."
            case .shipped(let date, let files):
                "Shipped at \(time(date)). Changed \(files.joined(separator: ", ")). A build with those files shows them."
            case .answered(let reply): "The agent answered: \(reply)"
            }
        }
    }

    /// The answer to the hand-off before the current one, which still
    /// counts: "The hand-off before, at 10:40: Shipped at 10:51. …"; `nil`
    /// while it has none.
    var previousHandOffLine: String? {
        guard let previous = handOff?.previous, let answer = agent.answers[previous.id.uuidString] else { return nil }
        let status: HandOffStatus =
            answer.changedFiles.isEmpty ? .answered(answer.reply) : .shipped(answer.date, files: answer.changedFiles)
        return "The hand-off before, at \(previous.sentAt.formatted(date: .omitted, time: .shortened)): \(status.text)"
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
    /// design now lives in source. While the device still shows that design,
    /// Tune clears its token and knob overrides, so the app shows the theme
    /// it was built with; a design changed since stays, since no source holds
    /// it. The current hand-off and the one before it take an answer; each
    /// ships once, and never after a later one.
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
            var cleared = false
            changeHistory { cleared = $0.ship(handoff: hand.id, design: hand.design, files: answer.changedFiles) }
            if cleared { apply(Design()) }
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
