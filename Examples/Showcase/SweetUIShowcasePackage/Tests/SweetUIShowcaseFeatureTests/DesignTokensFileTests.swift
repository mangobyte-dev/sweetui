import Foundation
import Testing
@testable import SweetUIDesignSurface

/// The design tokens file is the surface's export and an agent's input, so it
/// must speak the preset tools' shape: the `code` any registry tool applies,
/// the `tuning` keys `sweetui preset decode --json` prints, colors as
/// `#RRGGBB`, and the environment switches kept apart because a code never
/// carries them. A file that drifted from that shape would tune the device
/// and tell the agent something else.
struct DesignTokensFileTests {
    private static func document(_ tuning: ThemeTuning) throws -> [String: Any] {
        let data = try ThemeTuning.fileEncoder.encode(tuning)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    private static func decode(_ json: String) throws -> ThemeTuning {
        try JSONDecoder().decode(ThemeTuning.self, from: Data(json.utf8))
    }

    @Test func `The file carries MANGO's pinned code and the decode keys`() throws {
        let vector = ThemePresetTests.vector(named: "Mango")
        let document = try Self.document(ThemePresetTests.tuning(from: vector.tuning))
        #expect(document["code"] as? String == vector.code)
        #expect(document["version"] as? String == "a")
        let knobs = try #require(document["tuning"] as? [String: Any])
        #expect(knobs["accent"] as? String == "custom")
        #expect(knobs["darkLabelOnAccent"] as? Bool == true)
        #expect(knobs["customAccent"] as? String == "#FFA033")
        #expect(knobs["customAccentDark"] as? String == "#FFB84D")
        #expect(knobs["surfaceOpacity"] as? Double == 0.07)
        #expect(knobs["cardRadius"] as? Double == 24)
        // Every knob is present, the version-b fields at their defaults and an
        // absent color pair as null, so a reader never has to know the defaults.
        #expect(knobs["fontDesign"] as? String == "default")
        #expect(knobs["surfaceStep"] as? Double == 0.02)
        #expect(knobs["chartPalette"] as? String == "accent")
        #expect(knobs["background"] is NSNull)
        #expect(knobs.count == 25)
    }

    @Test func `A version-b tuning round-trips through the file`() throws {
        let tuning = ThemePresetTests.tuning(from: ThemePresetTests.vector(named: "Every b field").tuning)
        let data = try ThemeTuning.fileEncoder.encode(tuning)
        let decoded = try JSONDecoder().decode(ThemeTuning.self, from: data)
        #expect(decoded == tuning)
        #expect(try Self.document(tuning)["version"] as? String == "b")
    }

    // An agent pushes a theme onto the device by writing the code alone.
    @Test func `A document with only a code loads that code`() throws {
        let vector = ThemePresetTests.vector(named: "MANGO b")
        let decoded = try Self.decode(#"{"code": "\#(vector.code)"}"#)
        #expect(decoded == ThemePresetTests.tuning(from: vector.tuning))
        #expect(decoded.fontDesign == .rounded)
        #expect(decoded.chartPalette == .spectrum)
    }

    @Test func `A partial tuning object keeps the defaults it does not name`() throws {
        let decoded = try Self.decode(#"{"tuning": {"accent": "teal", "cardRadius": 20}}"#)
        #expect(decoded.accent == .teal)
        #expect(decoded.cardRadius == 20)
        #expect(decoded.controlRadius == ThemeTuning.default.controlRadius)
        #expect(decoded.customAccent == ThemeTuning.default.customAccent)
    }

    // A wrong file is refused rather than guessed; guessing would tune the
    // device to a theme nobody wrote.
    @Test func `An invalid code, color, or accent is refused, not guessed`() {
        #expect(throws: DecodingError.self) { try Self.decode(#"{"code": "zzz"}"#) }
        #expect(throws: DecodingError.self) { try Self.decode(#"{"tuning": {"background": "orange"}}"#) }
        #expect(throws: DecodingError.self) { try Self.decode(#"{"tuning": {"accent": "mango"}}"#) }
        #expect(throws: DecodingError.self) { try Self.decode("{}") }
    }

    // The environment switches shape the preview, never the theme: they ride
    // in the file under their own key and leave the code untouched.
    @Test func `Environment switches persist beside the code and never enter it`() throws {
        var tuning = ThemeTuning.default
        tuning.accent = .indigo
        // The file spells colors as #RRGGBB, so a color already on that grid
        // round-trips exactly; the default custom accent is not on it.
        tuning.customAccent = ThemeTuning.RGB(packed: 0x5957D6)
        let plainCode = tuning.presetCode
        tuning.appearance = .dark
        tuning.textSize = .accessibility
        tuning.rightToLeft = true
        let document = try Self.document(tuning)
        #expect(document["code"] as? String == plainCode)
        let environment = try #require(document["environment"] as? [String: Any])
        #expect(environment["appearance"] as? String == "dark")
        #expect(environment["textSize"] as? String == "accessibility")
        #expect(environment["rightToLeft"] as? Bool == true)
        let decoded = try JSONDecoder().decode(ThemeTuning.self, from: ThemeTuning.fileEncoder.encode(tuning))
        #expect(decoded == tuning)
    }
}
