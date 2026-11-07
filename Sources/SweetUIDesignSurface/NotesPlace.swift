#if canImport(UIKit)
import SwiftUI
import SweetUIFoundations

/// Notes: what the agent last changed, the notes with the composer, and the
/// variants the agent staged.
struct NotesPlace: View {
    @Bindable var model: TuneModel

    var body: some View {
        Form {
            AgentChangeSection(model: model)
            NotesSection(model: model)
            VariantsSection(model: model)
        }
        .accessibilityIdentifier("tuning.form")
    }
}

/// What the agent last wrote to the device, read from the record MCP
/// `set_tuning` and `set_knobs` leave beside the files; the app already
/// shows the change itself through the file watch. Undo restores the
/// previous values; Keep keeps them. Both clear the record.
private struct AgentChangeSection: View {
    let model: TuneModel

    var body: some View {
        if let change = model.agentChange {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(change.summary)
                    Text(change.changedAt, format: .dateTime.hour().minute().second())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("tuning.agentChange")
                HStack {
                    Button("Undo", systemImage: "arrow.uturn.backward") {
                        withAnimation(ToolChrome.animation) { model.undoAgentChangeTapped() }
                    }
                    .accessibilityIdentifier("tuning.agentChange.undo")
                    Spacer()
                    Button("Keep", systemImage: "checkmark") { model.keepAgentChangeTapped() }
                        .accessibilityIdentifier("tuning.agentChange.keep")
                }
                .buttonStyle(.borderless)
            } header: {
                Text("From the agent")
            }
        }
    }
}

/// The notes a person leaves for the agent, about the selected item or,
/// with nothing selected, the screen. Open notes list newest first with what
/// they are about; an answered note stays in the file for the agent and
/// leaves the list. The composer under them saves a note with a screenshot.
private struct NotesSection: View {
    @Bindable var model: TuneModel
    @FocusState private var fieldFocused: Bool

    private var open: [DesignNote] { model.notes.filter { !$0.resolved }.reversed() }
    private var answered: [DesignNote] { model.notes.filter(\.resolved).reversed() }

    private func about(_ note: DesignNote) -> String {
        note.item.map(model.stage.title) ?? note.screen ?? "Screen"
    }

    var body: some View {
        Section {
            ForEach(open) { note in
                NoteRow(note: note, about: about(note))
                    .accessibilityIdentifier("tuning.note.\(note.id)")
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) { model.deleteNote(note.id) }
                    }
            }
            if !answered.isEmpty {
                DisclosureGroup("Answered (\(answered.count))") {
                    ForEach(answered) { note in
                        NoteRow(note: note, about: about(note))
                            .accessibilityIdentifier("tuning.note.\(note.id)")
                            .swipeActions {
                                Button("Reopen", systemImage: "arrow.uturn.backward") { model.reopenNote(note.id) }
                                    .tint(ToolChrome.accent)
                                Button("Delete", systemImage: "trash", role: .destructive) { model.deleteNote(note.id) }
                            }
                    }
                }
                .accessibilityIdentifier("tuning.notes.answered")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("About \(model.composerSubject)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(alignment: .bottom) {
                    TextField("Say what is wrong", text: $model.noteDraft, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($fieldFocused)
                        .accessibilityLabel("Note")
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
        } header: {
            Text("Notes for the agent")
        } footer: {
            Text("Saved to design-notes.json beside the tokens, with the item, the tokens it reads, its knobs, the preset code, and a screenshot under notes/. The screen's items and frames are in design-context.json.")
        }
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

/// One note: its text, what it is about, and the agent's reply once it
/// has one, with the files the agent changed.
private struct NoteRow: View {
    let note: DesignNote
    let about: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(note.text)
            Text(verbatim: about)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let reply = note.reply {
                Label(reply, systemImage: "arrowshape.turn.up.left")
                    .font(.footnote)
                    .padding(.top, 2)
                if let files = note.changedFiles, !files.isEmpty {
                    Text(files.joined(separator: ", "))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The themes an agent staged in `design-variants.json`, one chip each; a
/// tap applies the code and records the pick as `chosen`. Hidden until the
/// file names a variant. A chip reads selected while the knobs still match
/// its code, so a knob moved afterwards clears it without clearing the pick.
private struct VariantsSection: View {
    let model: TuneModel

    var body: some View {
        let variants = model.variants
        if !variants.variants.isEmpty {
            Section {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(variants.variants) { variant in
                            VariantChip(variant: variant, isCurrent: variants.matching(model.tuning)?.name == variant.name) {
                                withAnimation(ToolChrome.animation) { model.variantChipTapped(variant) }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("Variants from the agent")
            } footer: {
                Text(variants.chosen.map { "Chosen: \($0). The pick is written to design-variants.json." }
                    ?? "Staged in design-variants.json. A tap applies the code and records the pick.")
            }
        }
    }
}

private struct VariantChip: View {
    let variant: DesignVariants.Variant
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        // A native style, not the registry button item: the panel is a
        // package product and items are copied source.
        Button(variant.name, action: action)
            .buttonStyle(isCurrent ? AnyButtonStyle(.borderedProminent) : AnyButtonStyle(.bordered))
            .controlSize(.small)
            .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
            .accessibilityIdentifier("tuning.variant.\(variant.name)")
    }
}

/// A button style chosen at runtime, erased once so the chip's chain stays one expression.
private struct AnyButtonStyle: PrimitiveButtonStyle {
    private let make: (Configuration) -> AnyView

    init<Style: PrimitiveButtonStyle>(_ style: Style) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}
#endif
