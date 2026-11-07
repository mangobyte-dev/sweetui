#if canImport(UIKit)
import CoreGraphics
import Dependencies
import Foundation
import UIKit

/// What Tune writes for the agent beside the value files: the context, the
/// hand-off, and the screenshots under `notes/`. Each write is atomic; a
/// failure is logged and never raised into the host.
struct DesignOutbox: Sendable {
    /// Writes `design-context.json`.
    var writeContext: @MainActor @Sendable (DesignContext) -> Void
    /// Writes `design-handoff.json`; `false` when it could not be written.
    var writeHandOff: @MainActor @Sendable (DesignHandoff) -> Bool
    /// Renders the app's window without Tune's own, strokes `outlining`
    /// (window points) over it, and saves `notes/<name>.png`. Returns the
    /// path relative to Documents, or `nil` when there is no window to draw
    /// or the file could not be written.
    var saveScreenshot: @MainActor @Sendable (_ name: String, _ outlining: CGRect?) -> String?
}

extension DesignOutbox {
    static let live = DesignOutbox(
        writeContext: { context in
            do {
                try DesignNote.fileEncoder.encode(context).write(to: DesignContext.fileURL, options: .atomic)
            } catch {
                SurfaceLog.logger.error("design-context.json was not written: \(error)")
            }
        },
        writeHandOff: { handoff in
            do {
                try DesignNote.fileEncoder.encode(handoff).write(to: DesignHandoff.fileURL, options: .atomic)
                return true
            } catch {
                SurfaceLog.logger.error("design-handoff.json was not written: \(error)")
                return false
            }
        },
        saveScreenshot: { name, frame in
            guard let image = DesignSurfaceWindow.shared.appImage(outlining: frame) else { return nil }
            let relative = "notes/\(name).png"
            do {
                try FileManager.default.createDirectory(
                    at: DesignContext.screenshotsDirectory, withIntermediateDirectories: true)
                try image.pngData()?.write(to: URL.documentsDirectory.appending(path: relative), options: .atomic)
            } catch {
                SurfaceLog.logger.error("\(relative) was not written: \(error)")
                return nil
            }
            return relative
        })

    /// Reports every call, so a test names each write it expects.
    static let unimplemented = DesignOutbox(
        writeContext: IssueReporting.unimplemented("DesignOutbox.writeContext"),
        writeHandOff: IssueReporting.unimplemented("DesignOutbox.writeHandOff", placeholder: false),
        saveScreenshot: IssueReporting.unimplemented("DesignOutbox.saveScreenshot", placeholder: nil))

    /// Writes nothing, for the card a preview or a render check shows.
    static let inert = DesignOutbox(
        writeContext: { _ in }, writeHandOff: { _ in false }, saveScreenshot: { _, _ in nil })
}

private enum DesignOutboxKey: DependencyKey {
    static let liveValue = DesignOutbox.live
    static let testValue = DesignOutbox.unimplemented
}

extension DependencyValues {
    var designOutbox: DesignOutbox {
        get { self[DesignOutboxKey.self] }
        set { self[DesignOutboxKey.self] = newValue }
    }
}
#endif
