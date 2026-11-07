#if canImport(UIKit)
import Sharing
import SwiftUI
import SweetUIFoundations


/// The theme tuning panel embedded in a host's own screen or a preview:
/// every foundation token as a live control, the preset code that names the
/// result, and the exact Swift to paste once at an app root. Tune's card
/// shows the same groups under Tokens.
public struct TuningPanel<PresetsFooter: View>: View {
    @Binding var tuning: ThemeTuning
    let presetsFooter: PresetsFooter
    /// The item scope: `nil` shows every section and no Select control, as
    /// the Showcase's previews and tests do.
    private let selection: Binding<ItemSelection>?

    /// The panel over the tuning it edits. `presetsFooter` is the host's own
    /// row under the preset chips, such as a link to a sample design system.
    /// `showsScreen` is no longer read: the screen, its notes, and its
    /// versions live in Tune's card, which `designSurface()` shows.
    public init(
        tuning: Binding<ThemeTuning>,
        selection: Binding<ItemSelection>? = nil,
        showsScreen: Bool = false,
        @ViewBuilder presetsFooter: () -> PresetsFooter
    ) {
        _tuning = tuning
        self.selection = selection
        self.presetsFooter = presetsFooter()
    }

    private var scope: Set<String>? { ThemeSections.scope(for: selection?.wrappedValue.item) }

    public var body: some View {
        NavigationStack {
            Form {
                if let selection, let item = selection.wrappedValue.item {
                    ScopeSection(item: item, tokenCount: scope?.count ?? 0) {
                        withAnimation(ToolChrome.animation) { selection.wrappedValue.item = nil }
                    }
                }
                PresetsSection(tuning: $tuning, footer: presetsFooter)
                ExportSection(tuning: tuning)
                ThemeSections(tuning: $tuning, color: $tuning, scope: scope)
            }
            .accessibilityIdentifier("tuning.form")
            .navigationTitle("Tune")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        withAnimation(ToolChrome.animation) { tuning = .default }
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
            }
        }
    }
}

extension TuningPanel where PresetsFooter == EmptyView {
    public init(tuning: Binding<ThemeTuning>) {
        self.init(tuning: tuning) { EmptyView() }
    }
}

/// The theme's groups, in Tune's Tokens and the embedded panel alike. With
/// an item selected, only the groups that reach it show; the accent, the
/// type, and the color pairs reach every item.
struct ThemeSections: View {
    @Binding var tuning: ThemeTuning
    /// The same tuning for the color pickers, whose version settles after
    /// the last change rather than at once.
    @Binding var color: ThemeTuning
    /// Told when a slider's touch goes down and comes up.
    var hold: (Bool) -> Void = { _ in }
    let scope: Set<String>?

    /// The tokens the item reads, or `nil` for the whole theme.
    static func scope(for item: String?) -> Set<String>? {
        guard let item, let tokens = RegistryItemTokens.tokens(for: item) else { return nil }
        return Set(tokens)
    }

    /// Whether a section whose knobs are `tokens` reaches the selected item.
    private func shows(_ tokens: Set<String>) -> Bool {
        guard let scope else { return true }
        return !scope.isDisjoint(with: tokens)
    }

    var body: some View {
        ContrastSection(tuning: $tuning)
        AccentSection(tuning: $tuning, color: $color)
        TypographySection(tuning: $tuning)
        if shows(PanelScope.surface) { SurfaceSection(tuning: $tuning, hold: hold) }
        if shows(["chartPalette"]) { ChartSection(tuning: $tuning) }
        if shows(PanelScope.radius.union(PanelScope.spacing)) { DensitySection(tuning: $tuning) }
        if shows(PanelScope.radius) { RadiusSection(tuning: $tuning, hold: hold) }
        if shows(PanelScope.spacing) { SpacingSection(tuning: $tuning, hold: hold) }
        ColorsSection(tuning: $tuning, color: $color)
        if shows(["disabledOpacity"]) { StateSection(tuning: $tuning, hold: hold) }
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

/// The selected item's name and how many of the theme's tokens reach it, with
/// the way back to the whole theme.
struct ScopeSection: View {
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

private struct PresetsSection<Footer: View>: View {
    @Binding var tuning: ThemeTuning
    let footer: Footer

    var body: some View {
        Section("Presets") {
            PresetChips { name in
                withAnimation(ToolChrome.animation) { tuning.apply(presetNamed: name) }
            }
            footer
        }
    }
}

/// One chip per foundation preset, each in its own theme, in a row that scrolls.
struct PresetChips: View {
    let apply: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(RegistryTheme.presets) { preset in
                    Button(preset.name) { apply(preset.name) }
                        // A native style, not the registry button item: the
                        // panel is a package product and items are copied source.
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .registryTheme(preset.theme)
                        .accessibilityIdentifier("tuning.preset.\(preset.name)")
                }
            }
        }
        .scrollIndicators(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

/// The preset code and the Swift, the two ways the tuned theme leaves the app.
struct ExportSection: View {
    let tuning: ThemeTuning
    @State private var isShowingSwift = false

    var body: some View {
        Section("Export") {
            LabeledContent {
                CopyButton("Copy Code", text: "--preset \(tuning.presetCode)")
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier("tuning.copyCode")
            } label: {
                Text("Preset code")
                Text(verbatim: tuning.presetCode)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            }
            CopyButton("Copy Swift", text: tuning.swiftSource)
                .accessibilityIdentifier("tuning.copySwift")
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
    @Binding var color: ThemeTuning

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

            ColorPicker("Custom accent", selection: $color.customAccentColor, supportsOpacity: false)
            Toggle("Separate dark accent", isOn: $tuning.hasSeparateDarkAccent)
            if tuning.customAccentDark != nil {
                ColorPicker("Custom accent in dark", selection: $color.customAccentDarkColor, supportsOpacity: false)
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
    @Binding var color: ThemeTuning

    var body: some View {
        Section("Colors") {
            ColorPairRows(
                name: "Background",
                identifier: "background",
                isOn: $tuning.hasBackground,
                color: $color.backgroundColor,
                hasDark: $tuning.hasBackgroundDark,
                darkColor: $color.backgroundDarkColor
            )
            ColorPairRows(
                name: "Foreground",
                identifier: "foreground",
                isOn: $tuning.hasForeground,
                color: $color.foregroundColor,
                hasDark: $tuning.hasForegroundDark,
                darkColor: $color.foregroundDarkColor
            )
            ColorPairRows(
                name: "Secondary foreground",
                identifier: "secondaryForeground",
                isOn: $tuning.hasSecondaryForeground,
                color: $color.secondaryForegroundColor,
                hasDark: $tuning.hasSecondaryForegroundDark,
                darkColor: $color.secondaryForegroundDarkColor
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
    let hold: (Bool) -> Void

    var body: some View {
        Section("Surface") {
            TuningSlider("Surface opacity", value: $tuning.surfaceOpacity, in: 0...0.2, step: 0.005, fraction: 3, hold: hold)
            TuningSlider("Surface step", value: $tuning.surfaceStep, in: 0...0.07, step: 0.01, fraction: 2, hold: hold)
                .accessibilityIdentifier("tuning.surfaceStep")
            SurfaceLadderPreview(opacity: tuning.surfaceOpacity, step: tuning.surfaceStep)
            TuningSlider("Border opacity", value: $tuning.borderOpacity, in: 0...0.3, step: 0.01, fraction: 2, hold: hold)
            TuningSlider("Border width", value: $tuning.borderWidth, in: 0.5...3, step: 0.5, fraction: 1, hold: hold)
            TuningSlider("Emphasized border", value: $tuning.emphasizedBorderWidth, in: 1...4, step: 0.5, fraction: 1, hold: hold)
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
    let hold: (Bool) -> Void

    var body: some View {
        Section("Radius") {
            TuningSlider("Compact", value: $tuning.compactRadius, in: 0...12, step: 1, hold: hold)
            TuningSlider("Control", value: $tuning.controlRadius, in: 0...22, step: 1, hold: hold)
            TuningSlider("Card", value: $tuning.cardRadius, in: 0...32, step: 1, hold: hold)
        }
    }
}

private struct SpacingSection: View {
    @Binding var tuning: ThemeTuning
    let hold: (Bool) -> Void

    var body: some View {
        Section("Spacing") {
            TuningSlider("Compact", value: $tuning.compactSpacing, in: 4...16, step: 1, hold: hold)
            TuningSlider("Standard", value: $tuning.standardSpacing, in: 8...32, step: 1, hold: hold)
            TuningSlider("Section", value: $tuning.sectionSpacing, in: 12...48, step: 1, hold: hold)
            TuningSlider("Control padding", value: $tuning.controlHorizontalPadding, in: 8...24, step: 1, hold: hold)
        }
    }
}

private struct StateSection: View {
    @Binding var tuning: ThemeTuning
    let hold: (Bool) -> Void

    var body: some View {
        Section("State") {
            TuningSlider("Disabled opacity", value: $tuning.disabledOpacity, in: 0.2...0.8, step: 0.05, fraction: 2, hold: hold)
        }
    }
}

private struct TuningSlider: View {
    let title: LocalizedStringResource
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let fraction: Int
    /// Told when the touch goes down and comes up, so a drag is one version.
    let hold: (Bool) -> Void

    init(
        _ title: LocalizedStringResource,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double,
        fraction: Int = 0,
        hold: @escaping (Bool) -> Void
    ) {
        self.title = title
        _value = value
        self.range = range
        self.step = step
        self.fraction = fraction
        self.hold = hold
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
            } onEditingChanged: { hold($0) }
        }
    }
}

#Preview("Tuning Panel") {
    @Previewable @State var tuning = ThemeTuning.default
    TuningPanel(tuning: $tuning)
        .registryTheme(tuning.theme)
}
#endif
