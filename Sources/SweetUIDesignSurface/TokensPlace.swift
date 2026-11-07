#if canImport(UIKit)
import SwiftUI
import SweetUIFoundations

/// Tokens: the selected item and its knobs, the host's tokens and sections,
/// Start from, and the theme's groups. A host that paints the items from its
/// own tokens has no Start from and no theme groups.
struct TokensPlace: View {
    @Bindable var model: TuneModel

    var body: some View {
        let stage = model.stage
        let scope = ThemeSections.scope(for: stage.selection.item)
        Form {
            if let item = stage.selection.item {
                // A host with its own tokens shows its own selection rows.
                if stage.tunesTheme {
                    ScopeSection(item: item, tokenCount: scope?.count ?? 0) {
                        withAnimation(ToolChrome.animation) { model.clearSelectionTapped() }
                    }
                }
                ItemKnobsSection(model: model, item: item)
            }
            if let host = stage.hostTokens {
                HostTokensSection(store: host)
            }
            if let host = stage.hostSections {
                host(stage.selection.chain)
            }
            if model.showsStartFrom {
                StartFromSection(model: model)
            }
            if stage.tunesTheme {
                ThemeSections(
                    tuning: $model.tuningEdit, color: $model.colorEdit, hold: model.sliderEditingChanged,
                    scope: scope)
            }
        }
        .accessibilityIdentifier("tuning.form")
    }
}

/// Where a design starts: the presets, the host's own row, Source, Default,
/// and a pasted code, each applied as a new version.
private struct StartFromSection: View {
    @Bindable var model: TuneModel

    var body: some View {
        Section("Start from") {
            PresetChips { name in
                withAnimation(ToolChrome.animation) { model.presetChipTapped(name) }
            }
            if let footer = model.stage.presetsFooter { footer }
            Button("Source") {
                withAnimation(ToolChrome.animation) { model.sourceButtonTapped() }
            }
            .accessibilityHint("Clears every token and knob, so the app's own theme shows.")
            .accessibilityIdentifier("tuning.start.shipped")
            Button("Default") {
                withAnimation(ToolChrome.animation) { model.defaultButtonTapped() }
            }
            .accessibilityHint("Applies the default theme. Knobs keep their values.")
            .accessibilityIdentifier("tuning.start.default")
            HStack {
                // A keyboard paste, which never raises the pasteboard prompt.
                TextField("Paste a code", text: $model.codeDraft)
                    .font(.footnote.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit(applyCode)
                    .accessibilityLabel("Code")
                    .accessibilityIdentifier("tuning.code.field")
                Button("Apply", action: applyCode)
                    .buttonStyle(.borderless)
                    .disabled(model.codeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("tuning.code.apply")
            }
            if let error = model.codeError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func applyCode() {
        withAnimation(ToolChrome.animation) { model.applyCodeButtonTapped() }
    }
}

/// The selected item's own knobs, registered by the host or declared by the
/// agent; a value at its shipped default leaves the file.
private struct ItemKnobsSection: View {
    let model: TuneModel
    let item: String

    var body: some View {
        let specs = model.stage.knobs.knobs(for: item)
        if !specs.isEmpty {
            Section {
                ForEach(specs) { knob in
                    switch knob.kind {
                    case .bool:
                        Toggle(knob.title, isOn: Binding(
                            get: { model.knobValue(item, knob) != 0 },
                            set: { model.knobChanged(item, knob, to: $0 ? 1 : 0) }))
                            .accessibilityIdentifier("tuning.knob.\(item).\(knob.name)")
                    case .choice(let options):
                        Picker(knob.title, selection: Binding(
                            get: { knob.option(for: model.knobValue(item, knob)) ?? options[0] },
                            set: { word in model.knobChanged(item, knob, to: Double(options.firstIndex(of: word) ?? 0)) })
                        ) {
                            ForEach(options, id: \.self) { Text(verbatim: $0).tag($0) }
                        }
                        .accessibilityIdentifier("tuning.knob.\(item).\(knob.name)")
                    case .number:
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(knob.title)
                                Spacer()
                                Text(
                                    model.knobValue(item, knob),
                                    format: .number.precision(.fractionLength(knob.step < 1 ? 2 : 0))
                                )
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            Slider(
                                value: Binding(
                                    get: { model.knobValue(item, knob) },
                                    set: { model.knobChanged(item, knob, to: $0) }),
                                in: knob.range, step: knob.step
                            ) {
                                Text(knob.title)
                            } onEditingChanged: {
                                model.sliderEditingChanged($0)
                            }
                            .accessibilityIdentifier("tuning.knob.\(item).\(knob.name)")
                        }
                    }
                }
                Button("Reset these knobs") { model.resetKnobsButtonTapped(item) }
                    .accessibilityIdentifier("tuning.knob.reset")
            } header: {
                Text("\(item) knobs")
            }
        }
    }
}

/// The host's own token document: one row per page, each pushing the page's
/// knobs, and a reset for the whole document. Applied live, outside versions.
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
#endif
