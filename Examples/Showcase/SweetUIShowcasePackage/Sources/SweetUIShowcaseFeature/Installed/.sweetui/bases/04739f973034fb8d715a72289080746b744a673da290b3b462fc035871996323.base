import SwiftUI
import SweetUIFoundations

public enum RegistryLabelPlacement: Sendable {
    case iconLeading
    case iconTrailing
}

/// Controls native `Label` icon placement with semantic spacing.
public struct RegistryLabelStyle: LabelStyle {
    @Environment(\.registryTheme) private var theme

    private let placement: RegistryLabelPlacement

    public init(_ placement: RegistryLabelPlacement = .iconLeading) {
        self.placement = placement
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            if placement == .iconLeading {
                configuration.icon.accessibilityHidden(true)
            }

            configuration.title

            if placement == .iconTrailing {
                configuration.icon.accessibilityHidden(true)
            }
        }
        .registryItem("label")
    }
}

public extension LabelStyle where Self == RegistryLabelStyle {
    static var registry: RegistryLabelStyle { RegistryLabelStyle() }
    static var registryTrailingIcon: RegistryLabelStyle { RegistryLabelStyle(.iconTrailing) }
}

private struct RegistryLabelStylePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Account settings", systemImage: "person.crop.circle")
                .labelStyle(.registry)
            Label("Continue", systemImage: "chevron.forward")
                .labelStyle(.registryTrailingIcon)
        }
        .padding()
    }
}

#Preview("Label") {
    RegistryLabelStylePreview().tint(.indigo)
}

#Preview("Label Dark") {
    RegistryLabelStylePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Label Right to Left") {
    RegistryLabelStylePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Label Accessibility Size") {
    RegistryLabelStylePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
