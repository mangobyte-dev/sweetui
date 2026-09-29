import Charts
import SwiftUI
import SweetUIFoundations

/// Traffic channels, translated from shadcn's bar-chart-card: a grouped Swift
/// Charts bar chart styled with registryChart(), a three-up totals strip split
/// by vertical separators, and a full-width report action.
public struct BarChartCard: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Monthly desktop and mobile traffic for the last six months.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Chart(points) { point in
                    BarMark(
                        x: .value("Month", point.month),
                        y: .value("Visits", point.visits)
                    )
                    .foregroundStyle(by: .value("Channel", point.channel))
                    .position(by: .value("Channel", point.channel))
                }
                .registryChart()
                .frame(height: 160)
                .accessibilityLabel("Desktop and mobile traffic by month")

                stats

                Button("View report") {}
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Traffic channels")
        }
        .groupBoxStyle(.registryCard)
    }

    private var stats: some View {
        HStack(spacing: 0) {
            StatColumn(title: "Desktop", value: Text(desktopTotal, format: .number))
            Divider().registrySeparator(.vertical)
            StatColumn(title: "Mobile", value: Text(mobileTotal, format: .number))
            Divider().registrySeparator(.vertical)
            StatColumn(
                title: "Mix delta",
                value: Text(mixDelta, format: .percent.precision(.fractionLength(0)).sign(strategy: .always(includingZero: false)))
            )
        }
        .frame(height: 44)
    }

    private struct StatColumn: View {
        let title: LocalizedStringResource
        let value: Text

        var body: some View {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                value
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private struct TrafficPoint: Identifiable {
        let id: String
        let month: String
        let channel: String
        let visits: Int
    }

    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
    private let desktop = [186, 305, 237, 73, 209, 214]
    private let mobile = [80, 200, 120, 190, 130, 140]

    private var points: [TrafficPoint] {
        months.indices.flatMap { index in
            [
                TrafficPoint(id: "\(months[index])-desktop", month: months[index], channel: "Desktop", visits: desktop[index]),
                TrafficPoint(id: "\(months[index])-mobile", month: months[index], channel: "Mobile", visits: mobile[index]),
            ]
        }
    }

    private var desktopTotal: Int { desktop.reduce(0, +) }
    private var mobileTotal: Int { mobile.reduce(0, +) }
    private var mixDelta: Double { Double(desktopTotal - mobileTotal) / Double(mobileTotal) }
}

#if DEBUG
#Preview("Bar Chart Card") {
    ScrollView { BarChartCard().padding() }
        .registryTheme(.indigo)
}

#Preview("Bar Chart Card Dark") {
    ScrollView { BarChartCard().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
