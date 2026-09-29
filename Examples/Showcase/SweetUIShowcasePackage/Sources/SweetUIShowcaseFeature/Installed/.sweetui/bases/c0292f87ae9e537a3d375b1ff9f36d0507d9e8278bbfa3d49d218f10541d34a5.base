import SwiftUI
import SweetUIFoundations

/// An upsell for anomaly monitoring, translated from shadcn's anomaly-alert: a
/// card whose whole content is a native `ContentUnavailableView` placed on the
/// registry content surface, with a single call to action.
public struct AnomalyAlert: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            ContentUnavailableView {
                Label("Get alerted for anomalies", systemImage: "bell.badge")
            } description: {
                Text("Automatically monitor your projects for anomalies and get notified.")
            } actions: {
                Button("Upgrade to Insights Plus") {}
                    .buttonStyle(.registry)
            }
            .registryEmptyState()
        } label: {
            Text("Anomaly detection")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Anomaly Alert") {
    ScrollView { AnomalyAlert().padding() }
        .registryTheme(.indigo)
}

#Preview("Anomaly Alert Dark") {
    ScrollView { AnomalyAlert().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
