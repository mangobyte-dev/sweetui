import Charts
import SwiftUI
import SweetUIFoundations

#if canImport(UIKit)
import UIKit
#endif

/// A categorical color palette for charts with more than one series, chosen by
/// the theme's ``RegistryTheme/chartPalette``: tints derived from the accent, a
/// fixed spectrum, or a gray ramp. A custom chart legend or a series label should
/// read its colors from here so it matches the plot.
public enum RegistryChartPalette {
    // Hue rotations, in degrees, applied to the accent for each series. The
    // first series is the accent unchanged.
    private static let hueOffsets: [Double] = [0, 30, 60, 90, 120, -30]

    // A fixed six-hue set, used when the theme opts out of accent-derived tints.
    private static let spectrum: [Color] = [.blue, .orange, .green, .pink, .purple, .teal]

    // Six gray levels off the primary color, so they follow the color scheme.
    private static let monochrome: [Color] = [1, 0.82, 0.64, 0.46, 0.3, 0.16].map {
        Color.primary.opacity($0)
    }

    public static func colors(for theme: RegistryTheme, colorScheme: ColorScheme) -> [Color] {
        switch theme.chartPalette {
        case .spectrum: return spectrum
        case .monochrome: return monochrome
        case .accent: return accentTints(for: theme, colorScheme: colorScheme)
        }
    }

    // The accent itself, then rotations of its hue so the series stay distinct
    // yet cohesive with the theme.
    private static func accentTints(for theme: RegistryTheme, colorScheme: ColorScheme) -> [Color] {
        let base = theme.accent ?? Color.accentColor

        #if canImport(UIKit)
        let resolved = UIColor(base).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        )
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        // An accent with real chroma rotates into distinct hues; an achromatic
        // accent (a graphite theme) has no hue to rotate, so fall through to the
        // tonal ramp below.
        if resolved.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha),
           saturation > 0.05 {
            return hueOffsets.map { offset in
                var rotated = (hue + CGFloat(offset) / 360).truncatingRemainder(dividingBy: 1)
                if rotated < 0 { rotated += 1 }
                return Color(
                    hue: Double(rotated),
                    saturation: Double(saturation),
                    brightness: Double(brightness),
                    opacity: Double(alpha)
                )
            }
        }
        #endif

        // Fallback: a tonal ramp of the accent, for an achromatic accent or a
        // platform without hue extraction.
        return (0..<hueOffsets.count).map { index in
            base.opacity(1 - Double(index) * 0.15)
        }
    }
}

public extension View {
    /// Styles a Swift Charts `Chart` to the theme: the derived series palette on
    /// the foreground style scale, the theme border on grid lines and ticks,
    /// footnote axis labels, and a legend below the plot. Bar, line, area, and
    /// pie charts all inherit it; a single-series mark follows the theme tint,
    /// and a mark colored `by:` a category reads the palette and shows in the
    /// legend.
    func registryChart() -> some View {
        modifier(RegistryChartModifier())
    }
}

private struct RegistryChartModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .chartForegroundStyleScale(
                range: RegistryChartPalette.colors(for: theme, colorScheme: colorScheme)
            )
            .chartXAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(theme.border)
                    AxisTick().foregroundStyle(theme.border)
                    AxisValueLabel()
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(theme.border)
                    AxisTick().foregroundStyle(theme.border)
                    AxisValueLabel()
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartLegend(position: .bottom, spacing: theme.metrics.standardSpacing)
            .registryItem("chart")
    }
}

private struct ChannelVisits: Identifiable {
    let id = UUID()
    let month: String
    let channel: String
    let visits: Int
}

private struct MonthlyBalance: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

private struct BrowserShare: Identifiable {
    let id = UUID()
    let browser: String
    let share: Double
}

private struct RegistryChartPreview: View {
    private let visits = [
        ChannelVisits(month: "Jan", channel: "Desktop", visits: 186),
        ChannelVisits(month: "Jan", channel: "Mobile", visits: 80),
        ChannelVisits(month: "Feb", channel: "Desktop", visits: 205),
        ChannelVisits(month: "Feb", channel: "Mobile", visits: 130),
        ChannelVisits(month: "Mar", channel: "Desktop", visits: 237),
        ChannelVisits(month: "Mar", channel: "Mobile", visits: 120),
        ChannelVisits(month: "Apr", channel: "Desktop", visits: 173),
        ChannelVisits(month: "Apr", channel: "Mobile", visits: 190),
    ]

    private let balances = [
        MonthlyBalance(month: "Jan", amount: 2.1),
        MonthlyBalance(month: "Feb", amount: 2.6),
        MonthlyBalance(month: "Mar", amount: 2.4),
        MonthlyBalance(month: "Apr", amount: 3.1),
        MonthlyBalance(month: "May", amount: 3.5),
    ]

    private let shares = [
        BrowserShare(browser: "Safari", share: 38),
        BrowserShare(browser: "Chrome", share: 34),
        BrowserShare(browser: "Firefox", share: 16),
        BrowserShare(browser: "Edge", share: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            chart("Traffic by channel") {
                Chart(visits) { row in
                    BarMark(
                        x: .value("Month", row.month),
                        y: .value("Visits", row.visits)
                    )
                    .foregroundStyle(by: .value("Channel", row.channel))
                    .position(by: .value("Channel", row.channel))
                }
                .registryChart()
                .frame(height: 170)
            }

            chart("Balance trend") {
                Chart(balances) { row in
                    LineMark(
                        x: .value("Month", row.month),
                        y: .value("Balance", row.amount)
                    )
                    .interpolationMethod(.catmullRom)
                    // A single series takes the accent explicitly; Swift Charts
                    // otherwise draws it in its own default color.
                    .foregroundStyle(TintShapeStyle())
                }
                .registryChart()
                .frame(height: 130)
            }

            chart("Cumulative inflow") {
                Chart(balances) { row in
                    AreaMark(
                        x: .value("Month", row.month),
                        y: .value("Balance", row.amount)
                    )
                    .foregroundStyle(TintShapeStyle().opacity(0.2))
                    LineMark(
                        x: .value("Month", row.month),
                        y: .value("Balance", row.amount)
                    )
                    .foregroundStyle(TintShapeStyle())
                }
                .registryChart()
                .frame(height: 130)
            }

            chart("Browser share") {
                Chart(shares) { row in
                    SectorMark(
                        angle: .value("Share", row.share),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Browser", row.browser))
                }
                .registryChart()
                .frame(height: 190)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func chart(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
            content()
        }
    }
}

#Preview("Chart") {
    ScrollView { RegistryChartPreview().tint(.indigo) }
}

#Preview("Chart Dark") {
    ScrollView { RegistryChartPreview().tint(.indigo).preferredColorScheme(.dark) }
}

#Preview("Chart Right to Left") {
    ScrollView { RegistryChartPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft) }
}

#Preview("Chart Accessibility Size") {
    ScrollView { RegistryChartPreview().tint(.indigo).dynamicTypeSize(.accessibility3) }
}
