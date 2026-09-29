import Foundation
import SwiftUI
import SweetUIFoundations

public extension View {
    /// Turns the receiver into a loading placeholder: native redaction, no
    /// interaction, one accessibility element with a loading label, and a
    /// gentle pulse that stops under Reduce Motion. Pass `false` to render the
    /// real content unchanged, so the same view tree serves both states.
    /// Redaction covers appearance and interaction only: an effect the content
    /// starts itself (`task`, `onAppear`, a request) still runs, so gate it on
    /// the same flag.
    func registrySkeleton(
        _ isActive: Bool = true,
        accessibilityLabel: LocalizedStringResource = "Loading"
    ) -> some View {
        modifier(
            RegistrySkeletonModifier(
                isActive: isActive,
                accessibilityLabel: accessibilityLabel
            )
        )
    }
}

private struct RegistrySkeletonModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDimmed = false

    let isActive: Bool
    let accessibilityLabel: LocalizedStringResource

    // Every modifier applies in both states so the content keeps one
    // structural identity: flipping isActive never resets the state, focus,
    // or scroll position of the view it wraps.
    func body(content: Content) -> some View {
        content
            .redacted(reason: isActive ? .placeholder : [])
            .opacity(opacity)
            .animation(pulse, value: isDimmed)
            .disabled(isActive)
            .allowsHitTesting(!isActive)
            .accessibilityHidden(isActive)
            .overlay {
                if isActive {
                    Color.clear
                        .accessibilityElement()
                        .accessibilityLabel(Text(accessibilityLabel))
                }
            }
            .task(id: isActive) {
                isDimmed = isActive && !reduceMotion
            }
            .registryItem("skeleton")
    }

    private var opacity: Double {
        guard isActive else { return 1 }
        if reduceMotion { return 0.7 }
        return isDimmed ? 0.45 : 1
    }

    private var pulse: Animation? {
        guard isActive, !reduceMotion else { return nil }
        return .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
    }
}

private struct RegistrySkeletonModifierPreview: View {
    @Environment(\.registryTheme) private var theme
    var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: theme.metrics.standardSpacing) {
                    Circle()
                        .fill(theme.surface)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mishmash Bakery order \(index + 1)")
                            .font(.body.weight(.medium))
                        Text("Placeholder detail text")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open") {}
                        .buttonStyle(.bordered)
                }
            }
        }
        .registrySkeleton(isLoading)
        .padding()
    }
}

#Preview("Skeleton") {
    RegistrySkeletonModifierPreview()
}

#Preview("Skeleton Loaded") {
    RegistrySkeletonModifierPreview(isLoading: false)
}

#Preview("Skeleton Dark") {
    RegistrySkeletonModifierPreview().preferredColorScheme(.dark)
}

#Preview("Skeleton Accessibility Size") {
    RegistrySkeletonModifierPreview().dynamicTypeSize(.accessibility3)
}
