#if canImport(UIKit)
import Foundation

/// Notes: the composer and its replies, the threads, and the agent's
/// proposals with Try, Keep, and Discard.
extension TuneModel {
    /// The note or proposal a reply follows, and the note whose subject the
    /// reply takes (none for a proposal that answers no note).
    struct ReplyTarget: Equatable {
        var id: String
        var label: String
        var subject: DesignNote?
    }

    /// One conversation: a note or a proposal that answers no note, then
    /// what followed it, oldest first.
    struct Thread: Identifiable {
        var id: String
        var rows: [Row]
    }

    enum Row: Identifiable {
        case note(DesignNote)
        case answer(note: String, AgentRecord.Answer)
        case proposal(Proposal)

        var id: String {
            switch self {
            case .note(let note): "note.\(note.id.uuidString)"
            case .answer(let note, _): "answer.\(note)"
            case .proposal(let proposal): "proposal.\(proposal.id)"
            }
        }
    }

    // MARK: The composer

    /// Goes to Notes with the composer focused on the selection. With
    /// nothing selected it arms Selecting first; the tap, on an item or on
    /// nothing, returns to the focused composer.
    func noteButtonTapped() {
        place = .notes
        guard stage.selection.item == nil else {
            composerFocused = true
            return
        }
        stage.selection.isSelecting = true
        composesAfterSelecting = true
    }

    /// The selection the composer's note is about: the selected item while
    /// it is on this screen, otherwise the screen.
    var composerSelection: ItemSelection {
        guard let item = stage.selection.item, stage.visibleItemNames.contains(where: { $0.name == item }) else {
            return ItemSelection()
        }
        return stage.selection
    }

    /// What the composer's note is about.
    var composerSubject: String {
        if let target = replyTarget { return target.subject.map(subject) ?? subjectOfSelection }
        return subjectOfSelection
    }

    private var subjectOfSelection: String {
        composerSelection.item.map(stage.title) ?? stage.screen ?? "this screen"
    }

    var canSend: Bool {
        !noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Saves the note with a screenshot of the app, its item outlined, then
    /// clears the field and puts the keyboard down. A reply follows its
    /// target and takes its subject. A save that fails keeps the draft.
    func sendButtonTapped() {
        let text = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        var note: DesignNote
        if let about = replyTarget?.subject {
            note = DesignNote.take(
                text, selection: ItemSelection(item: about.item, chain: about.chain), code: liveDesign.code,
                state: stage)
            note.screen = about.screen
        } else {
            note = DesignNote.take(text, selection: composerSelection, code: liveDesign.code, state: stage)
        }
        note.id = uuid()
        note.createdAt = now
        note.inReplyTo = replyTarget?.id
        note.screenshot = outbox.saveScreenshot(note.id.uuidString, note.frame.map {
            CGRect(x: $0.x, y: $0.y, width: $0.width, height: $0.height)
        })
        $notes.withLock { $0.append(note) }
        if let error = $notes.saveError {
            noteSaveError = "Your note did not save, so the agent cannot read it. \(error.localizedDescription)"
            $notes.withLock { $0.removeAll { $0.id == note.id } }
            return
        }
        noteSaveError = nil
        noteDraft = ""
        composerFocused = false
        replyTarget = nil
        scrollTarget = Row.note(note).id
    }

    /// The composer replies to this note, about its subject.
    func replyButtonTapped(note: DesignNote) {
        replyTarget = ReplyTarget(id: note.id.uuidString, label: note.text, subject: note)
        composerFocused = true
    }

    /// The composer replies to this proposal, about its note's subject.
    func replyButtonTapped(proposal: Proposal) {
        let about = proposal.note.flatMap { id in notes.first { $0.id.uuidString == id } }
        replyTarget = ReplyTarget(id: proposal.id, label: proposal.name, subject: about)
        composerFocused = true
    }

    /// Back to a note about the selection; the draft stays.
    func cancelReplyTapped() {
        replyTarget = nil
    }

    func deleteNote(_ id: UUID) {
        $notes.withLock { $0.removeAll { $0.id == id } }
        if replyTarget?.id == id.uuidString { replyTarget = nil }
    }

    /// Selects a note's item, which Tune outlines on the app.
    func subjectTapped(_ note: DesignNote) {
        guard let item = note.item else { return }
        select(note.chain.isEmpty ? [item] : note.chain)
    }

    // MARK: The threads

    /// Every note that follows nothing, with what followed it, oldest first;
    /// then the proposals that answer no note, by date.
    var threads: [Thread] {
        let noteIDs = Set(notes.map(\.id.uuidString))
        let proposals = agent.proposals.sorted { $0.date < $1.date }
        let proposalIDs = Set(proposals.map(\.id))
        var replies: [String: [DesignNote]] = [:]
        var roots: [DesignNote] = []
        for note in notes {
            if let parent = note.inReplyTo, noteIDs.contains(parent) || proposalIDs.contains(parent) {
                replies[parent, default: []].append(note)
            } else {
                roots.append(note)
            }
        }
        var answering: [String: [Proposal]] = [:]
        var loose: [Proposal] = []
        for proposal in proposals {
            if let note = proposal.note, noteIDs.contains(note) {
                answering[note, default: []].append(proposal)
            } else {
                loose.append(proposal)
            }
        }
        // Visited ids keep a hand-edited file with a loop from recursing forever.
        var visited: Set<String> = []
        func noteRows(_ note: DesignNote) -> [Row] {
            let id = note.id.uuidString
            guard visited.insert(id).inserted else { return [] }
            var rows: [Row] = [.note(note)]
            if let answer = agent.answers[id] { rows.append(.answer(note: id, answer)) }
            rows += (answering[id] ?? []).flatMap(proposalRows)
            rows += (replies[id] ?? []).flatMap(noteRows)
            return rows
        }
        func proposalRows(_ proposal: Proposal) -> [Row] {
            guard visited.insert(proposal.id).inserted else { return [] }
            return [.proposal(proposal)] + (replies[proposal.id] ?? []).flatMap(noteRows)
        }
        return roots.map { Thread(id: $0.id.uuidString, rows: noteRows($0)) }
            + loose.map { Thread(id: $0.id, rows: proposalRows($0)) }
    }

    /// What a note is about: its item's title, "Card, on Settings" when that
    /// item is on another screen, or its screen.
    func subject(_ note: DesignNote) -> String {
        guard let item = note.item else { return note.screen ?? "The screen" }
        let title = stage.title(item)
        if let screen = note.screen, screen != stage.screen, !stage.visibleItemNames.contains(where: { $0.name == item }) {
            return "\(title), on \(screen)"
        }
        return title
    }

    /// Answered once the agent answered it, Read once it listed it.
    func status(_ note: DesignNote) -> String {
        let id = note.id.uuidString
        if agent.answers[id] != nil { return "Answered" }
        return agent.read.notes[id] == nil ? "Not read yet" : "Read"
    }

    /// The line over the threads: when the agent last listed the notes.
    var readLine: String {
        guard let last = agent.read.notes.values.max() else { return "The agent has not read your notes yet." }
        return "The agent last read your notes at \(last.formatted(date: .omitted, time: .shortened))."
    }

    /// Why the agent's file did not decode; the notes still show.
    var agentFileError: String? {
        $agent.loadError.map { _ in
            "The agent's last write did not decode, so its answers and proposals are not shown. Ask the agent to replace or remove design-agent.json."
        }
    }

    // MARK: New from the agent

    /// Answers to notes and proposals the person has not seen on Notes.
    var unseen: Int {
        unseenKeys.subtracting(seen).count
    }

    private var unseenKeys: Set<String> {
        let noteIDs = Set(notes.map(\.id.uuidString))
        let answers = agent.answers.filter { noteIDs.contains($0.key) }
            .map { "answer.\($0.key).\($0.value.date.timeIntervalSince1970)" }
        return Set(answers + agent.proposals.map { "proposal.\($0.id)" })
    }

    /// The person saw Notes: everything there now is no longer new.
    func notesSeen() {
        let keys = unseenKeys
        guard keys != seen else { return }
        seen = keys
        defaults.set(Array(keys).sorted(), forKey: Self.seenStorageKey)
    }

    // MARK: Proposals

    func proposal(_ id: String) -> Proposal? {
        agent.proposals.first { $0.id == id }
    }

    /// The proposal on the device on top of its base.
    var trying: Proposal? {
        history.trial.flatMap { proposal($0.proposal) }
    }

    /// The version a proposal is tried over: the trial's base, so tries
    /// never stack, or Current.
    private var tryBase: DesignHistory.Entry? {
        history.entry(history.trial?.base ?? history.current)
    }

    /// Every token and knob the proposal changes, in words: for one trying
    /// or kept, from its version's parent to its version; for any other,
    /// from the version a try would build on.
    func changes(_ proposal: Proposal) -> [DesignChanges.Change] {
        let from: Design
        let to: Design
        if [.trying, .kept].contains(proposal.state(in: history)),
           let version = history.entries.last(where: { $0.origin == .proposal(id: proposal.id) }),
           let parent = history.entry(version.parent) {
            (from, to) = (parent.design, version.design)
        } else if let base = tryBase, let design = try? proposal.design(over: base.design) {
            (from, to) = (base.design, design)
        } else {
            return []
        }
        return DesignChanges.between(from, to, title: stage.title) { [stage] item, knob in
            stage.knobs.knobs(for: item).first { $0.name == knob }?.title ?? knob
        }
    }

    /// Why Tune cannot try it, or `nil` when it can.
    func unreadable(_ proposal: Proposal) -> String? {
        do {
            _ = try proposal.design(over: tryBase?.design ?? Design())
            return nil
        } catch {
            return error.reason
        }
    }

    func tryButtonTapped(_ id: String) {
        flush()
        guard let proposal = proposal(id) else { return }
        tryProposal(proposal)
    }

    /// Keeps the proposal trying and discards its Offered siblings, the
    /// other proposals that answer the same note.
    func keepButtonTapped() {
        guard let trial = history.trial else { return }
        let note = proposal(trial.proposal)?.note
        let siblings = agent.proposals.filter {
            $0.id != trial.proposal && $0.note == note && $0.state(in: history) == .offered
        }
        changeHistory { $0.keep(discarding: siblings.map(\.id)) }
        refreshContext()
    }

    /// Puts the base back exactly and discards the proposal trying.
    func discardButtonTapped() {
        guard history.trial != nil else { return }
        changeHistory { $0.discard() }
        if let current { apply(current.design) }
        refreshContext()
    }

    /// Turns down a proposal that is offered, leaving the device as it is.
    func discardOfferedTapped(_ id: String) {
        guard let proposal = proposal(id) else { return }
        $history.withLock { $0.discard(offered: id) }
        announce("Discarded \(proposal.name).")
    }

    /// Whether the strip shows: a proposal trying, or what became of it.
    var showsStrip: Bool { trying != nil || stripMessage != nil }

    /// "Trying Warm. Accent, Card radius."
    func tryingLine(_ proposal: Proposal) -> String {
        let titles = changes(proposal).map(\.title)
        return "Trying \(proposal.name)." + (titles.isEmpty ? "" : " \(titles.joined(separator: ", ")).")
    }

    /// A place's title; Notes counts what is new from the agent.
    func title(_ place: Place) -> String {
        place == .notes && unseen > 0 ? "\(place.title) (\(unseen))" : place.title
    }

    /// The strip's name: Notes, scrolled to the proposal.
    func stripNameTapped() {
        guard let trying else { return }
        place = .notes
        scrollTarget = Row.proposal(trying).id
    }

    /// Tries every proposal that asks to be applied and was never tried,
    /// oldest first, so the newest is the one on the device.
    func tryArrivals() {
        for proposal in agent.proposals.sorted(by: { $0.date < $1.date }) where proposal.needsTry(in: history) {
            tryProposal(proposal)
        }
    }

    /// Puts the proposal on the device as a version by the agent, merged
    /// over the base at this moment.
    private func tryProposal(_ proposal: Proposal) {
        guard let base = tryBase, let design = try? proposal.design(over: base.design) else { return }
        changeHistory { $0.tryProposal(proposal.id, design: design) }
        apply(design)
        refreshContext()
    }
}
#endif
