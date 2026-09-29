import SwiftUI
import SweetUIFoundations

/// A weekly workout summary, translated from shadcn's weekly-fitness-summary: a
/// seven-day column of load bars drawn with theme tokens rather than a chart,
/// and a details action. Each day is one accessibility element that reads its
/// workout load as a percentage.
public struct WeeklyFitnessSummary: View {
    @Environment(\.registryTheme) private var theme

    private let trackHeight: CGFloat = 64

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Calories and workout load by day.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(alignment: .bottom, spacing: theme.metrics.compactSpacing / 2) {
                    ForEach(days) { day in
                        bar(day)
                    }
                }

                Button("View details") {}
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Weekly Fitness Summary")
        }
        .groupBoxStyle(.registryCard)
    }

    private func bar(_ day: Day) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)
        return VStack(spacing: theme.metrics.compactSpacing / 2) {
            ZStack(alignment: .bottom) {
                shape.fill(theme.surface)
                shape
                    .fill(.tint)
                    .frame(height: trackHeight * day.load)
            }
            .frame(height: trackHeight)
            .frame(maxWidth: .infinity)

            Text(day.letter)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(day.name), workout load \(day.load, format: .percent.precision(.fractionLength(0)))"))
    }

    private struct Day: Identifiable {
        let id: String
        let letter: String
        let name: String
        let load: Double
    }

    private let days: [Day] = [
        Day(id: "mon", letter: "M", name: "Monday", load: 0.84),
        Day(id: "tue", letter: "T", name: "Tuesday", load: 0.52),
        Day(id: "wed", letter: "W", name: "Wednesday", load: 0.73),
        Day(id: "thu", letter: "T", name: "Thursday", load: 0.66),
        Day(id: "fri", letter: "F", name: "Friday", load: 0.91),
        Day(id: "sat", letter: "S", name: "Saturday", load: 0.48),
        Day(id: "sun", letter: "S", name: "Sunday", load: 0.61),
    ]
}

#if DEBUG
#Preview("Weekly Fitness Summary") {
    ScrollView { WeeklyFitnessSummary().padding() }
        .registryTheme(.indigo)
}

#Preview("Weekly Fitness Summary Dark") {
    ScrollView { WeeklyFitnessSummary().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
