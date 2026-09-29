import Foundation
import SwiftUI
import SweetUIFoundations

/// One selectable command in a ``CommandPalette`` section.
public struct CommandEntry<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: Text
    public let detail: Text?
    public let systemImage: String
    /// A visible shortcut hint such as "⌘K", rendered as a keycap.
    public let shortcut: String?
    /// The spoken form of the shortcut, such as "Command K".
    public let shortcutLabel: Text?

    public init(
        id: ID,
        title: Text,
        detail: Text? = nil,
        systemImage: String,
        shortcut: String? = nil,
        shortcutLabel: Text? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.shortcut = shortcut
        self.shortcutLabel = shortcutLabel
    }
}

/// A titled group of commands. The caller filters and orders entries; the
/// palette only renders what it is given.
public struct CommandSection<ID: Hashable>: Identifiable {
    public let id: String
    public let title: LocalizedStringResource
    public let entries: [CommandEntry<ID>]

    public init(id: String, title: LocalizedStringResource, entries: [CommandEntry<ID>]) {
        self.id = id
        self.title = title
        self.entries = entries
    }
}

/// A search field over caller-prepared command sections: the registry input
/// group on top, sectioned rows beneath, and the native empty state when no
/// section has entries. Filtering, ranking, and what a command does stay with
/// the caller through the query binding and the selection closure.
public struct CommandPalette<ID: Hashable>: View {
    @Environment(\.registryTheme) private var theme
    // The symbol column scales with the body text the symbols are drawn in.
    @ScaledMetric(relativeTo: .body) private var symbolWidth: CGFloat = 28

    @Binding private var query: String
    private let prompt: LocalizedStringResource
    private let sections: [CommandSection<ID>]
    private let emptyTitle: LocalizedStringResource
    private let emptyDescription: Text?
    private let onSelect: (ID) -> Void

    public init(
        query: Binding<String>,
        prompt: LocalizedStringResource = LocalizedStringResource("Search", comment: "Placeholder inside the command search field"),
        sections: [CommandSection<ID>],
        emptyTitle: LocalizedStringResource = "No results",
        emptyDescription: Text? = nil,
        onSelect: @escaping (ID) -> Void
    ) {
        self._query = query
        self.prompt = prompt
        self.sections = sections
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            InputGroup {
                Image(systemName: "magnifyingglass")
                    .accessibilityHidden(true)
            } content: {
                TextField(text: $query, prompt: Text(prompt)) {
                    Text(prompt)
                }
                .accessibilityLabel(Text(prompt))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            } trailing: {
                if !query.isEmpty {
                    Button("Clear search", systemImage: "xmark.circle.fill") {
                        query = ""
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.registryGhost)
                    .controlSize(.small)
                }
            }

            let visible = sections.filter { !$0.entries.isEmpty }
            if visible.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "magnifyingglass",
                    description: emptyDescription
                )
                .registryEmptyState()
            } else {
                VStack(spacing: 0) {
                    ForEach(visible) { section in
                        Text(section.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, theme.metrics.standardSpacing)
                            .padding(.bottom, theme.metrics.compactSpacing / 2)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(section.entries) { entry in
                            row(entry)
                            if entry.id != section.entries.last?.id {
                                Divider().registrySeparator()
                            }
                        }
                    }
                }
                .padding(.horizontal, theme.metrics.standardSpacing)
                .padding(.bottom, theme.metrics.compactSpacing)
                .registrySurface()
            }
        }
        .registryItem("command")
    }

    private func row(_ entry: CommandEntry<ID>) -> some View {
        Button {
            onSelect(entry.id)
        } label: {
            ItemRow(title: entry.title, description: entry.detail) {
                Image(systemName: entry.systemImage)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.tint)
                    .frame(width: symbolWidth)
                    .accessibilityHidden(true)
            } accessory: {
                if let shortcut = entry.shortcut {
                    Text(shortcut)
                        .registryKeycap(accessibilityLabel: entry.shortcutLabel)
                }
            }
            .padding(.vertical, theme.metrics.compactSpacing)
        }
        .buttonStyle(.plain)
        // Voice Control can name the row by its title alone.
        .accessibilityInputLabels([entry.title])
    }
}

#if DEBUG
private struct CommandPalettePreview: View {
    @State private var query = ""

    // The caller owns filtering: keep a plain name to match against.
    private let commands: [(id: String, name: String, detail: String?, symbol: String, shortcut: String?, section: String)] = [
        ("transfer", "New transfer", "Send money to a saved payee", "arrow.up.right", "⌘T", "Actions"),
        ("freeze", "Freeze card", nil, "snowflake", nil, "Actions"),
        ("bakery", "Mishmash Bakery", "KWD 8.750, today", "cup.and.saucer.fill", nil, "Recent"),
    ]

    // Section titles stay literals so a string catalog can extract them.
    private let groups: [(id: String, title: LocalizedStringResource)] = [
        ("Actions", "Actions"),
        ("Recent", "Recent")
    ]

    private var sections: [CommandSection<String>] {
        groups.map { group in
            CommandSection(
                id: group.id,
                title: group.title,
                entries: commands
                    .filter { $0.section == group.id && (query.isEmpty || $0.name.localizedStandardContains(query)) }
                    .map {
                        CommandEntry(
                            id: $0.id,
                            title: Text($0.name),
                            detail: $0.detail.map { Text($0) },
                            systemImage: $0.symbol,
                            shortcut: $0.shortcut,
                            shortcutLabel: $0.shortcut == nil ? nil : Text("Command T")
                        )
                    }
            )
        }
    }

    var body: some View {
        CommandPalette(
            query: $query,
            prompt: "Search actions and activity",
            sections: sections,
            emptyDescription: Text("Try a payee, a card, or an action."),
            onSelect: { _ in }
        )
        .padding()
    }
}

#Preview("Command Palette") {
    CommandPalettePreview().tint(.indigo)
}

#Preview("Command Palette Dark") {
    CommandPalettePreview().tint(.indigo).preferredColorScheme(.dark)
}

#Preview("Command Palette Right to Left") {
    CommandPalettePreview().tint(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Command Palette Accessibility Size") {
    CommandPalettePreview().tint(.indigo).dynamicTypeSize(.accessibility3)
}
#endif
