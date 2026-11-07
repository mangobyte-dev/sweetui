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
                note: note, subject: model.subject(note), status: model.status(note),
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

/// One note: its subject (a tap selects the item), the text, when it was
/// sent and whether the agent read or answered it, and Reply. Delete is a
/// swipe, mirrored as an accessibility action.
private struct NoteRow: View {
    let note: DesignNote
    let subject: String
    let status: String
    let selectSubject: () -> Void
    let reply: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: ToolChrome.compactSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                if note.item != nil {
                    Button(action: selectSubject) {
                        Text(verbatim: subject)
                            .font(.footnote.weight(.semibold))
                            .frame(minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Selects it on the app.")
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
            Button(action: reply) {
                Label("Reply", systemImage: "arrowshape.turn.up.left").barTarget()
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("tuning.note.\(note.id.uuidString).reply")
        }
        .swipeActions {
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
            }
            HStack(spacing: ToolChrome.spacing) {
                switch state {
                case .offered:
                    action("Try", "try", `try`)
                        .disabled(unreadable != nil)
                    action("Discard", "discard", discard)
                case .trying:
                    Text("Trying").foregroundStyle(.secondary)
                    action("Keep", "keep", keep)
                    action("Discard", "discard", discard)
                case .kept:
                    Text("Kept").foregroundStyle(.secondary)
                case .discarded:
                    Text("Discarded").foregroundStyle(.secondary)
                    action("Try again", "try", `try`)
                        .disabled(unreadable != nil)
                }
                Spacer(minLength: 0)
                Button(action: reply) {
                    Label("Reply", systemImage: "arrowshape.turn.up.left").barTarget()
                }
                .accessibilityIdentifier("tuning.proposal.\(proposal.id).reply")
            }
            .buttonStyle(.borderless)
        }
    }

    /// A text button with the whole 44 point height as its target.
    private func action(_ title: LocalizedStringKey, _ id: String, _ perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            Text(title)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
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
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let target = model.replyTarget {
                HStack {
                    Text(verbatim: "Replying to: \(target.label)")
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Button("Cancel") { model.cancelReplyTapped() }
                        .buttonStyle(.borderless)
                        .frame(minHeight: 44)
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
            }
            HStack(alignment: .bottom) {
                TextField("Say what is wrong", text: $model.noteDraft, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($fieldFocused)
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
        .padding(.horizontal, ToolChrome.spacing)
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
