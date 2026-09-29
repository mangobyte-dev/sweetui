import SwiftUI
import SweetUIFoundations

/// A sidebar navigation card, translated from shadcn's sidebar-nav: grouped
/// navigation with an active item. shadcn uses its sidebar primitive; this
/// keeps a native `List` with sections and a selection binding, styled onto the
/// registry content surface rather than recreated as a NavigationSplitView, so
/// selection, grouping, and scrolling stay native. The destinations are
/// invented, so the card names no brand.
public struct SidebarNav: View {
    @Environment(\.registryTheme) private var theme
    @State private var selection: String? = "dashboard"

    public init() {}

    public var body: some View {
        GroupBox {
            List(selection: $selection) {
                ForEach(Self.sections) { section in
                    Section {
                        ForEach(section.items) { item in
                            Label(item.title, systemImage: item.systemImage)
                                .tag(item.id)
                        }
                    } header: {
                        Text(section.title)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous))
            .registrySurface()
        } label: {
            Text("Navigation")
        }
        .groupBoxStyle(.registryCard)
    }

    private struct NavItem: Identifiable {
        let id: String
        let title: LocalizedStringResource
        let systemImage: String
    }

    private struct NavSection: Identifiable {
        let id: String
        let title: LocalizedStringResource
        let items: [NavItem]
    }

    private static let sections: [NavSection] = [
        NavSection(id: "overview", title: "Overview", items: [
            NavItem(id: "dashboard", title: "Dashboard", systemImage: "square.grid.2x2"),
            NavItem(id: "transactions", title: "Transactions", systemImage: "arrow.left.arrow.right"),
            NavItem(id: "investments", title: "Investments", systemImage: "chart.line.uptrend.xyaxis"),
            NavItem(id: "accounts", title: "Accounts", systemImage: "building.columns"),
            NavItem(id: "spending", title: "Spending", systemImage: "chart.pie"),
        ]),
        NavSection(id: "planning", title: "Planning", items: [
            NavItem(id: "goals", title: "Goals", systemImage: "target"),
            NavItem(id: "budget", title: "Budget", systemImage: "wallet.bifold"),
            NavItem(id: "reports", title: "Reports", systemImage: "chart.bar.xaxis"),
            NavItem(id: "documents", title: "Documents", systemImage: "doc.text"),
        ]),
        NavSection(id: "account", title: "Account", items: [
            NavItem(id: "profile", title: "Profile", systemImage: "person"),
            NavItem(id: "billing", title: "Billing", systemImage: "creditcard"),
            NavItem(id: "notifications", title: "Notifications", systemImage: "bell"),
            NavItem(id: "security", title: "Security", systemImage: "lock.shield"),
            NavItem(id: "appearance", title: "Appearance", systemImage: "paintbrush"),
        ]),
        NavSection(id: "support", title: "Support", items: [
            NavItem(id: "help", title: "Help center", systemImage: "questionmark.circle"),
            NavItem(id: "contact", title: "Contact us", systemImage: "message"),
            NavItem(id: "docs", title: "Documentation", systemImage: "book"),
            NavItem(id: "status", title: "Status", systemImage: "waveform.path.ecg"),
        ]),
    ]
}

#if DEBUG
#Preview("Sidebar Nav") {
    ScrollView { SidebarNav().padding() }
        .registryTheme(.indigo)
}

#Preview("Sidebar Nav Dark") {
    ScrollView { SidebarNav().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
