#if canImport(UIKit)
import Foundation
import SwiftUI
import SweetUIFoundations
import UIKit

/// Every token Tune exposes, as plain values so the result can be
/// persisted, restored, and exported as the exact `RegistryTheme` source a
/// consuming app pastes once at its root.
public struct ThemeTuning: Equatable, Sendable {
    public enum Accent: String, Codable, CaseIterable, Identifiable, Sendable {
        case system, ink, blue, indigo, purple, pink, red, orange, yellow, green, mint, teal, cyan, brown, custom

        public var id: String { rawValue }

        /// Every accent a swatch can show; the custom color has its own picker.
        public static let named: [Accent] = allCases.filter { $0 != .custom }

        public var title: String {
            switch self {
            case .system: "System"
            case .ink: "Ink"
            case .custom: "Custom"
            default: rawValue.capitalized
            }
        }

        /// The Swift expression that produces this accent, or `nil` for the app tint.
        var source: String? {
            switch self {
            case .system: nil
            case .ink: ".primary"
            case .custom: nil
            default: ".\(rawValue)"
            }
        }

        public func color(custom: RGB, dark: RGB? = nil) -> Color? {
            switch self {
            // The app accent rather than nil: registryTheme(_:) can only apply
            // the tint conditionally, so a theme that flips between nil and a
            // value replaces the whole subtree and throws the panel off its
            // tab. The export still omits the accent for System.
            case .system: Color.accentColor
            case .ink: .primary
            case .blue: .blue
            case .indigo: .indigo
            case .purple: .purple
            case .pink: .pink
            case .red: .red
            case .orange: .orange
            case .yellow: .yellow
            case .green: .green
            case .mint: .mint
            case .teal: .teal
            case .cyan: .cyan
            case .brown: .brown
            case .custom:
                if let dark {
                    Color(uiColor: UIColor { traits in
                        traits.userInterfaceStyle == .dark ? dark.uiColor : custom.uiColor
                    })
                } else {
                    custom.color
                }
            }
        }
    }

    public struct RGB: Codable, Equatable, Sendable {
        public var red: Double
        public var green: Double
        public var blue: Double

        var color: Color { Color(red: red, green: green, blue: blue) }
        var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: 1) }

        var source: String {
            "Color(red: \(RGB.format(red)), green: \(RGB.format(green)), blue: \(RGB.format(blue)))"
        }

        var uiSource: String {
            "UIColor(red: \(RGB.format(red)), green: \(RGB.format(green)), blue: \(RGB.format(blue)), alpha: 1)"
        }

        /// The fewest decimals, never under `minimum`, that read back as the
        /// value, so a token off its slider grid exports what the screen shows
        /// and a token on it keeps its short form.
        static func format(_ value: Double, minimum: Int = 3) -> String {
            for digits in minimum...15 {
                let text = String(format: "%.\(digits)f", value)
                if let read = Double(text), abs(read - value) <= 1e-12 * max(1, abs(value)) { return text }
            }
            return "\(value)"
        }

        public init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        public init(_ color: Color) {
            let resolved = color.resolve(in: EnvironmentValues())
            red = Double(resolved.red)
            green = Double(resolved.green)
            blue = Double(resolved.blue)
        }
    }

    public enum Appearance: String, Codable, CaseIterable, Identifiable, Sendable {
        case system, light, dark
        public var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    public enum TextSize: String, Codable, CaseIterable, Identifiable, Sendable {
        case system, large, accessibility
        public var id: String { rawValue }
        var title: String {
            switch self {
            case .system: "System"
            case .large: "XXXL"
            case .accessibility: "AX3"
            }
        }
    }

    /// Preview's layout direction: the system's, or one forced either way.
    public enum Direction: String, Codable, CaseIterable, Identifiable, Sendable {
        case system, leftToRight, rightToLeft
        public var id: String { rawValue }
        var title: String {
            switch self {
            case .system: "System"
            case .leftToRight: "Left to right"
            case .rightToLeft: "Right to left"
            }
        }
    }

    /// The font design the theme carries, applied by `registryTheme(_:)` through
    /// `fontDesign(_:)`. A custom family is never a token: it lives in the Swift
    /// export and the theme package, not in a code.
    public enum FontDesign: String, Codable, CaseIterable, Identifiable, Sendable {
        case `default`, rounded, serif, monospaced
        public var id: String { rawValue }
        var title: String {
            switch self {
            case .default: "System"
            case .rounded: "Rounded"
            case .serif: "Serif"
            case .monospaced: "Mono"
            }
        }

        /// The SwiftUI design; `nil` keeps the system font.
        var design: Font.Design? {
            switch self {
            case .default: nil
            case .rounded: .rounded
            case .serif: .serif
            case .monospaced: .monospaced
            }
        }

        /// The `fontDesign(_:)` argument for the export, or `nil` for the default.
        var source: String? {
            switch self {
            case .default: nil
            case .rounded: ".rounded"
            case .serif: ".serif"
            case .monospaced: ".monospaced"
            }
        }
    }

    /// Which colors the chart draws, kept separate from the accent so a chart
    /// can leave the accent alone. `reserved` (index 3) has no case here, so a
    /// code carrying it is rejected rather than guessed.
    public enum ChartPalette: String, Codable, CaseIterable, Identifiable, Sendable {
        case accent, spectrum, monochrome
        public var id: String { rawValue }
        var title: String {
            switch self {
            case .accent: "Accent"
            case .spectrum: "Spectrum"
            case .monochrome: "Mono"
            }
        }

        var registryPalette: RegistryTheme.ChartPalette {
            switch self {
            case .accent: .accent
            case .spectrum: .spectrum
            case .monochrome: .monochrome
            }
        }
    }

    /// A named bundle of the spacing, padding, and radius metrics. Not a stored
    /// field or part of a code: selecting one writes those seven tokens, and
    /// Tokens shows which bundle the current tokens match, or Custom.
    enum Density: String, CaseIterable, Identifiable {
        case compact, regular, generous
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    public var accent: Accent = .indigo
    public var customAccent = RGB(red: 0.35, green: 0.34, blue: 0.84)
    /// A separate custom accent for dark appearance; `nil` reuses `customAccent`.
    public var customAccentDark: RGB? = nil
    public var darkLabelOnAccent = false
    public var surfaceOpacity = 0.055
    public var borderOpacity = 0.08
    public var borderWidth = 1.0
    public var emphasizedBorderWidth = 2.0
    public var compactRadius = 6.0
    public var controlRadius = 8.0
    public var cardRadius = 16.0
    public var compactSpacing = 8.0
    public var standardSpacing = 16.0
    public var sectionSpacing = 24.0
    public var controlHorizontalPadding = 12.0
    public var disabledOpacity = 0.5
    public var fontDesign: FontDesign = .default
    public var surfaceStep = 0.02
    public var chartPalette: ChartPalette = .accent
    /// Background, foreground, and secondary foreground as optional custom light
    /// and dark pairs; `nil` leaves the system color in place. The dark value is
    /// `nil` unless the pair carries its own dark color.
    public var background: RGB? = nil
    public var backgroundDark: RGB? = nil
    public var foreground: RGB? = nil
    public var foregroundDark: RGB? = nil
    public var secondaryForeground: RGB? = nil
    public var secondaryForegroundDark: RGB? = nil
    /// The environment switches: never part of a theme, a code, or the Swift
    /// export; the surface applies them around the tuned subtree.
    public var appearance: Appearance = .system
    public var textSize: TextSize = .system
    public var direction: Direction = .system

    /// Whether Preview forces right to left; setting `false` returns to the
    /// system direction.
    public var rightToLeft: Bool {
        get { direction == .rightToLeft }
        set { direction = newValue ? .rightToLeft : .system }
    }

    public static let `default` = ThemeTuning()

    public init() {}

    // MARK: Projections for the panel's controls

    /// The custom accent as a color; setting it also selects the custom accent.
    var customAccentColor: Color {
        get { customAccent.color }
        set {
            customAccent = RGB(newValue)
            accent = .custom
        }
    }

    /// The dark custom accent as a color; setting it also selects the custom accent.
    var customAccentDarkColor: Color {
        get { (customAccentDark ?? customAccent).color }
        set {
            customAccentDark = RGB(newValue)
            accent = .custom
        }
    }

    // MARK: Color seeds

    /// What a color token's picker shows before it is set: the system
    /// background, the label, and a lighter step for the secondary text.
    static let backgroundSeed = RGB(red: 1, green: 1, blue: 1)
    static let foregroundSeed = RGB(red: 0, green: 0, blue: 0)
    static let secondaryForegroundSeed = RGB(red: 0.24, green: 0.24, blue: 0.26)

    // MARK: Derived

    /// These tokens as the preset code carries them: each number on its slider
    /// grid, each color at 8 bits a channel. A value that arrives off the grid
    /// (an import, an edited file) renders and exports snapped, so the screen
    /// never shows what the code would change.
    var onCodeGrid: ThemeTuning { ThemeTuning(presetCode: presetCode, base: self) ?? self }

    public var theme: RegistryTheme { onCodeGrid.exactTheme }

    private var exactTheme: RegistryTheme {
        var theme = RegistryTheme(
            accent: accent.color(custom: customAccent, dark: customAccentDark),
            onAccent: onAccent,
            surface: .primary.opacity(surfaceOpacity),
            border: .primary.opacity(borderOpacity),
            disabledOpacity: disabledOpacity,
            metrics: RegistryMetrics(
                compactSpacing: compactSpacing,
                standardSpacing: standardSpacing,
                sectionSpacing: sectionSpacing,
                controlHorizontalPadding: controlHorizontalPadding,
                borderWidth: borderWidth,
                emphasizedBorderWidth: emphasizedBorderWidth,
                compactRadius: compactRadius,
                controlRadius: controlRadius,
                cardRadius: cardRadius
            )
        )
        theme.fontDesign = fontDesign.design
        theme.surfaceOpacity = surfaceOpacity
        theme.surfaceStep = surfaceStep
        theme.chartPalette = chartPalette.registryPalette
        theme.background = Self.dynamicColor(background, dark: backgroundDark)
        theme.foreground = Self.dynamicColor(foreground, dark: foregroundDark)
        theme.secondaryForeground = Self.dynamicColor(secondaryForeground, dark: secondaryForegroundDark)
        return theme
    }

    /// A single color from a light value and an optional dark value, matching
    /// the accent's dual-appearance shape; `nil` when the light value is absent.
    private static func dynamicColor(_ light: RGB?, dark: RGB?) -> Color? {
        guard let light else { return nil }
        guard let dark else { return light.color }
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark.uiColor : light.uiColor
        })
    }

    private var onAccent: Color {
        if accent == .ink { return Color(uiColor: .systemBackground) }
        return darkLabelOnAccent ? .black : .white
    }

    private var onAccentSource: String {
        if accent == .ink { return "Color(uiColor: .systemBackground)" }
        return darkLabelOnAccent ? ".black" : ".white"
    }

    public var preferredColorScheme: ColorScheme? {
        switch appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    public var layoutDirection: LayoutDirection? {
        switch direction {
        case .system: nil
        case .leftToRight: .leftToRight
        case .rightToLeft: .rightToLeft
        }
    }

    public var dynamicTypeSize: DynamicTypeSize? {
        switch textSize {
        case .system: nil
        case .large: .xxxLarge
        case .accessibility: .accessibility3
        }
    }

    /// The exact Swift a consumer pastes; applying it at the root reproduces
    /// what the panel shows.
    public var swiftSource: String { onCodeGrid.exactSwiftSource }

    private var exactSwiftSource: String {
        var lines = ["let theme = RegistryTheme("]
        if accent == .custom, let dark = customAccentDark {
            lines.append("    accent: Color(uiColor: UIColor { traits in")
            lines.append("        traits.userInterfaceStyle == .dark")
            lines.append("            ? \(dark.uiSource)")
            lines.append("            : \(customAccent.uiSource)")
            lines.append("    }),")
        } else if accent == .custom {
            lines.append("    accent: \(customAccent.source),")
        } else if let source = accent.source {
            lines.append("    accent: \(source),")
        }
        lines.append("    onAccent: \(onAccentSource),")
        lines.append("    surface: .primary.opacity(\(RGB.format(surfaceOpacity))),")
        lines.append("    border: .primary.opacity(\(RGB.format(borderOpacity))),")
        lines.append("    disabledOpacity: \(RGB.format(disabledOpacity)),")
        lines.append("    metrics: RegistryMetrics(")
        lines.append("        compactSpacing: \(Self.points(compactSpacing)),")
        lines.append("        standardSpacing: \(Self.points(standardSpacing)),")
        lines.append("        sectionSpacing: \(Self.points(sectionSpacing)),")
        lines.append("        controlHorizontalPadding: \(Self.points(controlHorizontalPadding)),")
        lines.append("        borderWidth: \(Self.points(borderWidth)),")
        lines.append("        emphasizedBorderWidth: \(Self.points(emphasizedBorderWidth)),")
        lines.append("        compactRadius: \(Self.points(compactRadius)),")
        lines.append("        controlRadius: \(Self.points(controlRadius)),")
        lines.append("        cardRadius: \(Self.points(cardRadius))")
        lines.append("    )")
        lines.append(")")
        let extras = newFieldExports
        if !extras.isEmpty {
            lines[0] = "var theme = RegistryTheme("
            lines += extras
        }
        lines.append("")
        lines.append("// Apply once at the root of your scene; every registry item below inherits it.")
        lines.append("ContentView()")
        lines.append("    .registryTheme(theme)")
        return lines.joined(separator: "\n")
    }

    /// The lines the export appends for fields the initializer above does not
    /// carry and that are off their default, so an unchanged tuning still
    /// exports the version-a initializer. `surfaceOpacity` is one of them: the
    /// surface fill alone does not carry it, and `surface(at:)` steps from it.
    private var newFieldExports: [String] {
        var lines: [String] = []
        if let design = fontDesign.source {
            lines.append("theme.fontDesign = \(design)")
        }
        if surfaceOpacity != Self.default.surfaceOpacity {
            lines.append("theme.surfaceOpacity = \(RGB.format(surfaceOpacity))")
        }
        if surfaceStep != Self.default.surfaceStep {
            lines.append("theme.surfaceStep = \(RGB.format(surfaceStep))")
        }
        if chartPalette != .accent {
            lines.append("theme.chartPalette = .\(chartPalette.rawValue)")
        }
        lines += colorPairExport("theme.background", light: background, dark: backgroundDark)
        lines += colorPairExport("theme.foreground", light: foreground, dark: foregroundDark)
        lines += colorPairExport(
            "theme.secondaryForeground", light: secondaryForeground, dark: secondaryForegroundDark
        )
        return lines
    }

    private func colorPairExport(_ property: String, light: RGB?, dark: RGB?) -> [String] {
        guard let light else { return [] }
        guard let dark else { return ["\(property) = \(light.source)"] }
        return [
            "\(property) = Color(uiColor: UIColor { traits in",
            "    traits.userInterfaceStyle == .dark",
            "        ? \(dark.uiSource)",
            "        : \(light.uiSource)",
            "})",
        ]
    }

    private static func points(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : RGB.format(value, minimum: 1)
    }

    // MARK: Import

    /// Reads a preset code, with or without its `--preset` flag, or a
    /// `RegistryTheme(...)` initializer in the exact shape ``swiftSource`` writes
    /// or any subset of its labeled arguments, into the tokens. Unknown or
    /// malformed arguments are ignored; nothing is imported when neither a code
    /// nor a `RegistryTheme(` call is present. Environment switches are never
    /// part of a theme.
    public static func parse(_ swift: String, into base: ThemeTuning = .default) -> ThemeTuning? {
        if let code = presetCode(in: swift) {
            return ThemeTuning(presetCode: code, base: base)
        }
        guard swift.contains("RegistryTheme(") else { return nil }
        var tuning = base
        let text = swift.replacingOccurrences(of: "\n", with: " ")

        func number(_ label: String) -> Double? {
            guard let range = text.range(of: "\\b\(label):\\s*([0-9]+(?:\\.[0-9]+)?)", options: .regularExpression) else {
                return nil
            }
            let match = text[range]
            let digits = match.split(separator: ":").last.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
            return Double(digits)
        }

        func opacity(_ label: String) -> Double? {
            guard let range = text.range(of: "\(label):\\s*\\.primary\\.opacity\\(([0-9.]+)\\)", options: .regularExpression) else {
                return nil
            }
            let match = text[range]
            guard let open = match.lastIndex(of: "("), let close = match.lastIndex(of: ")") else { return nil }
            return Double(match[match.index(after: open)..<close])
        }

        func rgb(after anchor: String) -> RGB? {
            guard let anchorRange = text.range(of: anchor) else { return nil }
            let tail = text[anchorRange.upperBound...]
            guard let range = tail.range(of: "(?:UI)?Color\\(red:\\s*([0-9.]+),\\s*green:\\s*([0-9.]+),\\s*blue:\\s*([0-9.]+)", options: .regularExpression) else {
                return nil
            }
            let parts = tail[range].split(separator: ",").compactMap { part -> Double? in
                Double(part.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) ?? "")
            }
            guard parts.count == 3 else { return nil }
            return RGB(red: parts[0], green: parts[1], blue: parts[2])
        }

        let colors = text.matches(of: #/(?:UI)?Color\(red:\s*([0-9.]+),\s*green:\s*([0-9.]+),\s*blue:\s*([0-9.]+)/#).compactMap { match -> RGB? in
            guard let red = Double(match.1), let green = Double(match.2), let blue = Double(match.3) else { return nil }
            return RGB(red: red, green: green, blue: blue)
        }
        if text.contains("accent: Color(uiColor: UIColor {"), colors.count >= 2 {
            // The dual form lists the dark color after `?`, then the light one after `:`.
            tuning.accent = .custom
            tuning.customAccentDark = colors[0]
            tuning.customAccent = colors[1]
        } else if let range = text.range(of: "accent:\\s*\\.([a-z]+)", options: .regularExpression) {
            let word = text[range].split(separator: ".").last.map(String.init) ?? ""
            let presetNames: [String: Accent] = ["primary": .ink, "rose": .pink, "emerald": .green, "amber": .yellow, "graphite": .ink, "system": .system]
            if let known = presetNames[word] {
                tuning.accent = known
            } else if let named = Accent(rawValue: word) {
                tuning.accent = named
            }
            tuning.customAccentDark = nil
        } else if let custom = rgb(after: "accent:") {
            tuning.accent = .custom
            tuning.customAccent = custom
            tuning.customAccentDark = nil
        }

        if text.contains("onAccent: .black") {
            tuning.darkLabelOnAccent = true
        } else if text.contains("onAccent: .white") {
            tuning.darkLabelOnAccent = false
        }
        if let value = opacity("surface") { tuning.surfaceOpacity = value }
        if let value = opacity("border") { tuning.borderOpacity = value }
        if let value = number("disabledOpacity") { tuning.disabledOpacity = value }
        if let value = number("compactSpacing") { tuning.compactSpacing = value }
        if let value = number("standardSpacing") { tuning.standardSpacing = value }
        if let value = number("sectionSpacing") { tuning.sectionSpacing = value }
        if let value = number("controlHorizontalPadding") { tuning.controlHorizontalPadding = value }
        if let value = number("borderWidth") { tuning.borderWidth = value }
        if let value = number("emphasizedBorderWidth") { tuning.emphasizedBorderWidth = value }
        if let value = number("compactRadius") { tuning.compactRadius = value }
        if let value = number("controlRadius") { tuning.controlRadius = value }
        if let value = number("cardRadius") { tuning.cardRadius = value }
        return tuning
    }

    // MARK: Density

    /// The seven metrics a density bundle sets. Density is derived, never stored:
    /// selecting a bundle writes these tokens, and `matchingDensity` reports which
    /// bundle, if any, the current tokens match.
    private struct DensityMetrics {
        let compactSpacing, standardSpacing, sectionSpacing, controlHorizontalPadding: Double
        let compactRadius, controlRadius, cardRadius: Double
    }

    private static let densityBundles: [Density: DensityMetrics] = [
        .compact: DensityMetrics(
            compactSpacing: 6, standardSpacing: 12, sectionSpacing: 20, controlHorizontalPadding: 10,
            compactRadius: 4, controlRadius: 6, cardRadius: 12
        ),
        .regular: DensityMetrics(
            compactSpacing: 8, standardSpacing: 16, sectionSpacing: 24, controlHorizontalPadding: 12,
            compactRadius: 6, controlRadius: 8, cardRadius: 16
        ),
        .generous: DensityMetrics(
            compactSpacing: 8, standardSpacing: 16, sectionSpacing: 28, controlHorizontalPadding: 16,
            compactRadius: 10, controlRadius: 14, cardRadius: 24
        ),
    ]

    /// Writes a density bundle's seven metrics, leaving every other token alone.
    mutating func apply(density: Density) {
        guard let bundle = Self.densityBundles[density] else { return }
        compactSpacing = bundle.compactSpacing
        standardSpacing = bundle.standardSpacing
        sectionSpacing = bundle.sectionSpacing
        controlHorizontalPadding = bundle.controlHorizontalPadding
        compactRadius = bundle.compactRadius
        controlRadius = bundle.controlRadius
        cardRadius = bundle.cardRadius
    }

    /// The bundle the spacing, padding, and radius tokens currently match, or
    /// `nil` when they match none, in which case the panel shows Custom.
    var matchingDensity: Density? {
        Density.allCases.first { density in
            guard let bundle = Self.densityBundles[density] else { return false }
            return compactSpacing == bundle.compactSpacing
                && standardSpacing == bundle.standardSpacing
                && sectionSpacing == bundle.sectionSpacing
                && controlHorizontalPadding == bundle.controlHorizontalPadding
                && compactRadius == bundle.compactRadius
                && controlRadius == bundle.controlRadius
                && cardRadius == bundle.cardRadius
        }
    }

    // MARK: Presets

    /// Loads a foundation preset's accent choice into the tokens, keeping the
    /// tuned metrics. MANGO is the exception: its strokeless surface and
    /// generous radii are part of its identity, so its case decodes the whole
    /// tuning from its preset code, keeping only the environment switches.
    mutating func apply(presetNamed name: String) {
        switch name {
        case "System": accent = .system; darkLabelOnAccent = false
        case "Graphite": accent = .ink; darkLabelOnAccent = false
        case "Indigo": accent = .indigo; darkLabelOnAccent = false
        case "Rose": accent = .pink; darkLabelOnAccent = false
        case "Emerald": accent = .green; darkLabelOnAccent = false
        case "Amber": accent = .yellow; darkLabelOnAccent = true
        case "Mango":
            // MANGO carries its own metrics, not only an accent, so decode its
            // pinned preset code (Registry/preset_vectors.json) over self to
            // load every token while keeping the environment switches.
            if let mango = ThemeTuning(presetCode: "a74hGF01CVunaG0vzZJG", base: self) {
                self = mango
            }
        default: break
        }
    }
}
#endif
