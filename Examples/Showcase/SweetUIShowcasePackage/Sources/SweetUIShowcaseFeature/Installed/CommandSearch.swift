import Foundation
import SwiftUI
import SweetUIFoundations

/// A source-owned search screen: a title, the command palette over
/// caller-filtered sections, and a legend of keyboard shortcuts drawn as
/// keycaps for hardware-keyboard and iPad users. The caller owns the query,
/// the filtering, the sections, and what a selection does. The block does
/// not own a `ScrollView`, navigation container, or maximum width.
public struct CommandSearch<ID: Hashable>: View {
    @Environment(\.registryTheme) private var theme

    private let title: LocalizedStringResource
    @Binding private var query: String
    private let prompt: LocalizedStringResource
    private let sections: [CommandSection<ID>]
    private let emptyTitle: LocalizedStringResource
    private let emptyDescription: Text?
    private let shortcuts: [CommandShortcutHint]
    private let onSelect: (ID) -> Void

    public init(
        _ title: LocalizedStringResource,
        query: Binding<String>,
        prompt: LocalizedStringResource = LocalizedStringResource("Search", comment: "Placeholder inside the command search field"),
        sections: [CommandSection<ID>],
        emptyTitle: LocalizedStringResource = "No results",
        emptyDescription: Text? = nil,
        shortcuts: [CommandShortcutHint] = [],
        onSelect: @escaping (ID) -> Void
    ) {
        self.title = title
        self._query = query
        self.prompt = prompt
        self.sections = sections
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.shortcuts = shortcuts
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.sectionSpacing) {
            Text(title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            CommandPalette(
                query: $query,
                prompt: prompt,
                sections: sections,
                emptyTitle: emptyTitle,
                emptyDescription: emptyDescription,
                onSelect: onSelect
            )

            if !shortcuts.isEmpty {
                VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                    ForEach(shortcuts) { hint in
                        HStack {
                            Text(hint.action)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(hint.keys)
                                .registryKeycap(accessibilityLabel: hint.keysLabel)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .registryItem("command-search")
    }
}

/// One line of the shortcut legend under ``CommandSearch``.
public struct CommandShortcutHint: Identifiable {
    public let id: String
    public let action: LocalizedStringResource
    public let keys: String
    public let keysLabel: Text

    /// - Parameters:
    ///   - action: What the shortcut does, in the caller's words.
    ///   - keys: The visible keycap text, such as "⌘K".
    ///   - keysLabel: The spoken form, such as "Command K".
    ///   - id: A stable identity for the legend line. Defaults to `keys`, so
    ///     pass one when two lines show the same keys.
    public init(_ action: LocalizedStringResource, keys: String, keysLabel: Text, id: String? = nil) {
        self.id = id ?? keys
        self.action = action
        self.keys = keys
        self.keysLabel = keysLabel
    }
}

#if DEBUG
private struct CommandSearchPreview: View {
    var initialQuery = ""
    @State private var query: String

    init(initialQuery: String = "") {
        self.initialQuery = initialQuery
        _query = State(initialValue: initialQuery)
    }

    private struct Command {
        let id: String
        let name: String
        let detail: String?
        let symbol: String
        let shortcut: String?
        let shortcutLabel: String?
        let section: String
    }

    private let commands: [Command] = [
        Command(id: "transfer", name: "New transfer", detail: "Send money to a saved payee", symbol: "arrow.up.right", shortcut: "⌘T", shortcutLabel: "Command T", section: "Actions"),
        Command(id: "freeze", name: "Freeze card", detail: nil, symbol: "snowflake", shortcut: nil, shortcutLabel: nil, section: "Actions"),
        Command(id: "statement", name: "Download statement", detail: "August 2026", symbol: "doc.text", shortcut: nil, shortcutLabel: nil, section: "Actions"),
        Command(id: "bakery", name: "Mishmash Bakery", detail: "KWD 8.750, today", symbol: "cup.and.saucer.fill", shortcut: nil, shortcutLabel: nil, section: "Recent"),
        Command(id: "salary", name: "Salary", detail: "KWD 2,450.000, yesterday", symbol: "building.columns.fill", shortcut: nil, shortcutLabel: nil, section: "Recent"),
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
                    .filter { $0.section == group.id }
                    .filter { query.isEmpty || $0.name.localizedStandardContains(query) }
                    .map {
                        CommandEntry(
                            id: $0.id,
                            title: Text($0.name),
                            detail: $0.detail.map { Text($0) },
                            systemImage: $0.symbol,
                            shortcut: $0.shortcut,
                            shortcutLabel: $0.shortcutLabel.map { Text($0) }
                        )
                    }
            )
        }
    }

    var body: some View {
        ScrollView {
            CommandSearch(
                "Search",
                query: $query,
                prompt: "Search actions and activity",
                sections: sections,
                emptyDescription: Text("Try a payee, a card, or an action."),
                shortcuts: [
                    CommandShortcutHint("Open search", keys: "⌘K", keysLabel: Text("Command K")),
                    CommandShortcutHint("Run the highlighted command", keys: "↩", keysLabel: Text("Return")),
                ],
                onSelect: { _ in }
            )
            .padding()
        }
    }
}

#Preview("Command Search") {
    CommandSearchPreview()
}

#Preview("Command Search Empty") {
    CommandSearchPreview(initialQuery: "zzz")
}

#Preview("Command Search Dark") {
    CommandSearchPreview().preferredColorScheme(.dark)
}

#Preview("Command Search Right to Left") {
    CommandSearchPreview().environment(\.layoutDirection, .rightToLeft)
}

#Preview("Command Search Accessibility Size") {
    CommandSearchPreview().environment(\.dynamicTypeSize, .accessibility3)
}
#endif
