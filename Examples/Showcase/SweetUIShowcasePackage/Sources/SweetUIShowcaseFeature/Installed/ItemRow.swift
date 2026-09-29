import SwiftUI
import SweetUIFoundations

/// A generic content row: leading media, a title with an optional description,
/// and a trailing accessory. Selection stays at the call site: wrap the row in
/// a native `Button` or `NavigationLink`, which combines its children into one
/// accessible label. The row owns spacing, the minimum row height, and the
/// title and description hierarchy.
public struct ItemRow<Media: View, Accessory: View>: View {
    @Environment(\.registryTheme) private var theme

    private let title: Text
    private let description: Text?
    private let media: Media
    private let accessory: Accessory

    public init(
        title: Text,
        description: Text? = nil,
        @ViewBuilder media: () -> Media,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.description = description
        self.media = media()
        self.accessory = accessory()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: theme.metrics.standardSpacing) {
            media

            VStack(alignment: .leading, spacing: theme.metrics.compactSpacing / 2) {
                title
                    .font(.body.weight(.medium))
                if let description {
                    description
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            accessory
        }
        .frame(minHeight: RegistryMetrics.minimumHitSize)
        .contentShape(Rectangle())
        .registryItem("item")
    }
}

public extension ItemRow where Media == EmptyView {
    /// A bare trailing closure resolves to the media initializer; name the
    /// `accessory:` closure to reach this one.
    @_disfavoredOverload
    init(
        title: Text,
        description: Text? = nil,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.init(title: title, description: description, media: { EmptyView() }, accessory: accessory)
    }
}

public extension ItemRow where Accessory == EmptyView {
    init(
        title: Text,
        description: Text? = nil,
        @ViewBuilder media: () -> Media
    ) {
        self.init(title: title, description: description, media: media, accessory: { EmptyView() })
    }
}

public extension ItemRow where Media == EmptyView, Accessory == EmptyView {
    init(title: Text, description: Text? = nil) {
        self.init(title: title, description: description, media: { EmptyView() }, accessory: { EmptyView() })
    }
}

private struct ItemRowPreview: View {
    @Environment(\.registryTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Button {} label: {
                ItemRow(
                    title: Text("Mishmash Bakery"),
                    description: Text("Card ending 4021 · Today, 09:41")
                ) {
                    Avatar(initials: "MB", accessibilityLabel: Text(verbatim: "Mishmash Bakery"))
                } accessory: {
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, theme.metrics.standardSpacing)
            }
            .buttonStyle(.plain)

            Divider().registrySeparator()

            ItemRow(
                title: Text("Statement ready"),
                description: Text("August 2026"),
                accessory: {
                    Text("New")
                        .registryBadge()
                }
            )
            .padding(.vertical, theme.metrics.standardSpacing)

            Divider().registrySeparator()

            // A switch row: the row is the toggle's label, so its words are
            // part of the control and are spoken once.
            Toggle(isOn: .constant(true)) {
                ItemRow(
                    title: Text("Spending limit"),
                    description: Text("Applies to online purchases.")
                )
            }
            .toggleStyle(.switch)
            .padding(.vertical, theme.metrics.standardSpacing)
        }
        .padding(.horizontal, theme.metrics.standardSpacing)
        .registrySurface()
        .padding()
    }
}

#Preview("Item Row") {
    ItemRowPreview().tint(.indigo)
}

#Preview("Item Row Dark") {
    ItemRowPreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Item Row Right to Left") {
    ItemRowPreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Item Row Accessibility Size") {
    ItemRowPreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
