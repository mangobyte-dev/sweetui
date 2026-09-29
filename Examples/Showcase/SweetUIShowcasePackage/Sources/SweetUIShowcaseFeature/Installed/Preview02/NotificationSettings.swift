import SwiftUI
import SweetUIFoundations

/// A notification preferences form, translated from shadcn's
/// notification-settings: a select-all checkbox over four labeled option
/// checkboxes, and a save action. shadcn uses its checkbox primitive with an
/// indeterminate select-all; this keeps native Toggles wearing the registry
/// checkbox treatment, and the select-all is a multi-source Toggle, so it shows
/// the mixed state when the options disagree and sets them all when tapped.
public struct NotificationSettings: View {
    @Environment(\.registryTheme) private var theme
    @State private var options = [
        NotificationOption(id: "transactions", label: "Transaction alerts", detail: "Deposits, withdrawals, and transfers.", isOn: true),
        NotificationOption(id: "security", label: "Security alerts", detail: "Login attempts and account changes.", isOn: true),
        NotificationOption(id: "goals", label: "Goal milestones", detail: "Updates at each quarter of a goal.", isOn: false),
        NotificationOption(id: "market", label: "Market updates", detail: "Daily portfolio summary and price alerts.", isOn: false),
    ]

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Choose what you want to be notified about.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    Toggle(sources: $options, isOn: \.isOn) {
                        Text("Select all")
                    }
                    .toggleStyle(.registryCheckbox)

                    Divider().registrySeparator()

                    ForEach($options) { $option in
                        Toggle(isOn: $option.isOn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label)
                                Text(option.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.registryCheckbox)
                    }
                }

                Button { } label: {
                    Text("Save preferences").frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)
            }
        } label: {
            Text("Notifications")
        }
        .groupBoxStyle(.registryCard)
    }

    private struct NotificationOption: Identifiable {
        let id: String
        let label: String
        let detail: String
        var isOn: Bool
    }
}

#if DEBUG
#Preview("Notification Settings") {
    ScrollView { NotificationSettings().padding() }
        .registryTheme(.indigo)
}

#Preview("Notification Settings Dark") {
    ScrollView { NotificationSettings().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
