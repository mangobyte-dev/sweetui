import Charts
import SwiftUI
import SweetUIFoundations

/// A savings-progress card, translated from shadcn's savings-progress: a donut
/// chart of saved versus remaining with the total and percentage at its center,
/// over a three-row summary. shadcn uses its chart primitive with a Recharts
/// pie; this keeps a Swift Charts SectorMark donut styled with registryChart(),
/// and the center readout sits in the plot area. Amounts and the projected date
/// are formatted at the call site, so the card names no brand.
public struct SavingsProgress: View {
    @Environment(\.registryTheme) private var theme

    private let goal = 30_000
    private let saved = 24_000
    private let projectedFinish = DateComponents(calendar: .current, year: 2026, month: 10, day: 1).date ?? .now

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                chart

                summary
            }
        } label: {
            Text("Savings Progress")
        }
        .groupBoxStyle(.registryCard)
    }

    private var chart: some View {
        Chart(Self.segments) { segment in
            SectorMark(
                angle: .value("Amount", segment.amount),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .cornerRadius(theme.metrics.compactRadius / 2)
            .foregroundStyle(by: .value("Segment", segment.name))
        }
        .registryChart()
        .frame(height: 220)
        .chartBackground { proxy in
            GeometryReader { geometry in
                if let anchor = proxy.plotFrame {
                    let frame = geometry[anchor]
                    VStack(spacing: 2) {
                        Text(saved, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.title2.weight(.bold))
                            .monospacedDigit()
                        Text("\(Double(saved) / Double(goal), format: .percent.precision(.fractionLength(0))) of \(goal, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .accessibilityLabel("Savings progress: \(saved, format: .currency(code: "USD").precision(.fractionLength(0))) saved of \(goal, format: .currency(code: "USD").precision(.fractionLength(0)))")
    }

    private var summary: some View {
        VStack(spacing: 0) {
            row("Projected finish", value: Text(projectedFinish, format: .dateTime.month(.wide).year()))
            Divider().registrySeparator()
            row("Monthly average", value: Text(1_250, format: .currency(code: "USD").precision(.fractionLength(0))))
            Divider().registrySeparator()
            row("Top contributor", value: Text("Auto-transfer"))
        }
    }

    private func row(_ label: LocalizedStringResource, value: Text) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            value
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, theme.metrics.compactSpacing)
    }

    private struct Segment: Identifiable {
        let id: String
        let name: String
        let amount: Int
    }

    private static let segments: [Segment] = [
        Segment(id: "saved", name: "Saved", amount: 24_000),
        Segment(id: "remaining", name: "Remaining", amount: 6_000),
    ]
}

#if DEBUG
#Preview("Savings Progress") {
    ScrollView { SavingsProgress().padding() }
        .registryTheme(.indigo)
}

#Preview("Savings Progress Dark") {
    ScrollView { SavingsProgress().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
