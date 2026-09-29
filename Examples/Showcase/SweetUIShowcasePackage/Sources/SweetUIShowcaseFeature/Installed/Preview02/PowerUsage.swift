import Charts
import SwiftUI
import SweetUIFoundations

/// A home-energy card, translated from shadcn's power-usage: an hourly usage
/// bar chart styled with registryChart(), a two-up stats strip, and a battery
/// level bar. shadcn uses its chart and progress primitives; this keeps a
/// Swift Charts bar chart with the registry chart treatment and a native
/// ProgressView with the registry linear style. Readings are formatted at the
/// call site. The copy is neutral smart-home, so the card names no brand.
public struct PowerUsage: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Whole home")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                chart

                Divider().registrySeparator()

                HStack(alignment: .top, spacing: theme.metrics.standardSpacing) {
                    StatColumn(title: "Currently using", value: Text("\(3.4, format: .number) kW"))
                    StatColumn(title: "Solar generation", value: Text("\(1.2, format: .number.sign(strategy: .always())) kW"))
                }

                batteryLevel
            }
        } label: {
            Text("Power Usage")
        }
        .groupBoxStyle(.registryCard)
    }

    private var chart: some View {
        Chart(hours) { point in
            BarMark(
                x: .value("Hour", point.hour),
                y: .value("Usage", point.usage)
            )
            .foregroundStyle(.tint)
            .cornerRadius(theme.metrics.compactRadius / 2)
        }
        .registryChart()
        .frame(height: 140)
        .accessibilityLabel("Power usage in kilowatts by hour")
    }

    private var batteryLevel: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            Text("Battery level")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack(spacing: theme.metrics.standardSpacing) {
                ProgressView(value: 0.85)
                    .progressViewStyle(.registryLinear)
                    .accessibilityLabel("Battery level")
                Text(0.85, format: .percent)
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
            }
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

    private struct HourUsage: Identifiable {
        let id: String
        let hour: String
        let usage: Double
    }

    private let hours: [HourUsage] = [
        HourUsage(id: "06", hour: "6a", usage: 1.2),
        HourUsage(id: "08", hour: "8a", usage: 2.8),
        HourUsage(id: "10", hour: "10a", usage: 3.1),
        HourUsage(id: "12", hour: "12p", usage: 2.4),
        HourUsage(id: "14", hour: "2p", usage: 3.4),
        HourUsage(id: "16", hour: "4p", usage: 2.9),
        HourUsage(id: "18", hour: "6p", usage: 3.8),
        HourUsage(id: "20", hour: "8p", usage: 3.2),
    ]
}

#if DEBUG
#Preview("Power Usage") {
    ScrollView { PowerUsage().padding() }
        .registryTheme(.indigo)
}

#Preview("Power Usage Dark") {
    ScrollView { PowerUsage().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
