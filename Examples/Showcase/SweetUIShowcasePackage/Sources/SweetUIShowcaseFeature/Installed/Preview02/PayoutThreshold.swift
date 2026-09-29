import SwiftUI
import SweetUIFoundations

/// A payout-threshold form, translated from shadcn's payout-threshold: a
/// currency select, a slider for the minimum payout with a live amount and
/// bounds, and a notes area, over a save action. shadcn uses its select,
/// slider, and textarea primitives; this keeps a native Picker with the
/// registry select chrome, a native Slider, and a native TextEditor with the
/// registry text-area chrome, each visible and labeled at the call site.
public struct PayoutThreshold: View {
    @Environment(\.registryTheme) private var theme
    @State private var currency = "usd"
    @State private var amount: Double = 2_500
    @State private var notes = ""

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Set the minimum balance required before a payout is triggered.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Preferred currency") { _ in
                        Picker("Preferred currency", selection: $currency) {
                            ForEach(Self.currencies) { option in
                                Text(option.label).tag(option.id)
                            }
                        }
                        .registrySelect()
                        .accessibilityLabel("Preferred currency")
                    }

                    minimumPayoutField

                    Field("Notes") { _ in
                        TextEditor(text: $notes)
                            .registryTextArea(accessibilityLabel: Text("Notes"), minimumHeight: 100)
                    }
                }

                Button { } label: {
                    Text("Save threshold").frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)
            }
        } label: {
            HStack {
                Text("Payout Threshold")
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

    private var minimumPayoutField: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text("Minimum payout amount")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(amount, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
            }

            Slider(value: $amount, in: 50...10_000, step: 50)
                .accessibilityLabel("Minimum payout amount")
                .accessibilityValue(Text(amount, format: .currency(code: "USD").precision(.fractionLength(0))))

            HStack {
                Text("\(50, format: .currency(code: "USD").precision(.fractionLength(0))) minimum")
                Spacer()
                Text("\(10_000, format: .currency(code: "USD").precision(.fractionLength(0))) maximum")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private struct CurrencyOption: Identifiable {
        let id: String
        let label: String
    }

    private static let currencies: [CurrencyOption] = [
        CurrencyOption(id: "usd", label: "US dollar"),
        CurrencyOption(id: "eur", label: "Euro"),
        CurrencyOption(id: "gbp", label: "British pound"),
        CurrencyOption(id: "jpy", label: "Japanese yen"),
    ]
}

#if DEBUG
#Preview("Payout Threshold") {
    ScrollView { PayoutThreshold().padding() }
        .registryTheme(.indigo)
}

#Preview("Payout Threshold Dark") {
    ScrollView { PayoutThreshold().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
