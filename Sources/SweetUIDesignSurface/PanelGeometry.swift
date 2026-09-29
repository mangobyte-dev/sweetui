#if canImport(UIKit)
import CoreGraphics
import Foundation

/// The floating card's frame rules as plain functions, so the view applies
/// them and a test can hold them. Every rect is in window points with the
/// origin at the top leading corner of the window, whatever the layout
/// direction; the overlay positions its layers in that space.
enum PanelGeometry {
    static let minimumSize = CGSize(width: 300, height: 260)
    static let columnWidth: CGFloat = 380
    static let snapDistance: CGFloat = 24
    /// The part of the drag bar that always stays inside the safe area, so
    /// the card can hang off an edge and still be pulled back.
    static let grab = CGSize(width: 96, height: 44)

    /// The smallest card: taller at an accessibility text size, where a row
    /// takes more than one line and the drag bar and the grip grow.
    static func minimumSize(accessibility: Bool) -> CGSize {
        accessibility ? CGSize(width: 300, height: 360) : minimumSize
    }

    /// Where the card lands before the person moves it: above the app's
    /// bottom bar on a compact width, tall enough to keep a whole section in
    /// reach; the trailing column on a regular width.
    static func defaultFrame(in area: CGRect, regular: Bool) -> CGRect {
        if regular { return column(in: area) }
        let barAllowance: CGFloat = 92
        let height = min(area.height * 0.72, 620)
        return CGRect(x: area.minX, y: area.maxY - barAllowance - height, width: area.width, height: height)
    }

    /// The full-height side column at the trailing edge.
    static func column(in area: CGRect) -> CGRect {
        CGRect(x: area.maxX - columnWidth, y: area.minY, width: columnWidth, height: area.height)
    }

    /// A moved card: its size within the minimum and the area, its grab strip
    /// inside the area on the leading, trailing, and bottom edges, and its
    /// top never above the area, because the strip is at the top of the card.
    static func clamp(_ rect: CGRect, in area: CGRect, accessibility: Bool = false) -> CGRect {
        let minimum = minimumSize(accessibility: accessibility)
        var result = rect
        result.size.width = min(max(minimum.width, rect.width), area.width)
        result.size.height = min(max(minimum.height, rect.height), area.height)
        result.origin.x = min(max(area.minX - result.width + grab.width, rect.minX), area.maxX - grab.width)
        result.origin.y = min(max(area.minY, rect.minY), area.maxY - grab.height)
        return result
    }

    /// A resized card: the origin holds and the size stops at the area's far
    /// edges, so the grip under the finger stays on screen at the maximum.
    static func resized(_ rect: CGRect, in area: CGRect, accessibility: Bool = false) -> CGRect {
        let minimum = minimumSize(accessibility: accessibility)
        var result = rect
        result.size.width = min(max(minimum.width, rect.width), max(minimum.width, area.maxX - rect.minX))
        result.size.height = min(max(minimum.height, rect.height), max(minimum.height, area.maxY - rect.minY))
        return clamp(result, in: area, accessibility: accessibility)
    }

    /// The column, when a drag ended against the trailing edge of an area
    /// wide enough to hold one beside the app; `nil` otherwise.
    static func snapped(_ frame: CGRect, in area: CGRect) -> CGRect? {
        guard area.maxX - frame.maxX < snapDistance, area.width > columnWidth * 1.5 else { return nil }
        return column(in: area)
    }

    /// The frame as the stored text: four numbers with one decimal.
    static func encode(_ frame: CGRect) -> String {
        [frame.minX, frame.minY, frame.width, frame.height]
            .map { String(format: "%.1f", locale: nil, $0) }
            .joined(separator: ",")
    }

    static func decode(_ text: String) -> CGRect? {
        let parts = text.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return CGRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
    }

    /// The card is remembered per size class, in the host's defaults.
    static func storageKey(regular: Bool) -> String {
        regular ? "designSurface.panel.regular" : "designSurface.panel.compact"
    }
}
#endif
