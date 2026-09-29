import SwiftUI
import SweetUIFoundations

public extension View {
    /// Draws the receiver as a keycap: monospaced, bordered, one line. For
    /// keyboard shortcut hints next to commands; hidden from accessibility
    /// unless the caller supplies a spoken label, because "⌘K" reads poorly.
    func registryKeycap(accessibilityLabel: Text? = nil) -> some View {
        modifier(RegistryKeycapModifier(accessibilityLabel: accessibilityLabel))
    }
}

private struct RegistryKeycapModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme

    let accessibilityLabel: Text?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)

        content
            .font(.caption.monospaced().weight(.medium))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(.secondary)
            .padding(.horizontal, theme.metrics.compactSpacing * 0.75)
            .padding(.vertical, theme.metrics.compactSpacing / 4)
            .background(theme.surface, in: shape)
            .overlay {
                shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth)
            }
            // One identity for both states: the label applies only when given,
            // and the keycap hides itself when it has nothing to say.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel ?? Text(verbatim: ""), isEnabled: accessibilityLabel != nil)
            .accessibilityHidden(accessibilityLabel == nil)
            .registryItem("kbd")
    }
}

private struct RegistryKeycapModifierPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Open search")
                Spacer()
                Text(verbatim: "⌘K").registryKeycap(accessibilityLabel: Text("Command K"))
            }
            HStack {
                Text("Select")
                Spacer()
                Text(verbatim: "↩").registryKeycap(accessibilityLabel: Text("Return"))
            }
            HStack {
                Text("Dismiss")
                Spacer()
                Text(verbatim: "esc").registryKeycap(accessibilityLabel: Text("Escape"))
            }
        }
        .padding()
    }
}

#Preview("Keycap") {
    RegistryKeycapModifierPreview()
}

#Preview("Keycap Dark") {
    RegistryKeycapModifierPreview().preferredColorScheme(.dark)
}

#Preview("Keycap Accessibility Size") {
    RegistryKeycapModifierPreview().dynamicTypeSize(.accessibility3)
}
