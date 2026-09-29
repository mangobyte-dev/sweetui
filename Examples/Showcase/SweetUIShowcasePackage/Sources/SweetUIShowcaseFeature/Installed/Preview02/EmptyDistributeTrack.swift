import SwiftUI
import SweetUIFoundations

/// A distribute-track empty state, translated from shadcn's
/// empty-distribute-track: a native ContentUnavailableView on the registry
/// content surface with a create action. shadcn names specific streaming
/// services; this uses neutral copy so the card carries no third-party brand.
public struct EmptyDistributeTrack: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            ContentUnavailableView {
                Label("Distribute track", systemImage: "plus.circle")
            } description: {
                Text("Upload your first master to start reaching listeners across every streaming service.")
            } actions: {
                Button("Create release") {}
                    .buttonStyle(.registry)
                    .controlSize(.small)
            }
            .registryEmptyState()
        } label: {
            Text("Releases")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Empty Distribute Track") {
    ScrollView { EmptyDistributeTrack().padding() }
        .registryTheme(.indigo)
}

#Preview("Empty Distribute Track Dark") {
    ScrollView { EmptyDistributeTrack().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
