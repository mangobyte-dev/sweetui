import Charts
import Foundation
import SwiftUI
import SweetUIFoundations

/// Prepared display data for one metric tile in ``Dashboard``.
public struct DashboardMetric {
    public let title: LocalizedStringResource
    public let value: Text
    public let detail: Text?
    public let systemImage: String

    public init(
        title: LocalizedStringResource,
        value: Text,
        detail: Text? = nil,
        systemImage: String
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.systemImage = systemImage
    }
}

/// One plotted point in ``Dashboard``'s grouped bar chart: a category on the
/// x axis (such as a month), the series it belongs to, and its value. Points
/// sharing a category are grouped, and each series takes its own color.
public struct DashboardSeriesPoint: Identifiable {
    public let id: String
    public let category: String
    public let series: String
    public let value: Double

    public init(id: String, category: String, series: String, value: Double) {
        self.id = id
        self.category = category
        self.series = series
        self.value = value
    }
}

/// Prepared display data for one row in ``Dashboard``'s table.
public struct DashboardRow<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: Text
    public let detail: Text
    public let status: Text
    public let amount: Text

    public init(id: ID, title: Text, detail: Text, status: Text, amount: Text) {
        self.id = id
        self.title = title
        self.detail = detail
        self.status = status
        self.amount = amount
    }
}

/// A source-owned analytics dashboard block that composes ``MetricCard``, a
/// themed Swift Charts `Chart`, and ``DataTable`` into one screen. The caller
/// owns every value and the row-selection action; the block owns no state. It
/// does not own a `ScrollView`, navigation container, or maximum width, so a
/// caller places it inside its own scrolling container.
public struct Dashboard<ID: Hashable>: View {
    private let title: LocalizedStringResource
    private let metrics: [DashboardMetric]
    private let chartTitle: LocalizedStringResource
    private let points: [DashboardSeriesPoint]
    private let tableTitle: LocalizedStringResource
    private let rows: [DashboardRow<ID>]
    private let onSelect: ((ID) -> Void)?

    @Environment(\.registryTheme) private var theme

    public init(
        _ title: LocalizedStringResource,
        metrics: [DashboardMetric],
        chartTitle: LocalizedStringResource,
        points: [DashboardSeriesPoint],
        tableTitle: LocalizedStringResource,
        rows: [DashboardRow<ID>],
        onSelect: ((ID) -> Void)? = nil
    ) {
        self.title = title
        self.metrics = metrics
        self.chartTitle = chartTitle
        self.points = points
        self.tableTitle = tableTitle
        self.rows = rows
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.sectionSpacing) {
            Text(title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            metricsSection

            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(chartTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Chart(points) { point in
                    BarMark(
                        x: .value("Category", point.category),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .position(by: .value("Series", point.series))
                }
                .registryChart()
                .frame(height: 200)
            }

            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(tableTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                DataTable(rows, columns: columns)
            }
        }
        .registryItem("dashboard")
    }

    // The metric tiles fit as a row when the width allows and fall back to a
    // column on compact widths, so they follow Dynamic Type and container size.
    private var metricsSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                    metricCard(metric)
                }
            }

            VStack(spacing: theme.metrics.standardSpacing) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                    metricCard(metric)
                }
            }
        }
    }

    private func metricCard(_ metric: DashboardMetric) -> some View {
        MetricCard(
            metric.title,
            value: metric.value,
            detail: metric.detail,
            systemImage: metric.systemImage
        )
    }

    private var columns: [DataTableColumn<DashboardRow<ID>>] {
        [
            DataTableColumn(Text("Invoice")) { row in
                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
                    invoiceTitle(row)
                    row.detail
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            },
            DataTableColumn(Text("Status")) { row in
                row.status
            },
            DataTableColumn(Text("Amount"), alignment: .trailing) { row in
                row.amount
            },
        ]
    }

    // Selection stays at the call site: with an action the title is a plain
    // Button, otherwise the table is a non-interactive grid.
    @ViewBuilder
    private func invoiceTitle(_ row: DashboardRow<ID>) -> some View {
        if let onSelect {
            Button {
                onSelect(row.id)
            } label: {
                row.title
            }
            .buttonStyle(.plain)
            // Voice Control can name the row by its title alone.
            .accessibilityInputLabels([row.title])
        } else {
            row.title
        }
    }
}

#if DEBUG
private struct DashboardPreview: View {
    private let metrics = [
        DashboardMetric(
            title: "Revenue",
            value: Text(48_200, format: .currency(code: "USD")),
            detail: Text("Up 12% this month"),
            systemImage: "dollarsign.circle.fill"
        ),
        DashboardMetric(
            title: "Active users",
            value: Text(3_182, format: .number),
            detail: Text("Up 4% this week"),
            systemImage: "person.2.fill"
        ),
        DashboardMetric(
            title: "Conversion",
            value: Text(0.061, format: .percent.precision(.fractionLength(1))),
            systemImage: "chart.line.uptrend.xyaxis"
        ),
    ]

    private let points: [DashboardSeriesPoint] = {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        let direct: [Double] = [186, 205, 237, 173, 209, 264]
        let referral: [Double] = [80, 130, 120, 190, 150, 172]
        var result: [DashboardSeriesPoint] = []
        for (index, month) in months.enumerated() {
            result.append(
                DashboardSeriesPoint(id: "\(month)-direct", category: month, series: "Direct", value: direct[index])
            )
            result.append(
                DashboardSeriesPoint(id: "\(month)-referral", category: month, series: "Referral", value: referral[index])
            )
        }
        return result
    }()

    private let rows = [
        DashboardRow(
            id: "1041",
            title: Text("Invoice 1041"),
            detail: Text("Northwind Trading"),
            status: Text("Paid"),
            amount: Text(1_240, format: .currency(code: "USD"))
        ),
        DashboardRow(
            id: "1042",
            title: Text("Invoice 1042"),
            detail: Text("Harbor Logistics"),
            status: Text("Pending"),
            amount: Text(880, format: .currency(code: "USD"))
        ),
        DashboardRow(
            id: "1043",
            title: Text("Invoice 1043"),
            detail: Text("Meridian Studio"),
            status: Text("Paid"),
            amount: Text(2_150, format: .currency(code: "USD"))
        ),
        DashboardRow(
            id: "1044",
            title: Text("Invoice 1044"),
            detail: Text("Cedar Supply"),
            status: Text("Overdue"),
            amount: Text(430, format: .currency(code: "USD"))
        ),
        DashboardRow(
            id: "1045",
            title: Text("Invoice 1045"),
            detail: Text("Atlas Freight"),
            status: Text("Pending"),
            amount: Text(1_675, format: .currency(code: "USD"))
        ),
    ]

    var body: some View {
        ScrollView {
            Dashboard(
                "Analytics",
                metrics: metrics,
                chartTitle: "Visitors by channel",
                points: points,
                tableTitle: "Recent invoices",
                rows: rows,
                onSelect: { _ in }
            )
            .padding()
        }
    }
}

#Preview("Dashboard") {
    DashboardPreview()
}

#Preview("Dashboard Dark") {
    DashboardPreview()
        .preferredColorScheme(.dark)
}

#Preview("Dashboard Right to Left") {
    DashboardPreview()
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Dashboard Accessibility Size") {
    DashboardPreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
