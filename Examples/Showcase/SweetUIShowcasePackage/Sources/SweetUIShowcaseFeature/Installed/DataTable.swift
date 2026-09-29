import SwiftUI
import SweetUIFoundations

/// One column of a ``DataTable``: a header, a horizontal alignment, and a cell
/// builder over a row. A trailing column is treated as numeric, so its cells
/// use monospaced digits and hug the trailing edge; a leading column is
/// flexible and takes the remaining width.
public struct DataTableColumn<Row> {
    public let header: Text
    public let alignment: HorizontalAlignment
    let cell: (Row) -> AnyView

    public init<Cell: View>(
        _ header: Text,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder cell: @escaping (Row) -> Cell
    ) {
        self.header = header
        self.alignment = alignment
        self.cell = { AnyView(cell($0)) }
    }
}

/// One summary row under the table body: a label that spans every column but
/// the last, and a trailing value. Use it for subtotals and totals.
public struct DataTableFooterRow {
    public let label: Text
    public let value: Text
    public let isEmphasized: Bool

    public init(label: Text, value: Text, isEmphasized: Bool = false) {
        self.label = label
        self.value = value
        self.isEmphasized = isEmphasized
    }
}

/// A content-layer data table built on a native `Grid`, so it keeps its columns
/// aligned on iPhone where SwiftUI's `Table` collapses to a single column. The
/// caller declares columns with alignment and provides `Identifiable` rows plus
/// optional footer rows. Numeric (trailing) columns use monospaced digits;
/// hairline separators come from the theme border.
public struct DataTable<Row: Identifiable>: View {
    @Environment(\.registryTheme) private var theme

    private let rows: [Row]
    private let columns: [DataTableColumn<Row>]
    private let footer: [DataTableFooterRow]

    public init(
        _ rows: [Row],
        columns: [DataTableColumn<Row>],
        footer: [DataTableFooterRow] = []
    ) {
        self.rows = rows
        self.columns = columns
        self.footer = footer
    }

    public var body: some View {
        Grid(alignment: .leading, horizontalSpacing: theme.metrics.standardSpacing, verticalSpacing: 0) {
            GridRow {
                // Columns are static per table, so position is a stable identity.
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    styledCell(column.header, alignment: column.alignment)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(column.alignment)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Divider().registrySeparator()

            ForEach(rows) { row in
                GridRow {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                        styledCell(column.cell(row), alignment: column.alignment)
                    }
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)

                if row.id != rows.last?.id {
                    Divider().registrySeparator()
                }
            }

            if !footer.isEmpty {
                Divider().registrySeparator()

                ForEach(Array(footer.enumerated()), id: \.offset) { index, row in
                    GridRow {
                        row.label
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.vertical, theme.metrics.compactSpacing)
                            .gridCellColumns(max(1, columns.count - 1))
                        row.value
                            .monospacedDigit()
                            .padding(.vertical, theme.metrics.compactSpacing)
                            .gridColumnAlignment(.trailing)
                    }
                    .font(.subheadline)
                    .fontWeight(row.isEmphasized ? .semibold : .regular)
                    .foregroundStyle(row.isEmphasized ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                    .accessibilityElement(children: .combine)

                    if index < footer.count - 1 {
                        Divider().registrySeparator()
                    }
                }
            }
        }
        .registryItem("table")
    }

    @ViewBuilder
    private func styledCell(_ content: some View, alignment: HorizontalAlignment) -> some View {
        let aligned = content
            .frame(
                maxWidth: alignment == .leading ? .infinity : nil,
                alignment: frameAlignment(alignment)
            )
            .padding(.vertical, theme.metrics.compactSpacing)

        if alignment == .trailing {
            aligned.monospacedDigit()
        } else {
            aligned
        }
    }

    private func frameAlignment(_ alignment: HorizontalAlignment) -> Alignment {
        switch alignment {
        case .trailing: .trailing
        case .center: .center
        default: .leading
        }
    }
}

private struct InvoiceLine: Identifiable {
    let id = UUID()
    let item: String
    let quantity: Int
    let unitPrice: Decimal
}

private struct DataTablePreview: View {
    private let lines = [
        InvoiceLine(item: "Design system license", quantity: 1, unitPrice: 499),
        InvoiceLine(item: "Priority support", quantity: 12, unitPrice: 99),
        InvoiceLine(item: "Custom components", quantity: 3, unitPrice: 250),
    ]

    private var subtotal: Decimal {
        lines.reduce(0) { $0 + Decimal($1.quantity) * $1.unitPrice }
    }

    var body: some View {
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
                    Text(Decimal(line.quantity) * line.unitPrice, format: .currency(code: "USD"))
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
        .padding(16)
        .registrySurface()
        .padding()
    }
}

#Preview("Data Table") {
    DataTablePreview().tint(.indigo)
}

#Preview("Data Table Dark") {
    DataTablePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Data Table Right to Left") {
    DataTablePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Data Table Accessibility Size") {
    DataTablePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
