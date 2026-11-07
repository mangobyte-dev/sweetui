#if canImport(UIKit)
import SwiftUI
import SweetUIFoundations

/// What a token row does beyond its binding. In Tune each action records one
/// version; the embedded panel edits its binding.
struct TokenActions {
    /// A slider's touch went down or came up.
    var hold: @MainActor (TokenCatalog.Token, Bool) -> Void = { _, _ in }
    var reset: @MainActor (TokenCatalog.Token) -> Void
    var useLightValue: @MainActor (TokenCatalog.Token) -> Void
    var fixLabel: @MainActor () -> Void
    /// Drafts a note about a failing check; `nil` where there is no agent.
    var ask: (@MainActor (ContrastAudit.Pair) -> Void)?
    /// How many items on screen a token reaches; `nil` where there is no screen.
    var reach: (@MainActor (TokenCatalog.Token) -> Int)?
    /// Tune sets no token, so the app shows its own theme.
    var isSource = false

    /// Edits the tuning in place, for a panel outside Tune's card.
    static func editing(_ tuning: Binding<ThemeTuning>) -> TokenActions {
        TokenActions(
            reset: { $0.reset(&tuning.wrappedValue) },
            useLightValue: { $0.useLightValue(&tuning.wrappedValue) },
            fixLabel: {
                if let dark = ContrastAudit.betterLabel(for: tuning.wrappedValue) {
                    tuning.wrappedValue.darkLabelOnAccent = dark
                }
            })
    }
}

/// The theme's groups in order, each a Form section of token rows. With
/// `open`, each group is a disclosure whose header says what changed and,
/// for Color, how many checks fail; without it every group shows open.
struct TokenGroups: View {
    @Binding var tuning: ThemeTuning
    /// The same tuning for the color pickers, whose version settles after
    /// the last change rather than at once.
    @Binding var color: ThemeTuning
    let tokens: [TokenCatalog.Token]
    var open: Binding<Set<TokenCatalog.Token.Group>>?
    /// The Checks lead the Color group.
    var showsChecks = true
    let actions: TokenActions

    var body: some View {
        let audit = ContrastAudit(tuning)
        ForEach(TokenCatalog.Token.Group.allCases) { group in
            let rows = tokens.filter { $0.group == group }
            if !rows.isEmpty {
                Section {
                    if let open {
                        DisclosureGroup(isExpanded: expanded(group, in: open)) {
                            content(group, rows, audit: audit)
                        } label: {
                            // On the label: on the group it would name every row inside.
                            header(group, rows, audit: audit)
                                .accessibilityIdentifier("tuning.group.\(group.rawValue)")
                        }
                    } else {
                        content(group, rows, audit: audit)
                    }
                } header: {
                    if open == nil { Text(group.title) }
                }
            }
        }
    }

    private func expanded(
        _ group: TokenCatalog.Token.Group, in open: Binding<Set<TokenCatalog.Token.Group>>
    ) -> Binding<Bool> {
        Binding(
            get: { open.wrappedValue.contains(group) },
            set: { isOpen in
                withAnimation(ToolChrome.animation) {
                    if isOpen { open.wrappedValue.insert(group) } else { open.wrappedValue.remove(group) }
                }
            })
    }

    /// "Space · 2 changed", "Color · 1 fails".
    private func header(_ group: TokenCatalog.Token.Group, _ rows: [TokenCatalog.Token], audit: ContrastAudit) -> some View {
        var words = [group.title]
        if group == .color, showsChecks, audit.failures > 0 {
            words.append(audit.failures == 1 ? "1 fails" : "\(audit.failures) fail")
        }
        let changed = rows.filter { $0.isChanged(tuning) }.count
        if changed > 0 { words.append("\(changed) changed") }
        return Text(verbatim: words.joined(separator: " · "))
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    @ViewBuilder
    private func content(_ group: TokenCatalog.Token.Group, _ rows: [TokenCatalog.Token], audit: ContrastAudit) -> some View {
        if group == .color, showsChecks {
            ChecksRows(audit: audit, tuning: tuning, actions: actions)
        }
        if group == .space {
            DensityRow(tuning: $tuning)
        }
        ForEach(rows) { token in
            TokenRow(token: token, tuning: $tuning, color: $color, actions: actions)
            if token.key == "fontDesign" {
                TypeScalePreview(design: tuning.fontDesign.design)
            }
            if token.key == "surfaceStep" {
                SurfaceLadderPreview(opacity: tuning.surfaceOpacity, step: tuning.surfaceStep)
            }
        }
    }
}

/// One token: its title, a dot when it is changed, its value ("source"
/// while Tune sets no token), the control its kind draws, its key and how
/// many items on screen it reaches, and Reset token while it is changed.
struct TokenRow: View {
    let token: TokenCatalog.Token
    @Binding var tuning: ThemeTuning
    @Binding var color: ThemeTuning
    let actions: TokenActions

    var body: some View {
        let changed = token.isChanged(tuning)
        let value = actions.isSource ? "source" : token.value(tuning)
        VStack(alignment: .leading, spacing: 6) {
            // The value moves under the title in a narrow card.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    title(changed: changed).fixedSize()
                    Spacer(minLength: ToolChrome.compactSpacing)
                    valueText(value)
                }
                VStack(alignment: .leading, spacing: 2) {
                    title(changed: changed)
                    valueText(value)
                }
            }
            .font(.subheadline)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(token.title)
            .accessibilityValue(changed ? "\(value), changed, \(token.value(.default)) to \(token.value(tuning))" : value)
            .accessibilityActions {
                if changed { Button("Reset token") { actions.reset(token) } }
            }
            control
            Text(verbatim: details)
                .font(.caption)
                .foregroundStyle(.secondary)
            if changed || token.hasDarkValue(tuning) {
                HStack(spacing: ToolChrome.spacing) {
                    if token.hasDarkValue(tuning) {
                        action("Use the Light value", "useLight") { actions.useLightValue(token) }
                    }
                    if changed {
                        action("Reset token", "reset") { actions.reset(token) }
                    }
                }
            }
        }
    }

    private func title(changed: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: token.title)
            if changed {
                Circle()
                    .fill(ToolChrome.accent)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
            }
        }
    }

    private func valueText(_ value: String) -> some View {
        Text(verbatim: value)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .contentTransition(.numericText())
    }

    /// "cardRadius · reaches 4 on screen".
    private var details: String {
        guard let reach = actions.reach?(token) else { return token.key }
        return "\(token.key) · reaches \(reach) on screen"
    }

    private func action(_ title: LocalizedStringKey, _ id: String, _ perform: @escaping () -> Void) -> some View {
        Button {
            withAnimation(ToolChrome.animation) { perform() }
        } label: {
            Text(title)
                .font(.footnote)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier("tuning.token.\(token.key).\(id)")
    }

    @ViewBuilder
    private var control: some View {
        switch token.kind {
        case .number(let path, let range, let step, _, _):
            Slider(value: $tuning[dynamicMember: path], in: range, step: step) {
                Text(verbatim: token.title)
            } onEditingChanged: { actions.hold(token, $0) }
                .accessibilityIdentifier("tuning.token.\(token.key)")
        case .choice(let options, let index):
            Picker(token.title, selection: $tuning[dynamicMember: index].animation(ToolChrome.animation)) {
                ForEach(options.indices, id: \.self) { Text(verbatim: options[$0]).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            // Ink draws the background color as its label, so it has no other.
            .disabled(token.key == "darkLabelOnAccent" && tuning.accent == .ink)
            .accessibilityIdentifier("tuning.token.\(token.key)")
        case .color(let light, let dark, let seed):
            ModeColumns {
                ColorPicker(selection: lightColor(light, seed: seed), supportsOpacity: false) { Text("Light") }
                    .frame(minHeight: 44)
                    .accessibilityLabel("\(token.title), Light")
                    .accessibilityIdentifier("tuning.token.\(token.key)")
            } dark: {
                ColorPicker(selection: darkColor(light, dark, seed: seed), supportsOpacity: false) { Text("Dark") }
                    .frame(minHeight: 44)
                    .accessibilityLabel("\(token.title), Dark")
                    .accessibilityIdentifier("tuning.token.\(token.key)Dark")
            }
        case .accent:
            AccentControl(tuning: $tuning, color: $color)
        }
    }

    /// The Light value, the seed until it is set.
    private func lightColor(_ light: WritableKeyPath<ThemeTuning, ThemeTuning.RGB?>, seed: ThemeTuning.RGB) -> Binding<Color> {
        Binding(
            get: { (color[keyPath: light] ?? seed).color },
            set: { color[keyPath: light] = ThemeTuning.RGB($0) })
    }

    /// The Dark value, or what dark shows without one; setting it alone also
    /// sets the Light value, since a code carries no Dark value without one.
    private func darkColor(
        _ light: WritableKeyPath<ThemeTuning, ThemeTuning.RGB?>, _ dark: WritableKeyPath<ThemeTuning, ThemeTuning.RGB?>,
        seed: ThemeTuning.RGB
    ) -> Binding<Color> {
        Binding(
            get: { (color[keyPath: dark] ?? color[keyPath: light] ?? seed).color },
            set: { picked in
                var tuned = color
                if tuned[keyPath: light] == nil { tuned[keyPath: light] = seed }
                tuned[keyPath: dark] = ThemeTuning.RGB(picked)
                color = tuned
            })
    }
}

/// The accent's swatches, then a custom accent with its Light and Dark values.
private struct AccentControl: View {
    @Binding var tuning: ThemeTuning
    @Binding var color: ThemeTuning

    var body: some View {
        VStack(alignment: .leading, spacing: ToolChrome.compactSpacing) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 4)], spacing: 4) {
                ForEach(ThemeTuning.Accent.named) { accent in
                    AccentSwatch(
                        accent: accent, isSelected: tuning.accent == accent, custom: tuning.customAccent, diameter: 30
                    ) {
                        withAnimation(ToolChrome.animation) { tuning.accent = accent }
                    }
                }
            }
            ModeColumns {
                ColorPicker(selection: $color.customAccentColor, supportsOpacity: false) { Text("Custom") }
                    .frame(minHeight: 44)
                    .accessibilityLabel("Custom accent, Light")
                    .accessibilityIdentifier("tuning.token.customAccent")
            } dark: {
                ColorPicker(selection: $color.customAccentDarkColor, supportsOpacity: false) { Text("Dark") }
                    .frame(minHeight: 44)
                    .accessibilityLabel("Custom accent, Dark")
                    .accessibilityIdentifier("tuning.token.customAccentDark")
            }
        }
    }
}

/// A color's Light and Dark pickers side by side, stacked in a narrow card.
private struct ModeColumns<Light: View, Dark: View>: View {
    @ViewBuilder let light: Light
    @ViewBuilder let dark: Dark

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: ToolChrome.spacing) {
                light.fixedSize()
                Spacer(minLength: 0)
                dark.fixedSize()
            }
            VStack(alignment: .leading, spacing: 0) {
                light
                dark
            }
        }
        .font(.subheadline)
    }
}

/// The Checks: each text pair's verdict as symbol, word, and ratios, with
/// Fix label where the other label would pass and Ask the agent on a failure.
private struct ChecksRows: View {
    let audit: ContrastAudit
    let tuning: ThemeTuning
    let actions: TokenActions

    var body: some View {
        let better = ContrastAudit.betterLabel(for: tuning)
        ForEach(audit.pairs) { pair in
            CheckRow(
                pair: pair, fixes: pair.kind == .labelOnAccent ? better : nil,
                asks: pair.verdict == .fails && actions.ask != nil, actions: actions)
        }
        VStack(alignment: .leading, spacing: 4) {
            Text("Text needs 4.5:1 in light and dark. A system color may reach it with Increase Contrast; a custom color has no such variant.")
            if audit.secondaryIsDerived {
                Text("Secondary text follows the foreground; give it its own color to measure it.")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

/// One check: its pair, the verdict in words beside its symbol, so the result
/// never rests on color alone, and the ratios that decide it.
private struct CheckRow: View {
    let pair: ContrastAudit.Pair
    /// The label Fix label switches to, black when `true`; `nil` offers none.
    let fixes: Bool?
    let asks: Bool
    let actions: TokenActions

    private var symbol: (name: String, color: Color) {
        switch pair.verdict {
        case .passes: ("checkmark.circle.fill", .green)
        case .passesWithIncreaseContrast: ("circle.lefthalf.filled", .secondary)
        case .fails: ("exclamationmark.triangle.fill", .orange)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: ToolChrome.compactSpacing) {
                Image(systemName: symbol.name)
                    .foregroundStyle(symbol.color)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: pair.title)
                    Text(verbatim: "\(pair.verdictWord): \(pair.ratios)")
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("tuning.contrast.\(pair.kind.rawValue)")
            if fixes != nil || asks {
                HStack(spacing: ToolChrome.spacing) {
                    if let fixes {
                        button("Fix label") { actions.fixLabel() }
                            .accessibilityHint("Switches the label on the accent to \(fixes ? "black" : "white").")
                            .accessibilityIdentifier("tuning.contrast.fixLabel")
                    }
                    if asks {
                        button("Ask the agent") { actions.ask?(pair) }
                            .accessibilityHint("Drafts a note with this pair and its ratios.")
                            .accessibilityIdentifier("tuning.contrast.\(pair.kind.rawValue).ask")
                    }
                }
            }
        }
    }

    private func button(_ title: LocalizedStringKey, _ perform: @escaping () -> Void) -> some View {
        Button {
            withAnimation(ToolChrome.animation) { perform() }
        } label: {
            Text(title)
                .font(.footnote)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
}

/// Density is a bundle of the spacing, padding, and radius tokens, not a
/// token: a choice writes them; Custom shows while they match no bundle.
private struct DensityRow: View {
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Density")
                .font(.subheadline)
            Picker("Density", selection: selection) {
                ForEach(ThemeTuning.Density.allCases) { Text($0.title).tag(Optional($0)) }
                if tuning.matchingDensity == nil {
                    Text("Custom").tag(ThemeTuning.Density?.none)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("tuning.density")
        }
    }
}

/// Apple's eleven text styles in the chosen design, a read-only scale. No
/// custom point sizes: the styles come from the system, so Dynamic Type
/// keeps scaling them.
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Type scale, eleven text styles")
        .accessibilityIdentifier("tuning.typeScale")
    }
}

/// The four elevation levels the surface step produces, drawn as swatches:
/// the regular surface opacity, one and two steps below it, and one above,
/// each clamped to a visible range, so the step reads at a glance.
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
#endif
