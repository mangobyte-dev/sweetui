import SwiftUI
import SweetUIFoundations

/// An empty team roster, translated from shadcn's no-team-members: a cluster of
/// initial avatars over a native `ContentUnavailableView` on the registry
/// content surface, with an invite action. Avatars use initials, never fetched
/// images, and read the member name as their label.
public struct NoTeamMembers: View {
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        GroupBox {
            ContentUnavailableView {
                VStack(spacing: theme.metrics.standardSpacing) {
                    avatarCluster
                    Text("No team members")
                }
            } description: {
                Text("Invite your team to collaborate on this project.")
            } actions: {
                Button("Invite members") {}
                    .buttonStyle(.registry)
                    .controlSize(.small)
            }
            .registryEmptyState()
        } label: {
            Text("Team")
        }
        .groupBoxStyle(.registryCard)
    }

    private var avatarCluster: some View {
        HStack(spacing: -theme.metrics.compactSpacing) {
            ForEach(members, id: \.self) { member in
                Avatar(initials: initials(member), accessibilityLabel: Text(member))
                    .controlSize(.large)
            }
        }
    }

    private func initials(_ name: String) -> String {
        let letters = name.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    private let members = ["Riverbend Ada", "Cobalt Lee", "Sable Ma"]
}

#if DEBUG
#Preview("No Team Members") {
    ScrollView { NoTeamMembers().padding() }
        .registryTheme(.indigo)
}

#Preview("No Team Members Dark") {
    ScrollView { NoTeamMembers().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
