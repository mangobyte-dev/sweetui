#if canImport(UIKit)
import SwiftUI
import SweetUIFoundations

/// Notes: when the agent last read them, then each thread oldest first (the
/// note, the agent's answer, the proposals that answer it, the replies), then
/// the proposals that answer no note. The card pins the composer under it,
/// beside its own bottom bar: an inset inside the card's navigation stack
/// would sit behind that bar.
struct NotesPlace: View {
    @Bindable var model: TuneModel

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                let threads = model.threads
                Section {
                    if threads.isEmpty {
                        Text("Select an item, then say what is wrong. The agent reads your notes and answers here.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(verbatim: model.readLine)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("tuning.notes.read")
                    }
                    if let error = model.agentFileError {
                        Text(verbatim: error)
                            .font(.footnote)
                    }
                }
                ForEach(threads) { thread in
                    Section {
                        ForEach(thread.rows) { row in
                            rowView(row).id(row.id)
                        }
                    }
                }
            }
            .accessibilityIdentifier("tuning.form")
            .onAppear {
                model.notesSeen()
                scroll(proxy, to: model.scrollTarget ?? model.threads.last?.rows.last?.id, animated: false)
            }
            .onChange(of: model.scrollTarget) { _, target in
                scroll(proxy, to: target, animated: true)
            }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, to id: String?, animated: Bool) {
        guard let id else { return }
        withAnimation(animated ? ToolChrome.animation : nil) { proxy.scrollTo(id, anchor: .bottom) }
        model.scrollTarget = nil
    }

    @ViewBuilder
    private func rowView(_ row: TuneModel.Row) -> some View {
        switch row {
        case .note(let note):
            NoteRow(
                note: note, subject: model.subject(note), status: model.status(note), replyLine: model.replyLine(note),
                selectSubject: { model.subjectTapped(note) },
                reply: { model.replyButtonTapped(note: note) },
                delete: { withAnimation(ToolChrome.animation) { model.deleteNote(note.id) } })
        case .answer(_, let answer):
            AnswerRow(answer: answer)
        case .proposal(let proposal):
            ProposalRow(
                proposal: proposal, state: proposal.state(in: model.history), changes: model.changes(proposal),
                unreadable: model.unreadable(proposal),
                try: { withAnimation(ToolChrome.animation) { model.tryButtonTapped(proposal.id) } },
                keep: { withAnimation(ToolChrome.animation) { model.keepButtonTapped() } },
                discard: {
                    withAnimation(ToolChrome.animation) {
                        if proposal.state(in: model.history) == .trying {
                            model.discardButtonTapped()
                        } else {
                            model.discardOfferedTapped(proposal.id)
                        }
                    }
                },
                reply: { model.replyButtonTapped(proposal: proposal) })
        }
    }
}

/// One note: what it replies to, its subject (a tap selects the item), the
/// text, when it was sent and whether the agent read or answered it, and
/// Reply. Delete is a swipe that never runs on its own, mirrored as an
/// accessibility action.
private struct NoteRow: View {
    let note: DesignNote
    let subject: String
    let status: String
    /// "Reply to Warm"; `nil` for a note that follows nothing.
    let replyLine: String?
    let selectSubject: () -> Void
    let reply: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: ToolChrome.compactSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                if let replyLine {
                    Label(replyLine, systemImage: "arrowshape.turn.up.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if note.item != nil {
                    Button(action: selectSubject) {
                        Text(verbatim: subject)
                            .font(.footnote.weight(.semibold))
                            .frame(minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Selects it on the app.")
                    .accessibilityIdentifier("tuning.note.\(note.id.uuidString).subject")
                } else {
                    Text(verbatim: subject)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: note.text)
                    Text(verbatim: details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAction(named: "Delete", delete)
                .accessibilityIdentifier("tuning.note.\(note.id.uuidString)")
            }
            Spacer(minLength: 0)
            // Gray, not the tint's own secondary, so Send stays the one tinted control in Notes.
            Button(action: reply) {
                Label("Reply", systemImage: "arrowshape.turn.up.left").barTarget().foregroundStyle(Color.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(verbatim: "Reply to your note about \(subject)"))
            .accessibilityIdentifier("tuning.note.\(note.id.uuidString).reply")
        }
        .swipeActions(allowsFullSwipe: false) {
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
        }
    }

    private var details: String {
        let time = note.createdAt.formatted(date: .omitted, time: .shortened)
        return "\(time) · \(status)" + (note.screenshot == nil ? " · No screenshot" : "")
    }
}

/// The agent's answer under its note: the reply and the files it changed.
private struct AnswerRow: View {
    let answer: AgentRecord.Answer

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text(verbatim: answer.reply)
            } icon: {
                Image(systemName: "sparkles").accessibilityHidden(true)
            }
            .font(.footnote)
            if !answer.changedFiles.isEmpty {
                Text(verbatim: answer.changedFiles.joined(separator: ", "))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The agent answered: \(answer.reply)")
        .accessibilityValue(answer.changedFiles.isEmpty ? "" : "Changed \(answer.changedFiles.joined(separator: ", ")).")
    }
}

/// A design the agent offers: its name and reason, what it changes in words,
/// and the actions its state allows. A proposal Tune cannot read says why
/// and cannot be tried.
private struct ProposalRow: View {
    let proposal: Proposal
    let state: Proposal.State
    let changes: [DesignChanges.Change]
    let unreadable: String?
    let `try`: () -> Void
    let keep: () -> Void
    let discard: () -> Void
    let reply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ToolChrome.compactSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                Label {
                    Text(verbatim: proposal.name).font(.headline)
                } icon: {
                    Image(systemName: "sparkles").accessibilityHidden(true)
                }
                if let reason = proposal.reason {
                    Text(verbatim: reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let unreadable {
                    Text(verbatim: unreadable)
                        .font(.footnote)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Proposal from the agent: \(proposal.name). \(stateWord).")
            .accessibilityValue([proposal.reason, unreadable].compactMap { $0 }.joined(separator: " "))
            .accessibilityIdentifier("tuning.proposal.\(proposal.id)")
            if !changes.isEmpty {
                DisclosureGroup {
                    ForEach(changes) { change in
                        Text(verbatim: change.words)
                            .font(.footnote)
                    }
                } label: {
                    Text("Changes (\(changes.count))")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("tuning.proposal.\(proposal.id).changes")
            }
            HStack(spacing: ToolChrome.spacing) {
                switch state {
                case .offered:
                    action("Try", "Try \(proposal.name)", "try", `try`)
                        .disabled(unreadable != nil)
                        .accessibilityHint(unreadable ?? "")
                    action("Discard", "Discard \(proposal.name)", "discard", discard)
                case .trying:
                    Text("Trying").foregroundStyle(.secondary)
                    action("Keep", "Keep \(proposal.name)", "keep", keep)
                    action("Discard", "Discard \(proposal.name)", "discard", discard)
                case .kept:
                    Text("Kept").foregroundStyle(.secondary)
                case .discarded:
                    Text("Discarded").foregroundStyle(.secondary)
                    action("Try again", "Try \(proposal.name) again", "try", `try`)
                        .disabled(unreadable != nil)
                        .accessibilityHint(unreadable ?? "")
                }
                Spacer(minLength: 0)
                // Gray, not the tint's own secondary, so Send stays the one tinted control in Notes.
                Button(action: reply) {
                    Label("Reply", systemImage: "arrowshape.turn.up.left").barTarget().foregroundStyle(Color.secondary)
                }
                .accessibilityLabel(Text(verbatim: "Reply to \(proposal.name)"))
                .accessibilityIdentifier("tuning.proposal.\(proposal.id).reply")
            }
            .buttonStyle(.borderless)
        }
    }

    /// A text button with the whole 44 point height as its target, labeled
    /// with the proposal it acts on, so repeated rows read apart.
    private func action(
        _ title: LocalizedStringKey, _ label: String, _ id: String, _ perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Text(title)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityIdentifier("tuning.proposal.\(proposal.id).\(id)")
    }

    private var stateWord: String {
        switch state {
        case .offered: "Offered"
        case .trying: "Trying"
        case .kept: "Kept"
        case .discarded: "Discarded"
        }
    }
}

/// The composer pinned under Notes: what the note is about, or the note or
/// proposal it replies to with Cancel, the field, and Send. In a card too
/// short to keep 120 pt for the place, the subject line goes; the field's
/// hint still names it.
struct NotesComposer: View {
    @Bindable var model: TuneModel
    var compact = false
    /// The composer is the card's last row, over the resize grip's corner.
    var clearsGrip = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let target = model.replyTarget {
                HStack {
                    Text(verbatim: "Replying to: \(target.label)")
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button {
                        model.cancelReplyTapped()
                    } label: {
                        Text("Cancel reply")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("tuning.composer.cancel")
                }
                .font(.footnote)
            } else if !compact {
                Text(verbatim: "About \(model.composerSubject)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let error = model.noteSaveError {
                Text(verbatim: error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            HStack(alignment: .bottom) {
                TextField(
                    model.replyTarget.map { "Reply to \($0.label)" } ?? "Say what is wrong", text: $model.noteDraft,
                    axis: .vertical)
                    .lineLimit(1...4)
                    .focused($fieldFocused)
                    // The field's row is a 44 pt target: a tap beside the text focuses it.
                    .frame(minHeight: 44)
                    .background {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { fieldFocused = true }
                    }
                    .accessibilityLabel(model.replyTarget == nil ? "Note" : "Reply")
                    .accessibilityHint("About \(model.composerSubject).")
                    .accessibilityIdentifier("tuning.composer.field")
                Button {
                    model.sendButtonTapped()
                } label: {
                    Label("Send", systemImage: "paperplane.fill").barTarget()
                }
                .buttonStyle(.borderless)
                .disabled(!model.canSend)
                .accessibilityIdentifier("tuning.composer.send")
            }
        }
        .modifier(BottomRowInsets(inset: ToolChrome.spacing, clearsGrip: clearsGrip))
        .padding(.vertical, compact ? 4 : ToolChrome.compactSpacing)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        // A field in Tune's window takes focus only while that window is key.
        .onChange(of: model.composerFocused, initial: true) { _, focused in
            if focused { DesignSurfaceWindow.shared.setKey(true) }
            fieldFocused = focused
        }
        .onChange(of: fieldFocused) { _, focused in
            model.composerFocused = focused
        }
    }
}
#endif
