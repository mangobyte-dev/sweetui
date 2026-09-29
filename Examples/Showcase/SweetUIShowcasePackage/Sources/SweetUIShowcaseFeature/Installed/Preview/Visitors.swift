import Charts
import SwiftUI
import SweetUIFoundations

/// A visitors trend, translated from shadcn's visitors: a single-series Swift
/// Charts area chart styled with registryChart(), and a month-over-month trend
/// badge in the header. The area and line follow the theme tint, and the trend
/// is percentage-formatted at the call site.
public struct Visitors: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Last 6 months")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                chart
            }
        } label: {
            HStack {
                Text("Visitors")
                Spacer()
                Text("\(trend, format: trendStyle) vs last month")
                    .registryBadge(trend >= 0 ? .secondary : .destructive)
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private var chart: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Month", point.month),
                y: .value("Visitors", point.visits)
            )
            .foregroundStyle(.tint.opacity(0.15))
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Month", point.month),
                y: .value("Visitors", point.visits)
            )
            .foregroundStyle(.tint)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .registryChart()
        .frame(height: 180)
        .accessibilityLabel(Text("Visitors over the last six months"))
    }

    private var trendStyle: FloatingPointFormatStyle<Double>.Percent {
        .percent.precision(.fractionLength(0)).sign(strategy: .always(includingZero: false))
    }

    private struct VisitorPoint: Identifiable {
        let id: String
        let month: String
        let visits: Int
    }

    private let points: [VisitorPoint] = [
        VisitorPoint(id: "jan", month: "Jan", visits: 186),
        VisitorPoint(id: "feb", month: "Feb", visits: 305),
        VisitorPoint(id: "mar", month: "Mar", visits: 237),
        VisitorPoint(id: "apr", month: "Apr", visits: 73),
        VisitorPoint(id: "may", month: "May", visits: 209),
        VisitorPoint(id: "jun", month: "Jun", visits: 214),
    ]

    private var trend: Double {
        guard points.count >= 2 else { return 0 }
        let latest = points[points.count - 1].visits
        let previous = points[points.count - 2].visits
        guard previous != 0 else { return 0 }
        return Double(latest - previous) / Double(previous)
    }
}

#if DEBUG
#Preview("Visitors") {
    ScrollView { Visitors().padding() }
        .registryTheme(.indigo)
}

#Preview("Visitors Dark") {
    ScrollView { Visitors().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
