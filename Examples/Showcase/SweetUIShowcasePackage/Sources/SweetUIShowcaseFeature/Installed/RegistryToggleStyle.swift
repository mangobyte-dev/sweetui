import SwiftUI

/// A button-like treatment for native SwiftUI toggle state.
public struct RegistryToggleStyle: ToggleStyle {
    private let variant: RegistryButtonStyle.Variant

    public init(_ variant: RegistryButtonStyle.Variant = .secondary) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .toggleStyle(.button)
            .buttonStyle(RegistryButtonStyle(variant))
            .opacity(configuration.isOn ? 1 : 0.72)
            .registryItem("toggle")
    }
}

public extension ToggleStyle where Self == RegistryToggleStyle {
    static var registryToggle: RegistryToggleStyle { RegistryToggleStyle() }
}

private struct RegistryToggleStylePreview: View {
    @State private var bold = true
    @State private var italic = false

    var body: some View {
        HStack(spacing: 12) {
            Toggle("Bold", systemImage: "bold", isOn: $bold)
            Toggle("Italic", systemImage: "italic", isOn: $italic)
        }
        .labelStyle(.iconOnly)
        .toggleStyle(.registryToggle)
        .padding()
    }
}

#Preview("Toggle") {
    RegistryToggleStylePreview().tint(.indigo)
}

#Preview("Toggle Dark") {
    RegistryToggleStylePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Toggle Right to Left") {
    RegistryToggleStylePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Toggle Accessibility Size") {
    RegistryToggleStylePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
