import SwiftUI
import SweetUIFoundations

// Each demo renders the item's real `usage` snippet (plus its other variants)
// against the installed registry source, on the registry surface.

struct ToastDemo: View {
    // A toast is present on launch with a long duration so the capture route
    // photographs it; the buttons present the other variants on demand.
    @State private var toast: RegistryToast? = RegistryToast(
        title: "Card frozen",
        message: "Unfreeze it any time from the card's settings.",
        variant: .positive,
        action: RegistryToast.Action(label: "Undo") {}
    )

    var body: some View {
        DemoSurface {
            DemoRow {
                Button("Status") {
                    toast = RegistryToast(
                        title: "Statement ready",
                        message: "August 2026 is available to download."
                    )
                }
                .buttonStyle(.registry)
                .accessibilityLabel("Show status toast")

                Button("Success") {
                    toast = RegistryToast(
                        title: "Import complete",
                        message: "124 transactions were added.",
                        variant: .positive
                    )
                }
                .buttonStyle(.registrySecondary)
                .accessibilityLabel("Show success toast")

                Button("Error") {
                    toast = RegistryToast(
                        title: "Payment failed",
                        message: "The card on file was declined.",
                        variant: .destructive,
                        action: RegistryToast.Action(label: "Retry") {}
                    )
                }
                .buttonStyle(.registryOutline)
                .accessibilityLabel("Show error toast")
            }
        }
        .frame(minHeight: 280, alignment: .top)
        .registryToast($toast, duration: .seconds(3600))
    }
}

struct AttachmentDemo: View {
    @Environment(\.registryTheme) private var theme

    var body: some View {
        DemoSurface {
            AttachmentRow(
                name: Text("Statement-Aug-2026.pdf"),
                detail: Text("PDF document, 1.2 MB"),
                state: .uploading(progress: 0.68)
            ) {
                thumbnail("doc.fill")
            } actions: {
                Button("Cancel", systemImage: "xmark") {}
                    .labelStyle(.iconOnly)
                    .buttonStyle(.registryGhost)
                    .controlSize(.small)
                    .accessibilityLabel("Cancel upload")
            }

            AttachmentRow(
                name: Text("Receipt.heic"),
                detail: Text("Image, 3.4 MB"),
                state: .processing,
                thumbnail: { thumbnail("photo.fill") }
            )

            AttachmentRow(
                name: Text("Contract.docx"),
                detail: Text("Word document, 84 KB"),
                state: .failed("Upload failed. Check your connection.")
            ) {
                thumbnail("doc.text.fill")
            } actions: {
                Button("Retry") {}
                    .buttonStyle(.registryOutline)
                    .controlSize(.small)
                    .accessibilityLabel("Retry upload")
            }

            AttachmentRow(
                name: Text("Logo.png"),
                detail: Text("Image, 512 KB"),
                state: .completed,
                thumbnail: { thumbnail("photo.fill") }
            )

            AttachmentRow(
                name: Text("Notes.txt"),
                detail: Text("Text file, 2 KB"),
                thumbnail: { thumbnail("doc.plaintext.fill") }
            )
        }
    }

    private func thumbnail(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.surface)
            .accessibilityHidden(true)
    }
}

struct MarkerDemo: View {
    var body: some View {
        DemoSurface {
            Text("Today")
                .registryMarker(.separator)

            Text("Maya joined the conversation")
                .registryMarker()

            Text("Your card was frozen by support")
                .registryMarker(.note)

            Text("Delivered 09:41")
                .registryMarker(.status)
        }
    }
}
