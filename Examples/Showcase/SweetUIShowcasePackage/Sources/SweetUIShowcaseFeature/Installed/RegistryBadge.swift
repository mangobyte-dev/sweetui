import SwiftUI
import SweetUIFoundations

/// Semantic visual treatments for compact status and category labels.
public enum RegistryBadgeVariant: Sendable {
    case primary
    case secondary
    case outline
    case positive
    case destructive
}

public extension View {
    /// Applies compact badge chrome while preserving the receiver's native semantics.
    func registryBadge(_ variant: RegistryBadgeVariant = .primary) -> some View {
        modifier(RegistryBadgeModifier(variant: variant))
    }
}

private struct RegistryBadgeModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme

    let variant: RegistryBadgeVariant

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)

        content
            .font(.caption.weight(.medium))
            // A badge is one line at its own width; it never wraps or breaks.
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, theme.metrics.compactSpacing)
            .padding(.vertical, theme.metrics.compactSpacing / 2)
            .background(backgroundStyle, in: shape)
            .overlay {
                shape.stroke(
                    borderStyle,
                    lineWidth: variant == .outline ? theme.metrics.borderWidth : 0
                )
            }
            .registryItem("badge")
    }

    private var foregroundStyle: AnyShapeStyle {
        switch variant {
        case .primary:
            AnyShapeStyle(TintShapeStyle())
        case .secondary, .outline:
            AnyShapeStyle(Color.primary)
        case .positive:
            AnyShapeStyle(theme.positive)
        case .destructive:
            AnyShapeStyle(theme.negative)
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch variant {
        case .primary:
            AnyShapeStyle(TintShapeStyle().opacity(0.14))
        case .secondary:
            AnyShapeStyle(theme.surface)
        case .outline:
            AnyShapeStyle(Color.clear)
        case .positive:
            AnyShapeStyle(theme.positive.opacity(0.14))
        case .destructive:
            AnyShapeStyle(theme.negative.opacity(0.14))
        }
    }

    private var borderStyle: Color {
        variant == .outline ? theme.border : .clear
    }
}

private struct RegistryBadgePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary")
                .registryBadge()

            Text("Secondary")
                .registryBadge(.secondary)

            Label("Outline", systemImage: "checkmark")
                .registryBadge(.outline)

            Label("Completed", systemImage: "checkmark.circle.fill")
                .registryBadge(.positive)

            Label("Payment failed", systemImage: "exclamationmark.triangle.fill")
                .registryBadge(.destructive)
        }
        .padding()
    }
}

#Preview("Badge Variants") {
    RegistryBadgePreview()
        .tint(.indigo)
}

#Preview("Badge Dark") {
    RegistryBadgePreview()
        .tint(.indigo)
        .preferredColorScheme(.dark)
}

#Preview("Badge Right to Left") {
    Label("جديد", systemImage: "sparkles")
        .registryBadge()
        .environment(\.layoutDirection, .rightToLeft)
        .padding()
}

#Preview("Badge Accessibility Size") {
    RegistryBadgePreview()
        .tint(.indigo)
        .dynamicTypeSize(.accessibility3)
}
