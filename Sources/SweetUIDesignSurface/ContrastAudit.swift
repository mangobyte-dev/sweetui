#if canImport(UIKit)
import SwiftUI
import UIKit

/// The theme's text pairs as WCAG 2.2 contrast ratios, measured in light and
/// dark and again with Increase Contrast, the check Apple's Human Interface
/// Guidelines ask for (Accessibility, Vision): 4.5:1 for text up to 17 points,
/// in both appearances; a color that misses it must at least reach it with
/// Increase Contrast on. A system color adapts there; a custom color does not,
/// so it must pass on its own.
///
/// A pair is listed when a token decides it: the accent pairs always, the text
/// pairs once the theme sets its own foreground or background. Two system
/// colors over each other are the system's to keep legible.
@MainActor
struct ContrastAudit: Equatable {
    /// The HIG's minimum for text up to 17 points. The registry button and
    /// link labels are subheadline, 15 points.
    nonisolated static let minimum = 4.5
    /// Under Source the app shows its own colors, which Tune cannot read.
    nonisolated static let unmeasuredUnderSource = "Tune sets no token, so the Checks cannot measure the app's own colors."

    struct Pair: Identifiable, Equatable {
        enum Kind: String, CaseIterable {
            case labelOnAccent, accentText, text, secondaryText
        }

        let kind: Kind
        /// Without Increase Contrast, then with it.
        let light, dark, lightIncreased, darkIncreased: Double

        var id: Kind { kind }

        var verdict: Verdict {
            if min(light, dark) >= ContrastAudit.minimum { return .passes }
            if min(lightIncreased, darkIncreased) >= ContrastAudit.minimum { return .passesWithIncreaseContrast }
            return .fails
        }

        var title: String {
            switch kind {
            case .labelOnAccent: "Label on accent"
            case .accentText: "Accent text"
            case .text: "Text"
            case .secondaryText: "Secondary text"
            }
        }

        var verdictWord: String {
            switch verdict {
            case .passes: "Passes"
            case .passesWithIncreaseContrast: "Passes with Increase Contrast"
            case .fails: "Fails"
            }
        }

        /// "3.20:1 light, 2.90:1 dark", and the lower ratio under Increase
        /// Contrast when that is what passes.
        var ratios: String {
            let base = "\(Self.format(light)) light, \(Self.format(dark)) dark"
            guard verdict == .passesWithIncreaseContrast else { return base }
            return base + ", \(Self.format(min(lightIncreased, darkIncreased))) increased"
        }

        /// Two decimals, as contrast checkers print them: one decimal would round
        /// a failing 4.47 up to a passing-looking 4.5.
        private static func format(_ ratio: Double) -> String {
            ratio.formatted(.number.precision(.fractionLength(2))) + ":1"
        }
    }

    /// Worst first, so a fix is offered only when it ranks higher.
    enum Verdict: Int, Comparable {
        case fails, passesWithIncreaseContrast, passes

        static func < (lhs: Verdict, rhs: Verdict) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let pairs: [Pair]
    /// Secondary text under a custom foreground with no secondary color of its
    /// own is SwiftUI's derived hierarchy, which the audit does not resolve.
    let secondaryIsDerived: Bool

    var failures: Int { pairs.filter { $0.verdict == .fails }.count }

    func pair(_ kind: Pair.Kind) -> Pair? { pairs.first { $0.kind == kind } }

    /// The other label on the accent, white or black, when it measures better
    /// than the current one: the value for `darkLabelOnAccent`, or `nil`. Ink
    /// draws the background color as its label, so it has no other.
    static func betterLabel(for tuning: ThemeTuning) -> Bool? {
        guard tuning.accent != .ink,
              let current = ContrastAudit(tuning).pair(.labelOnAccent)?.verdict,
              current != .passes else { return nil }
        var flipped = tuning
        flipped.darkLabelOnAccent.toggle()
        guard let other = ContrastAudit(flipped).pair(.labelOnAccent)?.verdict, other > current else { return nil }
        return flipped.darkLabelOnAccent
    }

    /// Measures what the panel renders: the tuning on its code grid, through
    /// the same `RegistryTheme` the app reads.
    init(_ tuning: ThemeTuning) {
        let tuning = tuning.onCodeGrid
        let theme = tuning.theme
        // `registryTheme(_:)` leaves the system colors in place where the theme
        // sets none, and applies a secondary color only beside a foreground.
        let background = theme.background.map { UIColor($0) } ?? .systemBackground
        let foreground = theme.foreground.map { UIColor($0) } ?? .label
        let secondary: UIColor? = theme.foreground == nil
            ? .secondaryLabel
            : theme.secondaryForeground.map { UIColor($0) }
        // The accent fills the primary button, and tints link text over the background.
        let accent = UIColor(theme.accent ?? .accentColor)

        var pairs = [
            Self.measure(.labelOnAccent, UIColor(theme.onAccent), over: accent),
            Self.measure(.accentText, accent, over: background),
        ]
        let setsText = tuning.foreground != nil || tuning.background != nil
        if setsText {
            pairs.append(Self.measure(.text, foreground, over: background))
        }
        if let secondary, setsText {
            pairs.append(Self.measure(.secondaryText, secondary, over: background))
        }
        self.pairs = pairs
        secondaryIsDerived = tuning.foreground != nil && tuning.secondaryForeground == nil
    }

    /// The four appearances a person can run, in the pair's field order.
    private static let appearances: [UITraitCollection] = [
        (UIUserInterfaceStyle.light, UIAccessibilityContrast.normal), (.dark, .normal), (.light, .high), (.dark, .high),
    ].map { style, contrast in
        UITraitCollection { traits in
            traits.userInterfaceStyle = style
            traits.accessibilityContrast = contrast
        }
    }

    private static func measure(_ kind: Pair.Kind, _ text: UIColor, over fill: UIColor) -> Pair {
        let ratios = appearances.map { traits in
            let fill = SRGB(fill.resolvedColor(with: traits))
            let text = SRGB(text.resolvedColor(with: traits)).composited(over: fill)
            return ratio(text.luminance, fill.luminance)
        }
        return Pair(kind: kind, light: ratios[0], dark: ratios[1], lightIncreased: ratios[2], darkIncreased: ratios[3])
    }

    /// WCAG 2.2, "contrast ratio": (L1 + 0.05) / (L2 + 0.05), the lighter
    /// color's relative luminance over the darker's.
    nonisolated static func ratio(_ a: Double, _ b: Double) -> Double {
        (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// An sRGB color with its alpha, channels in 0...1.
    struct SRGB: Equatable {
        var red, green, blue, alpha: Double

        init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
            (self.red, self.green, self.blue, self.alpha) = (red, green, blue, alpha)
        }

        /// A resolved color's components, clamped into sRGB: a wide-gamut
        /// channel outside 0...1 has no WCAG luminance.
        init(_ color: UIColor) {
            var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            func clamped(_ value: CGFloat) -> Double { min(1, max(0, Double(value))) }
            self.init(red: clamped(r), green: clamped(g), blue: clamped(b), alpha: clamped(a))
        }

        /// This color drawn over an opaque one: a translucent label such as
        /// the system's secondary label is seen blended with its background.
        func composited(over base: SRGB) -> SRGB {
            func blend(_ top: Double, _ bottom: Double) -> Double { alpha * top + (1 - alpha) * bottom }
            return SRGB(red: blend(red, base.red), green: blend(green, base.green), blue: blend(blue, base.blue))
        }

        /// WCAG 2.2, "relative luminance", for sRGB.
        var luminance: Double {
            func linear(_ channel: Double) -> Double {
                channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
    }
}
#endif
