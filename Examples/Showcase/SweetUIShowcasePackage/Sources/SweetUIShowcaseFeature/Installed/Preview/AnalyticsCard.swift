import Charts
import SwiftUI
import SweetUIFoundations

/// A visitors analytics summary, translated from shadcn's analytics-card: a
/// headline count with a delta badge, a themed area chart, and a header action
/// that opens the full report. The chart is a native Swift Charts chart styled
/// with `registryChart()`.
public struct AnalyticsCard: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                HStack(spacing: theme.metrics.compactSpacing) {
                    Text("418.2K Visitors")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("+10%").registryBadge()
                }

                Chart(points) { point in
                    AreaMark(
                        x: .value("Month", point.month),
                        y: .value("Visitors", point.visitors)
                    )
                    .foregroundStyle(TintShapeStyle().opacity(0.2))
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Visitors", point.visitors)
                    )
                    .foregroundStyle(TintShapeStyle())
                    .interpolationMethod(.catmullRom)
                }
                .registryChart()
                .frame(height: 120)
                .accessibilityLabel("Monthly visitors")
            }
        } label: {
            HStack {
                Text("Analytics")
                Spacer()
                Button("View Analytics") {}
                    .buttonStyle(.registryOutline)
                    .controlSize(.small)
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private struct VisitorPoint: Identifiable {
        let id: String
        let month: String
        let visitors: Int
    }

    private let points: [VisitorPoint] = [
        VisitorPoint(id: "jan", month: "Jan", visitors: 186),
        VisitorPoint(id: "feb", month: "Feb", visitors: 305),
        VisitorPoint(id: "mar", month: "Mar", visitors: 237),
        VisitorPoint(id: "apr", month: "Apr", visitors: 73),
        VisitorPoint(id: "may", month: "May", visitors: 209),
        VisitorPoint(id: "jun", month: "Jun", visitors: 214),
    ]
}

#if DEBUG
#Preview("Analytics Card") {
    ScrollView { AnalyticsCard().padding() }
        .registryTheme(.indigo)
}

#Preview("Analytics Card Dark") {
    ScrollView { AnalyticsCard().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
