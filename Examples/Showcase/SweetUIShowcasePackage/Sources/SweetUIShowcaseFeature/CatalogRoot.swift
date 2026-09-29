import Sharing
import SwiftUI
import SweetUIDesignSurface
import SweetUIFoundations

/// The browsable catalog: one tab per item kind, with the design surface
/// kept beside it rather than on a tab of its own: a trailing column on a
/// regular width and, on iPhone, a sheet the catalog stays interactive under,
/// plus the accent strip above the tab bar. `designSurface(isPresented:)`
/// applies the tuned theme once here, so every screen below inherits it,
/// which is exactly how a consuming app adopts the registry; the column's
/// layout and its measured reason live with the modifier.
struct CatalogRoot: View {
    let arguments: LaunchArguments
    @Shared(.designTokens) private var tuning
    @State private var isTuning = false

    /// A `-preset` code wins over the persisted tuning and `-default-tuning`
    /// resets it for the UI suite; otherwise the last tuning returns from the
    /// surface's file. Seeded exactly once per process: this initializer runs
    /// again whenever the parent re-evaluates, and measured on 2026-09-08 that
    /// happened after every knob change, so a seed in the initializer body put
    /// the launch tuning back over each edit (the file was rewritten with the
    /// defaults right after a tap on Ink).
    private static let launchSeed: Void = {
        let arguments = LaunchArguments.current
        @Shared(.designTokens) var tuning
        if let code = arguments.value(after: "-preset"), let tuned = ThemeTuning(presetCode: code) {
            $tuning.withLock { $0 = tuned }
        } else if arguments.contains("-default-tuning") {
            $tuning.withLock { $0 = .default }
            // The card a person dragged on this simulator would otherwise
            // shape the suite (measured 2026-09-08: a small card left at the
            // bottom put the On this screen rows out of reach).
            DesignSurface.forgetRememberedLayout()
        }
    }()

    init(arguments: LaunchArguments) {
        self.arguments = arguments
        _ = Self.launchSeed
    }

    var body: some View {
        TabView {
            Tab("Components", systemImage: "square.grid.2x2") {
                CatalogList(kind: "component", title: "Components")
            }
            Tab("Blocks", systemImage: "rectangle.3.group") {
                CatalogList(kind: "block", title: "Blocks")
            }
            Tab("Recipes", systemImage: "text.book.closed") {
                CatalogList(kind: "recipe", title: "Recipes")
            }
        }
        .tabViewBottomAccessory {
            TuningAccessory(tuning: Binding($tuning), isTuning: $isTuning)
        }
        .designSurface(isPresented: $isTuning) {
            // The MANGO sample design system, the worked example of building one
            // on the registry. The panel lives in a NavigationStack, so this pushes.
            NavigationLink("See MANGO") {
                MangoDemo()
            }
            .accessibilityIdentifier("tuning.mango")
        }
    }
}

struct CatalogList: View {
    let kind: String
    let title: String

    @State private var query = ""

    private var entries: [CatalogEntry] {
        let all = RegistryCatalogManifest.entries(ofKind: kind)
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all }
        return all.filter { entry in
            entry.name.localizedCaseInsensitiveContains(trimmed)
                || entry.description.localizedCaseInsensitiveContains(trimmed)
                || entry.tags.contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                NavigationLink(value: entry) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.name)
                            .font(.body.weight(.semibold))
                        Text(entry.description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
                .accessibilityIdentifier("catalog.item.\(entry.name)")
            }
            .navigationTitle(title)
            .registryScreen(title)
            .navigationDestination(for: CatalogEntry.self) { entry in
                ItemDetailScreen(entry: entry)
            }
            .searchable(text: $query, prompt: "Search \(title.lowercased())")
        }
    }
}

/// Description, live demo, install command, usage snippet, and details for one item.
struct ItemDetailScreen: View {
    let entry: CatalogEntry
    @Environment(\.registryTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.metrics.sectionSpacing) {
                Text(entry.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ItemDemoView(name: entry.name)

                if entry.kind == "recipe" {
                    Text("Nothing to install. Copy the snippet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    DetailSection("Install") {
                        CodeBlock(
                            "sweetui install \(entry.name) --destination Sources/YourFeature/Components"
                        )
                    }
                }

                DetailSection("Usage") {
                    CodeBlock(entry.usage)
                }

                DetailSection("Details") {
                    VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
                        LabeledContent("Kind", value: entry.kind)
                        LabeledContent("Version", value: entry.version)
                        LabeledContent(
                            "Dependencies",
                            value: entry.dependencies.isEmpty ? "none" : entry.dependencies.joined(separator: ", ")
                        )
                    }
                    .font(.subheadline)
                }
            }
            .padding()
            .frame(maxWidth: 792)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(entry.name)
        // The design surface titles its panel and its notes with the screen's name.
        .registryScreen(entry.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailSection<Content: View>: View {
    @Environment(\.registryTheme) private var theme
    let title: LocalizedStringResource
    let content: Content

    init(_ title: LocalizedStringResource, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.compactSpacing) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

/// Renders the demo registered for an item, or a loud placeholder the UI
/// tests assert never appears.
struct ItemDemoView: View {
    let name: String

    var body: some View {
        if let demo = ItemDemos.demo(for: name) {
            demo
        } else {
            ContentUnavailableView(
                "No demo for \(name)",
                systemImage: "exclamationmark.triangle",
                description: Text("Register one in ItemDemos.swift.")
            )
            .registryEmptyState()
        }
    }
}
