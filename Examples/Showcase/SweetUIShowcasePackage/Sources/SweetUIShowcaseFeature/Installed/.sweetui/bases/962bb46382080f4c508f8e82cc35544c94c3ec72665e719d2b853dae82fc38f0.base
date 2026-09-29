import SwiftUI
import SweetUIFoundations

/// A connect-bank empty state, translated from shadcn's empty-connect-bank: a
/// native ContentUnavailableView on the registry content surface with a setup
/// action, so the empty section keeps the system's empty-state semantics.
public struct EmptyConnectBank: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            ContentUnavailableView {
                Label("Connect bank", systemImage: "creditcard")
            } description: {
                Text("Link your payout method to receive monthly royalty distributions automatically.")
            } actions: {
                Button("Set up payouts") {}
                    .buttonStyle(.registry)
                    .controlSize(.small)
            }
            .registryEmptyState()
        } label: {
            Text("Payouts")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Empty Connect Bank") {
    ScrollView { EmptyConnectBank().padding() }
        .registryTheme(.indigo)
}

#Preview("Empty Connect Bank Dark") {
    ScrollView { EmptyConnectBank().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
