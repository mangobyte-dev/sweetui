#if canImport(UIKit)
import Foundation
import SweetUIFoundations
import UIKit

/// What the person is looking at, for an agent that cannot see the screen:
/// the named screen, every registry item on it with its frame and the tokens
/// it reads, the selection, the moved knobs, the preset code, and the
/// environment switches. Tune rewrites `design-context.json` beside the
/// tokens after each settled version and screen change, card open or closed,
/// and saves `notes/context.png` of the app once it has drawn, with Tune left
/// out and the selected item outlined.
public struct DesignContext: Codable, Equatable, Sendable {
    public struct Item: Codable, Equatable, Sendable {
        public var name: String
        public var title: String
        public var frame: DesignNote.Frame
        public var ancestors: [String]
        public var tokens: [String]
        public var knobs: [String: Double]
    }

    public var capturedAt: Date
    public var screen: String?
    /// The window's size in points, the frames' coordinate space.
    public var stage: DesignNote.Frame
    public var selectedItem: String?
    public var selectionChain: [String]
    public var items: [Item]
    public var presetCode: String
    public var appearance: String
    public var textSize: String
    public var rightToLeft: Bool
    /// The last screenshot saved, relative to the Documents directory.
    public var screenshot: String?
    /// The preset code the app showed when that screenshot was taken.
    public var screenshotCode: String?
    /// Whether the host tunes the registry theme; `false` for a host that
    /// paints the items from its own tokens.
    public var tunesTheme: Bool

    public static let fileURL = URL.documentsDirectory.appending(component: "design-context.json")
    public static let screenshotsDirectory = URL.documentsDirectory.appending(component: "notes")

    /// The context as the tool state has it now.
    @MainActor
    static func capture(
        state: DesignSurfaceState, tuning: ThemeTuning, screenshot: String?, screenshotCode: String? = nil
    ) -> DesignContext {
        let items = state.visibleItems.map { report in
            var knobs: [String: Double] = [:]
            for knob in state.knobs.knobs(for: report.name) {
                let value = state.knobs.value(report.name, knob)
                if value != knob.shipped { knobs[knob.name] = value }
            }
            return Item(
                name: report.name, title: state.title(report.name), frame: .init(report.frame),
                ancestors: report.ancestors, tokens: RegistryItemTokens.tokens(for: report.name) ?? [],
                knobs: knobs)
        }
        return DesignContext(
            capturedAt: .now, screen: state.screen, stage: .init(state.stage),
            selectedItem: state.selection.item, selectionChain: state.selection.chain, items: items,
            presetCode: tuning.presetCode, appearance: tuning.appearance.rawValue,
            textSize: tuning.textSize.rawValue, rightToLeft: tuning.rightToLeft, screenshot: screenshot,
            screenshotCode: screenshotCode, tunesTheme: state.tunesTheme)
    }
}

extension DesignNote.Frame {
    init(_ rect: CGRect) {
        self.init(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
    }
}
#endif
