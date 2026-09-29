import SwiftUI
import SweetUIFoundations

/// The kind of inline conversation marker applied by ``SwiftUI/View/registryMarker(_:)``.
public enum RegistryMarkerVariant: Sendable {
    /// A quiet system note centered in the timeline, such as "Maya joined the conversation".
    case note
    /// A compact pill with a leading clock, such as "Delivered 09:41".
    case status
    /// A labelled rule between messages, such as a "Today" date break.
    case separator
}

public extension View {
    /// Treats the receiver's text as an inline conversation marker. Use it on a
    /// `Text` between messages: `.note` for a system line, `.status` for a
    /// delivery pill, `.separator` for a labelled date rule. The text stays on
    /// one line and scales down before it wraps.
    func registryMarker(_ variant: RegistryMarkerVariant = .note) -> some View {
        modifier(RegistryMarkerModifier(variant: variant))
    }
}

private struct RegistryMarkerModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme

    let variant: RegistryMarkerVariant

    func body(content: Content) -> some View {
        marker(content)
            .registryItem("marker")
    }

    @ViewBuilder
    private func marker(_ content: Content) -> some View {
        switch variant {
        case .note:
            content
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, theme.metrics.compactSpacing)

        case .status:
            let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)
            HStack(spacing: theme.metrics.compactSpacing / 2) {
                Image(systemName: "clock")
                    .accessibilityHidden(true)
                content
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, theme.metrics.compactSpacing)
            .padding(.vertical, theme.metrics.compactSpacing / 2)
            .background(theme.surface, in: shape)
            .overlay {
                shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth)
            }
            // The pill sizes to its content, then centers in the row.
            .frame(maxWidth: .infinity, alignment: .center)

        case .separator:
            HStack(spacing: theme.metrics.compactSpacing) {
                rule
                content
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                rule
            }
            .padding(.vertical, theme.metrics.compactSpacing)
        }
    }

    // A Divider draws vertically inside an HStack, so wrap it in a VStack to
    // draw it as a horizontal rule, then let registrySeparator stretch it to
    // fill each side of the label.
    private var rule: some View {
        VStack {
            Divider().registrySeparator()
        }
    }
}

private struct RegistryMarkerModifierPreview: View {
    @Environment(\.registryTheme) private var theme

    var body: some View {
        VStack(spacing: theme.metrics.standardSpacing) {
            Text("Today")
                .registryMarker(.separator)

            Text("Maya joined the conversation")
                .registryMarker(.note)

            Text("Your card was frozen by support")
                .registryMarker()

            Text("Delivered 09:41")
                .registryMarker(.status)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview("Marker") {
    RegistryMarkerModifierPreview().tint(.indigo)
}

#Preview("Marker Dark") {
    RegistryMarkerModifierPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Marker Right to Left") {
    RegistryMarkerModifierPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Marker Accessibility Size") {
    RegistryMarkerModifierPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
