import SwiftUI
import SweetUIFoundations

public extension View {
    /// Applies semantic color, orientation, and insets to a native `Divider`.
    func registrySeparator(
        _ axis: Axis = .horizontal,
        insets: EdgeInsets = EdgeInsets()
    ) -> some View {
        modifier(RegistrySeparatorModifier(axis: axis, insets: insets))
    }
}

private struct RegistrySeparatorModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme

    let axis: Axis
    let insets: EdgeInsets

    @ViewBuilder
    func body(content: Content) -> some View {
        Group {
            if axis == .horizontal {
                styled(content)
                    .frame(maxWidth: .infinity)
            } else {
                styled(content)
                    .frame(maxHeight: .infinity)
            }
        }
        .registryItem("separator")
    }

    private func styled(_ content: Content) -> some View {
        content
            .overlay(theme.border)
            .padding(.top, insets.top)
            .padding(.leading, insets.leading)
            .padding(.bottom, insets.bottom)
            .padding(.trailing, insets.trailing)
    }
}

private struct RegistrySeparatorModifierPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
            Divider()
                .registrySeparator(insets: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            HStack(spacing: 16) {
                Text("Profile")
                Divider().registrySeparator(.vertical)
                Text("Security")
            }
            .frame(height: 44)
        }
        .padding()
    }
}

#Preview("Separator") {
    RegistrySeparatorModifierPreview()
}

#Preview("Separator Dark") {
    RegistrySeparatorModifierPreview().preferredColorScheme(.dark)
}

#Preview("Separator Right to Left") {
    RegistrySeparatorModifierPreview().environment(\.layoutDirection, .rightToLeft)
}

#Preview("Separator Accessibility Size") {
    RegistrySeparatorModifierPreview().dynamicTypeSize(.accessibility3)
}
