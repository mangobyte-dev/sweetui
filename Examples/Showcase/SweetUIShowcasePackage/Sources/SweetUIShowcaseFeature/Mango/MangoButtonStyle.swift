import SwiftUI
import SweetUIFoundations

// MangoButtonStyle is an owned copy of the registry `button` item, version 0.5.1,
// copied from Installed/RegistryButtonStyle.swift for the MANGO sample design system.
// MANGO edits, one per line:
// 1. Renamed the type RegistryButtonStyle to MangoButtonStyle.
// 2. Narrowed the ButtonStyle extension to `static var mango` (primary only), the
//    one accent MANGO spends on the primary action.
// 3. Added press feedback: the label scales to 0.97 while pressed, animated by a
//    critically damped spring (response 0.4, damping 1.0), from Emil Kowalski's
//    apple-design skill (respond on press, critically damped default).
// 4. Under Reduce Motion the press drops the scale and reads as a short opacity
//    cross-fade instead, per the same skill's reduced-motion rule.
// 5. The previews apply .registryTheme(.mango) and .fontDesign(.rounded), show MANGO
//    labels, and drop the sizes preview; light, dark, right-to-left, and the
//    accessibility size remain.

/// A shadcn-inspired treatment for native SwiftUI buttons.
public struct MangoButtonStyle: ButtonStyle {
    public enum Variant: Sendable {
        case primary
        case destructive
        case outline
        case secondary
        case ghost
        case link
    }

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.registryTheme) private var theme

    private let variant: Variant

    public init(_ variant: Variant = .primary) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        let variant = resolvedVariant(for: configuration)
        let isDestructiveRole = configuration.role == .destructive
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        configuration.label
            .font(font)
            // A button label never wraps or breaks lines: it stays on one
            // line, scales down a little under pressure, and the call site
            // gives it room (a full-width frame, a stacked layout) instead.
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: visualMinimumHeight)
            .foregroundStyle(foregroundStyle(for: variant, isDestructiveRole: isDestructiveRole))
            .background(backgroundStyle(for: variant, isPressed: configuration.isPressed), in: shape)
            .overlay {
                shape.stroke(
                    borderStyle(for: variant, isDestructiveRole: isDestructiveRole),
                    lineWidth: variant == .outline ? theme.metrics.borderWidth : 0
                )
            }
            .underline(variant == .link)
            .opacity(opacity(isPressed: configuration.isPressed))
            .frame(
                minWidth: RegistryMetrics.minimumHitSize,
                minHeight: RegistryMetrics.minimumHitSize
            )
            .contentShape(Rectangle())
            // A custom button style drops SwiftUI's automatic pointer effect on
            // iPad (measured 2026-09-07: hovering changed nothing until this
            // line), so the style asks for it back and the system picks the shape.
            .hoverEffect()
            // MANGO press feedback: the label scales on press, or cross-fades
            // when Reduce Motion is on. Feedback lives on the press, not release.
            .scaleEffect(pressScale(configuration.isPressed))
            .animation(pressAnimation, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == MangoButtonStyle {
    static var mango: MangoButtonStyle { MangoButtonStyle() }
}

private extension MangoButtonStyle {
    func resolvedVariant(for configuration: Configuration) -> Variant {
        if variant == .primary, configuration.role == .destructive {
            return .destructive
        }
        return variant
    }

    var font: Font {
        switch controlSize {
        case .mini:
            .caption2.weight(.medium)
        case .small:
            .caption.weight(.medium)
        case .regular:
            .subheadline.weight(.medium)
        case .large, .extraLarge:
            .body.weight(.medium)
        @unknown default:
            .subheadline.weight(.medium)
        }
    }

    var horizontalPadding: CGFloat {
        switch controlSize {
        case .mini:
            8
        case .small:
            12
        case .regular:
            16
        case .large:
            20
        case .extraLarge:
            24
        @unknown default:
            16
        }
    }

    var verticalPadding: CGFloat {
        switch controlSize {
        case .mini:
            4
        case .small:
            6
        case .regular:
            8
        case .large:
            10
        case .extraLarge:
            12
        @unknown default:
            8
        }
    }

    var visualMinimumHeight: CGFloat {
        switch controlSize {
        case .mini:
            24
        case .small:
            32
        case .regular:
            36
        case .large:
            40
        case .extraLarge:
            44
        @unknown default:
            36
        }
    }

    /// A destructive role inside a non-primary variant keeps that variant's
    /// chrome and reads in the negative color, so an outline or ghost Delete
    /// still signals what it does.
    func foregroundStyle(for variant: Variant, isDestructiveRole: Bool) -> AnyShapeStyle {
        switch variant {
        case .primary:
            AnyShapeStyle(theme.onAccent)
        case .destructive:
            // The negative fill is always dark enough for a white label; the
            // accent may not be, which is why primary reads theme.onAccent.
            AnyShapeStyle(Color.white)
        case .outline, .secondary, .ghost:
            AnyShapeStyle(isDestructiveRole ? theme.negative : Color.primary)
        case .link:
            isDestructiveRole ? AnyShapeStyle(theme.negative) : AnyShapeStyle(TintShapeStyle())
        }
    }

    func backgroundStyle(for variant: Variant, isPressed: Bool) -> AnyShapeStyle {
        switch variant {
        case .primary:
            AnyShapeStyle(TintShapeStyle())
        case .destructive:
            AnyShapeStyle(theme.negative)
        case .secondary:
            AnyShapeStyle(theme.surface)
        case .outline, .ghost:
            AnyShapeStyle(isPressed ? theme.surface : Color.clear)
        case .link:
            AnyShapeStyle(Color.clear)
        }
    }

    func borderStyle(for variant: Variant, isDestructiveRole: Bool) -> Color {
        guard variant == .outline else { return .clear }
        return isDestructiveRole ? theme.negative : theme.border
    }

    func opacity(isPressed: Bool) -> Double {
        guard isEnabled else { return theme.disabledOpacity }
        // With motion the scale carries the press feedback and the label stays
        // opaque; under Reduce Motion the press reads as an opacity cross-fade.
        guard reduceMotion else { return 1 }
        return isPressed ? 0.82 : 1
    }

    func pressScale(_ isPressed: Bool) -> CGFloat {
        guard !reduceMotion else { return 1 }
        return isPressed ? 0.97 : 1
    }

    var pressAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.4, dampingFraction: 1.0)
    }
}

private struct MangoButtonStylePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Save changes") {}
                .buttonStyle(.mango)

            Button("Delete", role: .destructive) {}
                .buttonStyle(.mango)

            Button("Disabled") {}
                .buttonStyle(.mango)
                .disabled(true)
        }
        .padding()
        .registryTheme(.mango)
        .fontDesign(.rounded)
    }
}

#Preview("Mango Button") {
    MangoButtonStylePreview()
}

#Preview("Mango Button Dark") {
    MangoButtonStylePreview()
        .preferredColorScheme(.dark)
}

#Preview("Mango Button Right to Left") {
    MangoButtonStylePreview()
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Mango Button Accessibility Size") {
    MangoButtonStylePreview()
        .dynamicTypeSize(.accessibility3)
}
