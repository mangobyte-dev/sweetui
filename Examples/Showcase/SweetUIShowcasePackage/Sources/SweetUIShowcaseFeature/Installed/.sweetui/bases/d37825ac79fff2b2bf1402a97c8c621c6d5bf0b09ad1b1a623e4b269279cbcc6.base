import SwiftUI
import SweetUIFoundations

/// A bordered surface treatment for native SwiftUI `GroupBox` content.
public struct RegistryCardStyle: GroupBoxStyle {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            configuration.label
                .font(.headline)

            configuration.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.metrics.standardSpacing)
        .registrySurface()
        .registryItem("card")
    }
}

public extension GroupBoxStyle where Self == RegistryCardStyle {
    static var registryCard: RegistryCardStyle { RegistryCardStyle() }
}

private struct RegistryCardStylePreview: View {
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Plan", value: "Premium")
                LabeledContent("Renews", value: "12 September")
                Text("Manage billing and renewal details from your account settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label("Subscription", systemImage: "creditcard.fill")
        }
        .groupBoxStyle(.registryCard)
        .padding()
    }
}

#Preview("Card") {
    RegistryCardStylePreview()
        .tint(.indigo)
}

#Preview("Card Dark") {
    RegistryCardStylePreview()
        .tint(.indigo)
        .preferredColorScheme(.dark)
}

#Preview("Card Right to Left") {
    RegistryCardStylePreview()
        .tint(.indigo)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Card Accessibility Size") {
    RegistryCardStylePreview()
        .tint(.indigo)
        .dynamicTypeSize(.accessibility3)
}
