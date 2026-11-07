import Foundation

/// WCAG 2.2 contrast for the colors a preset code carries as literal sRGB:
/// a custom accent under its label, and a custom foreground over a custom
/// background. A system accent (indigo, green, the app tint) resolves on the
/// device per appearance and Increase Contrast, so the tool cannot measure
/// it here; the Tune panel does, on the device.
public enum Contrast {
  /// The Human Interface Guidelines' minimum for text up to 17 points.
  public static let minimum = 4.5

  /// WCAG 2.2, "relative luminance", for an `#RRGGBB` color; `nil` for any
  /// other spelling.
  public static func luminance(_ hex: String) -> Double? {
    guard hex.count == 7, hex.hasPrefix("#"), let packed = Int(hex.dropFirst(), radix: 16) else {
      return nil
    }
    func linear(_ channel: Int) -> Double {
      let value = Double(channel) / 255
      return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(packed >> 16 & 0xff) + 0.7152 * linear(packed >> 8 & 0xff)
      + 0.0722 * linear(packed & 0xff)
  }

  /// WCAG 2.2, "contrast ratio": (L1 + 0.05) / (L2 + 0.05), lighter over darker.
  public static func ratio(_ a: String, _ b: String) -> Double? {
    guard let a = luminance(a), let b = luminance(b) else { return nil }
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
  }

  /// The measurable pairs of a decoded tuning, in the decode's own shape:
  /// `labelOnAccent` for a custom accent (light, and dark when the code carries
  /// a dark accent), `text` when both a foreground and a background are set,
  /// each with its ratios rounded to two decimals and `passes` against the
  /// minimum in every appearance measured. Empty when nothing is literal.
  static func report(_ tuning: JSON) -> JSON {
    var pairs: [String: JSON] = [:]
    if tuning["accent"] == "custom", let light = tuning["customAccent"].string {
      let label = tuning["darkLabelOnAccent"] == .bool(true) ? "#000000" : "#FFFFFF"
      let dark = tuning["customAccentDark"].string ?? light
      pairs["labelOnAccent"] = pair(label, over: light, dark: label, over: dark)
    }
    if let foreground = tuning["foreground"].string, let background = tuning["background"].string {
      pairs["text"] = pair(
        foreground, over: background,
        dark: tuning["foregroundDark"].string ?? foreground,
        over: tuning["backgroundDark"].string ?? background)
    }
    return .object(pairs)
  }

  private static func pair(
    _ text: String, over fill: String, dark darkText: String, over darkFill: String
  ) -> JSON {
    guard let light = ratio(text, fill), let dark = ratio(darkText, darkFill) else { return .null }
    func rounded(_ value: Double) -> JSON { .number((value * 100).rounded() / 100) }
    return [
      "light": rounded(light), "dark": rounded(dark),
      "passes": .bool(min(light, dark) >= minimum),
    ]
  }
}
