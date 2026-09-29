import SwiftUI
import SweetUIFoundations

/// Issue assignment, translated from shadcn's assign-issue. The registry
/// Combobox is single selection, so this composes it with a caller-owned list
/// of assignees shown as avatar rows: pick a user to add, remove one from its
/// row. Avatars use initials, never fetched images.
public struct AssignIssue: View {
    @Environment(\.registryTheme) private var theme
    @State private var assigned: [String] = ["riverbend"]
    @State private var selection: String?

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Select users to assign to this issue.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if !assigned.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(assigned, id: \.self) { user in
                            assignedRow(user)
                            if user != assigned.last {
                                Divider().registrySeparator()
                            }
                        }
                    }
                    .padding(.horizontal, theme.metrics.standardSpacing)
                    .registrySurface()
                }

                Combobox(
                    selection: $selection,
                    options: options,
                    prompt: "Assign a user",
                    emptyDescription: Text("No users found.")
                )
            }
        } label: {
            HStack {
                Text("Assign Issue")
                Spacer()
                Button("Add user", systemImage: "plus") { addNextUser() }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.registryOutline)
                    .controlSize(.small)
                    .help("Add user")
            }
        }
        .groupBoxStyle(.registryCard)
        .onChange(of: selection) { _, newValue in
            if let newValue, !assigned.contains(newValue) {
                assigned.append(newValue)
            }
        }
    }

    private func assignedRow(_ user: String) -> some View {
        ItemRow(title: Text(user)) {
            Avatar(initials: initials(user), accessibilityLabel: Text(user))
                .controlSize(.small)
        } accessory: {
            Button("Remove \(user)", systemImage: "xmark") {
                assigned.removeAll { $0 == user }
                if selection == user { selection = nil }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.registryGhost)
            .controlSize(.small)
            .help("Remove \(user)")
        }
        .padding(.vertical, theme.metrics.compactSpacing)
    }

    private func addNextUser() {
        if let next = users.first(where: { !assigned.contains($0) }) {
            assigned.append(next)
        }
    }

    private func initials(_ user: String) -> String {
        String(user.prefix(1)).uppercased()
    }

    private let users = [
        "riverbend", "cobaltlab", "sablewing", "meridianco", "quartzly", "harborline", "cedargrove",
    ]

    private var options: [ComboboxOption<String>] {
        users.map { ComboboxOption(id: $0, title: $0) }
    }
}

#if DEBUG
#Preview("Assign Issue") {
    ScrollView { AssignIssue().padding() }
        .registryTheme(.indigo)
}

#Preview("Assign Issue Dark") {
    ScrollView { AssignIssue().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
