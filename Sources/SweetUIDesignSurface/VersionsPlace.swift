#if canImport(UIKit)
import SwiftUI

/// Versions: Current (what it is, what it changes, the Checks, the open
/// notes, its name, its code and Swift), Hand off with its status, and the
/// history newest first, where a tap restores a version. A host that paints
/// the items from its own tokens keeps the place for its knobs, without the
/// Checks, the code, and the Swift.
struct VersionsPlace: View {
    @Bindable var model: TuneModel

    var body: some View {
        Form {
            if let current = model.current {
                CurrentSection(model: model, current: current)
            }
            HandOffSection(model: model)
            HistorySection(model: model)
        }
        .accessibilityIdentifier("tuning.form")
        .onAppear { model.versionsSeen() }
        .onChange(of: model.history.current, initial: true) { model.currentChanged() }
    }
}

/// The version on the device: its label, author, and time, the proposal
/// trying, its changes in words (Source as a state), the Checks and the
/// open notes as links, the Name field, and Copy code, Copy Swift, and the
/// Swift to read.
private struct CurrentSection: View {
    @Bindable var model: TuneModel
    let current: DesignHistory.Entry

    var body: some View {
        Section("Current") {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: model.label(current))
                    .font(.headline)
                Text(verbatim: "\(current.author == .agent ? "By the agent" : "By you") · \(model.time(current))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let trying = model.trying {
                    Text(verbatim: "Trying \(trying.name)")
                        .font(.footnote.weight(.semibold))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("tuning.version.current")
            if let source = model.sourceLine {
                Text(verbatim: source)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            }
            if let changes = model.changesFromParent(current) {
                ChangesRow(title: "From the version before", changes: changes)
            }
            if let changes = model.changesFromDefault {
                ChangesRow(title: "From default", changes: changes)
            }
            if let checks = model.checksLine {
                LinkRow(text: checks, hint: "Shows the Checks in Tokens.") {
                    withAnimation(ToolChrome.animation) { model.checksLineTapped() }
                }
            }
            if let open = model.openNotesLine {
                LinkRow(text: open, hint: "Shows them in Notes.") {
                    withAnimation(ToolChrome.animation) { model.openNotesLineTapped() }
                }
            }
            TextField("Name", text: $model.versionName, prompt: Text("Name this version"))
                .submitLabel(.done)
                .onSubmit { model.nameSubmitted() }
                .frame(minHeight: 44)
                .accessibilityLabel("Name")
                .accessibilityHint("Return names the current version.")
                .accessibilityIdentifier("tuning.version.name")
            if model.stage.tunesTheme {
                CodeRows(tuning: model.tuning, isSource: model.liveDesign.code.isEmpty)
            }
        }
    }
}

/// A count of changes that opens to the changes in words.
private struct ChangesRow: View {
    let title: String
    let changes: [DesignChanges.Change]

    var body: some View {
        let label = "\(title) (\(changes.count))"
        if changes.isEmpty {
            Text(verbatim: label)
                .foregroundStyle(.secondary)
                .frame(minHeight: 44)
        } else {
            DisclosureGroup {
                ForEach(changes) { change in
                    Text(verbatim: change.words)
                        .font(.footnote)
                }
            } label: {
                Text(verbatim: label)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
    }
}

/// A line that takes the person to another place, as Tokens' item links do.
private struct LinkRow: View {
    let text: String
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: text)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .accessibilityHint(hint)
    }
}

/// Hand off, the place's one prominent control, and where the last hand-off
/// stands: not read yet, read, Shipped with the files changed, the agent's
/// answer, or why it did not save.
private struct HandOffSection: View {
    let model: TuneModel

    var body: some View {
        Section {
            Button {
                withAnimation(ToolChrome.animation) { model.handOffButtonTapped() }
            } label: {
                Label("Hand off", systemImage: "paperplane")
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(hint)
            .accessibilityIdentifier("tuning.handoff")
            if let status = model.handOffStatus {
                Text(verbatim: status.text)
                    .font(.footnote)
                    .accessibilityIdentifier("tuning.handoff.status")
            }
        } footer: {
            Text("The agent puts the design into source. Once it answers with the files it changed, Tune clears its overrides so the source shows.")
        }
    }

    private var hint: String {
        let send = "Sends the design and the open notes to the agent."
        return model.trying.map { "Keeps \($0.name) first. \(send)" } ?? send
    }
}

/// Every version on this device, newest first; a tap restores one and
/// deletes nothing.
private struct HistorySection: View {
    let model: TuneModel

    var body: some View {
        let rows = model.historyRows
        Section {
            if rows.count <= 1 {
                Text("This is the first version. Changes land here as you make them.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(rows) { row in
                VersionRow(
                    label: model.label(row.entry), author: row.entry.author, time: model.time(row.entry),
                    changeCount: model.changesFromParent(row.entry)?.count,
                    branch: row.branch.map { "from \(model.label($0)) at \(model.time($0))" },
                    isCurrent: row.entry.id == model.history.current
                ) {
                    withAnimation(ToolChrome.animation) { model.restore(row.entry.id) }
                }
                .accessibilityIdentifier("tuning.version.\(row.entry.id.uuidString)")
            }
        } header: {
            Text("History")
        }
    }
}

/// One version: who made it, its label, when, how much it changed, where
/// it came from on a branch, and a check on Current.
private struct VersionRow: View {
    let label: String
    let author: DesignHistory.Author
    let time: String
    /// Changes from the version it came from; `nil` for a root, and for
    /// Source with no knob moved.
    let changeCount: Int?
    let branch: String?
    let isCurrent: Bool
    let restore: () -> Void

    var body: some View {
        Button(action: restore) {
            HStack(spacing: ToolChrome.compactSpacing) {
                Image(systemName: author == .agent ? "sparkles" : "person.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: label)
                    Text(verbatim: ([time] + details).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), by \(author == .agent ? "the agent" : "you"), \(time)")
        .accessibilityValue(details.joined(separator: ", "))
        .accessibilityHint("Makes it current.")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    /// "2 changes", "from Mango at 10:40".
    private var details: [String] {
        var words: [String] = []
        switch changeCount {
        case nil: break
        case 0: words.append("No changes")
        case 1: words.append("1 change")
        case let count?: words.append("\(count) changes")
        }
        if let branch { words.append(branch) }
        return words
    }
}
#endif
