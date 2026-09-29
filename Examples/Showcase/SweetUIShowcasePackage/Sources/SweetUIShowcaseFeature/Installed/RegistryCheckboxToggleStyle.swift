import SwiftUI
import SweetUIFoundations

/// A checkbox treatment for a native SwiftUI `Toggle` binding and label.
public struct RegistryCheckboxToggleStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.registryTheme) private var theme
    // The box scales with the label's text so it never shrinks beside large type.
    @ScaledMetric(relativeTo: .body) private var boxSize: CGFloat = 22

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: theme.metrics.compactSpacing) {
                checkbox(configuration: configuration)
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: RegistryMetrics.minimumHitSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The plain style carries no pointer effect on iPad; ask for the automatic one.
        .hoverEffect()
        .opacity(isEnabled ? 1 : theme.disabledOpacity)
        .accessibilityRepresentation {
            Toggle(configuration)
                .toggleStyle(.switch)
        }
        .registryItem("checkbox")
    }

    private func checkbox(configuration: Configuration) -> some View {
        let isSelected = configuration.isOn || configuration.isMixed
        let shape = RoundedRectangle(cornerRadius: theme.metrics.compactRadius, style: .continuous)

        return Image(systemName: configuration.isMixed ? "minus" : "checkmark")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.tint)
            .opacity(isSelected ? 1 : 0)
            .frame(width: boxSize, height: boxSize)
            .background(TintShapeStyle().opacity(isSelected ? 0.16 : 0), in: shape)
            .overlay {
                shape.stroke(
                    isSelected ? AnyShapeStyle(TintShapeStyle()) : AnyShapeStyle(theme.border),
                    lineWidth: theme.metrics.borderWidth
                )
            }
            .accessibilityHidden(true)
    }
}

public extension ToggleStyle where Self == RegistryCheckboxToggleStyle {
    static var registryCheckbox: RegistryCheckboxToggleStyle { RegistryCheckboxToggleStyle() }
}

private struct RegistryCheckboxToggleStylePreview: View {
    private struct Channel: Identifiable {
        let id: String
        var isOn: Bool
    }

    @State private var accepted = true
    @State private var updates = false
    @State private var channels = [
        Channel(id: "push", isOn: true),
        Channel(id: "email", isOn: false)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Accept terms", isOn: $accepted)
            Toggle("Product updates", isOn: $updates)
            // Mixed state: a select-all row over channels that disagree.
            Toggle(sources: $channels, isOn: \.isOn) {
                Text("All channels")
            }
            Toggle("Unavailable option", isOn: .constant(false))
                .disabled(true)
        }
        .toggleStyle(.registryCheckbox)
        .padding()
    }
}

#Preview("Checkbox") {
    RegistryCheckboxToggleStylePreview().tint(.indigo)
}

#Preview("Checkbox Dark") {
    RegistryCheckboxToggleStylePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Checkbox Right to Left") {
    RegistryCheckboxToggleStylePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Checkbox Accessibility Size") {
    RegistryCheckboxToggleStylePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
