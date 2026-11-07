#if canImport(UIKit)
import SwiftUI
import SweetUIFoundations

/// Tokens. With nothing selected: Start from, the theme's groups (Color open,
/// the rest collapsed), the app's tokens, and the host's sections. With an
/// item selected: the Item section, its knobs, only the tokens that reach
/// it, what it reads that no token moves, the host's sections, and the
/// host's page. A host that paints the items from its own tokens has no
/// Start from and no theme groups.
struct TokensPlace: View {
    @Bindable var model: TuneModel

    var body: some View {
        let stage = model.stage
        Form {
            if let error = model.tokensFileError {
                Text(verbatim: error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("tuning.tokens.error")
            }
            if let line = model.ownTokensLine {
                Text(verbatim: line)
                    .foregroundStyle(.secondary)
            }
            if let item = model.selectedItem {
                ItemSection(model: model, item: item)
                KnobsSection(model: model, item: item.name)
                if stage.tunesTheme {
                    TokenGroups(
                        tuning: $model.tuningEdit, color: $model.colorEdit, tokens: model.scopedTokens,
                        showsChecks: false, actions: model.tokenActions)
                    FixedFieldsSection(item: item)
                }
                if let host = stage.hostSections {
                    host(stage.selection.chain)
                }
                if let page = model.hostPageItem {
                    Section {
                        NavigationLink(value: page) {
                            Text(verbatim: "The app's page for \(stage.title(page))")
                        }
                        .accessibilityIdentifier("tuning.item.page")
                    }
                }
            } else {
                if model.showsStartFrom {
                    StartFromSection(model: model)
                }
                if stage.tunesTheme {
                    TokenGroups(
                        tuning: $model.tuningEdit, color: $model.colorEdit, tokens: model.scopedTokens,
                        open: $model.openGroups, actions: model.tokenActions)
                }
                if let host = stage.hostTokens {
                    HostTokensSection(store: host)
                }
                if let host = stage.hostSections {
                    host(stage.selection.chain)
                }
            }
        }
        .accessibilityIdentifier("tuning.form")
    }
}

/// What the selection is: its title and name, where its first instance sits,
/// how many are on screen, the item around it, the notes about it, and Copy
/// name.
private struct ItemSection: View {
    let model: TuneModel
    let item: TuneModel.ItemDetails

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.title)
                    .font(.headline)
                    .accessibilityIdentifier("tuning.item")
                Text(verbatim: item.name)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Name, \(item.name)")
                    .accessibilityIdentifier("tuning.scope.item")
            }
            LabeledContent("Size") {
                Text(verbatim: size)
                    .monospacedDigit()
            }
            LabeledContent("Instances") {
                Text(verbatim: item.frame == nil ? "None on this screen" : "\(item.instances) on screen")
            }
            if let container = item.container {
                Button {
                    withAnimation(ToolChrome.animation) { model.containerTapped() }
                } label: {
                    Text(verbatim: "Inside: \(model.stage.title(container))")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityHint("Selects it.")
                .accessibilityIdentifier("tuning.item.container")
            }
            if item.notes > 0 {
                Button {
                    model.notesAboutTapped()
                } label: {
                    Text(verbatim: "\(item.notes) \(item.notes == 1 ? "note" : "notes") about \(item.title)")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityHint("Shows them in Notes.")
                .accessibilityIdentifier("tuning.item.notes")
            }
            CopyButton("Copy name", text: item.name)
                .accessibilityIdentifier("tuning.item.copyName")
            Button("Clear selection", systemImage: "xmark.circle") {
                withAnimation(ToolChrome.animation) { model.clearSelectionTapped() }
            }
            .accessibilityHint("Shows every token again.")
            .accessibilityIdentifier("tuning.item.clear")
        }
    }

    /// "320 × 88 pt at 16, 120", from the first instance on screen.
    private var size: String {
        guard let frame = item.frame else { return "Not on this screen" }
        func points(_ value: CGFloat) -> String { "\(Int(value.rounded()))" }
        return "\(points(frame.width)) × \(points(frame.height)) pt at \(points(frame.minX)), \(points(frame.minY))"
    }
}

/// What the item reads that no token moves, and an item that reads no
/// theme token at all.
private struct FixedFieldsSection: View {
    let item: TuneModel.ItemDetails

    var body: some View {
        let fixed = TokenCatalog.fixedFields(of: item.name)
        let readsNone = RegistryItemTokens.tokens(for: item.name)?.isEmpty == true
        if readsNone || !fixed.isEmpty {
            Section {
                if readsNone {
                    Text(verbatim: "\(item.title) reads no theme tokens. Accent, type, and the colors still reach it.")
                }
                if !fixed.isEmpty {
                    Text(verbatim: "Also reads \(fixed.formatted(.list(type: .and))). No token moves \(fixed.count == 1 ? "it" : "them").")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

/// Where a design starts: the presets, the host's own row, Source, Default,
/// and a pasted code, each applied as a new version. The one Current came
/// from carries a check.
private struct StartFromSection: View {
    @Bindable var model: TuneModel

    var body: some View {
        let origin = model.current?.origin
        Section("Start from") {
            PresetChips(current: origin) { name in
                withAnimation(ToolChrome.animation) { model.presetChipTapped(name) }
            }
            if let footer = model.stage.presetsFooter { footer }
            StartRow(
                title: "Source", detail: "Clears every token and knob, so the app's own theme shows.",
                isCurrent: origin == .source
            ) {
                withAnimation(ToolChrome.animation) { model.sourceButtonTapped() }
            }
            .accessibilityIdentifier("tuning.start.source")
            StartRow(
                title: "Default", detail: "Applies the default theme. Knobs keep their values.",
                isCurrent: origin == .defaultTheme
            ) {
                withAnimation(ToolChrome.animation) { model.defaultButtonTapped() }
            }
            .accessibilityIdentifier("tuning.start.default")
            HStack {
                // A keyboard paste, which never raises the pasteboard prompt.
                TextField("Paste a code or RegistryTheme(...)", text: $model.codeDraft)
                    .font(.footnote.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit(applyCode)
                    .accessibilityLabel("Code")
                    .accessibilityIdentifier("tuning.code.field")
                Button(action: applyCode) {
                    Text("Apply")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
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

/// Source or Default: its title, what it does in a line under it, and a
/// check while Current came from it.
private struct StartRow: View {
    let title: String
    let detail: String
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                    Text(verbatim: detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if isCurrent {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityHint(Text(verbatim: detail))
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

/// One chip per foundation preset, each in its own theme, in a grid that
/// wraps, so every chip is on the card; the one Current came from is checked.
private struct PresetChips: View {
    let current: DesignHistory.Origin?
    let apply: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(RegistryTheme.presets) { preset in
                let isCurrent = current == .preset(name: preset.name)
                Button {
                    apply(preset.name)
                } label: {
                    // The small bezel around it makes a 44 pt target.
                    Group {
                        if isCurrent {
                            Label(preset.name, systemImage: "checkmark")
                        } else {
                            Text(preset.name)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, minHeight: 34)
                }
                // A native style, not the registry button item: Tune is
                // a package product and items are copied source.
                .buttonStyle(.bordered)
                .controlSize(.small)
                .registryTheme(preset.theme)
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
                .accessibilityIdentifier("tuning.preset.\(preset.name)")
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

/// The selected item's knobs, registered by the host or declared by the
/// agent ("Declared by the agent"), and each declared one Tune cannot draw
/// with its reason; a value at its default leaves the file.
private struct KnobsSection: View {
    let model: TuneModel
    let item: String

    var body: some View {
        let specs = model.stage.knobs.knobs(for: item)
        let declared = model.stage.knobs.declaredNames(for: item)
        let undrawable = model.stage.knobs.undrawable(for: item)
        if !specs.isEmpty || !undrawable.isEmpty {
            Section {
                ForEach(specs) { knob in
                    KnobRow(model: model, item: item, knob: knob, isDeclared: declared.contains(knob.name))
                }
                ForEach(undrawable, id: \.name) { spec in
                    Text(verbatim: "\(spec.name) is not shown: \(spec.reason) Ask the agent to fix design-knob-specs.json.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("tuning.knob.\(item).\(spec.name)")
                }
                if !specs.isEmpty {
                    // A value at its default leaves the file, so none stored is none moved.
                    Button("Reset knobs") { model.resetKnobsButtonTapped(item) }
                        .disabled(model.stage.knobs.values[item] == nil)
                        .accessibilityIdentifier("tuning.knob.reset")
                }
            } header: {
                Text("Knobs")
            }
        }
    }
}

/// One knob by kind: a switch, a choice, or a slider with its value; a dot
/// and "changed, 36 to 44" while it is off its default.
private struct KnobRow: View {
    let model: TuneModel
    let item: String
    let knob: ItemKnob
    let isDeclared: Bool

    var body: some View {
        let value = model.knobValue(item, knob)
        let changed = value != knob.shipped
        let word = knob.word(for: value)
        VStack(alignment: .leading, spacing: 4) {
            control(changed: changed)
                .accessibilityValue(
                    Text(verbatim: changed ? "\(word), changed, \(knob.word(for: knob.shipped)) to \(word)" : word))
            if isDeclared {
                Label("Declared by the agent", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func title(changed: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(knob.title)
            if changed {
                Circle()
                    .fill(ToolChrome.accent)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private func control(changed: Bool) -> some View {
        switch knob.kind {
        case .bool:
            Toggle(isOn: Binding(
                get: { model.knobValue(item, knob) != 0 },
                set: { model.knobChanged(item, knob, to: $0 ? 1 : 0) })
            ) {
                title(changed: changed)
            }
            .accessibilityIdentifier("tuning.knob.\(item).\(knob.name)")
        case .choice(let options):
            Picker(selection: Binding(
                get: { knob.option(for: model.knobValue(item, knob)) ?? options[0] },
                set: { word in model.knobChanged(item, knob, to: Double(options.firstIndex(of: word) ?? 0)) })
            ) {
                ForEach(options, id: \.self) { Text(verbatim: $0).tag($0) }
            } label: {
                title(changed: changed)
            }
            .accessibilityIdentifier("tuning.knob.\(item).\(knob.name)")
        case .number:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    title(changed: changed)
                    Spacer()
                    Text(
                        model.knobValue(item, knob),
                        format: .number.precision(.fractionLength(knob.step < 1 ? 2 : 0))
                    )
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .accessibilityHidden(true)
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
}

/// The host's own token document: one row per page, each pushing the page's
/// knobs, and a reset for the whole document. Applied live, outside versions.
private struct HostTokensSection: View {
    let store: any AnyTokenStore

    var body: some View {
        Section("App tokens, outside versions") {
            ForEach(Array(store.pageTitles.enumerated()), id: \.offset) { index, title in
                NavigationLink(title) {
                    Form { store.page(index) }
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .accessibilityIdentifier("tuning.tokens.\(index)")
            }
            Button("Reset app tokens", role: .destructive) { store.reset() }
                .accessibilityIdentifier("tuning.tokens.reset")
        }
    }
}
#endif
