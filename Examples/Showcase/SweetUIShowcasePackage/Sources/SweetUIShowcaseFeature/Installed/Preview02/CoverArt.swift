import SwiftUI
import SweetUIFoundations

/// A cover-art uploader, translated from shadcn's cover-art: a square artwork
/// slot, an upload action, and a spec note. shadcn shows a fetched image and a
/// hidden file input; this draws a themed placeholder (a rounded square on the
/// content surface with an SF Symbol) and opens a native fileImporter from a
/// registry button. The importer result is not handled beyond dismissal.
public struct CoverArt: View {
    @Environment(\.registryTheme) private var theme
    @State private var isImporting = false

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                placeholder

                Button("Upload artwork") { isImporting = true }
                    .buttonStyle(.registrySecondary)
                    .frame(maxWidth: .infinity)

                Text("Minimum 3000 × 3000 px. JPEG or PNG only.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        } label: {
            Text("Cover Art")
        }
        .groupBoxStyle(.registryCard)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.jpeg, .png]
        ) { _ in }
    }

    private var placeholder: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)

        return shape
            .fill(theme.surface)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .overlay {
                shape.strokeBorder(
                    theme.border,
                    style: StrokeStyle(
                        lineWidth: theme.metrics.borderWidth,
                        dash: [theme.metrics.compactSpacing, theme.metrics.compactSpacing / 2]
                    )
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Cover art placeholder")
    }
}

#if DEBUG
#Preview("Cover Art") {
    ScrollView { CoverArt().padding() }
        .registryTheme(.indigo)
}

#Preview("Cover Art Dark") {
    ScrollView { CoverArt().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
