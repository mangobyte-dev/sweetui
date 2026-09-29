import SwiftUI

/// The small, stable design contract shared by source-owned registry items.
///
/// Set it once at the root of a scene with ``SwiftUI/View/registryTheme(_:)``
/// and every registry item below inherits the same accent, surfaces, borders,
/// semantic colors, and metrics. Apple controls still read the app tint, so a
/// theme with an ``accent`` also tints native buttons, toggles, and pickers.
public struct RegistryTheme: Sendable {
    /// The interactive accent applied as the subtree tint. `nil` inherits the
    /// app tint already in the environment instead of replacing it.
    public var accent: Color?
    /// The foreground drawn on top of accent-filled controls, such as the
    /// primary button label. Pair it with the accent's luminance.
    public var onAccent: Color
    /// The content-layer surface fill used by cards and secondary controls.
    public var surface: Color
    /// The hairline stroke used by surfaces, inputs, and separators.
    public var border: Color
    /// Success and completion semantics.
    public var positive: Color
    /// Error and destructive semantics. Registry buttons draw a white label
    /// on this fill, so keep it dark enough for white text.
    public var negative: Color
    /// Opacity applied to disabled registry controls.
    public var disabledOpacity: Double
    public var metrics: RegistryMetrics
    /// The font design applied to the whole subtree by ``SwiftUI/View/registryTheme(_:)``.
    /// `nil` inherits the design already in the environment. A custom font family
    /// is never carried here; it lives in the Swift export and the theme package.
    public var fontDesign: Font.Design?
    /// The opacity of the ``regular`` surface level, and the base of the
    /// elevation ladder. Kept as a number so ``surface(at:)`` can step it; the
    /// resolved ``regular`` fill stays ``surface``.
    public var surfaceOpacity: Double
    /// The opacity difference between adjacent elevation levels. Each step up
    /// adds this much opacity to the surface, each step down subtracts it.
    public var surfaceStep: Double
    /// How ``RegistryChartPalette`` colors a multi-series chart: derived tints of
    /// the accent, a fixed spectrum, or a gray ramp.
    public var chartPalette: ChartPalette
    /// The window background applied by ``SwiftUI/View/registryTheme(_:)``.
    /// `nil` keeps the system background.
    public var background: Color?
    /// The primary content color applied by ``SwiftUI/View/registryTheme(_:)``.
    /// `nil` keeps the system label. SwiftUI derives the secondary hierarchy from
    /// it unless ``secondaryForeground`` is also set.
    public var foreground: Color?
    /// The secondary content color. Only meaningful when ``foreground`` is set.
    public var secondaryForeground: Color?

    /// How a multi-series chart draws its categories.
    public enum ChartPalette: String, Sendable, CaseIterable {
        /// Tints derived from the theme accent, the first series being the accent.
        case accent
        /// A fixed six-hue set: blue, orange, green, pink, purple, teal.
        case spectrum
        /// Six gray levels, for a monochrome chart.
        case monochrome
    }

    public init(
        accent: Color? = nil,
        onAccent: Color = .white,
        surface: Color = .primary.opacity(0.055),
        border: Color = .primary.opacity(0.08),
        positive: Color = .green,
        negative: Color = .red,
        disabledOpacity: Double = 0.5,
        metrics: RegistryMetrics = .init(),
        fontDesign: Font.Design? = nil,
        surfaceOpacity: Double = 0.055,
        surfaceStep: Double = 0.02,
        chartPalette: ChartPalette = .accent,
        background: Color? = nil,
        foreground: Color? = nil,
        secondaryForeground: Color? = nil
    ) {
        self.accent = accent
        self.onAccent = onAccent
        self.surface = surface
        self.border = border
        self.positive = positive
        self.negative = negative
        self.disabledOpacity = disabledOpacity
        self.metrics = metrics
        self.fontDesign = fontDesign
        self.surfaceOpacity = surfaceOpacity
        self.surfaceStep = surfaceStep
        self.chartPalette = chartPalette
        self.background = background
        self.foreground = foreground
        self.secondaryForeground = secondaryForeground
    }

    /// The surface fill at an elevation ``RegistrySurfaceLevel``, stepping
    /// ``surfaceOpacity`` by ``surfaceStep`` per level and clamping to 0 through 1.
    /// ``RegistrySurfaceLevel/regular`` returns ``surface`` unchanged.
    public func surface(at level: RegistrySurfaceLevel) -> Color {
        if level == .regular { return surface }
        let opacity = min(1, max(0, surfaceOpacity + Double(level.step) * surfaceStep))
        return .primary.opacity(opacity)
    }
}

/// A rung on the elevation ladder, offset from the ``RegistryTheme/regular``
/// surface by a whole number of ``RegistryTheme/surfaceStep`` steps.
public enum RegistrySurfaceLevel: Sendable {
    case lowest
    case low
    case regular
    case high

    /// The number of ``RegistryTheme/surfaceStep`` steps from ``regular``.
    var step: Int {
        switch self {
        case .lowest: return -2
        case .low: return -1
        case .regular: return 0
        case .high: return 1
        }
    }
}

/// Layout and appearance values shared without imposing an app-wide theme system.
public struct RegistryMetrics: Equatable, Sendable {
    public static let minimumHitSize: CGFloat = 44

    public var compactSpacing: CGFloat
    public var standardSpacing: CGFloat
    public var sectionSpacing: CGFloat
    public var controlHorizontalPadding: CGFloat
    public var borderWidth: CGFloat
    public var emphasizedBorderWidth: CGFloat
    /// Radius of small chrome such as badges and checkboxes.
    public var compactRadius: CGFloat
    public var controlRadius: CGFloat
    public var cardRadius: CGFloat

    public init(
        compactSpacing: CGFloat = 8,
        standardSpacing: CGFloat = 16,
        sectionSpacing: CGFloat = 24,
        controlHorizontalPadding: CGFloat = 12,
        borderWidth: CGFloat = 1,
        emphasizedBorderWidth: CGFloat = 2,
        compactRadius: CGFloat = 6,
        controlRadius: CGFloat = 8,
        cardRadius: CGFloat = 16
    ) {
        self.compactSpacing = compactSpacing
        self.standardSpacing = standardSpacing
        self.sectionSpacing = sectionSpacing
        self.controlHorizontalPadding = controlHorizontalPadding
        self.borderWidth = borderWidth
        self.emphasizedBorderWidth = emphasizedBorderWidth
        self.compactRadius = compactRadius
        self.controlRadius = controlRadius
        self.cardRadius = cardRadius
    }
}

// MARK: - Presets

/// A named starting point for a design system. Pick one, apply it once, then
/// edit the copied item source or override individual tokens as the product
/// diverges.
public struct RegistryThemePreset: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let theme: RegistryTheme

    public init(name: String, theme: RegistryTheme) {
        self.name = name
        self.theme = theme
    }
}

public extension RegistryTheme {
    /// Inherits the app tint and the system's semantic colors. The default.
    static let system = RegistryTheme()

    /// Monochrome: primary-colored accent with a background-colored label, the
    /// familiar black-on-light, white-on-dark treatment.
    static let graphite = RegistryTheme(
        accent: .primary,
        onAccent: systemBackground,
        surface: .primary.opacity(0.05),
        border: .primary.opacity(0.1)
    )

    static let indigo = RegistryTheme(accent: .indigo)

    static let rose = RegistryTheme(accent: .pink)

    static let emerald = RegistryTheme(accent: .green)

    /// A light accent that needs a dark label; proves ``onAccent`` earns its place.
    static let amber = RegistryTheme(accent: .yellow, onAccent: .black)

    /// MangoByte's sample design system, the worked example of building one on
    /// the registry. It demonstrates three brand choices at once: a custom
    /// accent that carries separate light and dark values (the mango, lightened
    /// so a dark label stays legible on black), no visible stroke with depth from
    /// a surface luminance step instead (``border`` opacity zero over a heavier
    /// ``surface``), and generous radii with one more step of section spacing.
    /// The matching preset code carries the same knobs.
    static let mango = RegistryTheme(
        accent: mangoAccent,
        onAccent: .black,
        surface: .primary.opacity(0.07),
        border: .primary.opacity(0),
        disabledOpacity: 0.4,
        metrics: RegistryMetrics(
            compactSpacing: 8,
            standardSpacing: 16,
            sectionSpacing: 28,
            controlHorizontalPadding: 16,
            borderWidth: 1,
            emphasizedBorderWidth: 2,
            compactRadius: 10,
            controlRadius: 14,
            cardRadius: 24
        )
    )

    /// Every preset in display order.
    static let presets: [RegistryThemePreset] = [
        RegistryThemePreset(name: "System", theme: .system),
        RegistryThemePreset(name: "Graphite", theme: .graphite),
        RegistryThemePreset(name: "Indigo", theme: .indigo),
        RegistryThemePreset(name: "Rose", theme: .rose),
        RegistryThemePreset(name: "Emerald", theme: .emerald),
        RegistryThemePreset(name: "Amber", theme: .amber),
        RegistryThemePreset(name: "Mango", theme: .mango),
    ]

    /// The mango accent as a dynamic color: a warm orange in light appearance
    /// that lightens for dark so the dark label stays legible on black. Built
    /// per platform like ``systemBackground``, the shape a preset code's custom
    /// accent pair exports.
    private static var mangoAccent: Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1, green: 0.722, blue: 0.302, alpha: 1)
                : UIColor(red: 1, green: 0.627, blue: 0.2, alpha: 1)
        })
        #elseif canImport(AppKit)
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(srgbRed: 1, green: 0.722, blue: 0.302, alpha: 1)
                : NSColor(srgbRed: 1, green: 0.627, blue: 0.2, alpha: 1)
        })
        #else
        Color(red: 1, green: 0.627, blue: 0.2)
        #endif
    }

    /// The platform window background, used as the label on a primary-colored accent.
    private static var systemBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.white
        #endif
    }

    /// The preset whose name matches, case-insensitively, or `nil`.
    static func preset(named name: String) -> RegistryTheme? {
        presets.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.theme
    }
}

// MARK: - Environment

public extension EnvironmentValues {
    @Entry var registryTheme = RegistryTheme()
}

public extension View {
    /// Applies registry foundations to this subtree: the tokens through the
    /// environment and, when the theme declares an accent, the tint as well.
    /// Apply once at the scene root for a set-up-once design system.
    ///
    /// The tint is applied only when an accent exists, because `tint(nil)`
    /// resets the tint instead of inheriting it and SwiftUI exposes no way to
    /// read the tint already in place. A theme whose accent changes between
    /// `nil` and a value at runtime therefore replaces the subtree and resets
    /// the state below it. Keep the accent's presence stable, or pass
    /// `Color.accentColor` instead of `nil`.
    func registryTheme(_ theme: RegistryTheme) -> some View {
        modifier(RegistryThemeModifier(theme: theme))
    }

    /// Applies the shared content-surface treatment used by registry cards, at
    /// the given elevation ``RegistrySurfaceLevel`` (``RegistrySurfaceLevel/regular``
    /// by default).
    func registrySurface(level: RegistrySurfaceLevel = .regular) -> some View {
        modifier(RegistrySurfaceModifier(level: level))
    }
}

private struct RegistryThemeModifier: ViewModifier {
    let theme: RegistryTheme

    @ViewBuilder
    func body(content: Content) -> some View {
        tinted(content)
            .environment(\.registryTheme, theme)
            .fontDesign(theme.fontDesign)
            .modifier(RegistryForegroundModifier(theme: theme))
            .modifier(RegistryBackgroundModifier(background: theme.background))
    }

    // The tint is applied only when an accent exists, because `tint(nil)` resets
    // the tint instead of inheriting it; see ``SwiftUI/View/registryTheme(_:)``.
    @ViewBuilder
    private func tinted(_ content: Content) -> some View {
        if let accent = theme.accent {
            content.tint(accent)
        } else {
            content
        }
    }
}

private struct RegistryForegroundModifier: ViewModifier {
    let theme: RegistryTheme

    @ViewBuilder
    func body(content: Content) -> some View {
        if let foreground = theme.foreground, let secondary = theme.secondaryForeground {
            content.foregroundStyle(foreground, secondary)
        } else if let foreground = theme.foreground {
            content.foregroundStyle(foreground)
        } else {
            content
        }
    }
}

private struct RegistryBackgroundModifier: ViewModifier {
    let background: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let background {
            content.background(background, ignoresSafeAreaEdges: .all)
        } else {
            content
        }
    }
}

private struct RegistrySurfaceModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme
    let level: RegistrySurfaceLevel

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: theme.metrics.cardRadius,
            style: .continuous
        )

        content
            .background(theme.surface(at: level), in: shape)
            .overlay {
                shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth)
            }
    }
}
