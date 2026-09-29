import SwiftUI

/// What a design surface tells the registry items below it. `nil`, the
/// default, means no surface is present, and ``SwiftUI/View/registryItem(_:)``
/// leaves its content untouched apart from an empty overlay.
public struct RegistryItemSurface: Equatable, Sendable {
    /// The name of the item the surface has selected, or `nil`.
    public var selected: String?
    /// The label the selection ring shows for the selected item; the name by default.
    public var selectedTitle: String?

    public init(selected: String? = nil, selectedTitle: String? = nil) {
        self.selected = selected
        self.selectedTitle = selectedTitle
    }
}

/// One tagged root's place on screen, reported to a surface as it changes:
/// the instance (`id`), the item name, the frame in the screen's global
/// coordinates, and the names of the tagged roots it sits inside, outermost
/// first. Reported through the environment rather than a preference so
/// a root inside a sheet or a cover, whose tree a preference never leaves,
/// still reaches the surface.
public struct RegistryItemReport: Sendable {
    public let id: UUID
    public let name: String
    public let frame: CGRect
    public let ancestors: [String]

    public init(id: UUID, name: String, frame: CGRect, ancestors: [String] = []) {
        self.id = id
        self.name = name
        self.frame = frame
        self.ancestors = ancestors
    }
}

/// The callbacks a design surface installs so tagged roots and named screens
/// can report themselves. `nil`, the default, means no surface listens.
public struct RegistrySurfaceReporter: Sendable {
    public var itemChanged: @MainActor @Sendable (RegistryItemReport) -> Void
    public var itemLeft: @MainActor @Sendable (UUID) -> Void
    public var screenAppeared: @MainActor @Sendable (String) -> Void
    public var screenLeft: @MainActor @Sendable (String) -> Void

    public init(
        itemChanged: @escaping @MainActor @Sendable (RegistryItemReport) -> Void,
        itemLeft: @escaping @MainActor @Sendable (UUID) -> Void,
        screenAppeared: @escaping @MainActor @Sendable (String) -> Void,
        screenLeft: @escaping @MainActor @Sendable (String) -> Void
    ) {
        self.itemChanged = itemChanged
        self.itemLeft = itemLeft
        self.screenAppeared = screenAppeared
        self.screenLeft = screenLeft
    }
}

public extension EnvironmentValues {
    @Entry var registryItemSurface: RegistryItemSurface? = nil
    @Entry var registrySurfaceReporter: RegistrySurfaceReporter? = nil
}

extension EnvironmentValues {
    /// The tagged roots around this view while a surface is present, outermost first.
    @Entry var registryItemAncestors: [String] = []
}

public extension View {
    /// Names the screen this view is, so a design surface can title its
    /// panel and its notes with it. Reported on appear and disappear; nested
    /// names stack, the innermost visible one wins. Inert without a surface,
    /// and an empty name reports nothing.
    nonisolated func registryScreen(_ name: String) -> some View {
        modifier(RegistryScreenModifier(name: name))
    }
}

private struct RegistryScreenModifier: ViewModifier {
    @Environment(\.registrySurfaceReporter) private var reporter
    let name: String

    func body(content: Content) -> some View {
        content
            .onAppear { if !name.isEmpty { reporter?.screenAppeared(name) } }
            .onDisappear { if !name.isEmpty { reporter?.screenLeft(name) } }
    }
}

public extension View {
    /// Names the registry item whose root this view is, so a design surface
    /// can select it on device: while a surface is present the root reports
    /// its frame and draws a selection ring and its name when selected.
    /// Without a surface the modifier adds nothing a user or a test can see,
    /// and an empty name tags nothing. Every installable item applies it
    /// once, at the end of its root view's or style's modifier chain.
    nonisolated func registryItem(_ name: String) -> some View {
        modifier(RegistryItemModifier(name: name))
    }
}

private struct RegistryItemModifier: ViewModifier {
    @Environment(\.registryItemSurface) private var surface
    @Environment(\.registrySurfaceReporter) private var reporter
    @Environment(\.registryTheme) private var theme
    @Environment(\.registryItemAncestors) private var ancestors
    @State private var token = UUID()
    let name: String

    // Explicit so `registryItem(_:)` (nonisolated) can build it; the
    // synthesized init is main-actor-isolated.
    nonisolated init(name: String) {
        self.name = name
    }

    func body(content: Content) -> some View {
        content
            .environment(\.registryItemAncestors, surface != nil && !name.isEmpty ? ancestors + [name] : ancestors)
            .overlay {
                if let surface, !name.isEmpty {
                    Color.clear
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .global)
                        } action: { frame in
                            reporter?.itemChanged(RegistryItemReport(id: token, name: name, frame: frame, ancestors: ancestors))
                        }
                        .onDisappear { reporter?.itemLeft(token) }
                        .overlay(alignment: .topLeading) {
                            if surface.selected == name {
                                selection
                            }
                        }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }

    /// A hairline ring 4 points outside the item and its name above it, so
    /// nothing of the tool covers the piece being tuned (owner, 2026-09-08).
    /// The tool's own blue, never the tuned accent, so the ring holds still.
    private var selection: some View {
        let blue = Color.blue
        return RoundedRectangle(cornerRadius: theme.metrics.controlRadius + 4, style: .continuous)
            .stroke(blue, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .padding(-4)
            .overlay(alignment: .topLeading) {
                Text(surface?.selectedTitle ?? name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .background(blue, in: Capsule())
                    // One line, wider than a small item if need be.
                    .fixedSize()
                    .alignmentGuide(.top) { $0[.bottom] + 6 }
            }
    }
}
