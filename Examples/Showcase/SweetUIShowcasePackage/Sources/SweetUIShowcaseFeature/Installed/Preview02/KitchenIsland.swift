import SwiftUI
import SweetUIFoundations

/// A smart-lighting scene controller, translated from shadcn's kitchen-island:
/// a power switch, a scene selector, and four labeled sliders. shadcn uses its
/// toggle-group, switch, and slider primitives; this keeps a native segmented
/// Picker, a native Toggle, and native Sliders visible at the call site, all
/// disabled while the fixture is off. Selecting a scene sets the four values.
/// The fixture name is invented, so the card names no brand.
public struct KitchenIsland: View {
    @Environment(\.registryTheme) private var theme
    @State private var isOn = true
    @State private var scene: Scene = .cooking
    @State private var brightness: Double = 90
    @State private var colorTemperature: Double = 70
    @State private var volume: Double = 30
    @State private var fade: Double = 0

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Lumen Color Ambient")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker("Lighting scene", selection: $scene) {
                    ForEach(Scene.allCases) { scene in
                        Text(scene.title).tag(scene)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel("Lighting scene")
                .disabled(!isOn)

                controls
            }
        } label: {
            HStack {
                Text("Kitchen Island")
                Spacer()
                Toggle("Lights", isOn: $isOn)
                    .labelsHidden()
                    .accessibilityLabel("Lights")
            }
        }
        .groupBoxStyle(.registryCard)
        .onChange(of: scene) { _, newValue in
            let preset = newValue.preset
            brightness = preset.brightness
            colorTemperature = preset.colorTemperature
            volume = preset.volume
            fade = preset.fade
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            SliderRow(title: "Brightness", systemImage: "sun.max.fill", value: $brightness, isEnabled: isOn)
            Divider().registrySeparator()
            SliderRow(title: "Color temperature", systemImage: "thermometer.medium", value: $colorTemperature, isEnabled: isOn)
            Divider().registrySeparator()
            SliderRow(title: "Volume", systemImage: "speaker.wave.2.fill", value: $volume, isEnabled: isOn)
            Divider().registrySeparator()
            SliderRow(title: "Fade", systemImage: "timer", value: $fade, isEnabled: isOn)
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }

    private struct SliderRow: View {
        @Environment(\.registryTheme) private var theme
        let title: LocalizedStringResource
        let systemImage: String
        @Binding var value: Double
        let isEnabled: Bool

        var body: some View {
            HStack(spacing: theme.metrics.standardSpacing) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline)
                    .fixedSize()
                Slider(value: $value, in: 0...100)
                    .accessibilityLabel(Text(title))
                    .disabled(!isEnabled)
            }
            .frame(minHeight: RegistryMetrics.minimumHitSize)
        }
    }

    private enum Scene: String, CaseIterable, Identifiable {
        case cooking, dining, nightlight, focus

        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .cooking: "Cooking"
            case .dining: "Dining"
            case .nightlight: "Nightlight"
            case .focus: "Focus"
            }
        }

        var preset: ScenePreset {
            switch self {
            case .cooking: ScenePreset(brightness: 90, colorTemperature: 70, volume: 30, fade: 0)
            case .dining: ScenePreset(brightness: 50, colorTemperature: 40, volume: 20, fade: 60)
            case .nightlight: ScenePreset(brightness: 15, colorTemperature: 20, volume: 0, fade: 80)
            case .focus: ScenePreset(brightness: 100, colorTemperature: 85, volume: 0, fade: 0)
            }
        }
    }

    private struct ScenePreset {
        let brightness: Double
        let colorTemperature: Double
        let volume: Double
        let fade: Double
    }
}

#if DEBUG
#Preview("Kitchen Island") {
    ScrollView { KitchenIsland().padding() }
        .registryTheme(.indigo)
}

#Preview("Kitchen Island Dark") {
    ScrollView { KitchenIsland().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
