import Foundation
import Testing
@testable import SweetUIDesignSurface

/// The Showcase speaks the same preset codes as `sweetui preset` and
/// the website: every vector pinned in `Registry/preset_vectors.json` must
/// encode and decode identically here, or a code copied from the Tune panel
/// would mean something else on the website. Version `b` appends the font
/// design, surface step, chart palette, and three optional color pairs, and a
/// version `a` code still decodes to the same tuning plus the new defaults.
struct ThemePresetTests {
    struct Document: Decodable {
        let vectors: [Vector]
    }

    struct Vector: Decodable {
        let name: String
        let code: String
        let tuning: Knobs
    }

    struct Knobs: Decodable {
        let accent: String
        let darkLabelOnAccent: Bool
        let surfaceOpacity: Double
        let borderOpacity: Double
        let borderWidth: Double
        let emphasizedBorderWidth: Double
        let compactRadius: Double
        let controlRadius: Double
        let cardRadius: Double
        let compactSpacing: Double
        let standardSpacing: Double
        let sectionSpacing: Double
        let controlHorizontalPadding: Double
        let disabledOpacity: Double
        let customAccent: String?
        let customAccentDark: String?
        // Version b fields; absent on an a vector.
        let fontDesign: String?
        let surfaceStep: Double?
        let chartPalette: String?
        let background: String?
        let backgroundDark: String?
        let foreground: String?
        let foregroundDark: String?
        let secondaryForeground: String?
        let secondaryForegroundDark: String?
    }

    static let vectors: [Vector] = {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { url.deleteLastPathComponent() }
        url.append(path: "Registry/preset_vectors.json")
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(Document.self, from: data).vectors
    }()

    static func vector(named prefix: String) -> Vector {
        vectors.first { $0.name.hasPrefix(prefix) }!
    }

    static func tuning(from knobs: Knobs) -> ThemeTuning {
        var tuning = ThemeTuning.default
        tuning.accent = ThemeTuning.Accent(rawValue: knobs.accent)!
        tuning.darkLabelOnAccent = knobs.darkLabelOnAccent
        tuning.surfaceOpacity = knobs.surfaceOpacity
        tuning.borderOpacity = knobs.borderOpacity
        tuning.borderWidth = knobs.borderWidth
        tuning.emphasizedBorderWidth = knobs.emphasizedBorderWidth
        tuning.compactRadius = knobs.compactRadius
        tuning.controlRadius = knobs.controlRadius
        tuning.cardRadius = knobs.cardRadius
        tuning.compactSpacing = knobs.compactSpacing
        tuning.standardSpacing = knobs.standardSpacing
        tuning.sectionSpacing = knobs.sectionSpacing
        tuning.controlHorizontalPadding = knobs.controlHorizontalPadding
        tuning.disabledOpacity = knobs.disabledOpacity
        if let hex = knobs.customAccent { tuning.customAccent = rgb(hex) }
        tuning.customAccentDark = knobs.customAccentDark.map(rgb)
        if let design = knobs.fontDesign { tuning.fontDesign = ThemeTuning.FontDesign(rawValue: design)! }
        if let step = knobs.surfaceStep { tuning.surfaceStep = step }
        if let palette = knobs.chartPalette { tuning.chartPalette = ThemeTuning.ChartPalette(rawValue: palette)! }
        tuning.background = knobs.background.map(rgb)
        tuning.backgroundDark = knobs.backgroundDark.map(rgb)
        tuning.foreground = knobs.foreground.map(rgb)
        tuning.foregroundDark = knobs.foregroundDark.map(rgb)
        tuning.secondaryForeground = knobs.secondaryForeground.map(rgb)
        tuning.secondaryForegroundDark = knobs.secondaryForegroundDark.map(rgb)
        return tuning
    }

    static func rgb(_ hex: String) -> ThemeTuning.RGB {
        ThemeTuning.RGB(packed: Int(hex.dropFirst(), radix: 16)!)
    }

    static func hex(_ rgb: ThemeTuning.RGB) -> String {
        String(format: "#%06X", rgb.packed)
    }

    static func knobs(of tuning: ThemeTuning) -> [Double] {
        [
            tuning.surfaceOpacity, tuning.borderOpacity, tuning.borderWidth, tuning.emphasizedBorderWidth,
            tuning.compactRadius, tuning.controlRadius, tuning.cardRadius, tuning.compactSpacing,
            tuning.standardSpacing, tuning.sectionSpacing, tuning.controlHorizontalPadding, tuning.disabledOpacity,
        ]
    }

    @Test func `Every pinned vector encodes to its code`() {
        #expect(Self.vectors.count >= 20)
        for vector in Self.vectors {
            #expect(Self.tuning(from: vector.tuning).presetCode == vector.code, "\(vector.name)")
        }
    }

    @Test func `Every pinned code decodes to its knobs`() {
        for vector in Self.vectors {
            let decoded = ThemeTuning(presetCode: vector.code)
            let expected = Self.tuning(from: vector.tuning)
            #expect(decoded?.accent == expected.accent, "\(vector.name)")
            #expect(decoded?.darkLabelOnAccent == expected.darkLabelOnAccent, "\(vector.name)")
            for (actual, wanted) in zip(Self.knobs(of: decoded ?? .default), Self.knobs(of: expected)) {
                #expect(abs(actual - wanted) < 1e-9, "\(vector.name)")
            }
            if expected.accent == .custom {
                #expect(decoded.map { Self.hex($0.customAccent) } == vector.tuning.customAccent, "\(vector.name)")
                #expect(decoded?.customAccentDark.map(Self.hex) == vector.tuning.customAccentDark, "\(vector.name)")
            } else {
                #expect(decoded?.customAccentDark == nil, "\(vector.name)")
            }
            // Version b fields, defaulted on an a vector.
            #expect(decoded?.fontDesign == expected.fontDesign, "\(vector.name)")
            #expect(decoded?.chartPalette == expected.chartPalette, "\(vector.name)")
            #expect(abs((decoded?.surfaceStep ?? -1) - expected.surfaceStep) < 1e-9, "\(vector.name)")
            #expect(decoded?.background.map(Self.hex) == expected.background.map(Self.hex), "\(vector.name)")
            #expect(decoded?.backgroundDark.map(Self.hex) == expected.backgroundDark.map(Self.hex), "\(vector.name)")
            #expect(decoded?.foreground.map(Self.hex) == expected.foreground.map(Self.hex), "\(vector.name)")
            #expect(decoded?.foregroundDark.map(Self.hex) == expected.foregroundDark.map(Self.hex), "\(vector.name)")
            #expect(decoded?.secondaryForeground.map(Self.hex) == expected.secondaryForeground.map(Self.hex), "\(vector.name)")
            #expect(decoded?.secondaryForegroundDark.map(Self.hex) == expected.secondaryForegroundDark.map(Self.hex), "\(vector.name)")
        }
    }

    // The 0.1.0 tag and every version a code are untouchable: an a code must
    // still round-trip to itself, byte for byte.
    @Test func `Every version a code round-trips to itself`() {
        let aVectors = Self.vectors.filter { $0.code.first == "a" }
        #expect(aVectors.count >= 10)
        for vector in aVectors {
            #expect(ThemeTuning(presetCode: vector.code)?.presetCode == vector.code, "\(vector.name)")
        }
    }

    // Decoding an a code yields the version b defaults for the new fields.
    @Test func `An a code decodes to the version b defaults`() {
        let decoded = ThemeTuning(presetCode: Self.vector(named: "Indigo").code)
        #expect(decoded?.fontDesign == .default)
        #expect(decoded?.surfaceStep == 0.02)
        #expect(decoded?.chartPalette == .accent)
        #expect(decoded?.background == nil)
        #expect(decoded?.foreground == nil)
        #expect(decoded?.secondaryForeground == nil)
    }

    // A b code whose appended bits are all absent decodes to the defaults, and
    // re-encoding a defaults-only tuning writes an a code, not a b code.
    @Test func `A b code carrying only defaults re-encodes as version a`() {
        let decoded = ThemeTuning(presetCode: "b13GkaOXWwIC")
        #expect(decoded != nil)
        #expect(decoded?.fontDesign == .default)
        #expect(decoded?.surfaceStep == 0.02)
        #expect(decoded?.chartPalette == .accent)
        #expect(decoded?.background == nil)
        #expect(decoded?.presetCode == "a13GkaOXWwIC")

        var tuning = ThemeTuning.default
        tuning.accent = .indigo
        #expect(tuning.presetCode.first == "a")
    }

    // Two bits carry four slots but only three palettes; the reserved fourth
    // (index 3) makes a b code invalid rather than being guessed.
    @Test func `A reserved chart palette index makes a b code invalid`() {
        #expect(ThemeTuning(presetCode: "b4GnS9YbjWKvL") == nil)
    }

    // A font design must be carried, not dropped: a tuning with one encodes as
    // b, and an a code never reads as anything but the default design.
    @Test func `Font design is carried, not dropped`() {
        var tuning = ThemeTuning.default
        tuning.accent = .indigo
        tuning.fontDesign = .serif
        let code = tuning.presetCode
        #expect(code.first == "b")
        #expect(ThemeTuning(presetCode: code)?.fontDesign == .serif)
        #expect(ThemeTuning(presetCode: Self.vector(named: "Indigo").code)?.fontDesign == .default)
    }

    // Surface step is a value list, not a grid: index 1 is 0.00, which a grid
    // implementation (0.02 + 1 * 0.01) would wrongly read as 0.03.
    @Test func `Surface step is a value list, so index one is zero`() {
        var tuning = ThemeTuning.default
        tuning.accent = .indigo
        tuning.surfaceStep = 0
        let code = tuning.presetCode
        #expect(code.first == "b")
        let decoded = ThemeTuning(presetCode: code)
        #expect(decoded?.surfaceStep == 0)
        #expect(decoded?.surfaceStep != 0.03)

        var defaulted = ThemeTuning.default
        defaulted.accent = .indigo
        defaulted.surfaceStep = 0.02
        #expect(defaulted.presetCode.first == "a")
    }

    // The chart palette round-trips and is independent of the accent.
    @Test func `Chart palette round-trips separate from the accent`() {
        var tuning = ThemeTuning.default
        tuning.accent = .indigo
        tuning.chartPalette = .spectrum
        let code = tuning.presetCode
        #expect(code.first == "b")
        #expect(ThemeTuning(presetCode: code)?.chartPalette == .spectrum)
        #expect(ThemeTuning(presetCode: Self.vector(named: "Indigo").code)?.chartPalette == .accent)
    }

    // The three pairs are ordered and independent: only foreground set must
    // leave background and secondary foreground untouched. A codec that read
    // the pairs in the wrong order would fill background instead.
    @Test func `Color pairs are independent and ordered`() {
        var tuning = ThemeTuning.default
        tuning.accent = .indigo
        tuning.foreground = ThemeTuning.RGB(packed: 0x1B1B1F)
        let decoded = ThemeTuning(presetCode: tuning.presetCode)
        #expect(decoded?.background == nil)
        #expect(decoded?.secondaryForeground == nil)
        #expect(decoded?.foreground.map(Self.hex) == "#1B1B1F")
        #expect(decoded?.foregroundDark == nil)
    }

    // A pair carries its own optional dark value, and clearing the pair clears
    // the dark with it so no orphan dark color survives.
    @Test func `A color pair carries its own dark value`() {
        var tuning = ThemeTuning.default
        tuning.accent = .indigo
        tuning.background = ThemeTuning.RGB(packed: 0xF7F2EA)
        tuning.backgroundDark = ThemeTuning.RGB(packed: 0x14110D)
        let decoded = ThemeTuning(presetCode: tuning.presetCode)
        #expect(decoded?.background.map(Self.hex) == "#F7F2EA")
        #expect(decoded?.backgroundDark.map(Self.hex) == "#14110D")

        var cleared = tuning
        cleared.background = nil
        cleared.backgroundDark = nil
        #expect(cleared.presetCode.first == "a")
    }

    // Environment switches are never part of a theme, so a code leaves them
    // to the base it decodes over.
    @Test func `Decoding keeps the environment of the base`() {
        var base = ThemeTuning.default
        base.rightToLeft = true
        base.textSize = .accessibility
        let decoded = ThemeTuning(presetCode: Self.vector(named: "Amber").code, base: base)
        #expect(decoded?.accent == .yellow)
        #expect(decoded?.darkLabelOnAccent == true)
        #expect(decoded?.rightToLeft == true)
        #expect(decoded?.textSize == .accessibility)
    }

    @Test func `Invalid codes are refused rather than guessed`() {
        for code in ["", "a", "b", "a13GkaOXWwI-", "aF", "b/", "abc def"] {
            #expect(ThemeTuning(presetCode: code) == nil, "\(code)")
        }
        #expect(ThemeTuning.presetCode(in: "--preset a13GkaOXWwIC") == "a13GkaOXWwIC")
        #expect(ThemeTuning.presetCode(in: "  a13GkaOXWwIC \n") == "a13GkaOXWwIC")
        #expect(ThemeTuning.presetCode(in: "zz") == nil)
    }

    @Test func `Knobs off the slider grid snap on encode`() {
        var tuning = ThemeTuning.default
        tuning.cardRadius = 18.3
        tuning.surfaceOpacity = 0.9
        tuning.compactSpacing = 1
        let decoded = ThemeTuning(presetCode: tuning.presetCode)
        #expect(decoded?.cardRadius == 18)
        #expect(decoded?.surfaceOpacity == 0.2)
        #expect(decoded?.compactSpacing == 4)
    }

    @Test func `Import takes a code before it looks for Swift`() {
        let graphite = Self.vector(named: "Graphite")
        let imported = ThemeTuning.parse("--preset \(graphite.code)")
        #expect(imported?.accent == .ink)
        #expect(imported?.surfaceOpacity == 0.05)
        #expect(imported?.presetCode == graphite.code)
        #expect(ThemeTuning.parse("nothing here") == nil)
    }

    // The export lists the dark color first; an import that read the first
    // color as the light one would silently swap a designer's two accents.
    @Test func `A dual custom accent survives the Swift export and import`() {
        var tuning = ThemeTuning.default
        tuning.accent = .custom
        tuning.customAccent = ThemeTuning.RGB(red: 0.1, green: 0.2, blue: 0.3)
        tuning.customAccentDark = ThemeTuning.RGB(red: 0.6, green: 0.7, blue: 0.8)
        let imported = ThemeTuning.parse(tuning.swiftSource)
        #expect(imported?.accent == .custom)
        #expect(imported.map { Self.hex($0.customAccent) } == Self.hex(tuning.customAccent))
        #expect(imported?.customAccentDark.map(Self.hex) == Self.hex(tuning.customAccentDark!))
    }
}
