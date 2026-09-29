import Charts
import SwiftUI
import SweetUIFoundations

/// A dividend-income card, translated from shadcn's dividend-income: a
/// dismissable header, a quarterly payout bar chart styled with
/// registryChart(), and a holdings list on the content surface. shadcn draws a
/// sparkline per holding row; this shows one quarterly chart plus the holdings
/// as ItemRows, so the chart earns the registryChart treatment. Fund names are
/// invented and amounts are currency-formatted at the call site.
public struct DividendIncome: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Quarterly dividend payouts across your portfolio holdings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                chart

                holdingsList
            }
        } label: {
            HStack {
                Text("Q2 Dividend Income")
                Spacer()
                Button("Dismiss", systemImage: "xmark") {}
                    .labelStyle(.iconOnly)
                    .buttonStyle(.registryGhost)
                    .controlSize(.small)
                    .help("Dismiss")
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private var chart: some View {
        Chart(quarters) { point in
            BarMark(
                x: .value("Quarter", point.quarter),
                y: .value("Payout", point.payout)
            )
            .foregroundStyle(.tint)
            .cornerRadius(theme.metrics.compactRadius / 2)
        }
        .registryChart()
        .frame(height: 160)
        .accessibilityLabel("Total dividend payout by quarter")
    }

    private var holdingsList: some View {
        VStack(spacing: 0) {
            ForEach(holdings) { holding in
                ItemRow(
                    title: Text(holding.name),
                    description: Text("\(holding.shares, format: .number) shares"),
                    accessory: {
                        Text(holding.amount, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                )
                if holding.id != holdings.last?.id {
                    Divider().registrySeparator()
                }
            }
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }

    private struct QuarterPayout: Identifiable {
        let id: String
        let quarter: String
        let payout: Int
    }

    private struct Holding: Identifiable {
        let id: String
        let name: String
        let shares: Int
        let amount: Double
    }

    private let quarters: [QuarterPayout] = [
        QuarterPayout(id: "q1", quarter: "Q1", payout: 860),
        QuarterPayout(id: "q2", quarter: "Q2", payout: 960),
        QuarterPayout(id: "q3", quarter: "Q3", payout: 1110),
        QuarterPayout(id: "q4", quarter: "Q4", payout: 1320),
    ]

    private let holdings: [Holding] = [
        Holding(id: "harborline", name: "Harborline Dividend Fund", shares: 450, amount: 1_842.10),
        Holding(id: "meridian", name: "Meridian Index 500", shares: 112, amount: 928.40),
        Holding(id: "cobalt", name: "Cobalt Technologies", shares: 85, amount: 340.00),
        Holding(id: "vellum", name: "Vellum Property Trust", shares: 320, amount: 1_139.50),
    ]
}

#if DEBUG
#Preview("Dividend Income") {
    ScrollView { DividendIncome().padding() }
        .registryTheme(.indigo)
}

#Preview("Dividend Income Dark") {
    ScrollView { DividendIncome().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
