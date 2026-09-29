import SwiftUI
import SweetUIFoundations

public enum RegistryProgressTone: Sendable {
    case accent
    case positive
    case negative
}

/// A linear treatment for native determinate and indeterminate `ProgressView` controls.
public struct RegistryProgressViewStyle: ProgressViewStyle {
    @Environment(\.registryTheme) private var theme

    private let tone: RegistryProgressTone

    public init(_ tone: RegistryProgressTone = .accent) {
        self.tone = tone
    }

    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            if let label = configuration.label {
                label.font(.subheadline.weight(.medium))
            }

            if let fraction = configuration.fractionCompleted {
                tinted(ProgressView(value: fraction).progressViewStyle(.linear))
            } else {
                tinted(ProgressView().progressViewStyle(.linear))
            }

            if let currentValueLabel = configuration.currentValueLabel {
                currentValueLabel
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .registryItem("progress")
    }

    /// Applies an explicit tint only for the positive/negative tones. The
    /// accent tone deliberately leaves `.tint` untouched: re-declaring it as
    /// `TintShapeStyle()` (i.e. "tint equals the ambient tint") is a
    /// self-referential `ShapeStyle` that recurses without terminating when
    /// SwiftUI resolves it.
    @ViewBuilder
    private func tinted<V: View>(_ view: V) -> some View {
        switch tone {
        case .accent:
            view
        case .positive:
            view.tint(theme.positive)
        case .negative:
            view.tint(theme.negative)
        }
    }
}

public extension ProgressViewStyle where Self == RegistryProgressViewStyle {
    static var registryLinear: RegistryProgressViewStyle { RegistryProgressViewStyle() }
    static var registryLinearPositive: RegistryProgressViewStyle { RegistryProgressViewStyle(.positive) }
    static var registryLinearNegative: RegistryProgressViewStyle { RegistryProgressViewStyle(.negative) }
}

private struct RegistryProgressViewStylePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: 0.68) {
                Text("Uploading")
            } currentValueLabel: {
                Text("68 percent")
            }
            ProgressView("Preparing files")

            ProgressView(value: 1) {
                Text("Import complete")
            }
            .progressViewStyle(.registryLinearPositive)

            ProgressView(value: 0.32) {
                Text("Upload interrupted")
            }
            .progressViewStyle(.registryLinearNegative)
        }
        .progressViewStyle(.registryLinear)
        .padding()
    }
}

#Preview("Progress") {
    RegistryProgressViewStylePreview().tint(.indigo)
}

#Preview("Progress Dark") {
    RegistryProgressViewStylePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Progress Right to Left") {
    RegistryProgressViewStylePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Progress Accessibility Size") {
    RegistryProgressViewStylePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
