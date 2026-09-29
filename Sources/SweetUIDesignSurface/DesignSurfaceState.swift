#if canImport(UIKit)
import SwiftUI
import SweetUIFoundations

/// The surface's tool state, shared between the app window (where the items
/// live and report their frames) and the overlay window (where the button and
/// the panel live): whether the panel is up, which item is selected, and the
/// host's optional row under the preset chips.
@MainActor
@Observable
final class DesignSurfaceState {
    static let shared = DesignSurfaceState()

    var isPresented = false
    /// Off, the window shows nothing and the app tree carries no surface;
    /// the host's own switch (seeFood's Design mode) drives it.
    var isEnabled = true
    /// Whether the panel tunes the registry theme itself. A host that paints
    /// the registry items from its own tokens turns this off, so the panel
    /// shows only its screen, its selection, and the host's sections.
    var tunesTheme = true
    /// The host's own panel sections, given the selected item's name; they
    /// follow the screen and the selection in the panel's form.
    var hostSections: (([String]) -> AnyView)?
    /// The host's title for an item name, for the On this screen rows and
    /// the outlines; `nil` keeps the name.
    var itemTitle: ((String) -> String?)?
    /// The host's page for an item name, pushed on the panel's own stack when
    /// a pick lands on an item the host has a page for; `nil` for none.
    var hostPage: ((String) -> AnyView?)?
    /// Wraps the panel's navigation stack, so a host can set environment values
    /// that every pushed page reads (a pushed page never reads its link's).
    var panelWrap: ((AnyView) -> AnyView)?

    /// The host's title for the item, or the name when the host has none or
    /// answers with an empty string.
    func title(_ name: String) -> String {
        guard let title = itemTitle?(name), !title.isEmpty else { return name }
        return title
    }
    /// True when the host drives `isPresented` itself (the Showcase's accessory
    /// strip); the window then shows no floating button of its own.
    var hostOwnsTrigger = false
    var selection = ItemSelection()
    /// The host's row under the preset chips, erased because the overlay's
    /// root is not generic over the host.
    var presetsFooter: AnyView?

    /// The host's own token document, when it registered one.
    var hostTokens: (any AnyTokenStore)?
    /// The per-item knobs: the host's specs and the tuned values.
    let knobs = KnobStore()

    /// Every tagged root on screen right now, by instance, in global points.
    var frames: [UUID: RegistryItemReport] = [:]
    /// The window's bounds, so a root scrolled out of view is not listed as
    /// on this screen; empty until the overlay measures it.
    var stage: CGRect = .zero
    /// The keyboard's frame in window points while it is up, so the card's
    /// content can scroll a field above it; empty otherwise.
    var keyboardFrame: CGRect = .zero
    /// The named screens on stage, innermost last.
    var screens: [String] = []
    /// Draws every reported frame with its name over the app.
    var showsOutlines = false
    var guides: Guides = []

    /// The screen the panel is looking at: the innermost named one.
    var screen: String? { screens.last }

    /// The items on screen, top to bottom, one row per instance: a reported
    /// frame that is empty or lies outside the stage is not on screen.
    var visibleItems: [RegistryItemReport] {
        frames.values
            .filter { !$0.frame.isEmpty && (stage.isEmpty || $0.frame.intersects(stage)) }
            // Top to bottom, then leading to trailing; a container that starts
            // where its child starts lists before the child.
            .sorted {
                let (a, b) = ($0.frame, $1.frame)
                if a.minY != b.minY { return a.minY < b.minY }
                if a.minX != b.minX { return a.minX < b.minX }
                return a.width * a.height > b.width * b.height
            }
    }

    /// The items on screen by name, in the order their first instance appears,
    /// with how many instances there are: the panel's list, one row per item.
    var visibleItemNames: [(name: String, count: Int)] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        for item in visibleItems {
            if counts[item.name] == nil { order.append(item.name) }
            counts[item.name, default: 0] += 1
        }
        return order.map { (name: $0, count: counts[$0] ?? 0) }
    }

    /// The design guides drawn over the app: an 8 point grid, 24 point lines,
    /// and the 16 and 24 point margins.
    struct Guides: OptionSet, Sendable {
        let rawValue: Int
        static let grid = Guides(rawValue: 1)
        static let lines = Guides(rawValue: 2)
        static let margins = Guides(rawValue: 4)
    }

    private init() {}

    func report(_ item: RegistryItemReport) { frames[item.id] = item }
    func forget(_ id: UUID) { frames[id] = nil }
    func screenAppeared(_ name: String) { screens.append(name) }
    func screenLeft(_ name: String) {
        if let index = screens.lastIndex(of: name) { screens.remove(at: index) }
    }
}

extension Binding where Value == DesignSurfaceState.Guides {
    /// A per-flag toggle binding, the one place this derivation constructs a
    /// `Binding` directly: everywhere else derives one from this subscript.
    subscript(contains member: DesignSurfaceState.Guides) -> Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue.contains(member) },
            set: { isOn in
                if isOn { wrappedValue.insert(member) } else { wrappedValue.remove(member) }
            }
        )
    }
}
#endif
