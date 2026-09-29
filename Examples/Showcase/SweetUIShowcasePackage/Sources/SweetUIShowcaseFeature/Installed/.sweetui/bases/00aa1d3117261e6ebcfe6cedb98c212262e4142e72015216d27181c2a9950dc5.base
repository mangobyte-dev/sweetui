import SwiftUI
import SweetUIFoundations

/// One crumb in a ``Breadcrumb`` trail: a title and an optional action. A crumb
/// with an action is a link; the last crumb in the trail is always rendered as
/// the current page, whether or not it carries an action.
public struct BreadcrumbItem {
    public let title: Text
    public let action: (() -> Void)?

    public init(_ title: Text, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }
}

/// A horizontal navigation trail: links separated by chevrons, ending in the
/// current page. iOS has no native breadcrumb control, so this composition adds
/// the reusable treatment, layout-direction aware separators, and, when the
/// crumbs do not fit the available width, collapse of the middle crumbs into an
/// overflow menu. Native back navigation stays the primary path; a breadcrumb
/// is a secondary aid for wide layouts.
public struct Breadcrumb: View {
    @Environment(\.registryTheme) private var theme

    private let items: [BreadcrumbItem]

    public init(_ items: [BreadcrumbItem]) {
        self.items = items
    }

    public var body: some View {
        Group {
            if items.count > 2 {
                // Prefer the full trail, and collapse the middle crumbs into an
                // overflow menu only when the full trail does not fit the width.
                ViewThatFits(in: .horizontal) {
                    trail(fullTrail)
                    trail(collapsedTrail)
                }
            } else {
                trail(fullTrail)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Breadcrumb")
        .registryItem("breadcrumb")
    }

    private func trail(_ crumbs: [Segment]) -> some View {
        HStack(spacing: theme.metrics.compactSpacing) {
            // A trail is rebuilt whole on each update, so position is its
            // stable identity.
            ForEach(Array(crumbs.enumerated()), id: \.offset) { _, segment in
                switch segment.content {
                case let .crumb(item, isCurrent):
                    crumb(item, isCurrent: isCurrent)
                case .separator:
                    separator
                case let .overflow(middle):
                    overflowMenu(middle)
                }
            }
        }
    }

    @ViewBuilder
    private func crumb(_ item: BreadcrumbItem, isCurrent: Bool) -> some View {
        if isCurrent {
            item.title
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(.vertical, theme.metrics.compactSpacing / 2)
                .accessibilityAddTraits(.isHeader)
        } else if let action = item.action {
            Button(action: action) {
                item.title
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.vertical, theme.metrics.compactSpacing / 2)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // The plain style carries no pointer effect on iPad; ask for the automatic one.
            .hoverEffect()
        } else {
            item.title
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.vertical, theme.metrics.compactSpacing / 2)
        }
    }

    private var separator: some View {
        // chevron.forward mirrors automatically for a right-to-left layout.
        Image(systemName: "chevron.forward")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }

    private func overflowMenu(_ middle: [BreadcrumbItem]) -> some View {
        Menu {
            ForEach(Array(middle.enumerated()), id: \.offset) { _, item in
                Button {
                    item.action?()
                } label: {
                    item.title
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.vertical, theme.metrics.compactSpacing / 2)
        }
        .accessibilityLabel("Show more")
    }

    private var fullTrail: [Segment] {
        var segments: [Segment] = []
        for (index, item) in items.enumerated() {
            segments.append(Segment(.crumb(item, isCurrent: index == items.count - 1)))
            if index < items.count - 1 {
                segments.append(Segment(.separator))
            }
        }
        return segments
    }

    private var collapsedTrail: [Segment] {
        let middle = Array(items[1..<(items.count - 1)])
        return [
            Segment(.crumb(items[0], isCurrent: false)),
            Segment(.separator),
            Segment(.overflow(middle)),
            Segment(.separator),
            Segment(.crumb(items[items.count - 1], isCurrent: true)),
        ]
    }

    private struct Segment {
        let content: Content

        init(_ content: Content) {
            self.content = content
        }

        enum Content {
            case crumb(BreadcrumbItem, isCurrent: Bool)
            case separator
            case overflow([BreadcrumbItem])
        }
    }
}

private struct BreadcrumbPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Breadcrumb([
                BreadcrumbItem(Text("Home"), action: {}),
                BreadcrumbItem(Text("Library"), action: {}),
                BreadcrumbItem(Text("Payments")),
            ])

            // A long trail constrained in width collapses its middle crumbs
            // into an overflow menu.
            Breadcrumb([
                BreadcrumbItem(Text("Home"), action: {}),
                BreadcrumbItem(Text("Accounts"), action: {}),
                BreadcrumbItem(Text("Cards"), action: {}),
                BreadcrumbItem(Text("Statements"), action: {}),
                BreadcrumbItem(Text("August 2026")),
            ])
            .frame(width: 240, alignment: .leading)
        }
        .padding()
    }
}

#Preview("Breadcrumb") {
    BreadcrumbPreview().tint(.indigo)
}

#Preview("Breadcrumb Dark") {
    BreadcrumbPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Breadcrumb Right to Left") {
    BreadcrumbPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Breadcrumb Accessibility Size") {
    BreadcrumbPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
