import SwiftUI
import SweetUIFoundations

/// A roller-shade controller, translated from shadcn's roller-shades: a shade
/// visualization, an open-to-close slider, and a preset chooser. shadcn uses
/// its slider and toggle-group primitives; this keeps a native Slider and a
/// native segmented Picker visible at the call site, and choosing a preset
/// moves the shade. The room name is invented, so the card names no brand.
public struct RollerShades: View {
    @Environment(\.registryTheme) private var theme
    @State private var position: Double = 50
    @State private var preset: Preset = .half

    private let shadeHeight: CGFloat = 128

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Roller shades")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                shade

                sliderRow

                Picker("Shade preset", selection: $preset) {
                    ForEach(Preset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("Shade preset")
            }
        } label: {
            Text("Living Room")
        }
        .groupBoxStyle(.registryCard)
        .onChange(of: preset) { _, newValue in
            position = newValue.position
        }
    }

    private var shade: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        return shape
            .fill(theme.surface)
            .frame(height: shadeHeight)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.secondary)
                    .frame(height: shadeHeight * CGFloat(position) / 100)
            }
            .clipShape(shape)
            .overlay { shape.stroke(theme.border, lineWidth: theme.metrics.borderWidth) }
            .accessibilityHidden(true)
    }

    private var sliderRow: some View {
        HStack(spacing: theme.metrics.standardSpacing) {
            Text("Open")
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Slider(value: $position, in: 0...100)
                .accessibilityLabel("Shade position")
                .accessibilityValue(Text(position / 100, format: .percent.precision(.fractionLength(0))))
            Text("Close")
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
    }

    private enum Preset: String, CaseIterable, Identifiable {
        case open, half, closed

        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .open: "Open"
            case .half: "Half"
            case .closed: "Closed"
            }
        }

        var position: Double {
            switch self {
            case .open: 0
            case .half: 50
            case .closed: 100
            }
        }
    }
}

#if DEBUG
#Preview("Roller Shades") {
    ScrollView { RollerShades().padding() }
        .registryTheme(.indigo)
}

#Preview("Roller Shades Dark") {
    ScrollView { RollerShades().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
