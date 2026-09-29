import SwiftUI
import SweetUIFoundations

/// A loading placeholder, translated from shadcn's loading-card: two heading
/// lines, a media block, a paragraph, and two actions, all wrapped in the
/// registry skeleton treatment. shadcn stacks bare skeleton bars; this redacts
/// real content, so the same view tree serves the loaded state, and redaction
/// disables interaction, stops the pulse under Reduce Motion, and exposes one
/// loading element to VoiceOver.
public struct LoadingCard: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    Text("Monthly performance")
                        .font(.body.weight(.medium))
                    Text("Preparing your summary")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                mediaBlock

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    Text("Gathering account balances and recent activity.")
                    Text("Reconciling transactions and dividends.")
                    Text("Almost ready.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                HStack(spacing: theme.metrics.compactSpacing) {
                    Button { } label: {
                        Text("Refresh").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.registryOutline)

                    Button { } label: {
                        Text("Cancel").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.registrySecondary)
                }
            }
            .registrySkeleton(accessibilityLabel: "Loading report")
        } label: {
            Text("Loading")
        }
        .groupBoxStyle(.registryCard)
    }

    private var mediaBlock: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        return shape
            .fill(theme.surface)
            .frame(height: 120)
            .overlay {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
    }
}

#if DEBUG
#Preview("Loading Card") {
    ScrollView { LoadingCard().padding() }
        .registryTheme(.indigo)
}

#Preview("Loading Card Dark") {
    ScrollView { LoadingCard().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
