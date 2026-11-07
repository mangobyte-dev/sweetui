#if canImport(UIKit)
import Foundation
import SweetUIFoundations
import UIKit

/// What the person is looking at, for an agent that cannot see the screen:
/// the named screen, every registry item on it with its frame and the tokens
/// it reads, the selection, the moved knobs, the preset code, and the
/// environment switches. The panel rewrites `design-context.json` beside the
/// tokens whenever one of those changes, and a note or a tap on the camera
/// saves a PNG of the app under `notes/`, with the panel left out and the
/// selected item outlined.
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

    public static let fileURL = URL.documentsDirectory.appending(component: "design-context.json")
    public static let screenshotsDirectory = URL.documentsDirectory.appending(component: "notes")

    /// The context as the tool state has it now.
    @MainActor
    static func capture(state: DesignSurfaceState, tuning: ThemeTuning, screenshot: String?) -> DesignContext {
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
            textSize: tuning.textSize.rawValue, rightToLeft: tuning.rightToLeft, screenshot: screenshot)
    }

    /// Writes the context file; a failure is logged, never raised into the host.
    @MainActor
    static func write(state: DesignSurfaceState, tuning: ThemeTuning, screenshot: String? = nil) {
        let context = capture(state: state, tuning: tuning, screenshot: screenshot ?? lastScreenshot)
        do {
            try DesignNote.fileEncoder.encode(context).write(to: fileURL, options: .atomic)
        } catch {
            SurfaceLog.logger.error("design-context.json was not written: \(error)")
        }
    }

    /// The screenshot the last write named, kept so a context rewritten for a
    /// knob move still points at it.
    @MainActor private static var lastScreenshot: String?

    /// Renders the app's window without the tool's own window, outlines the
    /// selected item, and saves `notes/<name>.png`. Returns the path relative
    /// to Documents, or `nil` when there is no window to draw.
    @MainActor
    static func saveScreenshot(named name: String, state: DesignSurfaceState) -> String? {
        guard let image = DesignSurfaceWindow.shared.appImage(outlining: state.selection.item.flatMap { item in
            state.visibleItems.first { $0.name == item }?.frame
        }) else { return nil }
        let relative = "notes/\(name).png"
        do {
            try FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: true)
            try image.pngData()?.write(to: URL.documentsDirectory.appending(path: relative), options: .atomic)
        } catch {
            SurfaceLog.logger.error("\(relative) was not written: \(error)")
            return nil
        }
        lastScreenshot = relative
        return relative
    }
}

extension DesignNote.Frame {
    init(_ rect: CGRect) {
        self.init(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
    }
}
#endif
