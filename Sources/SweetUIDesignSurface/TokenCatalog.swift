#if canImport(UIKit)
import Foundation

/// Every theme value Tune edits, as a token: its key in `registry-tokens.json`,
/// its title, its group, how its row draws it, and the `RegistryTheme` fields it
/// moves, named as `RegistryItemTokens` names them. A color token carries its
/// Dark value under `<key>Dark`; the accent token carries the custom accent
/// pair. Every key a preset code encodes belongs to exactly one token.
enum TokenCatalog {
    struct Token: Identifiable, Sendable {
        enum Group: String, CaseIterable, Identifiable, Sendable {
            case color, type, space, shape, surface, chart, disabled
            var id: String { rawValue }
            var title: String { rawValue.capitalized }
        }

        enum Kind: Sendable {
            /// A number on its code grid, read in `unit` with `fraction` decimals.
            case number(
                WritableKeyPath<ThemeTuning, Double> & Sendable, range: ClosedRange<Double>, step: Double,
                fraction: Int = 0, unit: String = "")
            /// One of a few words, stored as the option's index.
            case choice([String], index: WritableKeyPath<ThemeTuning, Int> & Sendable)
            /// A Light value and an optional Dark one; `nil` keeps the system color,
            /// which the picker shows as `seed` until it is set.
            case color(
                light: WritableKeyPath<ThemeTuning, ThemeTuning.RGB?> & Sendable,
                dark: WritableKeyPath<ThemeTuning, ThemeTuning.RGB?> & Sendable, seed: ThemeTuning.RGB)
            /// A named accent, or a custom one with an optional Dark value.
            case accent
        }

        let key: String
        let title: String
        let group: Group
        let kind: Kind
        /// The `RegistryTheme` fields this token moves.
        let drives: Set<String>
        var id: String { key }

        /// The file's keys this token owns.
        var codeKeys: [String] {
            switch kind {
            case .accent: ["accent", "customAccent", "customAccentDark"]
            case .color: [key, key + "Dark"]
            case .number, .choice: [key]
            }
        }

        /// A number's unit, such as "pt"; `nil` for a plain number or another kind.
        var unit: String? {
            guard case .number(_, _, _, _, let unit) = kind, !unit.isEmpty else { return nil }
            return unit
        }

        /// Whether the tuning moves it off Default.
        func isChanged(_ tuning: ThemeTuning) -> Bool {
            !Set(tuning.differences(from: .default).map(\.key)).isDisjoint(with: codeKeys)
        }

        /// The value in words: "16 pt", "Rounded", "#FFFFFF, dark #1C1C1E", "System".
        func value(_ tuning: ThemeTuning) -> String {
            switch kind {
            case .number(let path, _, _, let fraction, let unit):
                let number = tuning[keyPath: path].formatted(.number.precision(.fractionLength(fraction)))
                return unit.isEmpty ? number : "\(number) \(unit)"
            case .choice(let options, let index):
                return options[min(max(tuning[keyPath: index], 0), options.count - 1)]
            case .color(let light, let dark, _):
                return Self.pair(tuning[keyPath: light], tuning[keyPath: dark])
            case .accent:
                guard tuning.accent == .custom else { return tuning.accent.title }
                return Self.pair(tuning.customAccent, tuning.customAccentDark)
            }
        }

        private static func pair(_ light: ThemeTuning.RGB?, _ dark: ThemeTuning.RGB?) -> String {
            guard let light else { return "System" }
            return dark.map { "\(light.hex), dark \($0.hex)" } ?? light.hex
        }

        /// Whether it carries a Dark value of its own, which Use the Light value clears.
        func hasDarkValue(_ tuning: ThemeTuning) -> Bool {
            switch kind {
            case .color(_, let dark, _): tuning[keyPath: dark] != nil
            case .accent: tuning.accent == .custom && tuning.customAccentDark != nil
            case .number, .choice: false
            }
        }

        /// Puts it back to Default.
        func reset(_ tuning: inout ThemeTuning) {
            let base = ThemeTuning.default
            switch kind {
            case .number(let path, _, _, _, _): tuning[keyPath: path] = base[keyPath: path]
            case .choice(_, let index): tuning[keyPath: index] = base[keyPath: index]
            case .color(let light, let dark, _):
                tuning[keyPath: light] = nil
                tuning[keyPath: dark] = nil
            case .accent:
                tuning.accent = base.accent
                tuning.customAccent = base.customAccent
                tuning.customAccentDark = nil
            }
        }

        /// Clears the Dark value, so dark shows the Light one.
        func useLightValue(_ tuning: inout ThemeTuning) {
            switch kind {
            case .color(_, let dark, _): tuning[keyPath: dark] = nil
            case .accent: tuning.customAccentDark = nil
            case .number, .choice: break
            }
        }
    }

    /// The theme's tokens in their groups' order, each group in row order.
    static let theme: [Token] = [
        Token(key: "accent", title: "Accent", group: .color, kind: .accent, drives: ["accent", "onAccent"]),
        Token(
            key: "darkLabelOnAccent", title: "Label on accent", group: .color,
            kind: .choice(["White", "Black"], index: \.labelOnAccentIndex), drives: ["onAccent"]),
        Token(
            key: "background", title: "Background", group: .color,
            kind: .color(light: \.background, dark: \.backgroundDark, seed: ThemeTuning.backgroundSeed), drives: []),
        Token(
            key: "foreground", title: "Foreground", group: .color,
            kind: .color(light: \.foreground, dark: \.foregroundDark, seed: ThemeTuning.foregroundSeed), drives: []),
        Token(
            key: "secondaryForeground", title: "Secondary foreground", group: .color,
            kind: .color(
                light: \.secondaryForeground, dark: \.secondaryForegroundDark,
                seed: ThemeTuning.secondaryForegroundSeed),
            drives: []),
        Token(
            key: "fontDesign", title: "Font design", group: .type,
            kind: .choice(ThemeTuning.FontDesign.allCases.map(\.title), index: \.fontDesignIndex), drives: []),
        Token(
            key: "compactSpacing", title: "Compact spacing", group: .space,
            kind: .number(\.compactSpacing, range: 4...16, step: 1, unit: "pt"), drives: ["compactSpacing"]),
        Token(
            key: "standardSpacing", title: "Standard spacing", group: .space,
            kind: .number(\.standardSpacing, range: 8...32, step: 1, unit: "pt"), drives: ["standardSpacing"]),
        Token(
            key: "sectionSpacing", title: "Section spacing", group: .space,
            kind: .number(\.sectionSpacing, range: 12...48, step: 1, unit: "pt"), drives: ["sectionSpacing"]),
        Token(
            key: "controlHorizontalPadding", title: "Control padding", group: .space,
            kind: .number(\.controlHorizontalPadding, range: 8...24, step: 1, unit: "pt"),
            drives: ["controlHorizontalPadding"]),
        Token(
            key: "compactRadius", title: "Compact radius", group: .shape,
            kind: .number(\.compactRadius, range: 0...12, step: 1, unit: "pt"), drives: ["compactRadius"]),
        Token(
            key: "controlRadius", title: "Control radius", group: .shape,
            kind: .number(\.controlRadius, range: 0...22, step: 1, unit: "pt"), drives: ["controlRadius"]),
        Token(
            key: "cardRadius", title: "Card radius", group: .shape,
            kind: .number(\.cardRadius, range: 0...32, step: 1, unit: "pt"), drives: ["cardRadius"]),
        Token(
            key: "surfaceOpacity", title: "Surface opacity", group: .surface,
            kind: .number(\.surfaceOpacity, range: 0...0.2, step: 0.005, fraction: 3),
            drives: ["surface", "surfaceOpacity"]),
        Token(
            key: "surfaceStep", title: "Surface step", group: .surface,
            kind: .number(\.surfaceStep, range: 0...0.07, step: 0.01, fraction: 2), drives: ["surfaceStep"]),
        Token(
            key: "borderOpacity", title: "Border opacity", group: .surface,
            kind: .number(\.borderOpacity, range: 0...0.3, step: 0.01, fraction: 2), drives: ["border"]),
        Token(
            key: "borderWidth", title: "Border width", group: .surface,
            kind: .number(\.borderWidth, range: 0.5...3, step: 0.5, fraction: 1, unit: "pt"), drives: ["borderWidth"]),
        Token(
            key: "emphasizedBorderWidth", title: "Emphasized border", group: .surface,
            kind: .number(\.emphasizedBorderWidth, range: 1...4, step: 0.5, fraction: 1, unit: "pt"),
            drives: ["emphasizedBorderWidth"]),
        Token(
            key: "chartPalette", title: "Chart palette", group: .chart,
            kind: .choice(ThemeTuning.ChartPalette.allCases.map(\.title), index: \.chartPaletteIndex),
            drives: ["chartPalette"]),
        Token(
            key: "disabledOpacity", title: "Disabled opacity", group: .disabled,
            kind: .number(\.disabledOpacity, range: 0.2...0.8, step: 0.05, fraction: 2), drives: ["disabledOpacity"]),
    ]

    /// The token that owns a file key.
    static func token(owning key: String) -> Token? {
        theme.first { $0.codeKeys.contains(key) }
    }

    /// A file key's title: its token's, "Background, Dark" for a Dark value,
    /// "Custom accent" for the accent's custom pair; the key for one no token owns.
    static func title(ofKey key: String) -> String {
        guard let token = token(owning: key) else { return key }
        switch key {
        case token.key: return token.title
        case "customAccent": return "Custom accent"
        case "customAccentDark": return "Custom accent, Dark"
        default: return "\(token.title), Dark"
        }
    }

    /// Fields items read that no token moves.
    static let fixed: Set<String> = ["negative", "positive"]

    /// The tokens `registryTheme(_:)` applies to the whole tree (the tint, the
    /// font design, the text colors, the background), so they reach every item.
    static let reachesEveryItem: Set<String> = ["accent", "fontDesign", "background", "foreground", "secondaryForeground"]

    /// Whether the token moves the item. An item the registry does not know
    /// may read anything, so every token reaches it.
    static func reaches(_ token: Token, _ item: String) -> Bool {
        guard let fields = RegistryItemTokens.tokens(for: item) else { return true }
        return reachesEveryItem.contains(token.key) || !token.drives.isDisjoint(with: fields)
    }

    /// The tokens that move the item, in the theme's order.
    static func reaching(_ item: String) -> [Token] {
        theme.filter { reaches($0, item) }
    }

    /// The fields the item reads that no token moves, sorted.
    static func fixedFields(of item: String) -> [String] {
        (RegistryItemTokens.tokens(for: item) ?? []).filter(fixed.contains).sorted()
    }
}

extension ThemeTuning {
    /// The choice tokens' options by index, for their pickers.
    var labelOnAccentIndex: Int {
        get { darkLabelOnAccent ? 1 : 0 }
        set { darkLabelOnAccent = newValue == 1 }
    }

    var fontDesignIndex: Int {
        get { FontDesign.allCases.firstIndex(of: fontDesign) ?? 0 }
        set { fontDesign = FontDesign.allCases[newValue] }
    }

    var chartPaletteIndex: Int {
        get { ChartPalette.allCases.firstIndex(of: chartPalette) ?? 0 }
        set { chartPalette = ChartPalette.allCases[newValue] }
    }
}
#endif
