import SwiftUI
import SweetUIFoundations

/// A row-like treatment for native `DisclosureGroup`: a full-width header that
/// toggles expansion, a trailing chevron, and content revealed beneath a
/// hairline. The content keeps the caller's own styling. Stack several groups
/// with separators for an accordion.
public struct RegistryAccordionStyle: DisclosureGroupStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.registryTheme) private var theme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if reduceMotion {
                    configuration.isExpanded.toggle()
                } else {
                    withAnimation(.snappy) {
                        configuration.isExpanded.toggle()
                    }
                }
            } label: {
                HStack(spacing: theme.metrics.compactSpacing) {
                    configuration.label
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(configuration.isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.vertical, theme.metrics.standardSpacing)
                .frame(minHeight: RegistryMetrics.minimumHitSize)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // The plain style carries no pointer effect on iPad; ask for the automatic one.
            .hoverEffect()
            .accessibilityValue(
                configuration.isExpanded
                    ? Text("Expanded", comment: "VoiceOver value of an open accordion header; never drawn on screen")
                    : Text("Collapsed", comment: "VoiceOver value of a closed accordion header; never drawn on screen")
            )

            if configuration.isExpanded {
                configuration.content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, theme.metrics.standardSpacing)
            }
        }
        .registryItem("accordion")
    }
}

public extension DisclosureGroupStyle where Self == RegistryAccordionStyle {
    static var registryAccordion: RegistryAccordionStyle { RegistryAccordionStyle() }
}

private struct RegistryAccordionStylePreview: View {
    @Environment(\.registryTheme) private var theme
    @State private var isFirstExpanded = true
    @State private var isSecondExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            DisclosureGroup("Is my card contactless?", isExpanded: $isFirstExpanded) {
                Text("Yes. Hold it near the terminal until it confirms the payment.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider().registrySeparator()

            DisclosureGroup("How do I freeze my card?", isExpanded: $isSecondExpanded) {
                Text("Open the card, then choose Freeze. Unfreeze the same way.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .disclosureGroupStyle(.registryAccordion)
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
        .padding()
    }
}

#Preview("Accordion") {
    RegistryAccordionStylePreview().tint(.indigo)
}

#Preview("Accordion Dark") {
    RegistryAccordionStylePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Accordion Right to Left") {
    RegistryAccordionStylePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Accordion Accessibility Size") {
    RegistryAccordionStylePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
