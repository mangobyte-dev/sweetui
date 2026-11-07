import SwiftUI
import Testing
import UIKit
@testable import SweetUIDesignSurface

/// The panel's contrast verdicts stand in for an accessibility review, so the
/// math must agree with an independent checker, and the audit must measure
/// what a person sees: blended translucent labels, both appearances, and the
/// Increase Contrast credit only a system color earns. A theme that reads as
/// passing here and fails on a device would ship unreadable text.
@MainActor
struct ContrastAuditTests {
    private static func hex(_ hex: String) throws -> ThemeTuning.RGB {
        try #require(ThemeTuning.RGB(hex: hex))
    }

    private static func ratio(_ text: String, on fill: String) throws -> Double {
        func srgb(_ hex: String) throws -> ContrastAudit.SRGB {
            let rgb = try Self.hex(hex)
            return ContrastAudit.SRGB(red: rgb.red, green: rgb.green, blue: rgb.blue)
        }
        return try ContrastAudit.ratio(srgb(text).luminance, srgb(fill).luminance)
    }

    /// Ratios from WebAIM's contrast checker, fetched 2026-11-06 from
    /// `https://webaim.org/resources/contrastchecker/?fcolor=<text>&bcolor=<fill>&api`,
    /// which truncates to two decimals (5.6496 prints as 5.64).
    @Test(arguments: [
        ("#767676", "#FFFFFF", 4.54),
        ("#777777", "#FFFFFF", 4.47),
        ("#595959", "#FFFFFF", 7.00),
        ("#FFFFFF", "#007AFF", 4.01),
        ("#FFFFFF", "#34C759", 2.21),
        ("#FFFFFF", "#5856D6", 5.64),
        ("#5E5CE6", "#000000", 4.14),
        ("#FFFFFF", "#FF3B30", 3.54),
    ])
    func `Ratios match an independent checker`(text: String, fill: String, expected: Double) throws {
        let measured = try Self.ratio(text, on: fill)
        #expect(measured >= expected && measured < expected + 0.01, "\(text) on \(fill) measured \(measured)")
    }

    @Test func `The scale runs from one to twenty-one, and 4.47 fails`() throws {
        #expect(try Self.ratio("#000000", on: "#FFFFFF") == 21)
        #expect(try Self.ratio("#808080", on: "#808080") == 1)
        // The order of the two colors never matters.
        #expect(try Self.ratio("#FFFFFF", on: "#007AFF") == Self.ratio("#007AFF", on: "#FFFFFF"))
        // #777777 rounds to 4.5 at one decimal; the bar is not met.
        #expect(try Self.ratio("#777777", on: "#FFFFFF") < ContrastAudit.minimum)
    }

    /// Tune holds the themes it tunes to 4.5:1, so its own one colored
    /// block must meet it: the strip's white text on its fixed fill, in
    /// light and dark alike. systemBlue under white is the negative case.
    @Test func `The Trying strip's white text measures at least 4.5 to 1`() throws {
        let fill = ToolChrome.stripRGB
        let white = ContrastAudit.SRGB(red: 1, green: 1, blue: 1)
        let strip = ContrastAudit.SRGB(red: fill.red, green: fill.green, blue: fill.blue)
        #expect(ContrastAudit.ratio(white.luminance, strip.luminance) >= ContrastAudit.minimum)
        #expect(try Self.ratio("#FFFFFF", on: "#007AFF") < ContrastAudit.minimum, "systemBlue under white falls short.")
    }

    @Test func `A translucent label is measured blended with its background`() {
        let white = ContrastAudit.SRGB(red: 1, green: 1, blue: 1)
        let halfBlack = ContrastAudit.SRGB(red: 0, green: 0, blue: 0, alpha: 0.5).composited(over: white)
        #expect(halfBlack == ContrastAudit.SRGB(red: 0.5, green: 0.5, blue: 0.5))
        // Ignoring the alpha would report black on white, 21:1.
        #expect(ContrastAudit.ratio(halfBlack.luminance, white.luminance) < 4)
    }

    /// The default accent is SwiftUI's indigo, which resolves lighter in dark
    /// than UIKit's `systemIndigo` (#5E5CE6, 5.06:1 under white): measured
    /// 3.51:1 on the iOS 27.1 simulator. A panel that checked light only
    /// would call the shipped default fine.
    @Test func `The shipped default's white label fails in dark, and the audit says so`() throws {
        let label = try #require(ContrastAudit(.default).pair(.labelOnAccent))
        #expect(label.light >= ContrastAudit.minimum)
        #expect(label.dark < ContrastAudit.minimum)
        #expect(label.verdict == .fails)
        // The same number through SwiftUI's own resolver, so the UIKit path
        // the audit takes is not measuring a different color.
        var environment = EnvironmentValues()
        environment.colorScheme = .dark
        let resolved = Color.indigo.resolve(in: environment)
        let fill = ContrastAudit.SRGB(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue))
        #expect(abs(ContrastAudit.ratio(1, fill.luminance) - label.dark) < 0.01)
        // A black label fails light instead (4.13:1), so neither is offered.
        #expect(ContrastAudit.betterLabel(for: .default) == nil)
    }

    @Test func `A failure only in dark fails the pair`() throws {
        var tuning = ThemeTuning.default
        tuning.accent = .custom
        tuning.customAccent = try Self.hex("#5856D6")
        tuning.customAccentDark = try Self.hex("#FFCC00")
        let label = try #require(ContrastAudit(tuning).pair(.labelOnAccent))
        #expect(label.light >= ContrastAudit.minimum)
        #expect(label.dark < 3)
        #expect(label.verdict == .fails)
        // A dark label would pass dark (13.8:1) and fail light (3.72:1):
        // no better, so the panel offers nothing rather than a false fix.
        #expect(ContrastAudit.betterLabel(for: tuning) == nil)
    }

    @Test func `Only a system color earns the Increase Contrast credit`() throws {
        var system = ThemeTuning.default
        system.accent = .green
        let adaptive = try #require(ContrastAudit(system).pair(.labelOnAccent))
        #expect(adaptive.light < ContrastAudit.minimum)
        #expect(adaptive.lightIncreased > adaptive.light)

        var custom = ThemeTuning.default
        custom.accent = .custom
        custom.customAccent = try Self.hex("#34C759")
        let fixed = try #require(ContrastAudit(custom).pair(.labelOnAccent))
        #expect(fixed.lightIncreased == fixed.light)
        #expect(fixed.verdict == .fails)
    }

    @Test func `The other label is offered only when it measures better`() throws {
        var amber = ThemeTuning.default
        amber.apply(presetNamed: "Amber")
        #expect(amber.darkLabelOnAccent)
        #expect(ContrastAudit.betterLabel(for: amber) == nil)

        amber.darkLabelOnAccent = false
        #expect(ContrastAudit.betterLabel(for: amber) == true)

        // Ink's label is the background color; there is no other to offer.
        var ink = ThemeTuning.default
        ink.accent = .ink
        #expect(ContrastAudit(ink).pair(.labelOnAccent)?.verdict == .passes)
        #expect(ContrastAudit.betterLabel(for: ink) == nil)
    }

    @Test func `Text pairs appear once the theme sets a text color or background`() throws {
        #expect(ContrastAudit(.default).pairs.map(\.kind) == [.labelOnAccent, .accentText])

        var background = ThemeTuning.default
        background.background = try Self.hex("#F2F2F7")
        #expect(ContrastAudit(background).pairs.map(\.kind) == [.labelOnAccent, .accentText, .text, .secondaryText])

        // A foreground alone leaves the secondary to SwiftUI's hierarchy.
        var foreground = ThemeTuning.default
        foreground.foreground = try Self.hex("#1C1C1E")
        let derived = ContrastAudit(foreground)
        #expect(derived.pair(.secondaryText) == nil)
        #expect(derived.secondaryIsDerived)

        foreground.secondaryForeground = try Self.hex("#636366")
        #expect(ContrastAudit(foreground).pair(.secondaryText) != nil)
        #expect(!ContrastAudit(foreground).secondaryIsDerived)
    }

    @Test func `Text the color of its background fails`() throws {
        var tuning = ThemeTuning.default
        tuning.background = try Self.hex("#8E8E93")
        tuning.foreground = tuning.background
        let text = try #require(ContrastAudit(tuning).pair(.text))
        #expect(text.light == 1)
        #expect(text.verdict == .fails)
    }
}
