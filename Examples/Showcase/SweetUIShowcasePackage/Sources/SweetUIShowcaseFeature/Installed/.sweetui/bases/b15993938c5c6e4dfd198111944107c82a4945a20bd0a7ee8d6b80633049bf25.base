import SwiftUI
import SweetUIFoundations

/// The conversational role of a bubble. Each variant carries its own fill and
/// text treatment; the message row, not the bubble, owns alignment.
public enum RegistryBubbleVariant: Sendable {
    case incoming
    case outgoing
    case muted
}

public extension View {
    /// Wraps text content in a conversation bubble. Incoming and outgoing
    /// bubbles take their depth from the fill and draw no stroke; the muted
    /// variant is a hairline outline for system lines instead.
    func registryBubble(_ variant: RegistryBubbleVariant = .incoming) -> some View {
        modifier(RegistryBubbleModifier(variant: variant))
    }
}

private struct RegistryBubbleModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme

    let variant: RegistryBubbleVariant

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous)

        content
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, theme.metrics.standardSpacing)
            .padding(.vertical, theme.metrics.compactSpacing)
            .background(backgroundStyle, in: shape)
            .overlay {
                shape.stroke(
                    borderStyle,
                    lineWidth: variant == .muted ? theme.metrics.borderWidth : 0
                )
            }
            .registryItem("bubble")
    }

    private var foregroundStyle: AnyShapeStyle {
        switch variant {
        case .incoming:
            AnyShapeStyle(Color.primary)
        case .outgoing:
            AnyShapeStyle(theme.onAccent)
        case .muted:
            AnyShapeStyle(Color.secondary)
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch variant {
        case .incoming:
            AnyShapeStyle(theme.surface)
        case .outgoing:
            AnyShapeStyle(TintShapeStyle())
        case .muted:
            AnyShapeStyle(Color.clear)
        }
    }

    private var borderStyle: Color {
        variant == .muted ? theme.border : .clear
    }
}

private struct RegistryBubblePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Are we still on for Thursday?")
                .registryBubble(.incoming)

            Text("Yes, 6pm works. I will bring the documents.")
                .registryBubble(.outgoing)

            Text("Maya added Omar to the conversation.")
                .registryBubble(.muted)
        }
        .padding()
    }
}

#Preview("Bubble Variants") {
    RegistryBubblePreview().tint(.indigo)
}

#Preview("Bubble Dark") {
    RegistryBubblePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Bubble Right to Left") {
    RegistryBubblePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Bubble Accessibility Size") {
    RegistryBubblePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
