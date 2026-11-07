#if canImport(UIKit)
import Sharing
import SwiftUI
import SweetUIFoundations

/// The theme's tokens embedded in a host's own screen or a preview: every
/// token as a live control in Tune's groups, the preset code that names the
/// result, and the exact Swift to paste once at an app root. Tune's card
/// shows the same groups under Tokens.
public struct TuningPanel<PresetsFooter: View>: View {
    @Binding var tuning: ThemeTuning
    let presetsFooter: PresetsFooter
    /// The selection: `nil` shows every token and no Select control, as the
    /// Showcase's previews and tests do; an item shows the tokens that reach it.
    private let selection: Binding<ItemSelection>?

    /// The panel over the tuning it edits. `presetsFooter` is the host's own
    /// row under the preset chips, such as a link to a sample design system.
    /// `showsScreen` is no longer read: the screen, its notes, and its
    /// versions live in Tune's card, which `designSurface()` shows.
    public init(
        tuning: Binding<ThemeTuning>,
        selection: Binding<ItemSelection>? = nil,
        showsScreen: Bool = false,
        @ViewBuilder presetsFooter: () -> PresetsFooter
    ) {
        _tuning = tuning
        self.selection = selection
        self.presetsFooter = presetsFooter()
    }

    @State private var openGroups: Set<TokenCatalog.Token.Group> = [.color]

    /// Every token, or those that reach the selected item.
    private var tokens: [TokenCatalog.Token] {
        selection?.wrappedValue.item.map(TokenCatalog.reaching) ?? TokenCatalog.theme
    }

    public var body: some View {
        NavigationStack {
            Form {
                PresetsSection(tuning: $tuning, footer: presetsFooter)
                Section("Code") {
                    CodeRows(tuning: tuning)
                }
                TokenGroups(
                    tuning: $tuning, color: $tuning, tokens: tokens, open: $openGroups,
                    actions: .editing($tuning))
            }
            .accessibilityIdentifier("tuning.form")
            .navigationTitle("Tune")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        withAnimation(ToolChrome.animation) { tuning = .default }
                    }
                }
                if let selection {
                    ToolbarItem(placement: .topBarLeading) {
                        // Arms the next tap on the content to pick the item under it.
                        Button("Select", systemImage: "scope") {
                            withAnimation(ToolChrome.animation) { selection.wrappedValue.isSelecting.toggle() }
                        }
                        .accessibilityIdentifier("tuning.select")
                        .accessibilityAddTraits(selection.wrappedValue.isSelecting ? [.isSelected] : [])
                    }
                }
            }
        }
    }
}

extension TuningPanel where PresetsFooter == EmptyView {
    public init(tuning: Binding<ThemeTuning>) {
        self.init(tuning: tuning) { EmptyView() }
    }
}

private struct PresetsSection<Footer: View>: View {
    @Binding var tuning: ThemeTuning
    let footer: Footer

    var body: some View {
        Section("Presets") {
            PresetChips { name in
                withAnimation(ToolChrome.animation) { tuning.apply(presetNamed: name) }
            }
            footer
        }
    }
}

/// One chip per foundation preset, each in its own theme, in a row that scrolls.
struct PresetChips: View {
    let apply: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(RegistryTheme.presets) { preset in
                    Button {
                        apply(preset.name)
                    } label: {
                        // The small bezel around it makes a 44 pt target.
                        Text(preset.name).frame(minHeight: 34)
                    }
                    // A native style, not the registry button item: the
                    // panel is a package product and items are copied source.
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .registryTheme(preset.theme)
                    .accessibilityIdentifier("tuning.preset.\(preset.name)")
                }
            }
        }
        .scrollIndicators(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

/// Copy code, Copy Swift, and the Swift to read: the two ways a tuned theme
/// leaves the app. Under Source the app shows its own theme, so there is no
/// code to copy.
struct CodeRows: View {
    let tuning: ThemeTuning
    var isSource = false

    var body: some View {
        CopyButton("Copy code", text: "--preset \(tuning.presetCode)")
            .disabled(isSource)
            .accessibilityIdentifier("tuning.copyCode")
        CopyButton("Copy Swift", text: tuning.swiftSource)
            .disabled(isSource)
            .accessibilityIdentifier("tuning.copySwift")
        if isSource {
            Text("Tune sets no token, so there is no code to copy. The app shows its own theme.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            DisclosureGroup("Swift") {
                Text(verbatim: tuning.swiftSource)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                Text("Paste this once at your scene root. Every registry item you install inherits it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Tuning Panel") {
    @Previewable @State var tuning = ThemeTuning.default
    TuningPanel(tuning: $tuning)
        .registryTheme(tuning.theme)
}
#endif
