import SwiftUI
import SweetUIFoundations

/// An invoice, translated from shadcn's invoice: a line-item DataTable with
/// subtotal, tax, and total footer rows, a status badge in the header, and
/// download and pay actions. Amounts are currency-formatted and the due date
/// is date-formatted at the call site.
public struct Invoice: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(dueDate, format: .dateTime.month(.wide).day().year())
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                table

                actions
            }
        } label: {
            HStack {
                Text("Invoice #INV-2847")
                Spacer()
                Text("Pending").registryBadge(.secondary)
            }
        }
        .groupBoxStyle(.registryCard)
    }

    private var table: some View {
        DataTable(
            lines,
            columns: [
                DataTableColumn(Text("Item")) { line in
                    Text(line.item)
                },
                DataTableColumn(Text("Qty"), alignment: .trailing) { line in
                    Text(line.quantity, format: .number)
                },
                DataTableColumn(Text("Rate"), alignment: .trailing) { line in
                    Text(line.unitPrice, format: .currency(code: "USD"))
                },
                DataTableColumn(Text("Amount"), alignment: .trailing) { line in
                    Text(line.amount, format: .currency(code: "USD"))
                },
            ],
            footer: [
                DataTableFooterRow(label: Text("Subtotal"), value: Text(subtotal, format: .currency(code: "USD"))),
                DataTableFooterRow(label: Text("Tax"), value: Text(0, format: .currency(code: "USD"))),
                DataTableFooterRow(
                    label: Text("Total due"),
                    value: Text(subtotal, format: .currency(code: "USD")),
                    isEmphasized: true
                ),
            ]
        )
    }

    private var actions: some View {
        HStack {
            Button("Download PDF") {}
                .buttonStyle(.registryOutline)
                .controlSize(.small)
            Spacer()
            Button("Pay now") {}
                .buttonStyle(.registry)
                .controlSize(.small)
        }
    }

    private struct Line: Identifiable {
        let id: String
        let item: String
        let quantity: Int
        let unitPrice: Decimal
        var amount: Decimal { Decimal(quantity) * unitPrice }
    }

    private let lines: [Line] = [
        Line(id: "license", item: "Design system license", quantity: 1, unitPrice: 499),
        Line(id: "support", item: "Priority support", quantity: 12, unitPrice: 99),
        Line(id: "components", item: "Custom components", quantity: 3, unitPrice: 250),
    ]

    private var subtotal: Decimal {
        lines.reduce(0) { $0 + $1.amount }
    }

    private var dueDate: Date {
        DateComponents(calendar: .current, year: 2026, month: 3, day: 30).date ?? .now
    }
}

#if DEBUG
#Preview("Invoice") {
    ScrollView { Invoice().padding() }
        .registryTheme(.indigo)
}

#Preview("Invoice Dark") {
    ScrollView { Invoice().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
