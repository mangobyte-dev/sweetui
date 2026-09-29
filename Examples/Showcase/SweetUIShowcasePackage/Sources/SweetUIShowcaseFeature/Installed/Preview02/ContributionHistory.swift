import Charts
import SwiftUI
import SweetUIFoundations

/// A contribution-history card, translated from shadcn's contribution-history:
/// a six-month bar chart styled with registryChart(), a two-up strip of muted
/// summary boxes on the content surface, and a full-width report action. The
/// scheduled amount is currency-formatted and the upcoming date is formatted
/// at the call site.
public struct ContributionHistory: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    private let upcomingDate = DateComponents(calendar: .current, year: 2026, month: 5, day: 25).date ?? .now

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Last 6 months of activity")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                chart

                HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                    StatBox(
                        caption: "Upcoming",
                        value: Text(upcomingDate, format: .dateTime.month(.abbreviated).day().year()),
                        detail: Text("\(1000, format: .currency(code: "USD").precision(.fractionLength(0))) scheduled")
                    )
                    StatBox(
                        caption: "Auto-save plan",
                        value: Text("Accelerated"),
                        detail: Text("Recurring weekly")
                    )
                }

                Button("View full report") {}
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Contribution History")
        }
        .groupBoxStyle(.registryCard)
    }

    private var chart: some View {
        Chart(months) { point in
            BarMark(
                x: .value("Month", point.month),
                y: .value("Amount", point.amount)
            )
            .foregroundStyle(.tint)
            .cornerRadius(theme.metrics.compactRadius / 2)
        }
        .registryChart()
        .frame(height: 180)
        .accessibilityLabel("Contribution amount for the last six months")
    }

    private struct StatBox: View {
        @Environment(\.registryTheme) private var theme
        let caption: LocalizedStringResource
        let value: Text
        let detail: Text

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(caption)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                value
                    .font(.headline)
                detail
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.metrics.standardSpacing)
            .registrySurface()
        }
    }

    private struct MonthlyContribution: Identifiable {
        let id: String
        let month: String
        let amount: Int
    }

    private let months: [MonthlyContribution] = [
        MonthlyContribution(id: "dec", month: "Dec", amount: 800),
        MonthlyContribution(id: "jan", month: "Jan", amount: 1100),
        MonthlyContribution(id: "feb", month: "Feb", amount: 900),
        MonthlyContribution(id: "mar", month: "Mar", amount: 1300),
        MonthlyContribution(id: "apr", month: "Apr", amount: 750),
        MonthlyContribution(id: "may", month: "May", amount: 1400),
    ]
}

#if DEBUG
#Preview("Contribution History") {
    ScrollView { ContributionHistory().padding() }
        .registryTheme(.indigo)
}

#Preview("Contribution History Dark") {
    ScrollView { ContributionHistory().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
