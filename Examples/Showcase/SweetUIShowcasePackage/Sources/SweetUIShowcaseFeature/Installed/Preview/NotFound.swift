import SwiftUI
import SweetUIFoundations

/// A 404 state, translated from shadcn's not-found: a native
/// `ContentUnavailableView` on the registry content surface whose actions hold
/// a search input group (with a leading symbol and a trailing keycap) and a
/// link back home.
public struct NotFound: View {
    @Environment(\.registryTheme) private var theme
    @State private var query = ""

    public init() {}

    public var body: some View {
        GroupBox {
            ContentUnavailableView {
                Text("404 - Not Found")
            } description: {
                Text("The page you're looking for doesn't exist. Try searching for what you need below.")
            } actions: {
                searchField
                Button("Go to homepage") {}
                    .buttonStyle(.registryLink)
            }
            .registryEmptyState()
        } label: {
            Text("Page")
        }
        .groupBoxStyle(.registryCard)
    }

    private var searchField: some View {
        InputGroup {
            Image(systemName: "magnifyingglass")
                .accessibilityHidden(true)
        } content: {
            TextField("Try searching for pages...", text: $query)
                .accessibilityLabel("Search pages")
        } trailing: {
            Text(verbatim: "/").registryKeycap(accessibilityLabel: Text("Slash"))
        }
    }
}

#if DEBUG
#Preview("Not Found") {
    ScrollView { NotFound().padding() }
        .registryTheme(.indigo)
}

#Preview("Not Found Dark") {
    ScrollView { NotFound().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
