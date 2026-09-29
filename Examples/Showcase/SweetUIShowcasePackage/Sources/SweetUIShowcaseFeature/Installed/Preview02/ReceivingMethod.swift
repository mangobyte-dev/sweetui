import SwiftUI
import SweetUIFoundations

/// A payout-method form, translated from shadcn's receiving-method: an
/// account-holder field, a method chooser, an account-number field, and a
/// disabled save action. shadcn uses its input and radio-group primitives; this
/// keeps native TextFields with the registry input chrome and a native inline
/// Picker for the mutually exclusive method, each visible and labeled at the
/// call site. The account name and method names are invented, so the card names
/// no brand.
public struct ReceivingMethod: View {
    @Environment(\.registryTheme) private var theme
    @State private var accountHolder = "Synthetic Horizons Music LLC"
    @State private var method: Method = .bank
    @State private var accountNumber = ""

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Payout preferences")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Account holder name") { _ in
                        TextField("Account holder name", text: $accountHolder)
                            .textFieldStyle(.registryInput)
                            .accessibilityLabel("Account holder name")
                    }

                    methodField

                    Field("IBAN or account number") { _ in
                        TextField("Account number", text: $accountNumber)
                            .textFieldStyle(.registryInput)
                            .accessibilityLabel("IBAN or account number")
                    }
                }

                Button { } label: {
                    Text("Save payout settings").frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)
                .disabled(true)
            }
        } label: {
            HStack {
                Text("Receiving Method")
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

    private var methodField: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            Text("Receiving method")
                .font(.subheadline.weight(.medium))
            Picker("Receiving method", selection: $method) {
                ForEach(Method.allCases) { method in
                    Text(method.label).tag(method)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            .accessibilityLabel("Receiving method")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Method: String, CaseIterable, Identifiable {
        case bank, wallet

        var id: String { rawValue }

        var label: LocalizedStringResource {
            switch self {
            case .bank: "Bank transfer (SWIFT or IBAN)"
            case .wallet: "Digital wallet (instant payout)"
            }
        }
    }
}

#if DEBUG
#Preview("Receiving Method") {
    ScrollView { ReceivingMethod().padding() }
        .registryTheme(.indigo)
}

#Preview("Receiving Method Dark") {
    ScrollView { ReceivingMethod().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
