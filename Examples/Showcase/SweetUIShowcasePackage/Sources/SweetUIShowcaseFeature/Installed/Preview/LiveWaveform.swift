import SwiftUI
import SweetUIFoundations

/// A live audio waveform, translated from shadcn's live-waveform canvas. The
/// bars are drawn in a `Canvas` driven by `TimelineView(.animation)`, their
/// heights a deterministic function of position and time (no randomness, so
/// captures stay coherent). When Reduce Motion is on the timeline pauses and a
/// still frame is drawn. Listening, processing, and scroll mode are switched
/// with registry buttons.
public struct LiveWaveform: View {
    @Environment(\.registryTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isListening = true
    @State private var isProcessing = false
    @State private var mode: Mode = .scrolling

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Real-time microphone input visualization with audio reactivity.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                waveform

                controls
            }
        } label: {
            Text("Live Audio Waveform")
        }
        .groupBoxStyle(.registryCard)
    }

    private var waveform: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                draw(in: context, size: size, time: time)
            }
        }
        .frame(height: 90)
        .frame(maxWidth: .infinity)
        .padding(theme.metrics.standardSpacing)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("Live audio waveform")
        .accessibilityValue(Text(stateDescription))
    }

    private var controls: some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            Button { isListening.toggle() } label: {
                Text(isListening ? "Stop listening" : "Start listening").frame(maxWidth: .infinity)
            }
            .buttonStyle(RegistryButtonStyle(isListening ? .primary : .outline))
            .controlSize(.small)

            Button { isProcessing.toggle() } label: {
                Text(isProcessing ? "Stop processing" : "Start processing").frame(maxWidth: .infinity)
            }
            .buttonStyle(RegistryButtonStyle(isProcessing ? .primary : .outline))
            .controlSize(.small)

            Button { mode = mode == .stationary ? .scrolling : .stationary } label: {
                Text(mode == .stationary ? "Static" : "Scrolling").frame(maxWidth: .infinity)
            }
            .buttonStyle(.registryOutline)
            .controlSize(.small)
        }
    }

    private func draw(in context: GraphicsContext, size: CGSize, time: Double) {
        let gap: CGFloat = 3
        let barWidth: CGFloat = 3
        let count = max(1, Int((size.width + gap) / (barWidth + gap)))
        let color = theme.accent ?? Color.accentColor
        let midY = size.height / 2
        for index in 0..<count {
            let x = barWidth / 2 + CGFloat(index) * (barWidth + gap)
            let height = max(barWidth, CGFloat(amplitude(index, count, time)) * size.height)
            let rect = CGRect(x: x - barWidth / 2, y: midY - height / 2, width: barWidth, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2), with: .color(color))
        }
    }

    /// A deterministic amplitude in `0.05...1` for one bar at one time. Idle is
    /// a quiet line; scrolling drifts the wave sideways; static breathes in
    /// place; processing adds a faster shimmer on top.
    private func amplitude(_ index: Int, _ count: Int, _ time: Double) -> Double {
        guard isListening else { return 0.05 }
        let x = Double(index) / Double(max(1, count - 1))
        let drift = mode == .scrolling ? time * 2 : 0
        let breath = mode == .scrolling ? 1 : (0.55 + 0.45 * sin(time * 2))
        var value = (0.5 + 0.5 * sin(x * 18 - drift) * sin(x * 7 + time)) * breath
        if isProcessing {
            value = value * 0.55 + 0.45 * (0.5 + 0.5 * sin(time * 6 + x * 24))
        }
        return min(1, max(0.05, abs(value)))
    }

    private var stateDescription: LocalizedStringResource {
        if !isListening { return "Idle" }
        return isProcessing ? "Listening and processing" : "Listening"
    }

    private enum Mode {
        case stationary, scrolling
    }
}

#if DEBUG
#Preview("Live Waveform") {
    ScrollView { LiveWaveform().padding() }
        .registryTheme(.indigo)
}

#Preview("Live Waveform Dark") {
    ScrollView { LiveWaveform().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
