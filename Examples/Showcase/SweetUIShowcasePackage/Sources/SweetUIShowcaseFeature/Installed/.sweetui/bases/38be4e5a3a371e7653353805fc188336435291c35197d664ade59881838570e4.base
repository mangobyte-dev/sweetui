import SwiftUI
import SweetUIFoundations

/// The upload lifecycle of an ``AttachmentRow``. Every state names itself in
/// text, so progress and outcome never rest on color or a bar alone.
public enum AttachmentState: Sendable, Equatable {
    case idle
    case uploading(progress: Double)
    case processing
    case failed(LocalizedStringResource)
    case completed
}

/// A file or image attachment row: leading media clipped to a square, a name
/// with optional detail, caller-owned trailing actions, and a state line that
/// reports the upload lifecycle underneath. It composes ``ItemRow`` so the
/// title and detail hierarchy, spacing, and minimum row height stay shared.
public struct AttachmentRow<Thumbnail: View, Actions: View>: View {
    @Environment(\.registryTheme) private var theme

    private let name: Text
    private let detail: Text?
    private let state: AttachmentState
    private let thumbnail: Thumbnail
    private let actions: Actions

    public init(
        name: Text,
        detail: Text? = nil,
        state: AttachmentState = .idle,
        @ViewBuilder thumbnail: () -> Thumbnail,
        @ViewBuilder actions: () -> Actions
    ) {
        self.name = name
        self.detail = detail
        self.state = state
        self.thumbnail = thumbnail()
        self.actions = actions()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            ItemRow(title: name, description: detail) {
                thumbnail
                    .frame(width: 44, height: 44)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: theme.metrics.controlRadius,
                            style: .continuous
                        )
                    )
            } accessory: {
                actions
            }

            stateLine
        }
        .registryItem("attachment")
    }

    @ViewBuilder
    private var stateLine: some View {
        switch state {
        case .idle:
            EmptyView()

        case let .uploading(progress):
            HStack(spacing: theme.metrics.compactSpacing) {
                ProgressView(value: progress)
                    .progressViewStyle(.registryLinear)
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    // The bar already reports its value; the digits are visual.
                    .accessibilityHidden(true)
            }

        case .processing:
            HStack(spacing: theme.metrics.compactSpacing) {
                ProgressView()
                    .controlSize(.small)
                Text("Processing")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

        case let .failed(message):
            Label {
                Text(message)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .font(.footnote)
            .foregroundStyle(theme.negative)

        case .completed:
            Label {
                Text("Uploaded")
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .font(.footnote)
            .foregroundStyle(theme.positive)
        }
    }
}

public extension AttachmentRow where Thumbnail == EmptyView {
    /// A bare trailing closure resolves to the thumbnail initializer; name the
    /// `actions:` closure to reach this one.
    @_disfavoredOverload
    init(
        name: Text,
        detail: Text? = nil,
        state: AttachmentState = .idle,
        @ViewBuilder actions: () -> Actions
    ) {
        self.init(
            name: name,
            detail: detail,
            state: state,
            thumbnail: { EmptyView() },
            actions: actions
        )
    }
}

public extension AttachmentRow where Actions == EmptyView {
    init(
        name: Text,
        detail: Text? = nil,
        state: AttachmentState = .idle,
        @ViewBuilder thumbnail: () -> Thumbnail
    ) {
        self.init(
            name: name,
            detail: detail,
            state: state,
            thumbnail: thumbnail,
            actions: { EmptyView() }
        )
    }
}

public extension AttachmentRow where Thumbnail == EmptyView, Actions == EmptyView {
    init(
        name: Text,
        detail: Text? = nil,
        state: AttachmentState = .idle
    ) {
        self.init(
            name: name,
            detail: detail,
            state: state,
            thumbnail: { EmptyView() },
            actions: { EmptyView() }
        )
    }
}

private struct AttachmentRowPreview: View {
    @Environment(\.registryTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            AttachmentRow(
                name: Text("Statement-Aug-2026.pdf"),
                detail: Text("PDF document, 1.2 MB"),
                state: .uploading(progress: 0.68)
            ) {
                thumbnail("doc.fill")
            } actions: {
                Button("Cancel upload", systemImage: "xmark") {}
                    .labelStyle(.iconOnly)
                    .buttonStyle(.registryGhost)
                    .controlSize(.small)
                    .accessibilityLabel("Cancel upload")
            }

            Divider().registrySeparator()

            AttachmentRow(
                name: Text("Receipt.heic"),
                detail: Text("Image, 3.4 MB"),
                state: .processing,
                thumbnail: { thumbnail("photo.fill") }
            )

            Divider().registrySeparator()

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

            Divider().registrySeparator()

            AttachmentRow(
                name: Text("Logo.png"),
                detail: Text("Image, 512 KB"),
                state: .completed,
                thumbnail: { thumbnail("photo.fill") }
            )

            Divider().registrySeparator()

            AttachmentRow(
                name: Text("Notes.txt"),
                detail: Text("Text file, 2 KB"),
                state: .idle,
                thumbnail: { thumbnail("doc.plaintext.fill") }
            )
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .padding(.vertical, theme.metrics.compactSpacing)
        .registrySurface()
        .padding()
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

#Preview("Attachment Row") {
    AttachmentRowPreview().tint(.indigo)
}

#Preview("Attachment Row Dark") {
    AttachmentRowPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Attachment Row Right to Left") {
    AttachmentRowPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Attachment Row Accessibility Size") {
    AttachmentRowPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
