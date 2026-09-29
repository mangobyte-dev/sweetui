import SwiftUI
import SweetUIFoundations

/// Review Agent activation, translated from shadcn's activate-agent-dialog: a
/// card that lists the agent's features and opens a native confirmation alert
/// from a registry button. The alert is a recipe here, so the native control
/// stays visible; the card owns only its transient presentation state.
public struct ActivateAgentDialog: View {
    @Environment(\.registryTheme) private var theme
    @State private var isConfirming = false

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Your use is subject to the beta program terms and AI usage guidelines.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    ForEach(features) { feature in
                        featureRow(feature)
                    }
                }

                InlineAlert(
                    "Trial credit",
                    message: Text("Pro teams get $100 in Review Agent trial credit for two weeks after activation.")
                )

                Button("Enable with $100 credits") { isConfirming = true }
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Ship faster & safer with Review Agent")
        }
        .groupBoxStyle(.registryCard)
        .alert("Enable Review Agent?", isPresented: $isConfirming) {
            Button("Cancel", role: .cancel) {}
            Button("Enable") {}
        } message: {
            Text("$100 in trial credit will be applied to your team for two weeks.")
        }
    }

    private func featureRow(_ feature: Feature) -> some View {
        ItemRow(title: Text(feature.title)) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        } accessory: {
            if let badge = feature.badge {
                Text(badge).registryBadge(.secondary)
            }
        }
    }

    private struct Feature: Identifiable {
        let id: String
        let title: LocalizedStringResource
        let badge: LocalizedStringResource?
    }

    private let features: [Feature] = [
        Feature(id: "reviews", title: "Code reviews with full codebase context to catch hard-to-find bugs.", badge: nil),
        Feature(id: "suggestions", title: "Code suggestions validated in sandboxes before you merge.", badge: nil),
        Feature(id: "root-cause", title: "Root-cause analysis for production issues with deployment context.", badge: "Insights Plus"),
    ]
}

#if DEBUG
#Preview("Activate Agent Dialog") {
    ScrollView { ActivateAgentDialog().padding() }
        .registryTheme(.indigo)
}

#Preview("Activate Agent Dialog Dark") {
    ScrollView { ActivateAgentDialog().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
