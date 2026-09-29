import SwiftUI
import SweetUIFoundations

/// A self-portrait of the design system, the registry counterpart of shadcn's
/// style-overview: it reads the current theme from the environment and draws
/// its color tokens, corner radii, and spacing so a theme can be judged against
/// its own values. Every swatch reads `@Environment(\.registryTheme)`, so the
/// card restyles itself under each preset.
public struct StyleOverview: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.sectionSpacing) {
                Text("The accent, surfaces, borders, radii, and spacing this theme applies.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                group("Colors") { ColorTokens() }
                group("Radii") { RadiusTokens() }
                group("Spacing") { SpacingTokens() }
            }
        } label: {
            Text("Style Overview")
        }
        .groupBoxStyle(.registryCard)
    }

    @ViewBuilder
    private func group<Content: View>(_ title: LocalizedStringResource, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

private struct ColorTokens: View {
    @Environment(\.registryTheme) private var theme

    var body: some View {
        Grid(horizontalSpacing: theme.metrics.compactSpacing, verticalSpacing: theme.metrics.compactSpacing) {
            GridRow {
                swatch("Accent", theme.accent ?? .accentColor)
                swatch("On accent", theme.onAccent)
                swatch("Surface", theme.surface)
            }
            GridRow {
                swatch("Border", theme.border)
                swatch("Positive", theme.positive)
                swatch("Negative", theme.negative)
            }
        }
    }

    private func swatch(_ name: LocalizedStringResource, _ color: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)
        return VStack(spacing: theme.metrics.compactSpacing / 2) {
            shape
                .fill(color)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct RadiusTokens: View {
    @Environment(\.registryTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
            sample("Compact", theme.metrics.compactRadius)
            sample("Control", theme.metrics.controlRadius)
            sample("Card", theme.metrics.cardRadius)
        }
    }

    private func sample(_ name: LocalizedStringResource, _ radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return VStack(spacing: theme.metrics.compactSpacing / 2) {
            shape
                .fill(theme.surface)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
            HStack(spacing: 3) {
                Text(name)
                Text(Double(radius), format: .number)
                    .monospacedDigit()
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }
}

private struct SpacingTokens: View {
    @Environment(\.registryTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            row("Compact", theme.metrics.compactSpacing)
            row("Standard", theme.metrics.standardSpacing)
            row("Section", theme.metrics.sectionSpacing)
        }
    }

    private func row(_ name: LocalizedStringResource, _ value: CGFloat) -> some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            Text(name)
                .font(.caption)
                .frame(width: 72, alignment: .leading)
            Capsule()
                .fill(.tint)
                .frame(width: value, height: 8)
            Text(Double(value), format: .number)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Spacer()
        }
    }
}

#if DEBUG
#Preview("Style Overview") {
    ScrollView { StyleOverview().padding() }
        .registryTheme(.indigo)
}

#Preview("Style Overview Dark") {
    ScrollView { StyleOverview().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
