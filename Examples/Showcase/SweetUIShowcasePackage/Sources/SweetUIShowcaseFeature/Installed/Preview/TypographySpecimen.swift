import SwiftUI
import SweetUIFoundations

/// A type specimen, the registry counterpart of shadcn's typography-specimen:
/// the system Dynamic Type styles from large title to caption 2, each named row
/// rendered in its own style so the ramp scales with the reader's text size.
public struct TypographySpecimen: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                Text("System text styles at the current Dynamic Type size.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(specimens) { specimen in
                    Text(specimen.name)
                        .font(specimen.font)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        } label: {
            Text("Typography")
        }
        .groupBoxStyle(.registryCard)
    }

    private struct Specimen: Identifiable {
        let id: String
        let name: LocalizedStringResource
        let font: Font
    }

    private let specimens: [Specimen] = [
        Specimen(id: "large-title", name: "Large Title", font: .largeTitle),
        Specimen(id: "title", name: "Title", font: .title),
        Specimen(id: "title2", name: "Title 2", font: .title2),
        Specimen(id: "title3", name: "Title 3", font: .title3),
        Specimen(id: "headline", name: "Headline", font: .headline),
        Specimen(id: "subheadline", name: "Subheadline", font: .subheadline),
        Specimen(id: "body", name: "Body", font: .body),
        Specimen(id: "callout", name: "Callout", font: .callout),
        Specimen(id: "footnote", name: "Footnote", font: .footnote),
        Specimen(id: "caption", name: "Caption", font: .caption),
        Specimen(id: "caption2", name: "Caption 2", font: .caption2),
    ]
}

#if DEBUG
#Preview("Typography Specimen") {
    ScrollView { TypographySpecimen().padding() }
        .registryTheme(.indigo)
}

#Preview("Typography Specimen Dark") {
    ScrollView { TypographySpecimen().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
