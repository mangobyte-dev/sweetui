import SwiftUI
import SweetUIFoundations

/// Invite team, translated from shadcn's invite-team: rows of an email field
/// and a role picker, an add-another action, and a shareable invite link in an
/// input group with a copy button. The email fields use the registry input
/// treatment and the roles a native menu Picker; the caller owns the invite
/// list.
public struct InviteTeam: View {
    @Environment(\.registryTheme) private var theme
    @State private var invites: [Invite] = [
        Invite(id: "1", email: "alex@example.com", role: "editor"),
        Invite(id: "2", email: "sam@example.com", role: "viewer"),
    ]
    private let inviteLink = "https://example.com/invite/x8f2k"

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Text("Add members to your workspace.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                invitesList

                Button("Add another", systemImage: "plus") { addInvite() }
                    .buttonStyle(.registryOutline)
                    .frame(maxWidth: .infinity)

                Divider().registrySeparator()

                linkField

                Button("Send invites") {}
                    .buttonStyle(.registry)
                    .frame(maxWidth: .infinity)
            }
        } label: {
            Text("Invite Team")
        }
        .groupBoxStyle(.registryCard)
    }

    private var invitesList: some View {
        VStack(spacing: theme.metrics.compactSpacing) {
            ForEach($invites) { $invite in
                HStack(spacing: theme.metrics.compactSpacing) {
                    TextField("Email", text: $invite.email)
                        .textFieldStyle(.registryInput)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Email")

                    Picker("Role", selection: $invite.role) {
                        Text("Admin").tag("admin")
                        Text("Editor").tag("editor")
                        Text("Viewer").tag("viewer")
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Role")
                }
            }
        }
    }

    private var linkField: some View {
        Field("Or share invite link") { _ in
            InputGroup {
                Text(inviteLink)
                    .font(.footnote)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Invite link")
            } trailing: {
                Button("Copy link", systemImage: "doc.on.doc") {}
                    .labelStyle(.iconOnly)
                    .buttonStyle(.registryGhost)
                    .controlSize(.small)
                    .help("Copy link")
            }
        }
    }

    private func addInvite() {
        invites.append(Invite(id: "invite-\(invites.count)", email: "", role: "viewer"))
    }

    private struct Invite: Identifiable {
        let id: String
        var email: String
        var role: String
    }
}

#if DEBUG
#Preview("Invite Team") {
    ScrollView { InviteTeam().padding() }
        .registryTheme(.indigo)
}

#Preview("Invite Team Dark") {
    ScrollView { InviteTeam().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
