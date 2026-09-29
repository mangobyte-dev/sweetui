import SwiftUI

public extension View {
    /// Applies one registry toggle treatment to a native multi-selection `ControlGroup`.
    func registryToggleGroup(
        _ variant: RegistryButtonStyle.Variant = .secondary
    ) -> some View {
        modifier(RegistryToggleGroupModifier(variant: variant))
    }
}

private struct RegistryToggleGroupModifier: ViewModifier {
    let variant: RegistryButtonStyle.Variant

    func body(content: Content) -> some View {
        content
            .toggleStyle(RegistryToggleStyle(variant))
            .registryItem("toggle-group")
    }
}

private struct RegistryToggleGroupModifierPreview: View {
    @State private var bold = true
    @State private var italic = false
    @State private var underline = false

    var body: some View {
        ControlGroup("Text formatting") {
            Toggle("Bold", systemImage: "bold", isOn: $bold)
            Toggle("Italic", systemImage: "italic", isOn: $italic)
            Toggle("Underline", systemImage: "underline", isOn: $underline)
        }
        .labelStyle(.iconOnly)
        .registryToggleGroup()
        .padding()
    }
}

#Preview("Toggle Group") {
    RegistryToggleGroupModifierPreview().tint(.indigo)
}

#Preview("Toggle Group Dark") {
    RegistryToggleGroupModifierPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Toggle Group Right to Left") {
    RegistryToggleGroupModifierPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Toggle Group Accessibility Size") {
    RegistryToggleGroupModifierPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
