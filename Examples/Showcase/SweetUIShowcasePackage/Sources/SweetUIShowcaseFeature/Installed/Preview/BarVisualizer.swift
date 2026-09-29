import SwiftUI
import SweetUIFoundations

/// An animated audio-frequency visualizer, translated from shadcn's
/// bar-visualizer canvas. The bars are drawn in a `Canvas` driven by
/// `TimelineView(.animation)`, their heights a deterministic function of time
/// (no randomness, so captures stay coherent). When Reduce Motion is on the
/// timeline pauses and a still frame is drawn instead.
public struct BarVisualizer: View {
    @Environment(\.registryTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var state: AgentState = .speaking

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Real-time frequency bands with animated state transitions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                bars

                HStack(spacing: theme.metrics.compactSpacing) {
                    ForEach(AgentState.allCases) { option in
                        Button { state = option } label: {
                            Text(option.title).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RegistryButtonStyle(state == option ? .primary : .outline))
                        .controlSize(.small)
                    }
                }
            }
        } label: {
            Text("Audio frequency visualizer")
        }
        .groupBoxStyle(.registryCard)
    }

    private var bars: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                draw(in: context, size: size, time: time)
            }
        }
        .frame(height: 130)
        .frame(maxWidth: .infinity)
        .padding(theme.metrics.standardSpacing)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("Audio frequency visualizer")
        .accessibilityValue(Text(state.title))
    }

    private func draw(in context: GraphicsContext, size: CGSize, time: Double) {
        let gap: CGFloat = 6
        let barWidth = min(12, max(4, (size.width - gap * CGFloat(barCount - 1)) / CGFloat(barCount)))
        let step = (size.width - barWidth) / CGFloat(barCount - 1)
        let color = theme.accent ?? Color.accentColor
        for index in 0..<barCount {
            let height = max(barWidth, CGFloat(level(index, time)) * size.height)
            let rect = CGRect(x: CGFloat(index) * step, y: (size.height - height) / 2, width: barWidth, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2), with: .color(color))
        }
    }

    /// A deterministic level in `0.08...1` for one bar at one time, shaped by
    /// the current state: a full wave while speaking, a centered breath while
    /// listening, a traveling bump while connecting.
    private func level(_ index: Int, _ time: Double) -> Double {
        let phase = Double(index) * 0.5
        let raw: Double
        switch state {
        case .speaking:
            raw = 0.5 + 0.4 * sin(time * 3 + phase)
        case .listening:
            let center = Double(barCount - 1) / 2
            let distance = abs(Double(index) - center) / center
            raw = 0.2 + 0.35 * (1 - distance) * (0.5 + 0.5 * sin(time * 2))
        case .connecting:
            let position = (sin(time * 2) * 0.5 + 0.5) * Double(barCount - 1)
            raw = 0.15 + 0.6 * max(0, 1 - abs(Double(index) - position) / 2)
        }
        return min(1, max(0.08, raw))
    }

    private let barCount = 20

    private enum AgentState: String, CaseIterable, Identifiable {
        case connecting, listening, speaking
        var id: String { rawValue }
        var title: LocalizedStringResource {
            switch self {
            case .connecting: "Connecting"
            case .listening: "Listening"
            case .speaking: "Speaking"
            }
        }
    }
}

#if DEBUG
#Preview("Bar Visualizer") {
    ScrollView { BarVisualizer().padding() }
        .registryTheme(.indigo)
}

#Preview("Bar Visualizer Dark") {
    ScrollView { BarVisualizer().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
