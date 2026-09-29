import SwiftUI
import SweetUIFoundations

/// A chat scroll container. It starts pinned to the newest turn, keeps the
/// newest turn visible while the reader stays at the bottom, leaves a reader who
/// scrolled up in place when new turns stream in, asks the caller to load
/// history when the reader reaches the top, and keeps the visible turns in
/// place while that history is prepended. The reader's position and the
/// following state stay with the caller through bindings.
public struct MessageScroller<ID: Hashable & Sendable, Content: View>: View {
    @Environment(\.registryTheme) private var theme

    @Binding private var position: ID?
    @Binding private var isFollowing: Bool
    private let onReachTop: (() -> Void)?
    private let content: Content

    // The content height that last fired onReachTop, so history loads once per
    // height: a prepend grows the content and re-arms the request.
    @State private var lastReachTopHeight: CGFloat?
    // True from a history request until the content grows, so the prepend
    // anchors to the bottom and the turns the reader was looking at stay put.
    @State private var isLoadingHistory = false

    /// Points from the content bottom within which the reader counts as following.
    private let followThreshold: CGFloat = 8
    /// Points from the content top within which a history load is requested.
    private let reachTopThreshold: CGFloat = 40

    /// - Parameters:
    ///   - position: The message id to scroll to; the container writes it back as the reader scrolls.
    ///   - isFollowing: True while the reader is at the bottom; the container keeps this current.
    ///   - onReachTop: Called once per content height when the reader nears the top, to load history.
    ///   - content: The rows, each carrying a stable `.id`, laid out newest last.
    public init(
        position: Binding<ID?>,
        isFollowing: Binding<Bool>,
        onReachTop: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._position = position
        self._isFollowing = isFollowing
        self.onReachTop = onReachTop
        self.content = content()
    }

    public var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: theme.metrics.compactSpacing) {
                content
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $position, anchor: .bottom)
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(isFollowing || isLoadingHistory ? .bottom : .top, for: .sizeChanges)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            isNearBottom(geometry)
        } action: { _, nearBottom in
            if isFollowing != nearBottom {
                isFollowing = nearBottom
            }
        }
        .onScrollGeometryChange(for: ReachTopState.self) { geometry in
            ReachTopState(
                isNearTop: isNearTop(geometry),
                contentHeight: geometry.contentSize.height
            )
        } action: { old, state in
            if isLoadingHistory, state.contentHeight > old.contentHeight {
                isLoadingHistory = false
            }
            guard let onReachTop, state.isNearTop else { return }
            guard lastReachTopHeight != state.contentHeight else { return }
            lastReachTopHeight = state.contentHeight
            isLoadingHistory = true
            onReachTop()
        }
        .registryItem("message-scroller")
    }

    private func isNearBottom(_ geometry: ScrollGeometry) -> Bool {
        let visibleBottom = geometry.contentOffset.y + geometry.containerSize.height
        return geometry.contentSize.height - visibleBottom <= followThreshold
    }

    private func isNearTop(_ geometry: ScrollGeometry) -> Bool {
        // At the top the content offset equals the negative top inset.
        geometry.contentOffset.y + geometry.contentInsets.top <= reachTopThreshold
    }
}

// The transform value for the top-reach observer: history loads once per
// content height, so the height rides along with the near-top flag.
private struct ReachTopState: Equatable {
    var isNearTop: Bool
    var contentHeight: CGFloat
}

private struct MessageScrollerPreview: View {
    @State private var position: Int?
    @State private var isFollowing = true

    var body: some View {
        MessageScroller(position: $position, isFollowing: $isFollowing) {
            ForEach(0 ..< 12, id: \.self) { index in
                messageRow(index)
                    .id(index)
            }
        }
        .frame(height: 360)
        .padding()
    }

    @ViewBuilder
    private func messageRow(_ index: Int) -> some View {
        if index.isMultiple(of: 3) {
            MessageRow {
                Avatar(initials: "OA", accessibilityLabel: Text(verbatim: "Omar Ali"))
            } content: {
                Text("Message number \(index + 1) in the thread.")
            }
        } else if index.isMultiple(of: 2) {
            MessageRow {
                Text("Reply number \(index + 1).")
            }
            .registryVariant(.outgoing)
        } else {
            MessageRow(author: Text(verbatim: "Omar Ali")) {
                Avatar(initials: "OA", accessibilityLabel: Text(verbatim: "Omar Ali"))
            } content: {
                Text("Another line, number \(index + 1).")
            }
        }
    }
}

#Preview("Message Scroller") {
    MessageScrollerPreview().tint(.indigo)
}

#Preview("Message Scroller Dark") {
    MessageScrollerPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Message Scroller Right to Left") {
    MessageScrollerPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Message Scroller Accessibility Size") {
    MessageScrollerPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
