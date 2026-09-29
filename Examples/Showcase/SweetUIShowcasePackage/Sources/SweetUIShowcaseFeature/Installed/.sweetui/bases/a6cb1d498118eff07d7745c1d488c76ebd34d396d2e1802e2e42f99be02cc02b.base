import SwiftUI
import SweetUIFoundations

/// An account preferences card, translated from shadcn's preferences: a
/// currency select and two labeled switches separated by dividers, over reset
/// and save actions. shadcn uses its select and switch primitives; this keeps
/// a native Picker with the registry select chrome and native Toggles whose
/// visible label is the row text, so each switch is spoken once. The copy is
/// neutral, so the card names no brand.
public struct Preferences: View {
    @Environment(\.registryTheme) private var theme
    @State private var currency = "usd"
    @State private var publicStatistics = true
    @State private var emailNotifications = true

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Manage your account settings and notifications.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                FieldGroup {
                    Field("Default currency") { _ in
                        Picker("Default currency", selection: $currency) {
                            ForEach(Self.currencies) { option in
                                Text(option.label).tag(option.id)
                            }
                        }
                        .registrySelect()
                        .accessibilityLabel("Default currency")
                    }

                    Divider().registrySeparator()

                    SwitchRow(
                        title: "Public statistics",
                        detail: "Let others see your total stream count and listening activity.",
                        isOn: $publicStatistics
                    )

                    Divider().registrySeparator()

                    SwitchRow(
                        title: "Email notifications",
                        detail: "Monthly royalty reports and distribution updates.",
                        isOn: $emailNotifications
                    )
                }

                HStack {
                    Button("Reset") {}
                        .buttonStyle(.registryOutline)
                    Spacer()
                    Button("Save preferences") {}
                        .buttonStyle(.registry)
                }
            }
        } label: {
            HStack {
                Text("Preferences")
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

    private struct SwitchRow: View {
        @Environment(\.registryTheme) private var theme
        let title: LocalizedStringResource
        let detail: LocalizedStringResource
        @Binding var isOn: Bool

        var body: some View {
            // The visible title and detail stay their own text; the native
            // switch carries the title as an explicit accessibility label, so
            // the switch itself is labeled for VoiceOver and the capture-route
            // audit rather than left as a bare, unlabeled element.
            HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle(isOn: $isOn) { Text(title) }
                    .labelsHidden()
                    .accessibilityLabel(Text(title))
            }
            .frame(minHeight: RegistryMetrics.minimumHitSize)
        }
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
#Preview("Preferences") {
    ScrollView { Preferences().padding() }
        .registryTheme(.indigo)
}

#Preview("Preferences Dark") {
    ScrollView { Preferences().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
