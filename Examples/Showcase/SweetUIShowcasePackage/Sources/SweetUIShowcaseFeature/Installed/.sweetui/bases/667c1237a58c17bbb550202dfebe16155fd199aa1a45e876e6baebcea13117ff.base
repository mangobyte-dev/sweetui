import SwiftUI
import SweetUIFoundations

/// A savings-targets pair, translated from shadcn's savings-targets: a targets
/// card listing goals with a progress bar each, beside a buy-investment form.
/// shadcn lays the two side by side; on a compact width they stack. The goal
/// panels sit on the registry content surface with a native ProgressView in the
/// registry linear style, and the form keeps a native amount field in an input
/// group and a native Picker in the registry select chrome. Amounts are
/// formatted at the call site, so the card names no brand.
public struct SavingsTargets: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            TargetsCard()
            BuyInvestmentCard()
        }
    }

    private struct TargetsCard: View {
        @Environment(\.registryTheme) private var theme

        var body: some View {
            GroupBox {
                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    Text("Active milestones for 2026")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(SavingsTargets.goals) { goal in
                        GoalPanel(goal: goal)
                    }

                    Text("You have not met your targets for this year.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            } label: {
                HStack {
                    Text("Savings Targets")
                    Spacer()
                    Button("New goal") {}
                        .buttonStyle(.registryOutline)
                        .controlSize(.small)
                }
            }
            .groupBoxStyle(.registryCard)
        }
    }

    private struct GoalPanel: View {
        @Environment(\.registryTheme) private var theme
        let goal: Goal

        var body: some View {
            VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                Text(goal.category)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text(goal.target, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
                ProgressView(value: goal.fraction)
                    .progressViewStyle(.registryLinear)
                    .accessibilityLabel(Text("\(goal.category) progress"))
                    .accessibilityValue(Text(goal.fraction, format: .percent.precision(.fractionLength(0))))
                HStack {
                    Text("\(goal.fraction, format: .percent.precision(.fractionLength(0))) achieved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(goal.current, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.metrics.standardSpacing)
            .registrySurface()
        }
    }

    private struct BuyInvestmentCard: View {
        @Environment(\.registryTheme) private var theme
        @State private var amount: Double = 1_000
        @State private var orderType: OrderType = .market

        var body: some View {
            GroupBox {
                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    FieldGroup {
                        Field("Amount to invest") { _ in
                            InputGroup {
                                Text(verbatim: "$")
                                    .font(.subheadline.weight(.medium))
                            } content: {
                                TextField("Amount to invest", value: $amount, format: .number.precision(.fractionLength(2)))
                                    .keyboardType(.decimalPad)
                                    .accessibilityLabel("Amount to invest")
                            }
                        }

                        Field("Order type", description: "Market orders execute at the current price.") { _ in
                            Picker("Order type", selection: $orderType) {
                                ForEach(OrderType.allCases) { type in
                                    Text(type.title).tag(type)
                                }
                            }
                            .registrySelect()
                            .accessibilityLabel("Order type")
                        }
                    }

                    VStack(spacing: theme.metrics.compactSpacing) {
                        summaryRow("Estimated shares", value: Text(1.95, format: .number.precision(.fractionLength(2))))
                        summaryRow("Buying power", value: Text(12_450, format: .currency(code: "USD")))
                    }

                    VStack(spacing: theme.metrics.compactSpacing) {
                        Button { } label: {
                            Text("Review order").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.registry)

                        Text("Trades are typically executed within minutes during market hours.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
            } label: {
                Text("Buy Investment")
            }
            .groupBoxStyle(.registryCard)
        }

        private func summaryRow(_ label: LocalizedStringResource, value: Text) -> some View {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                value
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
        }
    }

    private enum OrderType: String, CaseIterable, Identifiable {
        case market, limit, stop

        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .market: "Market order"
            case .limit: "Limit order"
            case .stop: "Stop order"
            }
        }
    }

    private struct Goal: Identifiable {
        let id: String
        let category: LocalizedStringResource
        let target: Int
        let current: Int
        let fraction: Double
    }

    private static let goals: [Goal] = [
        Goal(id: "retirement", category: "Retirement", target: 420_000, current: 273_000, fraction: 0.65),
        Goal(id: "real-estate", category: "Real estate", target: 85_000, current: 27_200, fraction: 0.32),
    ]
}

#if DEBUG
#Preview("Savings Targets") {
    ScrollView { SavingsTargets().padding() }
        .registryTheme(.indigo)
}

#Preview("Savings Targets Dark") {
    ScrollView { SavingsTargets().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
