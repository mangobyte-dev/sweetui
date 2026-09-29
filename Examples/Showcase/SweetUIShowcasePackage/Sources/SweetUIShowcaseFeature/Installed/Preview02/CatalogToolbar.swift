import SwiftUI
import SweetUIFoundations

/// A catalog toolbar, translated from shadcn's catalog-toolbar: a search input
/// group, an upload action, and a multi-select filter group. shadcn lays the
/// controls in one row; on a compact card width they stack. The filter group
/// is a native ControlGroup of toggles wearing the registry toggle-group
/// treatment, so each filter stays a toggle at the call site.
public struct CatalogToolbar: View {
    @Environment(\.registryTheme) private var theme
    @State private var query = ""
    @State private var showAllTracks = false
    @State private var showReleases = true
    @State private var showTopEarners = false

    public init() {}

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                InputGroup {
                    Image(systemName: "magnifyingglass")
                        .accessibilityHidden(true)
                } content: {
                    TextField("Search releases or catalog", text: $query)
                        .accessibilityLabel("Search releases or catalog")
                }

                Button {
                } label: {
                    Label("Upload new release", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.registry)

                ControlGroup {
                    Toggle("All tracks", isOn: $showAllTracks)
                    Toggle("Releases", isOn: $showReleases)
                    Toggle("Top earners", isOn: $showTopEarners)
                }
                .registryToggleGroup(.outline)
            }
        } label: {
            Text("Catalog")
        }
        .groupBoxStyle(.registryCard)
    }
}

#if DEBUG
#Preview("Catalog Toolbar") {
    ScrollView { CatalogToolbar().padding() }
        .registryTheme(.indigo)
}

#Preview("Catalog Toolbar Dark") {
    ScrollView { CatalogToolbar().padding() }
        .registryTheme(.indigo)
        .preferredColorScheme(.dark)
}
#endif
