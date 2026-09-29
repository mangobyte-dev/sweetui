import SwiftUI
import SweetUIFoundations

/// A bordered input treatment for native `TextField` and `SecureField` controls.
public struct RegistryInputStyle: TextFieldStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.registryTheme) private var theme
    @FocusState private var isFocused: Bool

    private let isInvalid: Bool

    public init(isInvalid: Bool = false) {
        self.isInvalid = isInvalid
    }

    public func _body(configuration: TextField<Self._Label>) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        configuration
            .focused($isFocused)
            .padding(.horizontal, theme.metrics.controlHorizontalPadding)
            .padding(.vertical, 10)
            .frame(minHeight: RegistryMetrics.minimumHitSize)
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
            .registryItem("input")
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

public extension TextFieldStyle where Self == RegistryInputStyle {
    static var registryInput: RegistryInputStyle { RegistryInputStyle() }
}

private struct RegistryInputStylePreview: View {
    @Environment(\.registryTheme) private var theme
    @State private var name = ""
    @State private var email = "not-an-email"
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // An explicit accessibility label: on iOS the field's title and
            // prompt are exposed as placeholder text only, so a field with
            // typed content would otherwise be unnamed to VoiceOver.
            TextField("Full name", text: $name)
                .textFieldStyle(.registryInput)
                .accessibilityLabel("Full name")
                .focused($focusedField, equals: .name)

            SecureField("Password", text: $password)
                .textFieldStyle(.registryInput)
                .accessibilityLabel("Password")

            VStack(alignment: .leading, spacing: 4) {
                TextField("Email", text: $email)
                    .textFieldStyle(RegistryInputStyle(isInvalid: true))
                    .accessibilityLabel("Email")
                    .accessibilityHint("Enter a valid email address")
                Text("Enter a valid email address")
                    .font(.footnote)
                    .foregroundStyle(theme.negative)
            }

            TextField("Disabled", text: .constant("Unavailable"))
                .textFieldStyle(.registryInput)
                .accessibilityLabel("Disabled")
                .disabled(true)
        }
        .padding()
        .onAppear { focusedField = .name }
    }
}

#Preview("Input States") {
    RegistryInputStylePreview().tint(.indigo)
}

#Preview("Input Dark") {
    RegistryInputStylePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Input Right to Left") {
    RegistryInputStylePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Input Accessibility Size") {
    RegistryInputStylePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
