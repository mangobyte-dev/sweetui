import Charts
import SwiftUI
import SweetUIFoundations

/// A browser-share donut, translated from shadcn's pie-chart-card: a native
/// Swift Charts `SectorMark` chart styled with registryChart(), a total in the
/// center, a legend, a badge for the leading category, and a footer with that
/// category's share on a linear progress bar.
public struct PieChartCard: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("January to June 2026")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                chart

                footer
            }
        } label: {
            HStack {
                Text("Browser Share")
                Spacer()
                Text(top.browser).registryBadge(.outline)
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private var chart: some View {
        Chart(shares) { share in
            SectorMark(
                angle: .value("Visitors", share.visitors),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Browser", share.browser))
        }
        .chartBackground { _ in centerLabel }
        .registryChart()
        .frame(height: 190)
        .accessibilityLabel(Text("Browser share, \(totalVisitors, format: .number) total visitors"))
    }

    private var centerLabel: some View {
        VStack(spacing: 0) {
            Text(totalVisitors, format: .number)
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text("Visitors")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityHidden(true)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            HStack {
                Text(top.browser)
                    .font(.footnote.weight(.medium))
                Spacer()
                Text(topShare, format: .percent.precision(.fractionLength(0)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: topShare)
                .progressViewStyle(.registryLinear)
                .accessibilityLabel("\(top.browser) share")
        }
    }

    private struct Share: Identifiable {
        let id: String
        let browser: String
        let visitors: Int
    }

    private let shares: [Share] = [
        Share(id: "chrome", browser: "Chrome", visitors: 275),
        Share(id: "safari", browser: "Safari", visitors: 200),
        Share(id: "firefox", browser: "Firefox", visitors: 287),
        Share(id: "edge", browser: "Edge", visitors: 173),
    ]

    private var totalVisitors: Int { shares.reduce(0) { $0 + $1.visitors } }
    private var top: Share { shares.max { $0.visitors < $1.visitors } ?? shares[0] }
    private var topShare: Double { Double(top.visitors) / Double(totalVisitors) }
}

#if DEBUG
#Preview("Pie Chart Card") {
    ScrollView { PieChartCard().padding() }
        .registryTheme(.indigo)
}

#Preview("Pie Chart Card Dark") {
    ScrollView { PieChartCard().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
