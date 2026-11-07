import Foundation
import Testing

@testable import SweetUIKit

/// A decoded preset tells an agent whether the literal colors it carries
/// read: the label on a custom accent and custom text over a custom
/// background, as WCAG 2.2 ratios in both appearances. The numbers must
/// agree with an independent checker, a system accent must stay unmeasured
/// rather than guessed, and the pinned indigo outputs must not change.
struct ContrastTests {
  /// WebAIM's contrast checker, fetched 2026-11-07 from
  /// `https://webaim.org/resources/contrastchecker/?fcolor=<text>&bcolor=<fill>&api`;
  /// it truncates to two decimals, three significant digits above 10.
  @Test(arguments: [
    ("#767676", "#FFFFFF", 4.54), ("#777777", "#FFFFFF", 4.47), ("#FFFFFF", "#007AFF", 4.01),
    ("#000000", "#FFA033", 10.3), ("#000000", "#FFB84D", 12.2), ("#FFFFFF", "#FFA033", 2.03),
  ])
  func ratiosMatchAnIndependentChecker(text: String, fill: String, expected: Double) throws {
    let measured = try #require(Contrast.ratio(text, fill))
    let tolerance = expected >= 10 ? 0.1 : 0.01
    #expect(
      measured >= expected && measured < expected + tolerance, "\(text) on \(fill): \(measured)")
  }

  @Test func scaleAndSpelling() {
    #expect(Contrast.ratio("#000000", "#FFFFFF") == 21)
    #expect(Contrast.ratio("#808080", "#808080") == 1)
    #expect(Contrast.ratio("#FFFFFF", "#007AFF") == Contrast.ratio("#007AFF", "#FFFFFF"))
    #expect(Contrast.luminance("FFA033") == nil)
    #expect(Contrast.luminance("#GGGGGG") == nil)
  }

  @Test func mangoReportsItsDarkLabelAndIndigoReportsNothing() throws {
    // MANGO: custom #FFA033 light, #FFB84D dark, dark label.
    let mango = try JSON.read(Data(Preset.description("a74hGF01CVunaG0vzZJG", json: true).utf8))
    #expect(mango["contrast"]["labelOnAccent"]["light"] == 10.33)
    #expect(mango["contrast"]["labelOnAccent"]["dark"] == 12.22)
    #expect(mango["contrast"]["labelOnAccent"]["passes"] == true)
    #expect(mango["contrast"]["text"] == .null, "No custom text pair in MANGO.")
    // A system accent is the device's to resolve: no key, no guess.
    let indigo = try JSON.read(Data(Preset.description("a13GkaOXWwIF", json: true).utf8))
    #expect(indigo.object?["contrast"] == nil)
    #expect(try !Preset.description("a13GkaOXWwIF").contains("contrast"))
    #expect(
      try Preset.description("a74hGF01CVunaG0vzZJG").contains(
        "contrast.labelOnAccent    10.33:1 light, 12.22:1 dark, passes"))
  }

  @Test func aWhiteLabelOnMangoFails() throws {
    var tuning = Preset.decode("a74hGF01CVunaG0vzZJG")!
    tuning["darkLabelOnAccent"] = false
    let report = Contrast.report(tuning)
    #expect(report["labelOnAccent"]["light"] == 2.03)
    #expect(report["labelOnAccent"]["passes"] == false)
  }

  @Test func textPairNeedsBothColorsAndFallsBackToLightForDark() {
    let onlyForeground: JSON = ["accent": "indigo", "foreground": "#1C1C1E"]
    #expect(Contrast.report(onlyForeground) == [:])
    let both: JSON = [
      "accent": "indigo", "foreground": "#1C1C1E", "background": "#FFFFFF",
      "backgroundDark": "#000000",
    ]
    let report = Contrast.report(both)
    // WebAIM: 17.0 and 1.23 (fetched 2026-11-07).
    #expect(report["text"]["light"] == 17.01)
    // Dark falls back to the light foreground over the dark background: near black on black.
    #expect(report["text"]["dark"] == 1.23)
    #expect(report["text"]["passes"] == false)
  }
}
