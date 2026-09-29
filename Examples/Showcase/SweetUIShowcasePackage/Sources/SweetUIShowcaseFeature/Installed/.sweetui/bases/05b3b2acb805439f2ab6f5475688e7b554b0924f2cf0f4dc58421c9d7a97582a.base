import SwiftUI
import SweetUIFoundations

/// A transfer-funds form, translated from shadcn's transfer-funds: an amount
/// field, from and to account selects, a fee-and-total summary, and a confirm
/// action. shadcn uses its input-group, select, and item primitives; this keeps
/// a native amount field in a registry InputGroup, native Pickers in the
/// registry select chrome, and the summary on the registry content surface.
/// Account names are generic and amounts and the date are formatted at the call
/// site, so the card names no brand.
public struct TransferFunds: View {
    @Environment(\.registryTheme) private var theme
    @State private var amount: Double = 1_200
    @State private var fromAccount = "checking"
    @State private var toAccount = "savings"

    private let arrivalDate = DateComponents(calendar: .current, year: 2026, month: 4, day: 14).date ?? .now

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Move money between your connected accounts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Amount to transfer") { _ in
                        InputGroup {
                            Text(verbatim: "$")
                                .font(.subheadline.weight(.medium))
                        } content: {
                            TextField("Amount to transfer", value: $amount, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("Amount to transfer")
                        }
                    }

                    Field("From account") { _ in
                        Picker("From account", selection: $fromAccount) {
                            ForEach(Self.fromAccounts) { account in
                                account.label.tag(account.id)
                            }
                        }
                        .registrySelect()
                        .accessibilityLabel("From account")
                    }

                    Field("To account") { _ in
                        Picker("To account", selection: $toAccount) {
                            ForEach(Self.toAccounts) { account in
                                account.label.tag(account.id)
                            }
                        }
                        .registrySelect()
                        .accessibilityLabel("To account")
                    }
                }

                summary

                Button { } label: {
                    Text("Confirm transfer").frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)
            }
        } label: {
            HStack {
                Text("Transfer Funds")
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

    private var summary: some View {
        VStack(spacing: 0) {
            summaryRow("Estimated arrival", value: Text(arrivalDate, format: .dateTime.month(.abbreviated).day()))
            Divider().registrySeparator()
            summaryRow("Transaction fee", value: Text(0, format: .currency(code: "USD")))
            Divider().registrySeparator()
            summaryRow("Total amount", value: Text(amount, format: .currency(code: "USD")), emphasized: true)
        }
        .padding(theme.metrics.standardSpacing)
        .registrySurface()
    }

    private func summaryRow(_ label: LocalizedStringResource, value: Text, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(emphasized ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            Spacer()
            value
                .font(.subheadline.weight(emphasized ? .semibold : .medium))
                .monospacedDigit()
        }
        .padding(.vertical, theme.metrics.compactSpacing / 2)
    }

    private struct Account: Identifiable {
        let id: String
        let name: String
        let number: String
        let balance: Double

        var label: Text {
            Text("\(name) ··\(number), \(balance, format: .currency(code: "USD"))")
        }
    }

    private static let fromAccounts: [Account] = [
        Account(id: "checking", name: "Main checking", number: "8402", balance: 12_450),
        Account(id: "business", name: "Business", number: "7731", balance: 8_920),
    ]

    private static let toAccounts: [Account] = [
        Account(id: "savings", name: "High-yield savings", number: "1192", balance: 42_100),
        Account(id: "investment", name: "Investment", number: "3349", balance: 18_200),
    ]
}

#if DEBUG
#Preview("Transfer Funds") {
    ScrollView { TransferFunds().padding() }
        .registryTheme(.indigo)
}

#Preview("Transfer Funds Dark") {
    ScrollView { TransferFunds().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
