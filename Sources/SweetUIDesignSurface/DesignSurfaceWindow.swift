#if canImport(UIKit)
import Sharing
import SwiftUI
import SweetUIFoundations
import UIKit

/// The tool's own window above the app: transparent, at the alert level so it
/// covers every tab, sheet, and cover, and taking only the touches that land
/// on its button or its panel. Everything else falls through to the app, so
/// the app stays live while a knob moves. The shape is seeFood's Design mode
/// (its ADR 0015), ported here in Stage 9.
@MainActor
final class DesignSurfaceWindow {
    static let shared = DesignSurfaceWindow()

    private var window: PassthroughWindow?
    /// The app's own window, which gets the keyboard back when a touch or a
    /// close hands it over.
    private weak var appWindow: UIWindow?
    /// The window's touchable regions in window points; a touch anywhere else
    /// reaches the app.
    var hitRects: [String: CGRect] = [:]

    private init() {}

    /// Installs the window over the first connected scene, once.
    func install() {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        appWindow = scene.keyWindow ?? scene.windows.first
        let window = PassthroughWindow(windowScene: scene)
        // Above the alert level: the Liquid Glass tab bar sat over the card at
        // `.alert + 1` on iOS 27 (measured on the iPhone 17 simulator).
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 100)
        window.backgroundColor = .clear
        let host = UIHostingController(rootView: DesignSurfaceOverlayRoot())
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
        // The app keeps the key window while the tool is up, so its own
        // sheets and fields behave as if the tool were not there; the tool
        // takes it only while it presents a sheet of its own or a field in
        // its panel begins editing, and hands it back on the app's next field.
        // Measured 2026-09-08: a field inside a sheet never takes focus in a
        // window that is not key, and a key switch inside hit testing cancels
        // the touch being decided.
        for name in [UITextField.textDidBeginEditingNotification, UITextView.textDidBeginEditingNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { note in
                // Delivered on the main queue; the object is the field itself.
                nonisolated(unsafe) let object = note.object
                MainActor.assumeIsolated {
                    guard let view = object as? UIView, let fieldWindow = view.window else { return }
                    DesignSurfaceWindow.shared.fieldBeganEditing(in: fieldWindow)
                }
            }
        }
    }

    /// A field took focus: the window that holds it becomes key.
    func fieldBeganEditing(in fieldWindow: UIWindow) {
        setKey(fieldWindow === window)
    }

    /// The window's safe area in window points, the region the card is
    /// clamped into. Read from the window rather than a geometry reader,
    /// whose reported insets depend on where it sits in the tree (measured
    /// 2026-09-08: one placement put the strip under the status bar, another
    /// stopped it a whole inset too low).
    var safeAreaOnScreen: CGRect {
        guard let window else { return .zero }
        return window.bounds.inset(by: window.safeAreaInsets)
    }

    /// Makes the overlay key (while it presents a sheet, or a field in its
    /// panel edits) or gives the key back to the app's window.
    func setKey(_ key: Bool) {
        guard let window else { return }
        if key {
            if !window.isKeyWindow { window.makeKey() }
        } else if let app = appWindow ?? window.windowScene?.windows.first(where: { $0 !== window }) {
            if !app.isKeyWindow { app.makeKey() }
        }
    }
}

/// A window whose hosting view claims every point, so hit testing is decided
/// here by the named regions instead.
private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // A sheet the panel presents (Import) owns the whole window while it
        // is up; otherwise only the named regions take touches.
        if rootViewController?.presentedViewController != nil {
            return super.hitTest(point, with: event)
        }
        let rects = DesignSurfaceWindow.shared.hitRects
        guard rects.values.contains(where: { $0.contains(point) }) else { return nil }
        return super.hitTest(point, with: event)
    }
}

extension View {
    /// Names a region of the overlay that takes touches; its frame in the
    /// window is reported as it changes.
    func designSurfaceHitRegion(_ name: String) -> some View {
        onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            DesignSurfaceWindow.shared.hitRects[name] = frame
        }
        .onDisappear {
            DesignSurfaceWindow.shared.hitRects[name] = nil
        }
    }
}

/// The overlay's content: the floating button, and the panel card while it
/// is up. Its chrome is fixed (``ToolChrome``), never the tuned theme. Every
/// layer is positioned in window points with a left origin, whatever the
/// app's layout direction, because the reported frames are global; the card's
/// own content reads the system direction again.
private struct DesignSurfaceOverlayRoot: View {
    @Shared(.designTokens) private var tuning
    @Environment(\.layoutDirection) private var direction
    @Bindable private var state = DesignSurfaceState.shared

    var body: some View {
        ZStack {
            if !state.isEnabled {
                EmptyView()
            } else {
            if !state.guides.isEmpty {
                GuideOverlay(guides: state.guides)
            }
            if state.isPresented && (state.showsOutlines || state.selection.isSelecting) {
                OutlineOverlay()
            }
            if state.selection.isSelecting {
                SelectCapture()
            }
            // While Select is armed the card steps aside so every item on
            // the screen is tappable; it returns with the scope once picked.
            if state.isPresented && !state.selection.isSelecting {
                FloatingPanel(contentDirection: direction) {
                    TuningPanel(tuning: Binding($tuning), selection: $state.selection, showsScreen: true) {
                        if let footer = state.presetsFooter { footer }
                    }
                }
            }
            // The card has its own collapse control, so the button steps out while it is up.
            if !state.hostOwnsTrigger && !state.isPresented {
                FloatingTuneButton()
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.layoutDirection, .leftToRight)
        .tint(ToolChrome.accent)
        // The stage is the whole window; measured on a background layer so
        // the layers above keep the safe area the card is clamped into
        // (measured 2026-09-08: ignoring it on the root put the card's strip
        // under the status bar).
        .background {
            Color.clear
                .ignoresSafeArea()
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    state.stage = frame
                }
        }
        .onChange(of: state.isPresented) { _, presented in
            if !presented {
                DesignSurfaceWindow.shared.setKey(false)
                DesignSurfaceWindow.shared.hitRects["panel"] = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            state.keyboardFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            state.keyboardFrame = .zero
        }
    }
}

/// While Select is armed the whole window takes the next tap and resolves it
/// to the innermost reported frame, so items never compete for a gesture and
/// a root inside a sheet is as selectable as one in the main tree. A tap on
/// nothing clears the selection and disarms Select.
private struct SelectCapture: View {
    private let state = DesignSurfaceState.shared

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .global) { point in
                let chain = ItemSelection.chain(reports: Array(state.frames.values), at: point)
                withAnimation(ToolChrome.animation) {
                    state.selection.item = chain.first
                    state.selection.chain = chain
                    state.selection.isSelecting = false
                }
            }
            .accessibilityLabel("Tap a registry item to select it")
            .accessibilityAddTraits(.isButton)
            .designSurfaceHitRegion("select")
            .ignoresSafeArea()
    }
}

/// Every reported frame as a labeled rectangle over the app, the selected
/// one in the accent; a tap on an outline selects its item.
private struct OutlineOverlay: View {
    private let state = DesignSurfaceState.shared

    var body: some View {
        let accent = ToolChrome.accent
        ZStack(alignment: .topLeading) {
            ForEach(state.visibleItems, id: \.id) { item in
                let isSelected = state.selection.item == item.name
                // Outside the piece by 2 points, the name above it: the outline never covers
                // what is being tuned.
                Rectangle()
                    .stroke(isSelected ? accent : accent.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: isSelected ? [4, 3] : []))
                    .padding(-2)
                    .overlay(alignment: .topLeading) {
                        Text(state.title(item.name))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .background(isSelected ? accent : accent.opacity(0.6), in: Capsule())
                            .fixedSize()
                            .alignmentGuide(.top) { $0[.bottom] + 4 }
                    }
                    .frame(width: item.frame.width, height: item.frame.height)
                    .offset(x: item.frame.minX, y: item.frame.minY)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// The design guides: an 8 point grid, 24 point lines, and the 16 and 24
/// point margins, drawn once over the whole window and never touchable.
private struct GuideOverlay: View {
    let guides: DesignSurfaceState.Guides

    var body: some View {
        let accent = ToolChrome.accent
        Canvas { context, size in
            if guides.contains(.grid) {
                var path = Path()
                stride(from: 0, through: size.width, by: 8).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: 0, through: size.height, by: 8).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(accent.opacity(0.12)), lineWidth: 0.5)
            }
            if guides.contains(.lines) {
                var path = Path()
                stride(from: 0, through: size.height, by: 24).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(accent.opacity(0.3)), lineWidth: 0.5)
            }
            if guides.contains(.margins) {
                var path = Path()
                for x in [16.0, 24.0, size.width - 24, size.width - 16] {
                    path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(accent.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The button's remembered-position keys, named once so `FloatingTuneButton`'s
/// own `@AppStorage` and `DesignSurface`'s `forgetRememberedLayout()` reset
/// can't drift apart the way two copies of the literal string could.
enum FloatingButtonStorage {
    static let restingY = "designSurface.button.y"
    static let restingTrailing = "designSurface.button.trailing"
}

/// The draggable button that opens the panel. It settles to the nearer side
/// after a drag and remembers its place. A hold offers the outlines and the
/// guides.
private struct FloatingTuneButton: View {
    @Bindable private var state = DesignSurfaceState.shared
    @AppStorage(FloatingButtonStorage.restingY) private var restingY = 0.72
    @AppStorage(FloatingButtonStorage.restingTrailing) private var restingTrailing = true
    @State private var drag: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let inset: CGFloat = 20
            let diameter: CGFloat = 52
            let restX = restingTrailing ? size.width - inset - diameter / 2 : inset + diameter / 2
            let restY = min(max(restingY, 0.1), 0.9) * size.height
            Button {
                withAnimation(ToolChrome.animation) { state.isPresented.toggle() }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3.weight(.semibold))
                    .frame(width: diameter, height: diameter)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Circle())
            .contextMenu {
                Toggle("Outline the pieces", systemImage: "rectangle.dashed", isOn: $state.showsOutlines)
                Toggle("8 pt grid", systemImage: "grid", isOn: $state.guides[contains: .grid])
                Toggle("24 pt lines", systemImage: "text.justify", isOn: $state.guides[contains: .lines])
                Toggle("Margins", systemImage: "arrow.left.and.right", isOn: $state.guides[contains: .margins])
            }
            .accessibilityLabel("Tune")
            .accessibilityHint("Opens the design surface panel. Hold for outlines and guides.")
            .accessibilityIdentifier("designSurface.button")
            .shadow(radius: 8, y: 4)
            // Measured on the button itself: after `position` the view fills
            // the window, and a full-window region would swallow every touch.
            .designSurfaceHitRegion("button")
            .position(x: restX + drag.width, y: restY + drag.height)
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { drag = $0.translation }
                    .onEnded { value in
                        let x = restX + value.translation.width
                        let y = restY + value.translation.height
                        withAnimation(ToolChrome.animation) {
                            restingTrailing = x > size.width / 2
                            restingY = Double(min(max(y / size.height, 0.1), 0.9))
                            drag = .zero
                        }
                    }
            )
        }
    }
}

/// The tool's own look: fixed system values, never the tuned theme, so the
/// panel holds still while a knob moves (owner, 2026-09-08). Its motion
/// follows Reduce Motion: none when the setting is on.
enum ToolChrome {
    static let accent = Color(uiColor: .systemBlue)
    static let cardRadius: CGFloat = 16
    static let spacing: CGFloat = 12
    static let compactSpacing: CGFloat = 8

    @MainActor static var animation: Animation? {
        animation(reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }

    static func animation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .snappy
    }
}

/// The panel as a floating card: a drag bar moves it, a corner grip resizes
/// it, a chevron collapses it to the button, and dragging it against the
/// trailing edge snaps it into a full-height side column. Its frame is
/// remembered per size class, re-clamped when the area changes (rotation),
/// and restored when the size class changes; the rules are ``PanelGeometry``.
private struct FloatingPanel<Content: View>: View {
    /// The system layout direction for the card's content; the card itself
    /// is positioned in window points.
    let contentDirection: LayoutDirection
    @ViewBuilder let content: Content
    private let state = DesignSurfaceState.shared
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage(PanelGeometry.storageKey(regular: false)) private var compactFrame = ""
    @AppStorage(PanelGeometry.storageKey(regular: true)) private var regularFrame = ""
    @State private var frame: CGRect = .zero
    @State private var moveStart: CGPoint?
    @State private var sizeStart: CGSize?

    init(contentDirection: LayoutDirection, @ViewBuilder content: () -> Content) {
        self.contentDirection = contentDirection
        self.content = content()
    }

    private var isRegular: Bool { sizeClass == .regular }
    private var accessibility: Bool { typeSize.isAccessibilitySize }

    var body: some View {
        GeometryReader { proxy in
            // The safe area in this reader's coordinates: the window's safe
            // rect shifted by where the reader sits on screen.
            let global = proxy.frame(in: .global)
            let safe = DesignSurfaceWindow.shared.safeAreaOnScreen
            let area = safe.isEmpty
                ? proxy.frame(in: .local)
                : safe.offsetBy(dx: -global.minX, dy: -global.minY)
            let current = frame == .zero ? PanelGeometry.defaultFrame(in: area, regular: isRegular) : frame
            // The keyboard covers the bottom of the card while a field in it
            // has focus; the content gets that much more bottom inset so the
            // field can scroll above it and the card itself holds still.
            let keyboard = state.keyboardFrame
            let overlap = keyboard.isEmpty ? 0 : max(0, current.maxY - keyboard.minY)
            VStack(spacing: 0) {
                dragBar(area: area, current: current)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaPadding(.bottom, overlap)
                    .environment(\.layoutDirection, contentDirection)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: ToolChrome.cardRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: ToolChrome.cardRadius, style: .continuous))
            .overlay(alignment: .bottomTrailing) { grip(area: area, current: current) }
            .shadow(radius: 16, y: 8)
            .frame(width: current.width, height: current.height)
            .designSurfaceHitRegion("panel")
            .position(x: current.midX, y: current.midY)
            .onAppear {
                if frame == .zero { frame = restored(in: area) ?? PanelGeometry.defaultFrame(in: area, regular: isRegular) }
            }
            // Rotation: a column stays a column in the new area, any other
            // frame is pulled back inside it.
            .onChange(of: area) { old, new in
                guard frame != .zero else { return }
                frame = frame == PanelGeometry.column(in: old)
                    ? PanelGeometry.column(in: new)
                    : PanelGeometry.clamp(frame, in: new, accessibility: accessibility)
            }
            // A larger text size raises the minimum; the card grows to it.
            .onChange(of: accessibility) { _, accessibility in
                guard frame != .zero else { return }
                frame = PanelGeometry.clamp(frame, in: area, accessibility: accessibility)
            }
            // Each size class keeps its own frame (an iPad entering Split View).
            .onChange(of: isRegular) { _, regular in
                frame = restored(in: area, regular: regular) ?? PanelGeometry.defaultFrame(in: area, regular: regular)
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    /// The handle and the collapse control side by side. The drag gesture
    /// runs simultaneously over the whole bar, so the card can be pulled
    /// back by whichever part of the strip is on screen, while the collapse
    /// button keeps its own tap and its own accessibility frame (measured
    /// 2026-09-08: a plain gesture on a labeled container gave the button the
    /// bar's frame and a tap at its center landed on the spacer).
    private func dragBar(area: CGRect, current: CGRect) -> some View {
        HStack(spacing: ToolChrome.spacing) {
            HStack {
                Capsule().fill(.secondary).frame(width: 36, height: 5)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityElement()
            .accessibilityLabel("Tuning panel drag bar")
            .accessibilityHint("Drag to move the panel.")
            .accessibilityIdentifier("designSurface.dragBar")
            Button {
                withAnimation(ToolChrome.animation) { state.isPresented = false }
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Collapse the tuning panel")
            .accessibilityIdentifier("designSurface.collapse")
        }
        .padding(.horizontal, ToolChrome.spacing)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { value in
                    let start = moveStart ?? current.origin
                    moveStart = start
                    var moved = current
                    moved.origin = CGPoint(x: start.x + value.translation.width, y: start.y + value.translation.height)
                    frame = PanelGeometry.clamp(moved, in: area, accessibility: accessibility)
                }
                .onEnded { _ in
                    moveStart = nil
                    if let column = PanelGeometry.snapped(frame, in: area) {
                        withAnimation(ToolChrome.animation) { frame = column }
                    }
                    remember()
                }
        )
    }

    private func grip(area: CGRect, current: CGRect) -> some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .padding(ToolChrome.compactSpacing)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel("Resize the tuning panel")
            .accessibilityHint("Drag to resize the panel.")
            .accessibilityIdentifier("designSurface.grip")
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .global)
                    .onChanged { value in
                        let start = sizeStart ?? current.size
                        sizeStart = start
                        var resized = current
                        resized.size = CGSize(
                            width: start.width + value.translation.width,
                            height: start.height + value.translation.height)
                        frame = PanelGeometry.resized(resized, in: area, accessibility: accessibility)
                    }
                    .onEnded { _ in
                        sizeStart = nil
                        remember()
                    }
            )
    }

    private func remember() {
        let text = PanelGeometry.encode(frame)
        if isRegular { regularFrame = text } else { compactFrame = text }
    }

    private func restored(in area: CGRect, regular: Bool? = nil) -> CGRect? {
        let text = (regular ?? isRegular) ? regularFrame : compactFrame
        guard let frame = PanelGeometry.decode(text) else { return nil }
        return PanelGeometry.clamp(frame, in: area, accessibility: accessibility)
    }
}
#endif
