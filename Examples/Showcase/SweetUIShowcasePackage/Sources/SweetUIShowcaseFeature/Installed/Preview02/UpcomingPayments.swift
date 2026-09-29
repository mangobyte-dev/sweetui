import SwiftUI
import SweetUIFoundations

/// An upcoming-payments card, translated from shadcn's upcoming-payments: a
/// calendar over a list of scheduled payments. shadcn uses its calendar and
/// item primitives; this keeps a native graphical DatePicker on the registry
/// content surface and each payment as an ItemRow with a value badge. Payment
/// names are generic and amounts and dates are formatted at the call site, so
/// the card names no brand.
public struct UpcomingPayments: View {
    @Environment(\.registryTheme) private var theme
    @State private var selectedDate = DateComponents(calendar: .current, year: 2026, month: 4, day: 15).date ?? .now

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Select a date to view scheduled payments.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                DatePicker("Payment date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .accessibilityLabel("Payment date")
                    .padding(theme.metrics.compactSpacing)
                    .registrySurface()

                paymentsList
            }
        } label: {
            Text("Upcoming Payments")
        }
        .groupBoxStyle(.registryCard)
    }

    private var paymentsList: some View {
        VStack(spacing: 0) {
            ForEach(Self.payments) { payment in
                ItemRow(
                    title: Text(payment.name),
                    description: Text(payment.due, format: .dateTime.month(.abbreviated).day().year()),
                    accessory: {
                        Text(payment.amount, format: .currency(code: "USD"))
                            .registryBadge(.secondary)
                    }
                )
                .padding(.vertical, theme.metrics.compactSpacing)

                if payment.id != Self.payments.last?.id {
                    Divider().registrySeparator()
                }
            }
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }

    private struct Payment: Identifiable {
        let id: String
        let name: LocalizedStringResource
        let due: Date
        let amount: Double
    }

    private static func day(_ month: Int, _ day: Int) -> Date {
        DateComponents(calendar: .current, year: 2026, month: month, day: day).date ?? .now
    }

    private static let payments: [Payment] = [
        Payment(id: "streaming", name: "Streaming plan", due: day(4, 15), amount: 19.99),
        Payment(id: "rent", name: "Rent payment", due: day(4, 1), amount: 2_400.00),
        Payment(id: "insurance", name: "Auto insurance", due: day(4, 22), amount: 186.00),
    ]
}

#if DEBUG
#Preview("Upcoming Payments") {
    ScrollView { UpcomingPayments().padding() }
        .registryTheme(.indigo)
}

#Preview("Upcoming Payments Dark") {
    ScrollView { UpcomingPayments().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
