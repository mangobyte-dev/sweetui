import Charts
import SwiftUI
import SweetUIFoundations

/// A sleep report, translated from shadcn's sleep-report: a stacked Swift Charts
/// bar chart of sleep stages through the night styled with registryChart(), a
/// four-up totals strip, a quality badge, and a details action. Durations are
/// formatted at the call site.
public struct SleepReport: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Last night · \(Duration.seconds(444 * 60), format: durationStyle)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Chart(points) { point in
                    BarMark(
                        x: .value("Hour", point.hour),
                        y: .value("Minutes", point.minutes)
                    )
                    .foregroundStyle(by: .value("Stage", point.stage))
                }
                .registryChart()
                .frame(height: 140)
                .accessibilityLabel("Sleep stages through the night")

                stats

                HStack {
                    Text("Good").registryBadge(.outline)
                    Spacer()
                    Button("Details") {}
                        .buttonStyle(.registryOutline)
                        .controlSize(.small)
                }
            }
        } label: {
            Text("Sleep Report")
        }
        .groupBoxStyle(.registryCard)
    }

    private var stats: some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            statColumn("Deep", value: Text(Duration.seconds(130 * 60), format: durationStyle))
            statColumn("Light", value: Text(Duration.seconds(228 * 60), format: durationStyle))
            statColumn("REM", value: Text(Duration.seconds(86 * 60), format: durationStyle))
            statColumn("Score", value: Text(84, format: .number))
        }
    }

    private func statColumn(_ label: LocalizedStringResource, value: Text) -> some View {
        VStack(spacing: 2) {
            value
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var durationStyle: Duration.UnitsFormatStyle {
        .units(allowed: [.hours, .minutes], width: .narrow)
    }

    private struct SleepPoint: Identifiable {
        let id: String
        let hour: String
        let stage: String
        let minutes: Int
    }

    private let hours = ["10pm", "11pm", "12am", "1am", "2am", "3am", "4am", "5am", "6am"]
    private let deep = [0, 20, 40, 30, 10, 25, 15, 5, 0]
    private let light = [30, 10, 0, 5, 20, 10, 25, 35, 20]
    private let rem = [0, 0, 10, 15, 30, 20, 10, 15, 25]

    private var points: [SleepPoint] {
        hours.indices.flatMap { index in
            [
                SleepPoint(id: "\(hours[index])-deep", hour: hours[index], stage: "Deep", minutes: deep[index]),
                SleepPoint(id: "\(hours[index])-light", hour: hours[index], stage: "Light", minutes: light[index]),
                SleepPoint(id: "\(hours[index])-rem", hour: hours[index], stage: "REM", minutes: rem[index]),
            ]
        }
    }
}

#if DEBUG
#Preview("Sleep Report") {
    ScrollView { SleepReport().padding() }
        .registryTheme(.indigo)
}

#Preview("Sleep Report Dark") {
    ScrollView { SleepReport().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
