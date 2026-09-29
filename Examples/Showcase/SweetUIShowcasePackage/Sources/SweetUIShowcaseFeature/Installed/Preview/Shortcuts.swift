import SwiftUI
import SweetUIFoundations

/// A keyboard shortcut legend, translated from shadcn's shortcuts: a titled
/// list of commands, each with its keycaps drawn by the registry keycap
/// treatment and separated by the registry separator. Each row reads its
/// spoken shortcut to VoiceOver, because a raw glyph like the command symbol
/// reads poorly.
public struct Shortcuts: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(spacing: theme.metrics.compactSpacing) {
                ForEach(Array(shortcuts.enumerated()), id: \.element.id) { index, shortcut in
                    if index > 0 {
                        Divider().registrySeparator()
                    }
                    row(shortcut)
                }
            }
        } label: {
            Text("Shortcuts")
        }
        .groupBoxStyle(.registryCard)
    }

    private func row(_ shortcut: Shortcut) -> some View {
        HStack(spacing: theme.metrics.standardSpacing) {
            Text(shortcut.label)
                .font(.subheadline)
            Spacer()
            HStack(spacing: theme.metrics.compactSpacing / 2) {
                ForEach(shortcut.keys, id: \.self) { key in
                    Text(key).registryKeycap()
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(shortcut.spoken))
        }
        .accessibilityElement(children: .combine)
    }

    private struct Shortcut: Identifiable {
        let id: String
        let label: LocalizedStringResource
        let keys: [String]
        let spoken: LocalizedStringResource
    }

    private let shortcuts: [Shortcut] = [
        Shortcut(id: "search", label: "Search", keys: ["⌘", "K"], spoken: "Command K"),
        Shortcut(id: "quick-actions", label: "Quick Actions", keys: ["⌘", "J"], spoken: "Command J"),
        Shortcut(id: "new-file", label: "New File", keys: ["⌘", "N"], spoken: "Command N"),
        Shortcut(id: "save", label: "Save", keys: ["⌘", "S"], spoken: "Command S"),
        Shortcut(id: "toggle-sidebar", label: "Toggle Sidebar", keys: ["⌘", "B"], spoken: "Command B"),
    ]
}

#if DEBUG
#Preview("Shortcuts") {
    ScrollView { Shortcuts().padding() }
        .registryTheme(.indigo)
}

#Preview("Shortcuts Dark") {
    ScrollView { Shortcuts().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
