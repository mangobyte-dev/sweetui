import SwiftUI
import SweetUIFoundations
import Testing

struct RegistryThemeTests {
    @Test func `Default metrics preserve the registry composition contract`() {
        let metrics = RegistryMetrics()

        #expect(metrics.compactSpacing == 8)
        #expect(metrics.standardSpacing == 16)
        #expect(metrics.sectionSpacing == 24)
        #expect(metrics.controlHorizontalPadding == 12)
        #expect(metrics.borderWidth == 1)
        #expect(metrics.emphasizedBorderWidth == 2)
        #expect(metrics.compactRadius == 6)
        #expect(metrics.controlRadius == 8)
        #expect(metrics.cardRadius == 16)
        #expect(RegistryMetrics.minimumHitSize == 44)
    }

    @Test func `A consumer can replace metrics without shared mutable state`() {
        var compact = RegistryTheme(disabledOpacity: 0.4)
        compact.metrics = RegistryMetrics(
            compactSpacing: 4,
            standardSpacing: 12,
            sectionSpacing: 20,
            controlHorizontalPadding: 10,
            borderWidth: 0.5,
            emphasizedBorderWidth: 1.5,
            compactRadius: 4,
            controlRadius: 6,
            cardRadius: 12
        )
        let standard = RegistryTheme()

        #expect(compact.disabledOpacity == 0.4)
        #expect(compact.metrics.controlHorizontalPadding == 10)
        #expect(compact.metrics.borderWidth == 0.5)
        #expect(compact.metrics.emphasizedBorderWidth == 1.5)
        #expect(compact.metrics.compactRadius == 4)
        #expect(compact.metrics.controlRadius == 6)
        #expect(compact.metrics.cardRadius == 12)
        #expect(standard.disabledOpacity == 0.5)
        #expect(standard.metrics.controlHorizontalPadding == 12)
        #expect(standard.metrics.borderWidth == 1)
        #expect(standard.metrics.emphasizedBorderWidth == 2)
        #expect(standard.metrics.compactRadius == 6)
        #expect(standard.metrics.controlRadius == 8)
        #expect(standard.metrics.cardRadius == 16)
    }

    // The default theme must never replace an app's own tint: a consumer that
    // already calls .tint(.indigo) keeps it when it adopts the registry. Only
    // a preset that declares an accent takes over the tint.
    @Test func `The system theme declares no accent so it inherits the app tint`() {
        #expect(RegistryTheme.system.accent == nil)
        #expect(RegistryTheme().accent == nil)
        #expect(RegistryTheme.indigo.accent == .indigo)
    }

    // onAccent exists because a light accent cannot carry a white label; the
    // amber preset is the proving case and must keep a dark label.
    @Test func `A light accent preset pairs a dark on-accent foreground`() {
        #expect(RegistryTheme.amber.onAccent == .black)
        #expect(RegistryTheme.indigo.onAccent == .white)
    }

    @Test func `Presets are unique by name and resolvable case-insensitively`() {
        let names = RegistryTheme.presets.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(names.first == "System")
        #expect(names.last == "Mango")
        #expect(RegistryTheme.preset(named: "graphite")?.accent == .primary)
        #expect(RegistryTheme.preset(named: "mango")?.onAccent == .black)
        #expect(RegistryTheme.preset(named: "no such preset") == nil)
    }

    // MANGO is the sample design system, not an accent swap: its identity is a
    // strokeless surface over a heavier fill, generous radii, one more step of
    // section spacing, and a dark label on the warm accent. A preset that only
    // changed the accent would fail the border, surface, and radius checks.
    @Test func `The mango preset is strokeless with generous radii and a dark label`() {
        let mango = RegistryTheme.mango
        #expect(mango.accent != nil)
        #expect(mango.onAccent == .black)
        #expect(mango.border == .primary.opacity(0))
        #expect(mango.surface == .primary.opacity(0.07))
        #expect(mango.metrics.cardRadius == 24)
        #expect(mango.metrics.controlRadius == 14)
        #expect(mango.metrics.sectionSpacing == 28)
        #expect(mango.disabledOpacity == 0.4)
    }

    // The Create studio fields default so every existing initializer call keeps
    // the old shape: a theme named the old way carries the old values and the new
    // fields at their defaults.
    @Test func `A theme built without the Create studio fields keeps the old shape`() {
        let theme = RegistryTheme(accent: .indigo)

        #expect(theme.accent == .indigo)
        #expect(theme.onAccent == .white)
        #expect(theme.surface == .primary.opacity(0.055))
        #expect(theme.border == .primary.opacity(0.08))
        #expect(theme.disabledOpacity == 0.5)
        #expect(theme.metrics == RegistryMetrics())
        #expect(theme.fontDesign == nil)
        #expect(theme.surfaceOpacity == 0.055)
        #expect(theme.surfaceStep == 0.02)
        #expect(theme.chartPalette == .accent)
        #expect(theme.background == nil)
        #expect(theme.foreground == nil)
        #expect(theme.secondaryForeground == nil)
    }

    // Elevation is a ladder off the surface opacity: regular is the surface, each
    // step changes the opacity by surfaceStep, and it never leaves 0 through 1.
    @Test func `The elevation ladder steps surface opacity and clamps at zero`() {
        let theme = RegistryTheme(
            surface: .primary.opacity(0.5),
            surfaceOpacity: 0.5,
            surfaceStep: 0.25
        )

        #expect(theme.surface(at: .regular) == theme.surface)
        #expect(theme.surface(at: .regular) == .primary.opacity(0.5))
        #expect(theme.surface(at: .low) == .primary.opacity(0.25))
        #expect(theme.surface(at: .lowest) == .primary.opacity(0))
        #expect(theme.surface(at: .high) == .primary.opacity(0.75))

        // A shallow base cannot step below zero.
        let shallow = RegistryTheme(surfaceOpacity: 0.25, surfaceStep: 0.25)
        #expect(shallow.surface(at: .lowest) == .primary.opacity(0))
    }
}
