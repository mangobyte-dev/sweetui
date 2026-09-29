import SwiftUI
import SweetUIFoundations

/// A cloud workspaces panel, translated from shadcn's codespaces-card. Its
/// tabs become a segmented Picker, its dropdown a native Menu, its tooltips
/// native help, and it composes the item row, input group, spinner, empty
/// state, field, and separator treatments.
public struct CodespacesCard: View {
    @Environment(\.registryTheme) private var theme
    @State private var tab: Tab = .cloud

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                Picker("View", selection: $tab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Workspaces view")

                switch tab {
                case .cloud: WorkspacesTab()
                case .local: LocalCloneTab()
                }
            }
        } label: {
            Text("Workspaces")
        }
        .groupBoxStyle(.registryCard)
    }

    private enum Tab: String, CaseIterable, Identifiable {
        case cloud, local
        var id: String { rawValue }
        var title: LocalizedStringResource {
            switch self {
            case .cloud: "Workspaces"
            case .local: "Local"
            }
        }
    }
}

private struct WorkspacesTab: View {
    @Environment(\.registryTheme) private var theme
    @State private var isCreating = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            ItemRow(title: Text("Workspaces"), description: Text("Your workspaces in the cloud")) {
                EmptyView()
            } accessory: {
                HStack(spacing: theme.metrics.compactSpacing) {
                    Button("Create a workspace on main", systemImage: "plus") {}
                        .labelStyle(.iconOnly)
                        .buttonStyle(.registryGhost)
                        .controlSize(.small)
                        .help("Create a workspace on main")
                    menu
                }
            }

            Divider().registrySeparator()

            ContentUnavailableView {
                Label("No workspaces", systemImage: "externaldrive")
            } description: {
                Text("You don't have any workspaces with this repository checked out.")
            } actions: {
                Button {
                    isCreating = true
                } label: {
                    HStack(spacing: theme.metrics.compactSpacing) {
                        if isCreating {
                            ProgressView().progressViewStyle(.registrySpinner)
                        }
                        Text("Create workspace")
                    }
                }
                .buttonStyle(.registry)
                .controlSize(.small)
                .disabled(isCreating)
            }
            .registryEmptyState()
            .task(id: isCreating) {
                guard isCreating else { return }
                try? await Task.sleep(for: .seconds(2))
                isCreating = false
            }

            Text("Workspace usage for this repository is paid for by acme.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var menu: some View {
        Menu {
            Button("New with options...", systemImage: "plus") {}
            Button("Configure container", systemImage: "shippingbox") {}
            Button("Set up prebuilds", systemImage: "bolt") {}
            Divider()
            Button("Manage workspaces", systemImage: "externaldrive") {}
            Button("What are workspaces?", systemImage: "info.circle") {}
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("More workspace options")
    }
}

private struct LocalCloneTab: View {
    @Environment(\.registryTheme) private var theme
    @State private var scheme: CloneScheme = .https

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
            Picker("Protocol", selection: $scheme) {
                ForEach(CloneScheme.allCases) { scheme in
                    Text(scheme.title).tag(scheme)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Clone protocol")

            Field("Clone URL", description: scheme.hint) { _ in
                InputGroup {
                    Text(scheme.url)
                        .font(.footnote)
                        .monospaced()
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Clone URL")
                } trailing: {
                    Button("Copy URL", systemImage: "doc.on.doc") {}
                        .labelStyle(.iconOnly)
                        .buttonStyle(.registryGhost)
                        .controlSize(.small)
                        .help("Copy URL")
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Button("Open with Desktop app", systemImage: "desktopcomputer") {}
                    .buttonStyle(.registryGhost)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Download ZIP", systemImage: "arrow.down.circle") {}
                    .buttonStyle(.registryGhost)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private enum CloneScheme: String, CaseIterable, Identifiable {
        case https, ssh, cli
        var id: String { rawValue }
        var title: LocalizedStringResource {
            switch self {
            case .https: "HTTPS"
            case .ssh: "SSH"
            case .cli: "CLI"
            }
        }
        var url: String {
            switch self {
            case .https: "https://example.com/acme/ui.git"
            case .ssh: "git@example.com:acme/ui.git"
            case .cli: "cli repo clone acme/ui"
            }
        }
        var hint: LocalizedStringResource {
            switch self {
            case .https: "Clone using the web URL."
            case .ssh: "Use a password-protected SSH key."
            case .cli: "Work fast with the command-line tool."
            }
        }
    }
}

#if DEBUG
#Preview("Codespaces Card") {
    ScrollView { CodespacesCard().padding() }
        .registryTheme(.indigo)
}

#Preview("Codespaces Card Dark") {
    ScrollView { CodespacesCard().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
