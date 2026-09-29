import SwiftUI
import SweetUIFoundations

/// A metered usage list, translated from shadcn's usage-card: each registry
/// item row pairs a circular usage gauge, a resource name, and its cost. The
/// gauge is a small ring that reads its percentage to VoiceOver, and every
/// amount is currency-formatted at the call site.
public struct UsageCard: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("5 days remaining in cycle.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(spacing: theme.metrics.compactSpacing / 2) {
                    ForEach(items) { item in
                        row(item)
                    }
                }
            }
        } label: {
            Text("Usage")
        }
        .groupBoxStyle(.registryCard)
    }

    private func row(_ item: Usage) -> some View {
        ItemRow(title: Text(item.name)) {
            gauge(item.fraction)
        } accessory: {
            Text(item.amount, format: .currency(code: "USD"))
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private func gauge(_ fraction: Double) -> some View {
        ZStack {
            Circle()
                .stroke(theme.border, lineWidth: 3)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(.tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 18, height: 18)
        .accessibilityElement()
        .accessibilityLabel(Text("\(fraction, format: .percent.precision(.fractionLength(0))) of limit used"))
    }

    private struct Usage: Identifiable {
        let id: String
        let name: LocalizedStringResource
        let amount: Decimal
        let fraction: Double
    }

    private let items: [Usage] = [
        Usage(id: "edge", name: "Edge Requests", amount: 1830, fraction: 0.67),
        Usage(id: "fast-data", name: "Fast Data Transfer", amount: 952.51, fraction: 0.52),
        Usage(id: "monitoring", name: "Monitoring data points", amount: 901.20, fraction: 0.89),
        Usage(id: "analytics", name: "Web Analytics Events", amount: 603.71, fraction: 0.46),
        Usage(id: "isr", name: "ISR Writes", amount: 524.52, fraction: 0.26),
        Usage(id: "function", name: "Function Duration", amount: 128.40, fraction: 0.05),
    ]
}

#if DEBUG
#Preview("Usage Card") {
    ScrollView { UsageCard().padding() }
        .registryTheme(.indigo)
}

#Preview("Usage Card Dark") {
    ScrollView { UsageCard().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
