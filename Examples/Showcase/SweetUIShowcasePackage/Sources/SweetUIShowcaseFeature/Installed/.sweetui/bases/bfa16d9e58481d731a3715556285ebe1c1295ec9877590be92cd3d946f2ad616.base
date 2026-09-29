import SwiftUI
import SweetUIFoundations

/// The conversational side of a ``MessageRow``. An incoming turn sits leading
/// with its avatar; an outgoing turn sits trailing with no avatar.
public enum MessageRowVariant: Sendable {
    case incoming
    case outgoing
}

/// One turn in a conversation: an optional header (author and timestamp), the
/// message content in a bubble, and an optional status line. The row owns
/// alignment, the header and status hierarchy, and the bubble treatment; the
/// caller owns the avatar and the message content.
public struct MessageRow<Avatar: View, Content: View>: View {
    @Environment(\.registryTheme) private var theme

    private let author: Text?
    private let timestamp: Text?
    private let status: Text?
    private var variant: MessageRowVariant = .incoming
    private let avatar: Avatar
    private let content: Content

    /// - Parameters:
    ///   - author: Optional name shown in the header above the bubble.
    ///   - timestamp: Optional time shown beside the author.
    ///   - status: Optional delivery line shown under the bubble, such as "Delivered".
    ///   - avatar: The caller-owned avatar, shown only for an incoming turn.
    ///   - content: The message content placed inside the bubble.
    public init(
        author: Text? = nil,
        timestamp: Text? = nil,
        status: Text? = nil,
        @ViewBuilder avatar: () -> Avatar,
        @ViewBuilder content: () -> Content
    ) {
        self.author = author
        self.timestamp = timestamp
        self.status = status
        self.avatar = avatar()
        self.content = content()
    }

    /// Sets the conversational side. Defaults to incoming.
    public func registryVariant(_ variant: MessageRowVariant) -> Self {
        var copy = self
        copy.variant = variant
        return copy
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: theme.metrics.compactSpacing) {
            switch variant {
            case .incoming:
                avatar
                column
                Spacer(minLength: 0)
            case .outgoing:
                Spacer(minLength: 0)
                column
            }
        }
        .registryItem("message")
    }

    private var columnAlignment: HorizontalAlignment {
        variant == .incoming ? .leading : .trailing
    }

    private var column: some View {
        VStack(alignment: columnAlignment, spacing: theme.metrics.compactSpacing / 2) {
            // The header and the bubble read as one turn for plain text
            // content. When the content holds controls, switch this to
            // .contain at the call site so buttons stay activatable.
            VStack(alignment: columnAlignment, spacing: theme.metrics.compactSpacing / 2) {
                header
                content.registryBubble(variant == .incoming ? .incoming : .outgoing)
            }
            .accessibilityElement(children: .combine)

            if let status {
                status
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        // A turn never fills the row: cap the column so a long message wraps.
        .frame(maxWidth: 320, alignment: variant == .incoming ? .leading : .trailing)
    }

    @ViewBuilder
    private var header: some View {
        if author != nil || timestamp != nil {
            HStack(spacing: theme.metrics.compactSpacing) {
                if let author {
                    author.font(.caption.weight(.semibold))
                }
                if let timestamp {
                    timestamp
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

public extension MessageRow where Avatar == EmptyView {
    /// A turn with no avatar, the common shape for an outgoing message.
    init(
        author: Text? = nil,
        timestamp: Text? = nil,
        status: Text? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            author: author,
            timestamp: timestamp,
            status: status,
            avatar: { EmptyView() },
            content: content
        )
    }
}

private struct MessageRowPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            MessageRow(
                author: Text(verbatim: "Maya Khalid"),
                timestamp: Text(verbatim: "09:41"),
                status: Text("Delivered")
            ) {
                Avatar(initials: "MK", accessibilityLabel: Text(verbatim: "Maya Khalid"))
            } content: {
                Text("Are we still on for Thursday?")
            }

            MessageRow(timestamp: Text(verbatim: "09:42"), status: Text("Delivered")) {
                Text("Yes, 6pm works. I will bring the documents.")
            }
            .registryVariant(.outgoing)

            // A grouped pair: an incoming turn answered by an outgoing turn.
            VStack(spacing: 4) {
                MessageRow {
                    Avatar(initials: "OA", accessibilityLabel: Text(verbatim: "Omar Ali"))
                } content: {
                    Text("Should I book the room?")
                }
                MessageRow {
                    Text("Please do.")
                }
                .registryVariant(.outgoing)
            }
        }
        .padding()
    }
}

#Preview("Message Row") {
    MessageRowPreview().tint(.indigo)
}

#Preview("Message Row Dark") {
    MessageRowPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Message Row Right to Left") {
    MessageRowPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Message Row Accessibility Size") {
    MessageRowPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
