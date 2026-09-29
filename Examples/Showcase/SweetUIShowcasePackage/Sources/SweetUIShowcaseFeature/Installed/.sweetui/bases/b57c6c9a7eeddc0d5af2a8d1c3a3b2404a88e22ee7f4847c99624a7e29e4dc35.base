import Foundation
import SwiftUI
import SweetUIFoundations

/// Prepared display data for one row in ``ActivityFeed``.
public struct ActivityItem<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: Text
    public let detail: Text
    public let timestamp: Text
    public let image: Image?
    public let initials: String?
    public let senderName: Text
    public let isUnread: Bool

    /// - Parameters:
    ///   - senderName: The accessibility label for the avatar; a monogram cannot be read aloud.
    ///   - isUnread: Rendered with a heavier title, a leading dot, and an accessibility value.
    public init(
        id: ID,
        title: Text,
        detail: Text,
        timestamp: Text,
        image: Image? = nil,
        initials: String? = nil,
        senderName: Text,
        isUnread: Bool = false
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.timestamp = timestamp
        self.image = image
        self.initials = initials
        self.senderName = senderName
        self.isUnread = isUnread
    }
}

/// A caller-prepared status shown above the feed as an inline alert.
public struct ActivityNotice {
    public let title: LocalizedStringResource
    public let message: Text?
    public let variant: InlineAlertVariant

    public init(
        _ title: LocalizedStringResource,
        message: Text? = nil,
        variant: InlineAlertVariant = .informational
    ) {
        self.title = title
        self.message = message
        self.variant = variant
    }
}

/// A source-owned activity feed composing the inline alert, avatar, item row,
/// skeleton, empty state, and accordion treatments. The caller owns loading,
/// the items, the notice, and selection; the native `DisclosureGroup` owns its
/// transient expansion. It does not own a `ScrollView`, navigation container,
/// or maximum width. Unread rows carry a heavier title, a dot, and an Unread
/// accessibility value, so the state never rests on color alone.
public struct ActivityFeed<ID: Hashable>: View {
    @Environment(\.registryTheme) private var theme
    @ScaledMetric(relativeTo: .caption) private var unreadDotSize: CGFloat = 8

    private let title: LocalizedStringResource
    private let notice: ActivityNotice?
    private let onDismissNotice: (() -> Void)?
    private let sectionTitle: LocalizedStringResource
    private let items: [ActivityItem<ID>]
    private let earlierTitle: LocalizedStringResource
    private let earlierItems: [ActivityItem<ID>]
    private let isLoading: Bool
    private let emptyTitle: LocalizedStringResource
    private let emptyDescription: Text?
    private let onSelect: (ID) -> Void

    public init(
        _ title: LocalizedStringResource,
        notice: ActivityNotice? = nil,
        onDismissNotice: (() -> Void)? = nil,
        sectionTitle: LocalizedStringResource = LocalizedStringResource("Recent", comment: "Header of the section listing the newest activity"),
        items: [ActivityItem<ID>],
        earlierTitle: LocalizedStringResource = LocalizedStringResource("Earlier", comment: "Header of the collapsible section listing older activity"),
        earlierItems: [ActivityItem<ID>] = [],
        isLoading: Bool = false,
        emptyTitle: LocalizedStringResource = "You're all caught up",
        emptyDescription: Text? = nil,
        onSelect: @escaping (ID) -> Void
    ) {
        self.title = title
        self.notice = notice
        self.onDismissNotice = onDismissNotice
        self.sectionTitle = sectionTitle
        self.items = items
        self.earlierTitle = earlierTitle
        self.earlierItems = earlierItems
        self.isLoading = isLoading
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.sectionSpacing) {
            Text(title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            if let notice {
                noticeView(notice)
            }

            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text(sectionTitle)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                if isLoading {
                    placeholderRows(placeholderItems)
                        .registrySkeleton(accessibilityLabel: "Loading activity")
                } else if items.isEmpty {
                    ContentUnavailableView(
                        emptyTitle,
                        systemImage: "tray",
                        description: emptyDescription
                    )
                    .registryEmptyState()
                } else {
                    rows(items)
                }
            }

            if !isLoading, !earlierItems.isEmpty {
                DisclosureGroup {
                    VStack(spacing: 0) {
                        ForEach(earlierItems) { item in
                            row(item)
                            if item.id != earlierItems.last?.id {
                                Divider().registrySeparator()
                            }
                        }
                    }
                } label: {
                    Text(earlierTitle)
                }
                .disclosureGroupStyle(.registryAccordion)
                .padding(.horizontal, theme.metrics.standardSpacing)
                .registrySurface()
            }
        }
        .registryItem("activity-feed")
    }

    private func noticeView(_ notice: ActivityNotice) -> some View {
        // One alert type whichever way the caller decides, so the notice
        // keeps its identity when a dismiss handler comes or goes.
        InlineAlert(notice.title, message: notice.message) {
            if let onDismissNotice {
                Button("Dismiss", action: onDismissNotice)
                    .buttonStyle(.registryGhost)
            }
        }
        .registryVariant(notice.variant)
    }

    private func rows(_ items: [ActivityItem<ID>]) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                row(item)
                if item.id != items.last?.id {
                    Divider().registrySeparator()
                }
            }
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }

    private func row(_ item: ActivityItem<ID>) -> some View {
        Button {
            onSelect(item.id)
        } label: {
            ItemRow(
                title: item.isUnread ? item.title.bold() : item.title,
                description: item.detail
            ) {
                Avatar(item.image, initials: item.initials, accessibilityLabel: item.senderName)
            } accessory: {
                HStack(spacing: theme.metrics.compactSpacing / 2) {
                    item.timestamp
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    if item.isUnread {
                        Circle()
                            .fill(.tint)
                            .frame(width: unreadDotSize, height: unreadDotSize)
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding(.vertical, theme.metrics.standardSpacing)
        }
        .buttonStyle(.plain)
        // Voice Control can name the row by its title alone.
        .accessibilityInputLabels([item.title])
        .accessibilityValue(
            item.isUnread
                ? Text("Unread", comment: "Accessibility value spoken after an activity row the user has not read")
                : Text(verbatim: "")
        )
    }

    /// Stable placeholder rows for the skeleton; ids never collide with caller ids
    /// because the placeholder list is rendered instead of, not alongside, the items.
    private var placeholderItems: [ActivityItem<Int>] {
        (0..<3).map { index in
            ActivityItem(
                id: index,
                title: Text(verbatim: "Placeholder activity title"),
                detail: Text(verbatim: "Placeholder detail that spans one line"),
                timestamp: Text(verbatim: "00:00"),
                initials: "··",
                senderName: Text(verbatim: "Placeholder")
            )
        }
    }

    private func placeholderRows(_ items: [ActivityItem<Int>]) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                ItemRow(title: item.title, description: item.detail) {
                    Avatar(initials: item.initials, accessibilityLabel: item.senderName)
                } accessory: {
                    item.timestamp
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, theme.metrics.standardSpacing)
                if item.id != items.last?.id {
                    Divider().registrySeparator()
                }
            }
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
    }
}

#if DEBUG
private struct ActivityFeedPreview: View {
    var isLoading = false
    var isEmpty = false
    var showNotice = true

    var body: some View {
        ScrollView {
            ActivityFeed(
                "Activity",
                notice: showNotice
                    ? ActivityNotice(
                        "Card delivery delayed",
                        message: Text("Your new card now arrives on Thursday.")
                    )
                    : nil,
                onDismissNotice: {},
                items: isEmpty ? [] : [
                    ActivityItem(
                        id: "bakery",
                        title: Text("Mishmash Bakery"),
                        detail: Text("Card payment of KWD 8.750"),
                        timestamp: Text("09:41"),
                        initials: "MB",
                        senderName: Text("Mishmash Bakery"),
                        isUnread: true
                    ),
                    ActivityItem(
                        id: "salary",
                        title: Text("Salary received"),
                        detail: Text("KWD 2,450.000 from Harbor Bank"),
                        timestamp: Text("Yesterday"),
                        initials: "HB",
                        senderName: Text("Harbor Bank")
                    ),
                    ActivityItem(
                        id: "statement",
                        title: Text("Statement ready"),
                        detail: Text("August 2026"),
                        timestamp: Text("Monday"),
                        initials: "ST",
                        senderName: Text("Statements")
                    )
                ],
                earlierItems: isEmpty ? [] : [
                    ActivityItem(
                        id: "mobile",
                        title: Text("Mobile service"),
                        detail: Text("Card payment of KWD 18.000"),
                        timestamp: Text("28 Aug"),
                        initials: "MS",
                        senderName: Text("Mobile service")
                    )
                ],
                isLoading: isLoading,
                emptyDescription: Text("New activity will appear here."),
                onSelect: { _ in }
            )
            .padding()
        }
    }
}

#Preview("Activity Feed") {
    ActivityFeedPreview()
}

#Preview("Activity Feed Loading") {
    ActivityFeedPreview(isLoading: true)
}

#Preview("Activity Feed Empty") {
    ActivityFeedPreview(isEmpty: true, showNotice: false)
}

#Preview("Activity Feed Dark") {
    ActivityFeedPreview().preferredColorScheme(.dark)
}

#Preview("Activity Feed Right to Left") {
    ActivityFeedPreview().environment(\.layoutDirection, .rightToLeft)
}

#Preview("Activity Feed Accessibility Size") {
    ActivityFeedPreview().environment(\.dynamicTypeSize, .accessibility3)
}
#endif
