import SwiftUI
import SweetUIFoundations

/// An icon preview grid, translated from shadcn's icon-preview-grid: a grid of
/// SF Symbols, each labeled with its symbol name. It uses a native `Grid`
/// rather than a lazy container so the card measures correctly inside the wall.
public struct IconPreviewGrid: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            Grid(horizontalSpacing: theme.metrics.standardSpacing, verticalSpacing: theme.metrics.standardSpacing) {
                ForEach(Array(stride(from: 0, to: symbols.count, by: columns)), id: \.self) { start in
                    GridRow {
                        ForEach(start..<min(start + columns, symbols.count), id: \.self) { index in
                            cell(symbols[index])
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        } label: {
            Text("Icons")
        }
        .groupBoxStyle(.registryCard)
    }

    private func cell(_ symbol: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)

        return VStack(spacing: theme.metrics.compactSpacing) {
            Image(systemName: symbol)
                .font(.body)
                .frame(width: RegistryMetrics.minimumHitSize, height: RegistryMetrics.minimumHitSize)
                .background(theme.surface, in: shape)
                .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
                .accessibilityHidden(true)

            Text(symbol)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity)
    }

    private let columns = 3
    private let symbols = [
        "doc.on.doc", "exclamationmark.circle", "trash",
        "square.and.arrow.up", "bag", "ellipsis",
        "arrow.triangle.2.circlepath", "plus", "minus",
        "arrow.left", "arrow.right", "checkmark",
        "chevron.down", "chevron.right", "magnifyingglass",
        "gearshape",
    ]
}

#if DEBUG
#Preview("Icon Preview Grid") {
    ScrollView { IconPreviewGrid().padding() }
        .registryTheme(.indigo)
}

#Preview("Icon Preview Grid Dark") {
    ScrollView { IconPreviewGrid().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
