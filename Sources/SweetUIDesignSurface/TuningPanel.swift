#if canImport(UIKit)
import SwiftUI
import SweetUIFoundations

/// The theme's tokens in a host's own screen or a preview: the groups Tune
/// shows under Tokens, Color open with the Checks and the rest collapsed,
/// each token a live control over the tuning it edits. Tune's card holds
/// Start from, the selection, the notes, the versions, and the code.
public struct TuningPanel<PresetsFooter: View>: View {
    @Binding var tuning: ThemeTuning
    private let presetsFooter: PresetsFooter
    /// The selection: `nil` shows every token; an item shows the tokens
    /// that reach it.
    private let selection: Binding<ItemSelection>?
    @State private var openGroups: Set<TokenCatalog.Token.Group> = [.color]

    /// The groups over the tuning they edit, with the host's row above them.
    /// `showsScreen` is not read: the screen, its notes, and its versions
    /// live in Tune's card.
    @available(
        *, deprecated,
        message: "Tune's card holds the presets, the selection, and the code. Use designSurface(isPresented:presetsFooter:)."
    )
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

    /// Every token, or those that reach the selected item.
    private var tokens: [TokenCatalog.Token] {
        selection?.wrappedValue.item.map(TokenCatalog.reaching) ?? TokenCatalog.theme
    }

    public var body: some View {
        Form {
            if !(presetsFooter is EmptyView) {
                Section { presetsFooter }
            }
            TokenGroups(
                tuning: $tuning, color: $tuning, tokens: tokens, open: $openGroups, actions: .editing($tuning))
        }
        .accessibilityIdentifier("tuning.form")
    }
}

extension TuningPanel where PresetsFooter == EmptyView {
    /// The theme's groups over the tuning they edit.
    public init(tuning: Binding<ThemeTuning>) {
        _tuning = tuning
        selection = nil
        presetsFooter = EmptyView()
    }
}

#Preview("Tokens") {
    @Previewable @State var tuning = ThemeTuning.default
    TuningPanel(tuning: $tuning)
        .registryTheme(tuning.theme)
}
#endif
