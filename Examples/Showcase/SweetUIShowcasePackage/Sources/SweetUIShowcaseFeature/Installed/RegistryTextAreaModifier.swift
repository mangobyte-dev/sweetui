import SwiftUI
import SweetUIFoundations

public extension View {
    /// Applies input-matching chrome to a native `TextEditor`.
    func registryTextArea(
        accessibilityLabel: Text,
        isInvalid: Bool = false,
        minimumHeight: CGFloat = 120
    ) -> some View {
        modifier(RegistryTextAreaModifier(isInvalid: isInvalid, minimumHeight: minimumHeight))
            .accessibilityLabel(accessibilityLabel)
    }
}

private struct RegistryTextAreaModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.registryTheme) private var theme
    @FocusState private var isFocused: Bool

    let isInvalid: Bool
    let minimumHeight: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        content
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .padding(8)
            .frame(minHeight: minimumHeight, alignment: .topLeading)
            .background(theme.surface, in: shape)
            .overlay {
                shape.stroke(
                    borderStyle,
                    lineWidth: isFocused || isInvalid
                        ? theme.metrics.emphasizedBorderWidth
                        : theme.metrics.borderWidth
                )
            }
            .opacity(isEnabled ? 1 : theme.disabledOpacity)
            .registryItem("textarea")
    }

    private var borderStyle: AnyShapeStyle {
        if isInvalid {
            AnyShapeStyle(theme.negative)
        } else if isFocused {
            AnyShapeStyle(TintShapeStyle())
        } else {
            AnyShapeStyle(theme.border)
        }
    }
}

private struct RegistryTextAreaModifierPreview: View {
    @Environment(\.registryTheme) private var theme
    @State private var notes = "Add delivery instructions"
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $notes)
                .registryTextArea(accessibilityLabel: Text("Delivery instructions"))
                .focused($isFocused)

            VStack(alignment: .leading, spacing: 4) {
                TextEditor(text: .constant("Too short"))
                    .registryTextArea(
                        accessibilityLabel: Text("Request details"),
                        isInvalid: true,
                        minimumHeight: 80
                    )
                    .accessibilityHint("Enter at least 20 characters")
                Text("Enter at least 20 characters")
                    .font(.footnote)
                    .foregroundStyle(theme.negative)
            }
        }
        .padding()
        .onAppear { isFocused = true }
    }
}

#Preview("Textarea States") {
    RegistryTextAreaModifierPreview().tint(.indigo)
}

#Preview("Textarea Dark") {
    RegistryTextAreaModifierPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Textarea Right to Left") {
    RegistryTextAreaModifierPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Textarea Accessibility Size") {
    RegistryTextAreaModifierPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
