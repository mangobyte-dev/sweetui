#if canImport(UIKit)
import Foundation

/// Preset codes: the tuning knobs as a short shareable string, the same code
/// `sweetui preset` and the website's `/create` page speak. Fields
/// pack little-endian in the reference order into one integer written in
/// base62 behind a version letter; numeric knobs store their slider-grid
/// index. Version `a` is the twelve-metric layout; version `b` appends, after
/// the custom accent block, the font design, the surface step, the chart
/// palette, and three optional color pairs, and a version `a` code still
/// decodes. The format rules live in `docs/registry-spec.md` and the pinned
/// vectors in `Registry/preset_vectors.json`.
extension ThemeTuning {
    static let presetVersionA: Character = "a"
    static let presetVersionB: Character = "b"
    private static let presetAlphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    /// A `b` code, with three color pairs on top of a custom accent pair, needs
    /// more room than an `a` code; the ceiling is shared, as in the reference
    /// `Preset.swift`, and an out-of-range field index is what rejects a code.
    private static let presetMaximumLength = 48
    private static let accentBits = 4
    private static let channelBits = 24

    // Version `b` appended fields, in order, after the custom accent block.
    private static let fontDesignBits = 2
    private static let surfaceStepBits = 3
    private static let chartPaletteBits = 2
    /// Surface step is a value list, not a grid, so the default 0.02 sits at
    /// index 0 as the spec's default-at-zero rule requires.
    static let surfaceStepValues: [Double] = [0.02, 0.00, 0.01, 0.03, 0.04, 0.05, 0.06, 0.07]

    private struct NumericField: Sendable {
        let keyPath: WritableKeyPath<ThemeTuning, Double> & Sendable
        let bits: Int
        let minimum: Double
        let step: Double
        let count: Int
        let decimals: Int

        func index(of value: Double) -> Int {
            let index = Int(((value - minimum) / step).rounded())
            return max(0, min(count - 1, index))
        }

        func value(at index: Int) -> Double {
            let scale = pow(10, Double(decimals))
            return ((minimum + Double(index) * step) * scale).rounded() / scale
        }
    }

    private static let numericFields: [NumericField] = [
        NumericField(keyPath: \.surfaceOpacity, bits: 6, minimum: 0, step: 0.005, count: 41, decimals: 3),
        NumericField(keyPath: \.borderOpacity, bits: 5, minimum: 0, step: 0.01, count: 31, decimals: 2),
        NumericField(keyPath: \.borderWidth, bits: 3, minimum: 0.5, step: 0.5, count: 6, decimals: 1),
        NumericField(keyPath: \.emphasizedBorderWidth, bits: 3, minimum: 1, step: 0.5, count: 7, decimals: 1),
        NumericField(keyPath: \.compactRadius, bits: 4, minimum: 0, step: 1, count: 13, decimals: 0),
        NumericField(keyPath: \.controlRadius, bits: 5, minimum: 0, step: 1, count: 23, decimals: 0),
        NumericField(keyPath: \.cardRadius, bits: 6, minimum: 0, step: 1, count: 33, decimals: 0),
        NumericField(keyPath: \.compactSpacing, bits: 4, minimum: 4, step: 1, count: 13, decimals: 0),
        NumericField(keyPath: \.standardSpacing, bits: 5, minimum: 8, step: 1, count: 25, decimals: 0),
        NumericField(keyPath: \.sectionSpacing, bits: 6, minimum: 12, step: 1, count: 37, decimals: 0),
        NumericField(keyPath: \.controlHorizontalPadding, bits: 5, minimum: 8, step: 1, count: 17, decimals: 0),
        NumericField(keyPath: \.disabledOpacity, bits: 4, minimum: 0.2, step: 0.05, count: 13, decimals: 2),
    ]

    /// The index of a surface-step value on the value list, snapping an off-list
    /// value to its nearest entry.
    private static func surfaceStepIndex(of value: Double) -> Int {
        var best = 0
        var bestDelta = Double.infinity
        for (index, listed) in surfaceStepValues.enumerated() {
            let delta = abs(listed - value)
            if delta < bestDelta {
                bestDelta = delta
                best = index
            }
        }
        return best
    }

    /// Whether the text has the shape of a code: a known version letter, a
    /// length within that version's ceiling, then base62.
    static func isPresetCode(_ value: String) -> Bool {
        guard let first = value.first, first == presetVersionA || first == presetVersionB else {
            return false
        }
        guard value.count >= 2, value.count <= presetMaximumLength else { return false }
        return value.dropFirst().allSatisfy { presetAlphabet.contains($0) }
    }

    /// The code inside pasted text: bare, or behind a `--preset` flag.
    static func presetCode(in text: String) -> String? {
        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = candidate.range(of: #"^--preset\s+"#, options: .regularExpression) {
            candidate = String(candidate[range.upperBound...])
        }
        return isPresetCode(candidate) ? candidate : nil
    }

    /// Whether any version-b field is off its default; when it is, the code is
    /// written as `b`, otherwise as `a` so an unchanged tuning keeps its code.
    private var appendedIsNonDefault: Bool {
        fontDesign != .default
            || Self.surfaceStepIndex(of: surfaceStep) != 0
            || chartPalette != .accent
            || background != nil
            || foreground != nil
            || secondaryForeground != nil
    }

    /// The code for these knobs; numeric values snap to their slider grid.
    public var presetCode: String {
        var writer = BitWriter()
        writeBaseBits(into: &writer)
        if appendedIsNonDefault {
            writeAppendedBits(into: &writer)
            return String(Self.presetVersionB) + Self.base62(writer.value)
        }
        return String(Self.presetVersionA) + Self.base62(writer.value)
    }

    private func writeBaseBits(into writer: inout BitWriter) {
        writer.write(Accent.allCases.firstIndex(of: accent) ?? 0, bits: Self.accentBits)
        writer.write(darkLabelOnAccent ? 1 : 0, bits: 1)
        for field in Self.numericFields {
            writer.write(field.index(of: self[keyPath: field.keyPath]), bits: field.bits)
        }
        if accent == .custom {
            writer.write(customAccent.packed, bits: Self.channelBits)
            writer.write(customAccentDark == nil ? 0 : 1, bits: 1)
            if let dark = customAccentDark {
                writer.write(dark.packed, bits: Self.channelBits)
            }
        }
    }

    private func writeAppendedBits(into writer: inout BitWriter) {
        writer.write(FontDesign.allCases.firstIndex(of: fontDesign) ?? 0, bits: Self.fontDesignBits)
        writer.write(Self.surfaceStepIndex(of: surfaceStep), bits: Self.surfaceStepBits)
        writer.write(ChartPalette.allCases.firstIndex(of: chartPalette) ?? 0, bits: Self.chartPaletteBits)
        writePair(light: background, dark: backgroundDark, into: &writer)
        writePair(light: foreground, dark: foregroundDark, into: &writer)
        writePair(light: secondaryForeground, dark: secondaryForegroundDark, into: &writer)
    }

    private func writePair(light: RGB?, dark: RGB?, into writer: inout BitWriter) {
        guard let light else {
            writer.write(0, bits: 1)
            return
        }
        writer.write(1, bits: 1)
        writer.write(light.packed, bits: Self.channelBits)
        if let dark {
            writer.write(1, bits: 1)
            writer.write(dark.packed, bits: Self.channelBits)
        } else {
            writer.write(0, bits: 1)
        }
    }

    /// The knobs a code carries, over `base` for what a code never stores
    /// (the environment switches and a named accent's remembered custom
    /// color); `nil` when the text is not a valid code. A version `a` code
    /// yields the version-b defaults for the appended fields.
    public init?(presetCode: String, base: ThemeTuning = .default) {
        guard Self.isPresetCode(presetCode), let version = presetCode.first,
              let number = Self.number(fromBase62: presetCode.dropFirst()) else { return nil }
        var reader = BitReader(value: number)
        var tuning = base
        guard Self.readBaseBits(into: &tuning, from: &reader) else { return nil }
        if version == Self.presetVersionB {
            guard Self.readAppendedBits(into: &tuning, from: &reader) else { return nil }
        } else {
            Self.applyAppendedDefaults(to: &tuning)
        }
        self = tuning
    }

    private static func readBaseBits(into tuning: inout ThemeTuning, from reader: inout BitReader) -> Bool {
        let accentIndex = reader.read(bits: accentBits)
        guard accentIndex < Accent.allCases.count else { return false }
        tuning.accent = Accent.allCases[accentIndex]
        tuning.darkLabelOnAccent = reader.read(bits: 1) == 1
        for field in numericFields {
            let index = reader.read(bits: field.bits)
            guard index < field.count else { return false }
            tuning[keyPath: field.keyPath] = field.value(at: index)
        }
        if tuning.accent == .custom {
            tuning.customAccent = RGB(packed: reader.read(bits: channelBits))
            let hasDark = reader.read(bits: 1) == 1
            tuning.customAccentDark = hasDark ? RGB(packed: reader.read(bits: channelBits)) : nil
        }
        return true
    }

    private static func readAppendedBits(into tuning: inout ThemeTuning, from reader: inout BitReader) -> Bool {
        let fontIndex = reader.read(bits: fontDesignBits)
        guard fontIndex < FontDesign.allCases.count else { return false }
        tuning.fontDesign = FontDesign.allCases[fontIndex]
        let stepIndex = reader.read(bits: surfaceStepBits)
        guard stepIndex < surfaceStepValues.count else { return false }
        tuning.surfaceStep = surfaceStepValues[stepIndex]
        // Two bits carry four slots but only three palettes; the fourth is
        // reserved, so a code that names it is invalid rather than guessed.
        let chartIndex = reader.read(bits: chartPaletteBits)
        guard chartIndex < ChartPalette.allCases.count else { return false }
        tuning.chartPalette = ChartPalette.allCases[chartIndex]
        (tuning.background, tuning.backgroundDark) = readPair(from: &reader)
        (tuning.foreground, tuning.foregroundDark) = readPair(from: &reader)
        (tuning.secondaryForeground, tuning.secondaryForegroundDark) = readPair(from: &reader)
        return true
    }

    private static func readPair(from reader: inout BitReader) -> (RGB?, RGB?) {
        guard reader.read(bits: 1) == 1 else { return (nil, nil) }
        let light = RGB(packed: reader.read(bits: channelBits))
        let dark = reader.read(bits: 1) == 1 ? RGB(packed: reader.read(bits: channelBits)) : nil
        return (light, dark)
    }

    private static func applyAppendedDefaults(to tuning: inout ThemeTuning) {
        tuning.fontDesign = .default
        tuning.surfaceStep = surfaceStepValues[0]
        tuning.chartPalette = .accent
        tuning.background = nil
        tuning.backgroundDark = nil
        tuning.foreground = nil
        tuning.foregroundDark = nil
        tuning.secondaryForeground = nil
        tuning.secondaryForegroundDark = nil
    }

    private static func base62(_ number: BigUInt) -> String {
        guard !number.isZero else { return "0" }
        var digits: [Character] = []
        var remaining = number
        while !remaining.isZero {
            digits.append(presetAlphabet[Int(remaining.divide(by: 62))])
        }
        return String(digits.reversed())
    }

    private static func number(fromBase62 text: Substring) -> BigUInt? {
        var number = BigUInt()
        for character in text {
            guard let digit = presetAlphabet.firstIndex(of: character) else { return nil }
            number.multiply(by: 62, adding: UInt32(digit))
        }
        return number
    }

    /// A little-endian arbitrary-precision unsigned integer. A version `b` code
    /// with three color pairs on top of a custom accent pair reaches 264 bits,
    /// past what `UInt128` holds, so the packed value is a limb array.
    private struct BigUInt {
        private var limbs: [UInt32] = []

        var isZero: Bool { limbs.isEmpty }

        mutating func setBit(at index: Int) {
            let word = index >> 5
            let offset = index & 31
            while limbs.count <= word { limbs.append(0) }
            limbs[word] |= UInt32(1) << UInt32(offset)
        }

        func bit(at index: Int) -> Int {
            let word = index >> 5
            guard word < limbs.count else { return 0 }
            return Int((limbs[word] >> UInt32(index & 31)) & 1)
        }

        /// Multiplies by a small factor and adds a small term, for base62 parsing.
        mutating func multiply(by factor: UInt32, adding addend: UInt32) {
            var carry = UInt64(addend)
            for i in limbs.indices {
                let value = UInt64(limbs[i]) * UInt64(factor) + carry
                limbs[i] = UInt32(truncatingIfNeeded: value)
                carry = value >> 32
            }
            while carry > 0 {
                limbs.append(UInt32(truncatingIfNeeded: carry))
                carry >>= 32
            }
        }

        /// Divides by a small divisor in place and returns the remainder, for
        /// base62 rendering.
        mutating func divide(by divisor: UInt32) -> UInt32 {
            var remainder: UInt64 = 0
            var i = limbs.count - 1
            while i >= 0 {
                let current = (remainder << 32) | UInt64(limbs[i])
                limbs[i] = UInt32(current / UInt64(divisor))
                remainder = current % UInt64(divisor)
                i -= 1
            }
            while let last = limbs.last, last == 0 { limbs.removeLast() }
            return UInt32(remainder)
        }
    }

    private struct BitWriter {
        var value = BigUInt()
        private var offset = 0

        mutating func write(_ field: Int, bits width: Int) {
            for k in 0..<width where (field >> k) & 1 == 1 {
                value.setBit(at: offset + k)
            }
            offset += width
        }
    }

    private struct BitReader {
        let value: BigUInt
        private var offset = 0

        init(value: BigUInt) {
            self.value = value
        }

        mutating func read(bits width: Int) -> Int {
            var result = 0
            for k in 0..<width {
                result |= value.bit(at: offset + k) << k
            }
            offset += width
            return result
        }
    }
}

extension ThemeTuning.RGB {
    /// Eight bits per channel, red highest, the way a hex color is written.
    var packed: Int {
        (Self.channel(red) << 16) | (Self.channel(green) << 8) | Self.channel(blue)
    }

    init(packed: Int) {
        self.init(
            red: Double((packed >> 16) & 0xFF) / 255,
            green: Double((packed >> 8) & 0xFF) / 255,
            blue: Double(packed & 0xFF) / 255
        )
    }

    private static func channel(_ value: Double) -> Int {
        max(0, min(255, Int((value * 255).rounded())))
    }
}
#endif
