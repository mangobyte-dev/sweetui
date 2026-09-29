import SwiftUI
import SweetUIFoundations

/// A syncing empty state, translated from shadcn's syncing-state: a spinner, a
/// title, a description, and a cancel action. shadcn uses its empty and spinner
/// primitives; this keeps a native ContentUnavailableView on the registry
/// content surface with the registry spinner as its media, so the section holds
/// the system's empty-state semantics while showing progress.
public struct SyncingState: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            ContentUnavailableView {
                VStack(spacing: theme.metrics.compactSpacing) {
                    ProgressView()
                        .progressViewStyle(.registrySpinner)
                        .accessibilityLabel("Syncing")
                    Text("Syncing your accounts")
                }
            } description: {
                Text("We're pulling in your latest transactions. This usually takes a few seconds.")
            } actions: {
                Button("Cancel") {}
                    .buttonStyle(.registryOutline)
                    .controlSize(.small)
            }
            .registryEmptyState()
        } label: {
            Text("Accounts")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Syncing State") {
    ScrollView { SyncingState().padding() }
        .registryTheme(.indigo)
}

#Preview("Syncing State Dark") {
    ScrollView { SyncingState().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
