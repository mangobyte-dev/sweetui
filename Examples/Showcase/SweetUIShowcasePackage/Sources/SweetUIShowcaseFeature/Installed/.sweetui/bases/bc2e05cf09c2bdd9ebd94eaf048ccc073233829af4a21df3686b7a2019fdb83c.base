import SwiftUI
import SweetUIFoundations

/// An explore-catalog empty state, translated from shadcn's
/// empty-explore-catalog: a native ContentUnavailableView on the registry
/// content surface with a browse action, so the empty section keeps the
/// system's empty-state semantics.
public struct EmptyExploreCatalog: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            ContentUnavailableView {
                Label("Explore catalog", systemImage: "waveform")
            } description: {
                Text("Check your ISRC codes, metadata, and visual assets before going live.")
            } actions: {
                Button("View catalog") {}
                    .buttonStyle(.registry)
                    .controlSize(.small)
            }
            .registryEmptyState()
        } label: {
            Text("Catalog")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Empty Explore Catalog") {
    ScrollView { EmptyExploreCatalog().padding() }
        .registryTheme(.indigo)
}

#Preview("Empty Explore Catalog Dark") {
    ScrollView { EmptyExploreCatalog().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
