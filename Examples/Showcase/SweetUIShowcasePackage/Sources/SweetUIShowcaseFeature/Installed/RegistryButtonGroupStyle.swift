import SwiftUI
import SweetUIFoundations

/// Lays out every native button of a `ControlGroup` side by side with one registry button
/// treatment. Measured on iOS 27, `ControlGroup(configuration)` draws the system capsule and
/// ignores the button style, so the style owns the row and the buttons keep their variant,
/// destructive role, labels, and control size.
public struct RegistryButtonGroupStyle: ControlGroupStyle {
    @Environment(\.registryTheme) private var theme

    private let variant: RegistryButtonStyle.Variant

    public init(_ variant: RegistryButtonStyle.Variant = .secondary) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            configuration.content
                .buttonStyle(RegistryButtonStyle(variant))
        }
        .accessibilityElement(children: .contain)
        .registryItem("button-group")
    }
}

public extension ControlGroupStyle where Self == RegistryButtonGroupStyle {
    static var registryButtons: RegistryButtonGroupStyle {
        RegistryButtonGroupStyle()
    }
}

private struct RegistryButtonGroupStylePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ControlGroup("Editor actions") {
                Button("Undo", systemImage: "arrow.uturn.backward") {}
                Button("Redo", systemImage: "arrow.uturn.forward") {}
                Button("Share", systemImage: "square.and.arrow.up") {}
            }
            .labelStyle(.iconOnly)
            .controlGroupStyle(.registryButtons)

            ControlGroup("Document actions") {
                Button("Save") {}
                Button("Duplicate") {}
                Button("Delete", role: .destructive) {}
            }
            .controlGroupStyle(RegistryButtonGroupStyle(.outline))
        }
        .padding()
    }
}

#Preview("Button Group") {
    RegistryButtonGroupStylePreview()
        .tint(.indigo)
}

#Preview("Button Group Dark") {
    RegistryButtonGroupStylePreview()
        .tint(.indigo)
        .preferredColorScheme(.dark)
}

#Preview("Button Group Right to Left") {
    RegistryButtonGroupStylePreview()
        .tint(.indigo)
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Button Group Accessibility Size") {
    RegistryButtonGroupStylePreview()
        .tint(.indigo)
        .dynamicTypeSize(.accessibility3)
}
