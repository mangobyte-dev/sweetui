import Foundation
import SwiftUI
import SweetUIFoundations

/// Prepared display data for one row in ``FinanceOverview``.
public struct FinanceTransactionItem<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: Text
    public let subtitle: Text
    public let amount: Text
    public let systemImage: String
    public let tone: TransactionRow.Tone

    public init(
        id: ID,
        title: Text,
        subtitle: Text,
        amount: Text,
        systemImage: String,
        tone: TransactionRow.Tone = .neutral
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.systemImage = systemImage
        self.tone = tone
    }
}

/// A source-owned finance block that composes metrics and transactions without owning app state.
public struct FinanceOverview<ID: Hashable>: View {
    private let title: LocalizedStringResource
    private let balanceTitle: LocalizedStringResource
    private let balance: Text
    private let changeTitle: LocalizedStringResource
    private let change: Text
    private let sectionTitle: LocalizedStringResource
    private let transactions: [FinanceTransactionItem<ID>]
    private let emptyTitle: LocalizedStringResource
    private let emptyDescription: Text?
    private let onSelect: (ID) -> Void

    public init(
        _ title: LocalizedStringResource,
        balanceTitle: LocalizedStringResource,
        balance: Text,
        changeTitle: LocalizedStringResource,
        change: Text,
        sectionTitle: LocalizedStringResource,
        transactions: [FinanceTransactionItem<ID>],
        emptyTitle: LocalizedStringResource = "No recent activity",
        emptyDescription: Text? = nil,
        onSelect: @escaping (ID) -> Void
    ) {
        self.title = title
        self.balanceTitle = balanceTitle
        self.balance = balance
        self.changeTitle = changeTitle
        self.change = change
        self.sectionTitle = sectionTitle
        self.transactions = transactions
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.onSelect = onSelect
    }

    public var body: some View {
        FinanceOverviewContent(
            title: title,
            balanceTitle: balanceTitle,
            balance: balance,
            changeTitle: changeTitle,
            change: change,
            sectionTitle: sectionTitle,
            transactions: transactions,
            emptyTitle: emptyTitle,
            emptyDescription: emptyDescription,
            onSelect: onSelect
        )
        .registryItem("finance-overview")
    }
}

private struct FinanceOverviewContent<ID: Hashable>: View {
    @Environment(\.registryTheme) private var theme

    let title: LocalizedStringResource
    let balanceTitle: LocalizedStringResource
    let balance: Text
    let changeTitle: LocalizedStringResource
    let change: Text
    let sectionTitle: LocalizedStringResource
    let transactions: [FinanceTransactionItem<ID>]
    let emptyTitle: LocalizedStringResource
    let emptyDescription: Text?
    let onSelect: (ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.sectionSpacing) {
            Text(title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            FinanceSummary(
                balanceTitle: balanceTitle,
                balance: balance,
                changeTitle: changeTitle,
                change: change
            )

            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(sectionTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                if transactions.isEmpty {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: "clock.arrow.circlepath",
                        description: emptyDescription
                    )
                    .registryEmptyState()
                } else {
                    VStack(spacing: 0) {
                        ForEach(transactions) { transaction in
                            Button {
                                onSelect(transaction.id)
                            } label: {
                                TransactionRow(
                                    title: transaction.title,
                                    subtitle: transaction.subtitle,
                                    amount: transaction.amount,
                                    systemImage: transaction.systemImage
                                )
                                .registryTone(transaction.tone)
                                .padding(.vertical, theme.metrics.standardSpacing)
                            }
                            .buttonStyle(.plain)
                            // Voice Control can name the row by its title alone.
                            .accessibilityInputLabels([transaction.title])

                            if transaction.id != transactions.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, theme.metrics.standardSpacing)
                    .registrySurface()
                }
            }
        }
    }
}

private struct FinanceSummary: View {
    @Environment(\.registryTheme) private var theme

    let balanceTitle: LocalizedStringResource
    let balance: Text
    let changeTitle: LocalizedStringResource
    let change: Text

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: theme.metrics.standardSpacing) {
                MetricCard(
                    balanceTitle,
                    value: balance,
                    systemImage: "creditcard.fill"
                )
                MetricCard(
                    changeTitle,
                    value: change,
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            }

            VStack(spacing: theme.metrics.standardSpacing) {
                MetricCard(
                    balanceTitle,
                    value: balance,
                    systemImage: "creditcard.fill"
                )
                MetricCard(
                    changeTitle,
                    value: change,
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }
}

#if DEBUG
private struct FinanceOverviewPreview: View {
    let isEmpty: Bool

    var body: some View {
        ScrollView {
            FinanceOverview(
                "Overview",
                balanceTitle: "Available balance",
                balance: Text(12_480.32, format: .currency(code: "USD")),
                changeTitle: "Monthly change",
                change: Text(0.082, format: .percent.precision(.fractionLength(1))),
                sectionTitle: "Recent activity",
                transactions: isEmpty ? [] : [
                    FinanceTransactionItem(
                        id: "bakery",
                        title: Text("Mishmash Bakery"),
                        subtitle: Text("Today, 09:41"),
                        amount: Text(-8.75, format: .currency(code: "KWD")),
                        systemImage: "cup.and.saucer.fill",
                        tone: .negative
                    ),
                    FinanceTransactionItem(
                        id: "salary",
                        title: Text("Salary"),
                        subtitle: Text("Yesterday"),
                        amount: Text(2_450, format: .currency(code: "KWD")),
                        systemImage: "building.columns.fill",
                        tone: .positive
                    )
                ],
                emptyDescription: Text("New transactions will appear here."),
                onSelect: { _ in }
            )
            .padding()
        }
    }
}

#Preview("Finance Overview") {
    FinanceOverviewPreview(isEmpty: false)
}

#Preview("Finance Overview Empty") {
    FinanceOverviewPreview(isEmpty: true)
}

#Preview("Finance Overview Accessibility Size") {
    FinanceOverviewPreview(isEmpty: false)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Finance Overview Dark") {
    FinanceOverviewPreview(isEmpty: false)
        .preferredColorScheme(.dark)
}

#Preview("Finance Overview Right to Left") {
    FinanceOverviewPreview(isEmpty: false)
        .environment(\.layoutDirection, .rightToLeft)
}
#endif
