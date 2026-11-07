#if canImport(UIKit)
import SwiftUI

/// Versions: the history, the code and the Swift, and the hand-off. A host
/// that paints the items from its own tokens keeps the history and the
/// hand-off for its knobs, without the code and the Swift.
struct VersionsPlace: View {
    @Bindable var model: TuneModel

    var body: some View {
        Form {
            HistorySection(model: model)
            if model.stage.tunesTheme {
                ExportSection(tuning: model.tuning)
            }
            HandoffSection(model: model)
        }
        .accessibilityIdentifier("tuning.form")
    }
}

/// Every settled version of the design on this device: a name marks Current
/// so it can be restored by name, and Compare to shipped lists each knob that
/// differs from the defaults. Undo and Redo sit in the bottom bar.
private struct HistorySection: View {
    @Bindable var model: TuneModel

    private var differences: [ThemeTuning.Difference] { model.tuning.differences(from: .default) }

    var body: some View {
        let history = model.history
        Section {
            HStack {
                TextField("Name this state", text: $model.versionName)
                    .accessibilityLabel("Name")
                    .accessibilityIdentifier("tuning.history.name")
                Button("Checkpoint") { model.nameButtonTapped() }
                    .buttonStyle(.borderless)
                    .disabled(model.versionName.trimmingCharacters(in: .whitespaces).isEmpty || history.current == nil)
                    .accessibilityIdentifier("tuning.history.checkpoint")
            }
            ForEach(history.named) { entry in
                Button {
                    withAnimation(ToolChrome.animation) { model.restore(entry.id) }
                } label: {
                    LabeledContent {
                        if history.current == entry.id {
                            Image(systemName: "checkmark").foregroundStyle(.tint).accessibilityHidden(true)
                        }
                    } label: {
                        Text(verbatim: entry.name ?? "")
                        Text(entry.date, format: .dateTime.hour().minute())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(history.current == entry.id ? [.isSelected] : [])
                .accessibilityIdentifier("tuning.history.restore")
            }
            DisclosureGroup("Compare to shipped (\(differences.count))") {
                if differences.isEmpty {
                    Text("Every knob is at its shipped value.")
                        .foregroundStyle(.secondary)
                }
                ForEach(differences, id: \.key) { difference in
                    LabeledContent(difference.key) {
                        Text(verbatim: "\(difference.from) → \(difference.to)")
                            .font(.footnote.monospaced())
                    }
                    .accessibilityIdentifier("tuning.history.difference.\(difference.key)")
                }
            }
            .accessibilityIdentifier("tuning.history.compare")
        } header: {
            Text("History")
        } footer: {
            Text("Every settled change is kept in design-history.json, by the person, the agent, or a variant.")
        }
    }
}

/// The device to code hand-off: one tap writes design-handoff.json with the
/// theme, the chosen variant, the moved knobs, the open notes, and the
/// checkpoints, and takes a screenshot; the agent reads it with read_handoff
/// and writes the theme and the knob defaults into source.
private struct HandoffSection: View {
    let model: TuneModel

    var body: some View {
        Section {
            Button("Send to agent", systemImage: "paperplane") { model.handOffButtonTapped() }
                .accessibilityIdentifier("tuning.handoff")
            if let sentAt = model.handOffSentAt {
                LabeledContent("Sent") {
                    Text(sentAt, format: .dateTime.hour().minute().second())
                }
                .accessibilityIdentifier("tuning.handoff.sent")
            }
        } header: {
            Text("Hand off")
        } footer: {
            Text("Writes design-handoff.json: the theme as a code and as Swift, the chosen variant, the moved knobs, the open notes, and the checkpoints. The agent reads it with read_handoff and writes the theme and the knob defaults into source.")
        }
    }
}
#endif
