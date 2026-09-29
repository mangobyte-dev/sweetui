import Charts
import SwiftUI
import SweetUIFoundations

/// A card-account overview, translated from shadcn's card-overview: a balance
/// card and a payment-due card side by side, and a full-width yearly-activity
/// card whose bar chart is styled with registryChart(). Amounts and the due
/// date are formatted at the call site; the reward badge sits in the header.
public struct CardOverview: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    private let dueDate = DateComponents(calendar: .current, year: 2026, month: 4, day: 1).date ?? .now

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                balanceCard
                paymentCard
            }
            activityCard
        }
    }

    private var balanceCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
                Text(12.94, format: .currency(code: "USD"))
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
                Text("\(11_337.06, format: .currency(code: "USD")) available")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } label: {
            Text("Card Balance")
        }
        .groupBoxStyle(.registryCard)
    }

    private var paymentCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(dueDate, format: .dateTime.day().month(.abbreviated))
                    .font(.title.weight(.semibold))
                Button("Pay early") {}
                    .buttonStyle(.registryOutline)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Payment Due")
        }
        .groupBoxStyle(.registryCard)
    }

    private var activityCard: some View {
        GroupBox {
            Chart(months) { point in
                BarMark(
                    x: .value("Month", point.month),
                    y: .value("Amount", point.amount)
                )
                .foregroundStyle(.tint)
                .cornerRadius(theme.metrics.compactRadius / 2)
            }
            .registryChart()
            .frame(height: 120)
            .accessibilityLabel("Monthly card activity for the last twelve months")
        } label: {
            HStack {
                Text("Yearly Activity")
                Spacer()
                Text("\(0.25, format: .currency(code: "USD").sign(strategy: .always(showZero: false))) daily rewards")
                    .registryBadge(.secondary)
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private struct MonthlyActivity: Identifiable {
        let id: String
        let month: String
        let amount: Int
    }

    private let months: [MonthlyActivity] = [
        MonthlyActivity(id: "jan", month: "Jan", amount: 40),
        MonthlyActivity(id: "feb", month: "Feb", amount: 55),
        MonthlyActivity(id: "mar", month: "Mar", amount: 35),
        MonthlyActivity(id: "apr", month: "Apr", amount: 60),
        MonthlyActivity(id: "may", month: "May", amount: 45),
        MonthlyActivity(id: "jun", month: "Jun", amount: 50),
        MonthlyActivity(id: "jul", month: "Jul", amount: 65),
        MonthlyActivity(id: "aug", month: "Aug", amount: 40),
        MonthlyActivity(id: "sep", month: "Sep", amount: 55),
        MonthlyActivity(id: "oct", month: "Oct", amount: 70),
        MonthlyActivity(id: "nov", month: "Nov", amount: 45),
        MonthlyActivity(id: "dec", month: "Dec", amount: 80),
    ]
}

#if DEBUG
#Preview("Card Overview") {
    ScrollView { CardOverview().padding() }
        .registryTheme(.indigo)
}

#Preview("Card Overview Dark") {
    ScrollView { CardOverview().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
