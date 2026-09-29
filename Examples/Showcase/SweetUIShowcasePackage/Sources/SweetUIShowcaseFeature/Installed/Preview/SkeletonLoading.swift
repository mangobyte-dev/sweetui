import SwiftUI
import SweetUIFoundations

/// A loading placeholder, translated from shadcn's skeleton-loading: an avatar,
/// two heading lines, a paragraph, and two actions, all wrapped in the registry
/// skeleton treatment. Redaction disables interaction, stops the pulse under
/// Reduce Motion, and exposes one loading element to VoiceOver, so the same
/// view tree serves both the loading and the loaded state.
public struct SkeletonLoading: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                HStack(spacing: theme.metrics.standardSpacing) {
                    Circle()
                        .fill(theme.surface)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                        Text("Loading the latest activity")
                            .font(.body.weight(.medium))
                        Text("A few seconds remaining")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    Text("Fetching your account details and recent activity from the server.")
                    Text("This placeholder keeps the layout stable while the data loads.")
                    Text("Hang tight for just a moment longer.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                HStack(spacing: theme.metrics.compactSpacing) {
                    Button("Refresh") {}
                        .buttonStyle(.registryOutline)
                        .controlSize(.small)
                    Button("Dismiss") {}
                        .buttonStyle(.registryGhost)
                        .controlSize(.small)
                }
            }
            .registrySkeleton(accessibilityLabel: "Loading content")
        } label: {
            Text("Loading")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Skeleton Loading") {
    ScrollView { SkeletonLoading().padding() }
        .registryTheme(.indigo)
}

#Preview("Skeleton Loading Dark") {
    ScrollView { SkeletonLoading().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
