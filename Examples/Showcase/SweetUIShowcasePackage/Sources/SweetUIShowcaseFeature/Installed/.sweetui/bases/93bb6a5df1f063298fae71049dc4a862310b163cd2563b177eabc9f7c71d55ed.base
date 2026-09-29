import SwiftUI
import SweetUIFoundations

/// A compact circular treatment for native indeterminate `ProgressView` controls.
public struct RegistrySpinnerStyle: ProgressViewStyle {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            ProgressView()
                .progressViewStyle(.circular)

            if let label = configuration.label {
                label.font(.subheadline)
            }
        }
        .accessibilityElement(children: .combine)
        .registryItem("spinner")
    }
}

public extension ProgressViewStyle where Self == RegistrySpinnerStyle {
    static var registrySpinner: RegistrySpinnerStyle { RegistrySpinnerStyle() }
}

private struct RegistrySpinnerStylePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProgressView()
                .accessibilityLabel("Loading")
            ProgressView("Loading results")
            ProgressView("Disabled")
                .disabled(true)
        }
        .progressViewStyle(.registrySpinner)
        .padding()
    }
}

#Preview("Spinner") {
    RegistrySpinnerStylePreview().tint(.indigo)
}

#Preview("Spinner Dark") {
    RegistrySpinnerStylePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Spinner Right to Left") {
    RegistrySpinnerStylePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Spinner Accessibility Size") {
    RegistrySpinnerStylePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
