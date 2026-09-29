import Foundation
import SwiftUI
import SweetUIFoundations

/// A source-owned nutrition progress row with prepared display values.
public struct MacroProgress: View {
    @Environment(\.registryTheme) private var theme

    private let name: LocalizedStringResource
    private let value: Text
    private let target: Text
    private let progress: Double
    private let systemImage: String
    private var tint: Color = .accentColor

    public init(
        _ name: LocalizedStringResource,
        value: Text,
        target: Text,
        progress: Double,
        systemImage: String
    ) {
        self.name = name
        self.value = value
        self.target = target
        self.progress = progress
        self.systemImage = systemImage
    }

    /// Sets the progress tint. Defaults to the theme tint.
    public func registryTint(_ tint: Color) -> Self {
        var copy = self
        copy.tint = tint
        return copy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: theme.metrics.compactSpacing) {
                    Label(name, systemImage: systemImage)
                        .font(.headline)
                    Spacer(minLength: theme.metrics.standardSpacing)
                    MacroValue(value: value, target: target)
                }

                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    Label(name, systemImage: systemImage)
                        .font(.headline)
                    MacroValue(value: value, target: target)
                }
            }

            ProgressView(value: min(max(progress, 0), 1))
                .tint(tint)
        }
        .accessibilityElement(children: .combine)
        .registryItem("macro-progress")
    }
}

private struct MacroValue: View {
    let value: Text
    let target: Text

    var body: some View {
        // One localized phrase, so translators can reorder it.
        Text(
            "\(value.fontWeight(.semibold).foregroundStyle(.primary)) of \(target)",
            comment: "Progress toward a target: the first value is the amount so far, the second is the target"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

private struct MacroProgressPreview: View {
    var body: some View {
        MacroProgress(
            "Protein",
            value: Text(96, format: .number),
            target: Text(130, format: .number),
            progress: 96.0 / 130.0,
            systemImage: "fish.fill"
        )
        .registryTint(.indigo)
        .padding()
    }
}

#Preview("Macro Progress") {
    MacroProgressPreview()
}

#Preview("Macro Progress Dark") {
    MacroProgressPreview().preferredColorScheme(.dark)
}

#Preview("Macro Progress Accessibility Size") {
    MacroProgressPreview().dynamicTypeSize(.accessibility3)
}
