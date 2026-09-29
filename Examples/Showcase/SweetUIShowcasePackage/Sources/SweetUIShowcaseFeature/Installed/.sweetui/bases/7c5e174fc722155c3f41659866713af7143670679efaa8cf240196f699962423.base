import SwiftUI
import SweetUIFoundations

/// An album summary, translated from shadcn's album-card: cover artwork with a
/// value badge, a title and release date, and a two-up stats strip below a
/// separator. shadcn shows a fetched cover image; this draws a themed
/// placeholder (a rounded rectangle on the content surface with an SF Symbol)
/// instead, so the card needs no network image.
public struct AlbumCard: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    private let releaseDate = DateComponents(calendar: .current, year: 2023, month: 8, day: 14).date ?? .now

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                artwork

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
                    Text("Synthetic Horizons EP")
                        .font(.title3.weight(.semibold))
                    Text("Released \(releaseDate, format: .dateTime.month(.abbreviated).day().year())")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }

                Divider().registrySeparator()

                stats
            }
        } label: {
            Text("Latest Release")
        }
        .groupBoxStyle(.registryCard)
    }

    private var artwork: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        return shape
            .fill(theme.surface)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .overlay {
                shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth)
            }
            .overlay(alignment: .topTrailing) {
                Text(26_033.79, format: .currency(code: "USD"))
                    .registryBadge(.secondary)
                    .padding(theme.metrics.compactSpacing)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Cover art for Synthetic Horizons EP")
    }

    private var stats: some View {
        HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
            StatColumn(title: "Tracks", value: Text(6, format: .number))
            StatColumn(title: "Cumulative streams", value: Text(6_198_524, format: .number))
        }
    }

    private struct StatColumn: View {
        let title: LocalizedStringResource
        let value: Text

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                value
                    .font(.title3.weight(.medium))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if DEBUG
#Preview("Album Card") {
    ScrollView { AlbumCard().padding() }
        .registryTheme(.indigo)
}

#Preview("Album Card Dark") {
    ScrollView { AlbumCard().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
