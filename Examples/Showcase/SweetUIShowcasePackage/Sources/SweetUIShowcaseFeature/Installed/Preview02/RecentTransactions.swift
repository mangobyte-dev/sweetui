import SwiftUI
import SweetUIFoundations

/// A recent-transactions card, translated from shadcn's recent-transactions: a
/// header with a view-all action over a table of transactions, each with a
/// category icon, a date, an amount, and a per-row options menu. shadcn uses
/// its table and dropdown-menu primitives; this keeps the registry DataTable,
/// which stays column-aligned on iPhone, and a native Menu in the last column.
/// Merchant names are invented and amounts and dates are formatted at the call
/// site, so income reads with a leading plus and the card names no brand.
public struct RecentTransactions: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Your latest account activity.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                table
            }
        } label: {
            HStack {
                Text("Recent Transactions")
                Spacer()
                Button("View all") {}
                    .buttonStyle(.registryOutline)
                    .controlSize(.small)
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private var table: some View {
        DataTable(
            Self.transactions,
            columns: [
                DataTableColumn(Text("Transaction")) { transaction in
                    TransactionCell(transaction: transaction)
                },
                DataTableColumn(Text("Date")) { transaction in
                    Text(transaction.date, format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(.secondary)
                },
                DataTableColumn(Text("Amount"), alignment: .trailing) { transaction in
                    Text(transaction.amount, format: .currency(code: "USD").sign(strategy: .always(showZero: false)))
                        .fontWeight(.semibold)
                        .foregroundStyle(transaction.amount > 0 ? theme.positive : Color.primary)
                },
                DataTableColumn(Text(verbatim: ""), alignment: .trailing) { transaction in
                    TransactionMenu(name: transaction.name)
                },
            ]
        )
        .padding(theme.metrics.standardSpacing)
        .registrySurface()
    }

    private struct TransactionCell: View {
        @Environment(\.registryTheme) private var theme
        let transaction: Transaction

        var body: some View {
            HStack(spacing: theme.metrics.compactSpacing) {
                let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)
                Image(systemName: transaction.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(theme.surface, in: shape)
                    .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.name)
                        .font(.subheadline.weight(.medium))
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private struct TransactionMenu: View {
        let name: String

        var body: some View {
            Menu {
                Button("View details") {}
                Button("Add note") {}
                Button("Categorize") {}
                Divider()
                Button("Dispute", role: .destructive) {}
            } label: {
                Label("Options", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
            }
            .accessibilityLabel(Text("Options for \(name)"))
        }
    }

    private struct Transaction: Identifiable {
        let id: String
        let name: String
        let category: LocalizedStringResource
        let systemImage: String
        let date: Date
        let amount: Double
    }

    private static func day(_ month: Int, _ day: Int) -> Date {
        DateComponents(calendar: .current, year: 2026, month: month, day: day).date ?? .now
    }

    private static let transactions: [Transaction] = [
        Transaction(id: "roasters", name: "Harbor Roasters", category: "Food & drink", systemImage: "cup.and.saucer.fill", date: day(10, 24), amount: -6.50),
        Transaction(id: "market", name: "Greenfield Market", category: "Groceries", systemImage: "cart.fill", date: day(10, 23), amount: -142.30),
        Transaction(id: "payout", name: "Studio Payout", category: "Income", systemImage: "wallet.bifold.fill", date: day(10, 12), amount: 4_200.00),
        Transaction(id: "rides", name: "Metro Rides", category: "Transport", systemImage: "car.fill", date: day(10, 11), amount: -24.10),
        Transaction(id: "stream", name: "Aurora Stream", category: "Entertainment", systemImage: "tv.fill", date: day(10, 10), amount: -19.99),
    ]
}

#if DEBUG
#Preview("Recent Transactions") {
    ScrollView { RecentTransactions().padding() }
        .registryTheme(.indigo)
}

#Preview("Recent Transactions Dark") {
    ScrollView { RecentTransactions().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
