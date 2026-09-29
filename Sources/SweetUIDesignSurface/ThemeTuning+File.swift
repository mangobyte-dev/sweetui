#if canImport(UIKit)
import Foundation

/// The file shape of a tuning: the JSON `registry-tokens.json` carries.
///
/// `tuning` holds the same keys `sweetui preset decode --json` prints
/// under its `tuning` object, every key always present and colors spelled
/// `#RRGGBB`, so a person and an agent read one shape; `code` and `version`
/// name the same knobs as a preset code, the string every registry tool and
/// the website accept. `environment` holds the switches a code never carries.
/// Decoding is forgiving in one direction: a `tuning` object may name any
/// subset of the keys and the rest keep their defaults, and a document with
/// only a `code` loads that code, so an agent can push a theme onto the
/// device by writing either.
extension ThemeTuning: Codable {
    private enum CodingKeys: String, CodingKey {
        case code, version, tuning, environment
    }

    private enum TuningKeys: String, CodingKey {
        case accent, darkLabelOnAccent, customAccent, customAccentDark
        case surfaceOpacity, borderOpacity, borderWidth, emphasizedBorderWidth
        case compactRadius, controlRadius, cardRadius
        case compactSpacing, standardSpacing, sectionSpacing, controlHorizontalPadding
        case disabledOpacity
        case fontDesign, surfaceStep, chartPalette
        case background, backgroundDark, foreground, foregroundDark
        case secondaryForeground, secondaryForegroundDark
    }

    private enum EnvironmentKeys: String, CodingKey {
        case appearance, textSize, rightToLeft
    }

    /// The numeric knobs in the reference order, each with its key.
    private static let numericKeys: [(key: TuningKeys, path: WritableKeyPath<ThemeTuning, Double> & Sendable)] = [
        (.surfaceOpacity, \.surfaceOpacity),
        (.borderOpacity, \.borderOpacity),
        (.borderWidth, \.borderWidth),
        (.emphasizedBorderWidth, \.emphasizedBorderWidth),
        (.compactRadius, \.compactRadius),
        (.controlRadius, \.controlRadius),
        (.cardRadius, \.cardRadius),
        (.compactSpacing, \.compactSpacing),
        (.standardSpacing, \.standardSpacing),
        (.sectionSpacing, \.sectionSpacing),
        (.controlHorizontalPadding, \.controlHorizontalPadding),
        (.disabledOpacity, \.disabledOpacity),
        (.surfaceStep, \.surfaceStep),
    ]

    /// The optional color pairs, each with its key.
    private static let colorKeys: [(key: TuningKeys, path: WritableKeyPath<ThemeTuning, RGB?> & Sendable)] = [
        (.customAccentDark, \.customAccentDark),
        (.background, \.background),
        (.backgroundDark, \.backgroundDark),
        (.foreground, \.foreground),
        (.foregroundDark, \.foregroundDark),
        (.secondaryForeground, \.secondaryForeground),
        (.secondaryForegroundDark, \.secondaryForegroundDark),
    ]

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let code = presetCode
        try container.encode(code, forKey: .code)
        try container.encode(String(code.prefix(1)), forKey: .version)

        var tuning = container.nestedContainer(keyedBy: TuningKeys.self, forKey: .tuning)
        try tuning.encode(accent.rawValue, forKey: .accent)
        try tuning.encode(darkLabelOnAccent, forKey: .darkLabelOnAccent)
        try tuning.encode(customAccent.hex, forKey: .customAccent)
        for field in Self.numericKeys {
            try tuning.encode(self[keyPath: field.path], forKey: field.key)
        }
        try tuning.encode(fontDesign.rawValue, forKey: .fontDesign)
        try tuning.encode(chartPalette.rawValue, forKey: .chartPalette)
        for field in Self.colorKeys {
            try tuning.encode(self[keyPath: field.path]?.hex, forKey: field.key)
        }

        var environment = container.nestedContainer(keyedBy: EnvironmentKeys.self, forKey: .environment)
        try environment.encode(appearance.rawValue, forKey: .appearance)
        try environment.encode(textSize.rawValue, forKey: .textSize)
        try environment.encode(rightToLeft, forKey: .rightToLeft)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var result = ThemeTuning.default

        if container.contains(.tuning) {
            let tuning = try container.nestedContainer(keyedBy: TuningKeys.self, forKey: .tuning)
            func word<Word: RawRepresentable>(_ key: TuningKeys, as type: Word.Type) throws -> Word?
            where Word.RawValue == String {
                guard let raw = try tuning.decodeIfPresent(String.self, forKey: key) else { return nil }
                guard let value = Word(rawValue: raw) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: key, in: tuning, debugDescription: "unknown \(key.rawValue) '\(raw)'")
                }
                return value
            }
            func color(_ key: TuningKeys) throws -> RGB?? {
                guard tuning.contains(key) else { return nil }
                guard let raw = try tuning.decodeIfPresent(String.self, forKey: key) else { return .some(nil) }
                guard let value = RGB(hex: raw) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: key, in: tuning, debugDescription: "\(key.rawValue) is not #RRGGBB: '\(raw)'")
                }
                return .some(value)
            }
            if let accent = try word(.accent, as: Accent.self) { result.accent = accent }
            if let flag = try tuning.decodeIfPresent(Bool.self, forKey: .darkLabelOnAccent) {
                result.darkLabelOnAccent = flag
            }
            if let custom = try color(.customAccent), let custom { result.customAccent = custom }
            for field in Self.numericKeys {
                if let value = try tuning.decodeIfPresent(Double.self, forKey: field.key) {
                    result[keyPath: field.path] = value
                }
            }
            if let design = try word(.fontDesign, as: FontDesign.self) { result.fontDesign = design }
            if let palette = try word(.chartPalette, as: ChartPalette.self) { result.chartPalette = palette }
            for field in Self.colorKeys {
                if let value = try color(field.key) { result[keyPath: field.path] = value }
            }
        } else if let code = try container.decodeIfPresent(String.self, forKey: .code) {
            guard let decoded = ThemeTuning(presetCode: code) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .code, in: container, debugDescription: "invalid preset code '\(code)'")
            }
            result = decoded
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.tuning,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "a design tokens document needs a tuning object or a code"))
        }

        if container.contains(.environment) {
            let environment = try container.nestedContainer(keyedBy: EnvironmentKeys.self, forKey: .environment)
            if let raw = try environment.decodeIfPresent(String.self, forKey: .appearance),
               let appearance = Appearance(rawValue: raw) {
                result.appearance = appearance
            }
            if let raw = try environment.decodeIfPresent(String.self, forKey: .textSize),
               let size = TextSize(rawValue: raw) {
                result.textSize = size
            }
            if let flag = try environment.decodeIfPresent(Bool.self, forKey: .rightToLeft) {
                result.rightToLeft = flag
            }
        }
        self = result
    }
}

extension ThemeTuning.RGB {
    /// `#RRGGBB`, the spelling the preset tools print.
    var hex: String {
        String(format: "#%06X", packed)
    }

    init?(hex: String) {
        guard hex.count == 7, hex.hasPrefix("#"), let packed = Int(hex.dropFirst(), radix: 16) else {
            return nil
        }
        self.init(packed: packed)
    }
}
#endif
