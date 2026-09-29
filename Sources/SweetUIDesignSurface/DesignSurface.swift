#if canImport(UIKit)
import Sharing
import SwiftUI
import SweetUIFoundations

public extension View {
    /// Turns this subtree into a design surface in debug builds: the theme the
    /// shared tokens describe is applied here, and the tool's own window puts
    /// a draggable Tune button and a floating, movable, resizable panel over
    /// the whole app, which stays live underneath on every tab, sheet, and
    /// cover. Every registry item below reads the tuned tokens from the environment
    /// and updates as a knob moves; the tokens persist in `registry-tokens.json`
    /// (``ThemeTuning/fileURL``) and leave through the panel's copy actions.
    ///
    /// `tokens` registers the host's own token document (``TokenDocument``),
    /// whose pages join the panel and whose file sits beside the registry's;
    /// `knobs` registers per-item numeric knobs (``ItemKnob``) the items read
    /// through `registryKnob(_:_:default:)` in the environment.
    ///
    /// A release build returns the content unchanged. Apply it inside the
    /// app's own `registryTheme(_:)`, `ContentView().designSurface().registryTheme(.app)`,
    /// so the tuned theme is the nearer one while tuning and the app's theme is
    /// the only one shipped.
    func designSurface(
        tokens: (any TokenDocument.Type)? = nil,
        knobs: [String: [ItemKnob]] = [:]
    ) -> some View {
        #if DEBUG
        modifier(DesignSurfaceModifier(
            isPresented: nil, tokens: tokens, knobs: knobs, presetsFooter: EmptyView()))
        #else
        self
        #endif
    }

    /// The surface for a host that paints the registry items from its own
    /// tokens. It compiles in every configuration (a host reviews on TestFlight
    /// too): `enabled` shows or hides the whole tool (the host's own switch),
    /// `tunesRegistryTheme: false` drops the panel's theme sections, and
    /// `panel` adds the host's own sections under the screen and the
    /// selection, given the selected item's name.
    func designSurface<Panel: View>(
        enabled: Bool = true,
        tunesRegistryTheme: Bool = true,
        knobs: [String: [ItemKnob]] = [:],
        itemTitle: @escaping (String) -> String? = { _ in nil },
        page: @escaping (String) -> AnyView? = { _ in nil },
        panelEnvironment: @escaping (AnyView) -> AnyView = { $0 },
        @ViewBuilder panel: @escaping ([String]) -> Panel
    ) -> some View {
        modifier(DesignSurfaceModifier(
            isPresented: nil, tokens: nil, knobs: knobs, presetsFooter: EmptyView(),
            enabled: enabled, tunesTheme: tunesRegistryTheme,
            hostSections: { AnyView(panel($0)) }, itemTitle: itemTitle, hostPage: page,
            panelWrap: panelEnvironment))
    }

    /// The surface with the host also driving the panel through `isPresented`;
    /// the window then shows no floating button of its own.
    func designSurface(
        isPresented: Binding<Bool>,
        tokens: (any TokenDocument.Type)? = nil,
        knobs: [String: [ItemKnob]] = [:]
    ) -> some View {
        #if DEBUG
        modifier(DesignSurfaceModifier(
            isPresented: isPresented, tokens: tokens, knobs: knobs, presetsFooter: EmptyView()))
        #else
        self
        #endif
    }

    /// The surface with the host owning the trigger and adding its own row
    /// under the panel's preset chips, such as a link to a sample design system.
    func designSurface<PresetsFooter: View>(
        isPresented: Binding<Bool>,
        tokens: (any TokenDocument.Type)? = nil,
        knobs: [String: [ItemKnob]] = [:],
        @ViewBuilder presetsFooter: () -> PresetsFooter
    ) -> some View {
        #if DEBUG
        modifier(DesignSurfaceModifier(
            isPresented: isPresented, tokens: tokens, knobs: knobs, presetsFooter: presetsFooter()))
        #else
        self
        #endif
    }
}

public enum DesignSurface {
    /// Forgets where the Tune button and the card were left, so the next
    /// open uses the defaults again: the button at the trailing side, the
    /// card above the bottom bar on a compact width and the trailing column
    /// on a regular one. A host offers it as a reset, and a test harness
    /// calls it at launch so a card a person moved never shapes a run.
    @MainActor public static func forgetRememberedLayout() {
        let defaults = UserDefaults.standard
        for key in [
            PanelGeometry.storageKey(regular: false), PanelGeometry.storageKey(regular: true),
            FloatingButtonStorage.restingY, FloatingButtonStorage.restingTrailing,
        ] {
            defaults.removeObject(forKey: key)
        }
    }
}

/// The callbacks tagged roots and named screens call, writing into the tool
/// state; one value for the process, outside the generic modifier.
private let surfaceReporter = RegistrySurfaceReporter(
    itemChanged: { DesignSurfaceState.shared.report($0) },
    itemLeft: { DesignSurfaceState.shared.forget($0) },
    screenAppeared: { DesignSurfaceState.shared.screenAppeared($0) },
    screenLeft: { DesignSurfaceState.shared.screenLeft($0) }
)

/// The tool lives in its own window (``DesignSurfaceWindow``): this modifier
/// keeps what must sit in the app's tree, the tuned theme and environment
/// switches, the item surface the tagged roots read, and the reporter they
/// and the named screens call. The button, the floating panel, the outlines,
/// the guides, and the tap capture that resolves a selection to the innermost
/// reported frame all come from the window, so they cover every tab, sheet,
/// and cover while the app stays live underneath.
private struct DesignSurfaceModifier<PresetsFooter: View>: ViewModifier {
    let isPresented: Binding<Bool>?
    let tokens: (any TokenDocument.Type)?
    let knobs: [String: [ItemKnob]]
    let presetsFooter: PresetsFooter
    var enabled = true
    var tunesTheme = true
    var hostSections: (([String]) -> AnyView)?
    var itemTitle: ((String) -> String?)?
    var hostPage: ((String) -> AnyView?)?
    var panelWrap: ((AnyView) -> AnyView)?
    @Shared(.designTokens) private var tuning
    private let state = DesignSurfaceState.shared

    func body(content: Content) -> some View {
        content
            // Items report their frames and draw their selection ring only
            // while the panel is up; one capture layer above the content
            // resolves a tap to the innermost item so items never compete
            // for the gesture and controls stay untouched when not selecting.
            .environment(
                \.registryItemSurface,
                state.isPresented
                    ? RegistryItemSurface(
                        selected: state.selection.item,
                        selectedTitle: state.selection.item.map { state.title($0) })
                    : nil
            )
            // Tagged roots and named screens report into the tool state through
            // this, from any tree, including sheets and covers; the window's
            // capture layer and its outlines read the reported frames.
            .environment(\.registrySurfaceReporter, enabled ? surfaceReporter : nil)
            .environment(\.registryKnobs, state.knobs.environmentValue)
            .modifier(TunedTheme(tuning: tunesTheme ? tuning : nil))
            .onAppear {
                // A registry-tokens.json that fails to decode (edited by hand,
                // or written by a newer version) leaves the defaults in place
                // and is reported once; it is rewritten only when a knob moves.
                if let error = $tuning.loadError {
                    SurfaceLog.logger.error("registry-tokens.json did not decode, the defaults apply: \(error)")
                }
                state.isEnabled = enabled
                state.tunesTheme = tunesTheme
                state.hostSections = hostSections
                state.itemTitle = itemTitle
                state.hostPage = hostPage
                state.panelWrap = panelWrap
                if !(presetsFooter is EmptyView) { state.presetsFooter = AnyView(presetsFooter) }
                if let isPresented {
                    state.hostOwnsTrigger = true
                    state.isPresented = isPresented.wrappedValue
                }
                if let tokens, state.hostTokens == nil {
                    state.hostTokens = tokens.makeStore()
                }
                state.knobs.register(knobs)
                DesignSurfaceWindow.shared.install()
            }
            .onChange(of: enabled) { _, enabled in
                state.isEnabled = enabled
                if !enabled {
                    state.isPresented = false
                    state.selection = ItemSelection()
                }
            }
            // The host's binding and the tool's state agree in both directions.
            .onChange(of: isPresented?.wrappedValue) { _, presented in
                if let presented, presented != state.isPresented { state.isPresented = presented }
            }
            .onChange(of: state.isPresented) { _, presented in
                if let isPresented, isPresented.wrappedValue != presented { isPresented.wrappedValue = presented }
            }
    }
}

/// The tuned registry theme over the app tree, or nothing for a host that
/// paints the items from its own tokens.
struct TunedTheme: ViewModifier {
    let tuning: ThemeTuning?

    func body(content: Content) -> some View {
        if let tuning {
            content
                // System exports no accent, so a consumer's controls keep their
                // own colors. The theme below carries the app accent to keep its
                // tint branch from flipping (and resetting the app); this inner
                // tint takes it off again. One unconditional modifier, no reset.
                .tint(tuning.accent == .system ? nil : tuning.theme.accent)
                .registryTheme(tuning.theme)
                .preferredColorScheme(tuning.preferredColorScheme)
                .transformEnvironment(\.layoutDirection) { direction in
                    if tuning.rightToLeft { direction = .rightToLeft }
                }
                .transformEnvironment(\.dynamicTypeSize) { size in
                    if let tuned = tuning.dynamicTypeSize { size = tuned }
                }
        } else {
            content
        }
    }
}
#endif
