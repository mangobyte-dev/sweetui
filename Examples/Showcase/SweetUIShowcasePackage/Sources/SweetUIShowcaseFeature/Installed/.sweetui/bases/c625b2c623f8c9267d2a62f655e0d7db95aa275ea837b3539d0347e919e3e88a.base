import SwiftUI
import SweetUIFoundations

/// A product migration notice, translated from shadcn's observability-card and
/// kept generic. shadcn's photo becomes an SF Symbol hero drawn with theme
/// tokens (this registry uses no bitmap images); the card carries a headline,
/// a description, a call to action, and a status badge.
public struct ObservabilityCard: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                hero

                Text("Switch to the improved way to explore your data, with natural language. Monitoring will no longer be available on the Pro plan in November 2026.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Create query", systemImage: "plus") {}
                        .buttonStyle(.registry)
                        .controlSize(.small)
                    Spacer()
                    Text("Warning").registryBadge(.secondary)
                }
            }
        } label: {
            Text("Insights Plus is replacing Monitoring")
        }
        .groupBoxStyle(.registryCard)
    }

    private var hero: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        return Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.largeTitle)
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(TintShapeStyle().opacity(0.12), in: shape)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Observability Card") {
    ScrollView { ObservabilityCard().padding() }
        .registryTheme(.indigo)
}

#Preview("Observability Card Dark") {
    ScrollView { ObservabilityCard().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
