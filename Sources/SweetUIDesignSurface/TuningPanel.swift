#if canImport(UIKit)
import Sharing
import SwiftUI
import SweetUIFoundations

/// The theme tuning panel: every foundation token as a live control, the
/// preset code that names the result, and the exact Swift to paste once at
/// an app root. It stays up beside the catalog, an inspector column on iPad
/// and a sheet the catalog remains interactive under on iPhone, so a change
/// shows on the demo behind it at once.
public struct TuningPanel<PresetsFooter: View>: View {
    @Binding var tuning: ThemeTuning
    let presetsFooter: PresetsFooter
    /// The item scope, when the host is a design surface: `nil` shows every
    /// section and no Select control, as the Showcase's previews and tests do.
    private let selection: Binding<ItemSelection>?
    /// Shows the On this screen section from the tool state: the screen's
    /// name, the items on it, and the outline switch. Off for a host that
    /// embeds the panel without the window.
    private let showsScreen: Bool
    @State private var isImporting = false
    /// The item names pushed as host pages.
    @State private var path: [String] = []

    /// The panel over the tuning it edits. `presetsFooter` is the host's own
    /// row under the preset chips, such as a link to a sample design system.
    public init(
        tuning: Binding<ThemeTuning>,
        selection: Binding<ItemSelection>? = nil,
        showsScreen: Bool = false,
        @ViewBuilder presetsFooter: () -> PresetsFooter
    ) {
        _tuning = tuning
        self.selection = selection
        self.showsScreen = showsScreen
        self.presetsFooter = presetsFooter()
    }

    /// The tokens the selected item reads, or `nil` for the whole theme.
    private var scope: Set<String>? {
        guard let item = selection?.wrappedValue.item,
              let tokens = RegistryItemTokens.tokens(for: item) else { return nil }
        return Set(tokens)
    }

    /// Off for a host that paints the items from its own tokens: the theme
    /// sections would move nothing there.
    private var tunesTheme: Bool { !showsScreen || DesignSurfaceState.shared.tunesTheme }

    /// Whether a section whose knobs are `tokens` reaches the selected item.
    private func shows(_ tokens: Set<String>) -> Bool {
        guard let scope else { return true }
        return !scope.isDisjoint(with: tokens)
    }

    public var body: some View {
        if showsScreen, let wrap = DesignSurfaceState.shared.panelWrap {
            wrap(AnyView(stack))
        } else {
            stack
        }
    }

    private var stack: some View {
        NavigationStack(path: $path) {
            Form {
                if showsScreen {
                    AgentChangeSection(tuning: $tuning)
                }
                if showsScreen, let selection {
                    OnThisScreenSection(selection: selection)
                }
                if let selection, let item = selection.wrappedValue.item {
                    // A host with its own tokens shows its own selection rows.
                    if tunesTheme {
                        ScopeSection(item: item, tokenCount: scope?.count ?? 0) {
                            withAnimation(ToolChrome.animation) { selection.wrappedValue.item = nil }
                        }
                    }
                    if showsScreen {
                        ItemKnobsSection(item: item)
                    }
                }
                if showsScreen, let selection {
                    NotesSection(selection: selection.wrappedValue, tuning: tuning)
                }
                if showsScreen, let host = DesignSurfaceState.shared.hostTokens {
                    HostTokensSection(store: host)
                }
                if showsScreen, let host = DesignSurfaceState.shared.hostSections {
                    host(selection?.wrappedValue.chain ?? [])
                }
                if showsScreen && tunesTheme {
                    HistorySection(tuning: $tuning)
                }
                if tunesTheme {
                    PresetsSection(tuning: $tuning, footer: presetsFooter)
                    if showsScreen { VariantsSection(tuning: $tuning) }
                    ExportSection(tuning: tuning)
                    ContrastSection(tuning: $tuning)
                    AccentSection(tuning: $tuning)
                    TypographySection(tuning: $tuning)
                    if shows(PanelScope.surface) { SurfaceSection(tuning: $tuning) }
                    if shows(["chartPalette"]) { ChartSection(tuning: $tuning) }
                    if shows(PanelScope.radius.union(PanelScope.spacing)) { DensitySection(tuning: $tuning) }
                    if shows(PanelScope.radius) { RadiusSection(tuning: $tuning) }
                    if shows(PanelScope.spacing) { SpacingSection(tuning: $tuning) }
                    ColorsSection(tuning: $tuning)
                    if shows(["disabledOpacity"]) { StateSection(tuning: $tuning) }
                    EnvironmentSection(tuning: $tuning)
                }
            }
            .accessibilityIdentifier("tuning.form")
            // The floating card is its own label (the drag bar says so), and
            // at its minimum width the four toolbar controls need the room a
            // title would take (measured 2026-09-08: "Tune" truncated to "Tu"
            // at 300 points); the embedded panel keeps its title.
            .navigationTitle(showsScreen ? "" : "Tune")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: String.self) { name in
                if let page = DesignSurfaceState.shared.hostPage?(name) { page } else { Text(verbatim: name) }
            }
            // A pick lands on the innermost item the host has a page for; an
            // item without one leaves the panel on its form.
            .onChange(of: selection?.wrappedValue.chain ?? []) { _, chain in
                guard showsScreen, let hostPage = DesignSurfaceState.shared.hostPage,
                      let name = chain.first(where: { hostPage($0) != nil }) else { return }
                path = [name]
            }
            // Clearing the selection (All tokens, a pick on nothing) also
            // leaves a pushed host page, which was about the selected item.
            .onChange(of: selection?.wrappedValue.item) { _, item in
                if item == nil { path = [] }
            }
            .sheet(isPresented: $isImporting, onDismiss: { if showsScreen { DesignSurfaceWindow.shared.setKey(false) } }) {
                ImportThemeSheet(apply: applyImport)
            }
            .toolbar {
                if tunesTheme {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Reset", action: reset)
                    }
                }
                if let selection {
                    ToolbarItem(placement: .topBarLeading) {
                        // Arms the next tap on the content to pick the item under it.
                        Button("Select", systemImage: "scope") {
                            withAnimation(ToolChrome.animation) { selection.wrappedValue.isSelecting.toggle() }
                        }
                        .accessibilityIdentifier("tuning.select")
                        .accessibilityAddTraits(selection.wrappedValue.isSelecting ? [.isSelected] : [])
                    }
                }
                if tunesTheme {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Import", systemImage: "square.and.arrow.down", action: beginImport)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        CopyButton("Copy Swift", text: tuning.swiftSource)
                    }
                }
            }
        }
    }

    private func reset() {
        withAnimation(ToolChrome.animation) { tuning = .default }
    }

    private func beginImport() {
        // A field inside a sheet takes focus only in the key window.
        if showsScreen { DesignSurfaceWindow.shared.setKey(true) }
        isImporting = true
    }

    /// Applies a pasted code or initializer; `false` leaves the sheet up to show the failure.
    private func applyImport(_ text: String) -> Bool {
        guard let parsed = ThemeTuning.parse(text, into: tuning) else { return false }
        withAnimation(ToolChrome.animation) { tuning = parsed }
        return true
    }
}

extension TuningPanel where PresetsFooter == EmptyView {
    public init(tuning: Binding<ThemeTuning>) {
        self.init(tuning: tuning) { EmptyView() }
    }
}

/// The selected item's own knobs, registered by the host, as sliders bound to
/// the knob store; a value at its shipped default leaves the file.
private struct ItemKnobsSection: View {
    let item: String
    private let knobs = DesignSurfaceState.shared.knobs

    var body: some View {
        let specs = knobs.knobs(for: item)
        if !specs.isEmpty {
            Section {
                ForEach(specs) { knob in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(knob.title)
                            Spacer()
                            Text(knobs.value(item, knob), format: .number.precision(.fractionLength(knob.step < 1 ? 2 : 0)))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        Slider(
                            value: Binding(
                                get: { knobs.value(item, knob) },
                                set: { knobs.set(item, knob, to: $0) }),
                            in: knob.range, step: knob.step
                        ) { Text(knob.title) }
                        .accessibilityIdentifier("tuning.knob.\(item).\(knob.name)")
                    }
                }
                Button("Reset these knobs") { knobs.reset(item) }
                    .accessibilityIdentifier("tuning.knob.reset")
            } header: {
                Text("\(item) knobs")
            }
        }
    }
}

/// The host's own token document: one row per page, each pushing the page's
/// knobs, and a reset for the whole document.
private struct HostTokensSection: View {
    let store: any AnyTokenStore

    var body: some View {
        Section("App tokens") {
            ForEach(Array(store.pageTitles.enumerated()), id: \.offset) { index, title in
                NavigationLink(title) {
                    Form { store.page(index) }
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .accessibilityIdentifier("tuning.tokens.\(index)")
            }
            Button("Reset the app tokens", role: .destructive) { store.reset() }
        }
    }
}

/// The knobs each scoped section moves, as the token names the generated
/// `RegistryItemTokens` map uses; a section shows when the selected item reads
/// any of them. Accent, typography, and the color pairs reach every item
/// through the root modifier, so their sections never scope out.
private enum PanelScope {
    static let surface: Set<String> = [
        "surface", "border", "borderWidth", "emphasizedBorderWidth", "surfaceOpacity", "surfaceStep",
    ]
    static let radius: Set<String> = ["compactRadius", "controlRadius", "cardRadius"]
    static let spacing: Set<String> = [
        "compactSpacing", "standardSpacing", "sectionSpacing", "controlHorizontalPadding",
    ]
}

/// The screen under the tool and the registry items on it, top to bottom:
/// a row selects its item, and the switch outlines every piece over the app.
private struct OnThisScreenSection: View {
    let selection: Binding<ItemSelection>
    private let state = DesignSurfaceState.shared

    var body: some View {
        Section {
            let items = state.visibleItemNames
            if items.isEmpty {
                Text("No registry item is on this screen.")
                    .foregroundStyle(.secondary)
            }
            ForEach(items, id: \.name) { item in
                Button {
                    withAnimation(ToolChrome.animation) {
                        selection.wrappedValue.item = item.name
                        selection.wrappedValue.chain = [item.name]
                    }
                } label: {
                    HStack {
                        Text(verbatim: state.title(item.name))
                        if item.count > 1 {
                            Text("\(item.count)").foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selection.wrappedValue.item == item.name {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("tuning.screen.\(item.name)")
            }
            Toggle("Outline the pieces", isOn: Binding(
                get: { state.showsOutlines }, set: { state.showsOutlines = $0 }))
                .accessibilityIdentifier("tuning.outlines")
        } header: {
            Text(state.screen ?? "On this screen")
                .accessibilityIdentifier("tuning.screen")
        }
    }
}

/// The selected item's name and how many of the theme's tokens reach it, with
/// the way back to the whole theme.
private struct ScopeSection: View {
    let item: String
    let tokenCount: Int
    let showAll: () -> Void

    var body: some View {
        Section("Selected item") {
            LabeledContent {
                Button("All tokens", action: showAll)
                    .accessibilityIdentifier("tuning.scope.all")
            } label: {
                Text(verbatim: item)
                    .font(.body.monospaced())
                    .accessibilityIdentifier("tuning.scope.item")
                Text("\(tokenCount) tokens reach it")
            }
        }
    }
}

/// Every settled state of the design on this device: Undo and Redo walk
/// it, a checkpoint names the current state so it can be restored by name,
/// and Compare to shipped lists each knob that differs from the defaults.
private struct HistorySection: View {
    @Binding var tuning: ThemeTuning
    @Shared(.designHistory) private var history
    @State private var checkpointName = ""
    private let state = DesignSurfaceState.shared

    private var differences: [ThemeTuning.Difference] { tuning.differences(from: .default) }

    var body: some View {
        Section {
            HStack {
                Button("Undo", systemImage: "arrow.uturn.backward") { step { $0.undo() } }
                    .disabled(!history.canUndo)
                    .accessibilityIdentifier("tuning.history.undo")
                Spacer()
                Text("\(history.entries.count) states")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Button("Redo", systemImage: "arrow.uturn.forward") { step { $0.redo() } }
                    .disabled(!history.canRedo)
                    .accessibilityIdentifier("tuning.history.redo")
            }
            .buttonStyle(.borderless)
            HStack {
                TextField("Name this state", text: $checkpointName)
                    .accessibilityIdentifier("tuning.history.name")
                Button("Checkpoint") {
                    $history.withLock { $0.name(checkpointName) }
                    checkpointName = ""
                }
                .buttonStyle(.borderless)
                .disabled(checkpointName.trimmingCharacters(in: .whitespaces).isEmpty || history.current == nil)
                .accessibilityIdentifier("tuning.history.checkpoint")
            }
            ForEach(history.named) { entry in
                Button {
                    step { $0.restore(entry.id) }
                } label: {
                    LabeledContent {
                        if history.current?.id == entry.id {
                            Image(systemName: "checkmark").foregroundStyle(.tint).accessibilityHidden(true)
                        }
                    } label: {
                        Text(verbatim: entry.name ?? "")
                        Text(entry.date, format: .dateTime.hour().minute())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(history.current?.id == entry.id ? [.isSelected] : [])
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

    /// Moves the cursor with `move`, then applies the entry it lands on: the
    /// code over the current tuning (the switches stay) and the knobs.
    private func step(_ move: (inout DesignHistory) -> DesignHistory.Entry?) {
        var landed: DesignHistory.Entry?
        $history.withLock { landed = move(&$0) }
        guard let entry = landed else { return }
        withAnimation(ToolChrome.animation) {
            if let restored = ThemeTuning(presetCode: entry.code, base: tuning) { tuning = restored }
            state.knobs.replaceAll(entry.knobs)
        }
    }
}

/// What the agent last wrote to the device, read from the record MCP
/// `set_tuning` and `set_knobs` leave beside the files; the panel already
/// shows the change itself through its file watch. Undo restores the
/// previous values; Dismiss keeps them. Both clear the record.
private struct AgentChangeSection: View {
    @Binding var tuning: ThemeTuning
    @Shared(.agentChange) private var change
    private let state = DesignSurfaceState.shared

    var body: some View {
        if let change {
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
                        withAnimation(ToolChrome.animation) { change.undo(tuning: &tuning, knobs: state.knobs) }
                        $change.withLock { $0 = nil }
                    }
                    .accessibilityIdentifier("tuning.agentChange.undo")
                    Spacer()
                    Button("Keep", systemImage: "checkmark") {
                        $change.withLock { $0 = nil }
                    }
                    .accessibilityIdentifier("tuning.agentChange.keep")
                }
                .buttonStyle(.borderless)
            } header: {
                Text("From the agent")
            }
        }
    }
}

/// The notes a person leaves for the agent: one about the selected item or,
/// with nothing selected, about the screen. Open notes list newest first
/// with what they are about; a resolved note stays in the file for the
/// agent and leaves the list.
private struct NotesSection: View {
    let selection: ItemSelection
    let tuning: ThemeTuning
    @Shared(.designNotes) private var notes
    @State private var isWriting = false
    /// The file name of the last screenshot taken from the camera button.
    @State private var captured: String?
    private let state = DesignSurfaceState.shared

    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private var open: [DesignNote] { notes.filter { !$0.resolved }.reversed() }
    private var answered: [DesignNote] { notes.filter(\.resolved).reversed() }

    var body: some View {
        Section {
            ForEach(open) { note in
                NoteRow(note: note, about: note.item.map(state.title) ?? note.screen ?? "Screen")
                    .accessibilityIdentifier("tuning.note")
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            $notes.withLock { $0.removeAll { $0.id == note.id } }
                        }
                    }
            }
            if !answered.isEmpty {
                DisclosureGroup("Answered (\(answered.count))") {
                    ForEach(answered) { note in
                        NoteRow(note: note, about: note.item.map(state.title) ?? note.screen ?? "Screen")
                            .accessibilityIdentifier("tuning.note.answered")
                            .swipeActions {
                                Button("Reopen", systemImage: "arrow.uturn.backward") {
                                    $notes.withLock { notes in
                                        if let index = notes.firstIndex(where: { $0.id == note.id }) { notes[index].reopen() }
                                    }
                                }
                                .tint(ToolChrome.accent)
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    $notes.withLock { $0.removeAll { $0.id == note.id } }
                                }
                            }
                    }
                }
                .accessibilityIdentifier("tuning.notes.answered")
            }
            Button(selection.item == nil ? "Note this screen" : "Note this item", systemImage: "square.and.pencil") {
                // A field inside a sheet takes focus only in the key window.
                DesignSurfaceWindow.shared.setKey(true)
                isWriting = true
            }
            .accessibilityIdentifier("tuning.note.add")
            Button(captured == nil ? "Capture the screen" : "Captured \(captured!)", systemImage: "camera") {
                let name = "screen-" + Self.stamp.string(from: .now)
                captured = DesignContext.saveScreenshot(named: name, state: state).map { _ in name + ".png" }
                DesignContext.write(state: state, tuning: tuning)
            }
            .accessibilityIdentifier("tuning.capture")
        } header: {
            Text("Notes for the agent")
        } footer: {
            Text("Saved to design-notes.json beside the tokens, with the item, the tokens it reads, its knobs, the preset code, and a screenshot under notes/. The screen's items and frames are in design-context.json.")
        }
        .sheet(isPresented: $isWriting, onDismiss: { DesignSurfaceWindow.shared.setKey(false) }) {
            NoteSheet(about: selection.item.map(state.title) ?? state.screen ?? "this screen") { text in
                var note = DesignNote.take(text, selection: selection, tuning: tuning, state: state)
                note.screenshot = DesignContext.saveScreenshot(named: note.id.uuidString, state: state)
                $notes.withLock { $0.append(note) }
                DesignContext.write(state: state, tuning: tuning, screenshot: note.screenshot)
            }
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

/// The note's text. The draft lives with the sheet, so dismissing it keeps nothing.
private struct NoteSheet: View {
    let about: String
    let save: (String) -> Void
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.registryTheme) private var theme

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("About \(about). The agent reads it with the item, its tokens, and the theme that is up now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                TextEditor(text: $text)
                    .accessibilityLabel(Text("Note"))
                    .frame(minHeight: 160)
                    .padding(theme.metrics.compactSpacing)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius))
                Spacer()
            }
            .padding()
            .navigationTitle("Note for the agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save(trimmed)
                        dismiss()
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
        }
    }
}

private struct PresetsSection<Footer: View>: View {
    @Binding var tuning: ThemeTuning
    let footer: Footer

    var body: some View {
        Section("Presets") {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(RegistryTheme.presets) { preset in
                        Button(preset.name) {
                            withAnimation(ToolChrome.animation) { tuning.apply(presetNamed: preset.name) }
                        }
                        // A native style, not the registry button item: the
                        // panel is a package product and items are copied source.
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .registryTheme(preset.theme)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            footer
        }
    }
}

/// The themes an agent staged in `design-variants.json`, one chip each; a
/// tap applies the code and records the pick as `chosen`. Hidden until the
/// file names a variant. A chip reads selected while the knobs still match
/// its code, so a knob moved afterwards clears it without clearing the pick.
private struct VariantsSection: View {
    @Binding var tuning: ThemeTuning
    @Shared(.designVariants) private var variants

    var body: some View {
        if !variants.variants.isEmpty {
            Section {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(variants.variants) { variant in
                            VariantChip(variant: variant, isCurrent: variants.matching(tuning)?.name == variant.name) {
                                guard let picked = variants.tuning(for: variant, base: tuning) else { return }
                                withAnimation(ToolChrome.animation) { tuning = picked }
                                $variants.withLock { $0.chosen = variant.name }
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

/// The preset code and the Swift, the two ways the tuned theme leaves the app.
private struct ExportSection: View {
    let tuning: ThemeTuning
    @State private var isShowingSwift = false

    var body: some View {
        Section("Export") {
            LabeledContent {
                CopyButton("Copy Code", text: "--preset \(tuning.presetCode)")
                    .labelStyle(.iconOnly)
            } label: {
                Text("Preset code")
                Text(verbatim: tuning.presetCode)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            }
            DisclosureGroup("Swift", isExpanded: $isShowingSwift) {
                CodeBlock(tuning.swiftSource)
                Text("Paste this once at your scene root. Every registry item you install inherits it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// The tuned theme's text pairs against the HIG's contrast minimum, beside
/// the export so a theme is checked before it leaves; a label on the accent
/// that the other label would fix is one tap away.
private struct ContrastSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        let audit = ContrastAudit(tuning)
        Section {
            ForEach(audit.pairs) { pair in
                ContrastRow(pair: pair)
            }
            if let dark = ContrastAudit.betterLabel(for: tuning) {
                Button(dark ? LocalizedStringKey("Use a dark label") : "Use a white label") {
                    withAnimation(ToolChrome.animation) { tuning.darkLabelOnAccent = dark }
                }
                .accessibilityIdentifier("tuning.contrast.fixLabel")
            }
        } header: {
            Text("Contrast")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Text needs 4.5:1 in light and dark (WCAG AA, as Apple's guidelines apply it). A system color may reach it with Increase Contrast; a custom color has no such variant.")
                if audit.secondaryIsDerived {
                    Text("Secondary text follows the foreground; give it its own color to measure it.")
                }
            }
        }
    }
}

/// One pair: its name, the ratios that decide it, and the verdict in words
/// beside its symbol, so the result never rests on color alone.
private struct ContrastRow: View {
    let pair: ContrastAudit.Pair

    private var verdict: (text: String, symbol: String, color: Color) {
        switch pair.verdict {
        case .passes: ("Passes", "checkmark.circle.fill", .green)
        case .passesWithIncreaseContrast: ("Passes with Increase Contrast", "circle.lefthalf.filled", .secondary)
        case .fails: ("Fails", "exclamationmark.triangle.fill", .orange)
        }
    }

    private var ratios: String {
        let base = "\(Self.format(pair.light)) light, \(Self.format(pair.dark)) dark"
        guard pair.verdict == .passesWithIncreaseContrast else { return base }
        return base + ", \(Self.format(min(pair.lightIncreased, pair.darkIncreased))) increased"
    }

    /// Two decimals, as contrast checkers print them: one decimal would round
    /// a failing 4.47 up to a passing-looking 4.5.
    private static func format(_ ratio: Double) -> String {
        ratio.formatted(.number.precision(.fractionLength(2))) + ":1"
    }

    var body: some View {
        LabeledContent {
            Image(systemName: verdict.symbol)
                .foregroundStyle(verdict.color)
                .accessibilityHidden(true)
        } label: {
            Text(pair.title)
            Text("\(verdict.text): \(ratios)")
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("tuning.contrast.\(pair.kind.rawValue)")
    }
}

private struct AccentSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("Accent") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                ForEach(ThemeTuning.Accent.named) { accent in
                    AccentSwatch(
                        accent: accent,
                        isSelected: tuning.accent == accent,
                        custom: tuning.customAccent,
                        diameter: 36
                    ) {
                        withAnimation(ToolChrome.animation) { tuning.accent = accent }
                    }
                }
            }
            .padding(.vertical, 4)

            ColorPicker("Custom accent", selection: $tuning.customAccentColor, supportsOpacity: false)
            Toggle("Separate dark accent", isOn: $tuning.hasSeparateDarkAccent)
            if tuning.customAccentDark != nil {
                ColorPicker("Custom accent in dark", selection: $tuning.customAccentDarkColor, supportsOpacity: false)
            }
            Toggle("Dark label on accent", isOn: $tuning.darkLabelOnAccent)
                .disabled(tuning.accent == .ink)
        }
    }
}

private struct TypographySection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("Typography") {
            Picker("Font design", selection: $tuning.fontDesign) {
                ForEach(ThemeTuning.FontDesign.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("tuning.fontDesign")
            TypeScalePreview(design: tuning.fontDesign.design)
        }
    }
}

/// Apple's eleven text styles rendered in the chosen design, a read-only scale.
/// No custom point sizes: the styles come from the system, so Dynamic Type keeps
/// scaling them.
private struct TypeScalePreview: View {
    let design: Font.Design?

    private static let styles: [(style: Font.TextStyle, name: String)] = [
        (.largeTitle, "Large Title"), (.title, "Title"), (.title2, "Title 2"),
        (.title3, "Title 3"), (.headline, "Headline"), (.subheadline, "Subheadline"),
        (.body, "Body"), (.callout, "Callout"), (.footnote, "Footnote"),
        (.caption, "Caption"), (.caption2, "Caption 2"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Self.styles, id: \.name) { entry in
                Text(entry.name)
                    .font(.system(entry.style, design: design ?? .default))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityIdentifier("tuning.typeScale")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Type scale, eleven text styles")
    }
}

private struct ChartSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("Chart") {
            Picker("Chart palette", selection: $tuning.chartPalette) {
                ForEach(ThemeTuning.ChartPalette.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("tuning.chartPalette")
        }
    }
}

/// Density is a bundle of the spacing, padding, and radius metrics, not a stored
/// field. Selecting one writes those knobs; Custom appears only while the knobs
/// match no bundle.
private struct DensitySection: View {
    @Binding var tuning: ThemeTuning

    private var selection: Binding<ThemeTuning.Density?> {
        Binding(
            get: { tuning.matchingDensity },
            set: { newValue in
                if let newValue {
                    withAnimation(ToolChrome.animation) { tuning.apply(density: newValue) }
                }
            }
        )
    }

    var body: some View {
        Section("Density") {
            Picker("Density", selection: selection) {
                ForEach(ThemeTuning.Density.allCases) { Text($0.title).tag(Optional($0)) }
                if tuning.matchingDensity == nil {
                    Text("Custom").tag(ThemeTuning.Density?.none)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("tuning.density")
        }
    }
}

private struct ColorsSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("Colors") {
            ColorPairRows(
                name: "Background",
                identifier: "background",
                isOn: $tuning.hasBackground,
                color: $tuning.backgroundColor,
                hasDark: $tuning.hasBackgroundDark,
                darkColor: $tuning.backgroundDarkColor
            )
            ColorPairRows(
                name: "Foreground",
                identifier: "foreground",
                isOn: $tuning.hasForeground,
                color: $tuning.foregroundColor,
                hasDark: $tuning.hasForegroundDark,
                darkColor: $tuning.foregroundDarkColor
            )
            ColorPairRows(
                name: "Secondary foreground",
                identifier: "secondaryForeground",
                isOn: $tuning.hasSecondaryForeground,
                color: $tuning.secondaryForegroundColor,
                hasDark: $tuning.hasSecondaryForegroundDark,
                darkColor: $tuning.secondaryForegroundDarkColor
            )
        }
    }
}

/// One optional color pair, built to match the accent's custom pair rows: an on
/// switch, a light color, and an optional separate dark color.
private struct ColorPairRows: View {
    let name: String
    let identifier: String
    @Binding var isOn: Bool
    @Binding var color: Color
    @Binding var hasDark: Bool
    @Binding var darkColor: Color

    var body: some View {
        Toggle(isOn: $isOn.animation(ToolChrome.animation)) { Text(name) }
            .accessibilityIdentifier("tuning.\(identifier)")
        if isOn {
            ColorPicker(selection: $color, supportsOpacity: false) { Text("\(name) color") }
                .accessibilityIdentifier("tuning.\(identifier)Color")
            Toggle(isOn: $hasDark.animation(ToolChrome.animation)) { Text("Separate dark \(name.lowercased())") }
                .accessibilityIdentifier("tuning.\(identifier)Dark")
            if hasDark {
                ColorPicker(selection: $darkColor, supportsOpacity: false) { Text("\(name) in dark") }
                    .accessibilityIdentifier("tuning.\(identifier)DarkColor")
            }
        }
    }
}

private struct SurfaceSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("Surface") {
            TuningSlider("Surface opacity", value: $tuning.surfaceOpacity, in: 0...0.2, step: 0.005, fraction: 3)
            TuningSlider("Surface step", value: $tuning.surfaceStep, in: 0...0.07, step: 0.01, fraction: 2)
                .accessibilityIdentifier("tuning.surfaceStep")
            SurfaceLadderPreview(opacity: tuning.surfaceOpacity, step: tuning.surfaceStep)
            TuningSlider("Border opacity", value: $tuning.borderOpacity, in: 0...0.3, step: 0.01, fraction: 2)
            TuningSlider("Border width", value: $tuning.borderWidth, in: 0.5...3, step: 0.5, fraction: 1)
            TuningSlider("Emphasized border", value: $tuning.emphasizedBorderWidth, in: 1...4, step: 0.5, fraction: 1)
        }
    }
}

/// The four elevation levels the surface step produces, drawn as swatches: the
/// regular surface opacity, one step below and two below it, and one above,
/// each clamped to a visible range, so the step's effect is legible at a glance.
private struct SurfaceLadderPreview: View {
    let opacity: Double
    let step: Double

    private var levels: [(name: String, opacity: Double)] {
        [("Lowest", opacity - 2 * step), ("Low", opacity - step), ("Regular", opacity), ("High", opacity + step)]
            .map { ($0.0, min(1, max(0, $0.1))) }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(levels, id: \.name) { level in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.primary.opacity(level.opacity))
                        .frame(height: 40)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(.separator)
                        }
                    Text(level.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Elevation ladder: lowest, low, regular, and high surface levels")
    }
}

private struct RadiusSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("Radius") {
            TuningSlider("Compact", value: $tuning.compactRadius, in: 0...12, step: 1)
            TuningSlider("Control", value: $tuning.controlRadius, in: 0...22, step: 1)
            TuningSlider("Card", value: $tuning.cardRadius, in: 0...32, step: 1)
        }
    }
}

private struct SpacingSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("Spacing") {
            TuningSlider("Compact", value: $tuning.compactSpacing, in: 4...16, step: 1)
            TuningSlider("Standard", value: $tuning.standardSpacing, in: 8...32, step: 1)
            TuningSlider("Section", value: $tuning.sectionSpacing, in: 12...48, step: 1)
            TuningSlider("Control padding", value: $tuning.controlHorizontalPadding, in: 8...24, step: 1)
        }
    }
}

private struct StateSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("State") {
            TuningSlider("Disabled opacity", value: $tuning.disabledOpacity, in: 0.2...0.8, step: 0.05, fraction: 2)
        }
    }
}

private struct EnvironmentSection: View {
    @Binding var tuning: ThemeTuning

    var body: some View {
        Section("Environment") {
            Picker("Appearance", selection: $tuning.appearance) {
                ForEach(ThemeTuning.Appearance.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Text size", selection: $tuning.textSize) {
                ForEach(ThemeTuning.TextSize.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Toggle("Right to left", isOn: $tuning.rightToLeft)
        }
    }
}

/// Paste a preset code, with or without its `--preset` flag, or a
/// `RegistryTheme(...)` initializer in the shape Copy Swift produces, to load
/// it into the knobs. Typing into the editor is a keyboard paste, which never
/// raises the system pasteboard prompt.
/// The draft and its failure live with the sheet: they exist only while it
/// is up, so the panel cannot hold a stale draft or a failure after dismissal.
private struct ImportThemeSheet: View {
    let apply: (String) -> Bool
    @State private var text = ""
    @State private var failed = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.registryTheme) private var theme

    private var fieldShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Paste a preset code or a RegistryTheme initializer. A code replaces every knob; an initializer replaces the knobs it names and the rest keep their values.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                // Native chrome, not the registry textarea item: the panel is a
                // package product and items are copied source.
                TextEditor(text: $text)
                    .accessibilityLabel(Text("Preset code or Swift"))
                    .frame(minHeight: 240)
                    .padding(theme.metrics.compactSpacing)
                    .background(theme.surface, in: fieldShape)
                    .overlay {
                        fieldShape.stroke(
                            failed ? Color.red : theme.border,
                            lineWidth: failed ? theme.metrics.emphasizedBorderWidth : theme.metrics.borderWidth
                        )
                    }
                    .font(.footnote.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if failed {
                    Text("No preset code or RegistryTheme( initializer found in the pasted text.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Import theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if apply(text) { dismiss() } else { failed = true }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct TuningSlider: View {
    let title: LocalizedStringResource
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let fraction: Int

    init(
        _ title: LocalizedStringResource,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double,
        fraction: Int = 0
    ) {
        self.title = title
        _value = value
        self.range = range
        self.step = step
        self.fraction = fraction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value, format: .number.precision(.fractionLength(fraction)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .font(.subheadline)
            Slider(value: $value, in: range, step: step) {
                Text(title)
            }
        }
    }
}

#Preview("Tuning Panel") {
    @Previewable @State var tuning = ThemeTuning.default
    TuningPanel(tuning: $tuning)
        .registryTheme(tuning.theme)
}
#endif
