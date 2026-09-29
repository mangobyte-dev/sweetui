import Accessibility
import Foundation
import SwiftUI
import SweetUIFoundations

/// The status semantics of a ``RegistryToast``. Each variant pairs a symbol
/// with its color so the meaning never rests on color alone.
public enum RegistryToastVariant: Sendable {
    case informational
    case positive
    case destructive
}

/// A transient status message presented over content and dismissed by time, a
/// swipe down, or the close control. iOS has no native toast, so this fills the
/// gap while keeping presentation caller-owned: the caller holds the optional
/// binding and sets it to present.
public struct RegistryToast: Identifiable {
    /// A caller-run button rendered inside the toast. Running it dismisses the
    /// toast after the action performs.
    public struct Action {
        public let label: LocalizedStringResource
        public let perform: @MainActor () -> Void

        public init(
            label: LocalizedStringResource,
            perform: @escaping @MainActor () -> Void
        ) {
            self.label = label
            self.perform = perform
        }
    }

    public let id: UUID
    /// The headline, always visible and kept to one line.
    public let title: LocalizedStringResource
    /// Optional supporting copy that may wrap to two lines.
    public let message: LocalizedStringResource?
    /// Overrides the variant's default symbol.
    public let systemImage: String?
    /// The semantic tone. Defaults to informational.
    public let variant: RegistryToastVariant
    /// An optional caller-run button, such as Undo or Retry.
    public let action: Action?

    public init(
        id: UUID = UUID(),
        title: LocalizedStringResource,
        message: LocalizedStringResource? = nil,
        systemImage: String? = nil,
        variant: RegistryToastVariant = .informational,
        action: Action? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.variant = variant
        self.action = action
    }
}

public extension View {
    /// Presents the bound toast over this view, aligned to the bottom safe
    /// area. Set the binding to a value to present and to `nil` to dismiss; the
    /// toast also dismisses itself after `duration`, on a swipe down, or when
    /// the close control is tapped.
    func registryToast(
        _ toast: Binding<RegistryToast?>,
        duration: Duration = .seconds(4)
    ) -> some View {
        modifier(RegistryToastModifier(toast: toast, duration: duration))
    }
}

private struct RegistryToastModifier: ViewModifier {
    @Environment(\.registryTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var toast: RegistryToast?
    let duration: Duration

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast {
                    RegistryToastCard(toast: toast, onDismiss: dismiss)
                        .padding(.horizontal, theme.metrics.standardSpacing)
                        .padding(.bottom, theme.metrics.standardSpacing)
                        .transition(transition)
                }
            }
            .animation(animation, value: toast?.id)
            .task(id: toast?.id) {
                guard let toast else { return }
                announce(toast)
                do {
                    try await Task.sleep(for: duration)
                } catch {
                    // Cancelled because a new toast replaced this one or it was
                    // dismissed early; the replacement runs its own timer.
                    return
                }
                if self.toast?.id == toast.id {
                    dismiss()
                }
            }
            .registryItem("toast")
    }

    private func dismiss() {
        toast = nil
    }

    private func announce(_ toast: RegistryToast) {
        var spoken = String(localized: toast.title)
        if let message = toast.message {
            spoken += ". " + String(localized: message)
        }
        AccessibilityNotification.Announcement(spoken).post()
    }

    // Move-from-bottom plus opacity, reduced to opacity only under Reduce
    // Motion so nothing slides for a motion-sensitive user.
    private var transition: AnyTransition {
        reduceMotion
            ? .opacity
            : .move(edge: .bottom).combined(with: .opacity)
    }

    private var animation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
    }
}

private struct RegistryToastCard: View {
    @Environment(\.registryTheme) private var theme

    let toast: RegistryToast
    let onDismiss: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        HStack(alignment: .top, spacing: theme.metrics.compactSpacing) {
            Image(systemName: toast.systemImage ?? defaultSystemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(toneStyle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
                    Text(toast.title)
                        .font(.subheadline.weight(.semibold))
                        // The title never wraps; it scales down before it does.
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let message = toast.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .accessibilityElement(children: .combine)

                if let action = toast.action {
                    Button {
                        action.perform()
                        onDismiss()
                    } label: {
                        Text(action.label)
                    }
                    .buttonStyle(.registryLink)
                    .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.registryGhost)
            .controlSize(.small)
            .accessibilityLabel("Dismiss")
        }
        .padding(theme.metrics.standardSpacing)
        .background(theme.surface, in: shape)
        .overlay {
            shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth)
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.height > 0 {
                        onDismiss()
                    }
                }
        )
    }

    private var defaultSystemImage: String {
        switch toast.variant {
        case .informational: "info.circle.fill"
        case .positive: "checkmark.circle.fill"
        case .destructive: "exclamationmark.triangle.fill"
        }
    }

    private var toneStyle: AnyShapeStyle {
        switch toast.variant {
        case .informational: AnyShapeStyle(TintShapeStyle())
        case .positive: AnyShapeStyle(theme.positive)
        case .destructive: AnyShapeStyle(theme.negative)
        }
    }
}

private struct RegistryToastPreview: View {
    @State private var toast: RegistryToast? = RegistryToast(
        title: "Card frozen",
        message: "Unfreeze it any time from the card's settings.",
        variant: .positive,
        action: RegistryToast.Action(label: "Undo") {}
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<5, id: \.self) { index in
                HStack(spacing: 12) {
                    Circle()
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Placeholder row \(index + 1)")
                            .font(.subheadline)
                        Text("Supporting detail text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // A long duration keeps the toast on screen for previews and capture.
        .registryToast($toast, duration: .seconds(3600))
    }
}

#Preview("Toast") {
    RegistryToastPreview().tint(.indigo)
}

#Preview("Toast Dark") {
    RegistryToastPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Toast Right to Left") {
    RegistryToastPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Toast Accessibility Size") {
    RegistryToastPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
