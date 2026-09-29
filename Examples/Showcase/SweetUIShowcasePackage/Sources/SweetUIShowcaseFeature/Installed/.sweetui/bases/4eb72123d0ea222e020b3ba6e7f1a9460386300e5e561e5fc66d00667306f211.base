import SwiftUI
import SweetUIFoundations
import UniformTypeIdentifiers

/// File upload, translated from shadcn's file-upload: a drop zone drawn with
/// theme tokens around an upload prompt, and a native `fileImporter` opened
/// from a registry button. The importer's result is not handled beyond
/// dismissal; the card owns only the transient presentation flag.
public struct FileUpload: View {
    @Environment(\.registryTheme) private var theme
    @State private var isImporting = false

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                Text("Drag and drop or browse")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                dropZone
            }
        } label: {
            Text("File Upload")
        }
        .groupBoxStyle(.registryCard)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.image, .pdf]
        ) { _ in }
    }

    private var dropZone: some View {
        let shape = RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous)

        return VStack(spacing: theme.metrics.compactSpacing) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Upload files")
                .font(.subheadline.weight(.medium))

            Text("PNG, JPG, PDF up to 10MB")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Browse files") { isImporting = true }
                .buttonStyle(.registry)
                .controlSize(.small)
                .padding(.top, theme.metrics.compactSpacing)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.metrics.sectionSpacing)
        .background(theme.surface, in: shape)
        .overlay {
            shape.strokeBorder(
                theme.border,
                style: StrokeStyle(
                    lineWidth: theme.metrics.borderWidth,
                    dash: [theme.metrics.compactSpacing, theme.metrics.compactSpacing / 2]
                )
            )
        }
    }
}

#if DEBUG
#Preview("File Upload") {
    ScrollView { FileUpload().padding() }
        .registryTheme(.indigo)
}

#Preview("File Upload Dark") {
    ScrollView { FileUpload().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
