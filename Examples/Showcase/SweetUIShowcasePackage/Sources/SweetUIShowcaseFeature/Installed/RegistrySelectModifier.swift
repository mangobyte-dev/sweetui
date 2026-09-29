import SwiftUI
import SweetUIFoundations

public extension View {
    /// Adds registry field chrome to a native menu-style `Picker`.
    func registrySelect() -> some View {
        modifier(RegistrySelectModifier())
    }
}

private struct RegistrySelectModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.registryTheme) private var theme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        content
            .pickerStyle(.menu)
            .padding(.horizontal, theme.metrics.controlHorizontalPadding)
            .padding(.vertical, 6)
            .frame(minHeight: RegistryMetrics.minimumHitSize)
            .background(theme.surface, in: shape)
            .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
            .opacity(isEnabled ? 1 : theme.disabledOpacity)
            .registryItem("select")
    }
}

private struct RegistrySelectModifierPreview: View {
    @State private var currency = "KWD"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Currency", selection: $currency) {
                Text("Kuwaiti dinar").tag("KWD")
                Text("US dollar").tag("USD")
                Text("Euro").tag("EUR")
            }
            .registrySelect()

            Picker("Unavailable", selection: .constant("KWD")) {
                Text("Kuwaiti dinar").tag("KWD")
            }
            .registrySelect()
            .disabled(true)
        }
        .padding()
    }
}

#Preview("Select") {
    RegistrySelectModifierPreview().tint(.indigo)
}

#Preview("Select Dark") {
    RegistrySelectModifierPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Select Right to Left") {
    RegistrySelectModifierPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Select Accessibility Size") {
    RegistrySelectModifierPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
