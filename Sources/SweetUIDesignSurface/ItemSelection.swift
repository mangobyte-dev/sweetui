#if canImport(UIKit)
import CoreGraphics
import SweetUIFoundations

/// Which registry item the surface is tuning: `item` is the selected item's
/// name, or `nil` for the whole theme, and `isSelecting` is the arming state
/// while the next tap picks an item.
public struct ItemSelection: Equatable, Sendable {
    public var item: String?
    public var isSelecting: Bool
    /// Every tagged item under the last pick, innermost first, so a host can
    /// offer the row around a button as well as the button.
    public var chain: [String]

    public init(item: String? = nil, isSelecting: Bool = false, chain: [String] = []) {
        self.item = item
        self.isSelecting = isSelecting
        self.chain = chain
    }

    /// The item under a tap, the innermost of the tagged frames that contain
    /// the point: a button inside a block is the button, not the block. Ties
    /// (equal areas) resolve by name, so an item that fills its container
    /// exactly picks the same one on every tap whatever order the frames
    /// arrive in.
    public static func pick(_ frames: [(name: String, frame: CGRect)], at point: CGPoint) -> String? {
        chain(frames, at: point).first
    }

    /// Every item under the point, innermost (smallest) first, each name once.
    /// An empty frame contains nothing; a point outside every frame gives an
    /// empty chain.
    public static func chain(_ frames: [(name: String, frame: CGRect)], at point: CGPoint) -> [String] {
        chain(frames.map { (name: $0.name, frame: $0.frame, depth: 0) }, at: point)
    }

    /// The chain under the point over the reports the tagged roots sent. A
    /// child that fills its parent exactly ties on area, and geometry cannot
    /// order the two, so the one nested deeper comes first.
    public static func chain(reports: [RegistryItemReport], at point: CGPoint) -> [String] {
        chain(reports.map { (name: $0.name, frame: $0.frame, depth: $0.ancestors.count) }, at: point)
    }

    private static func chain(_ frames: [(name: String, frame: CGRect, depth: Int)], at point: CGPoint) -> [String] {
        var seen: Set<String> = []
        return frames
            .filter { !$0.frame.isEmpty && $0.frame.contains(point) }
            .sorted {
                let (a, b) = ($0.frame.width * $0.frame.height, $1.frame.width * $1.frame.height)
                if a != b { return a < b }
                return $0.depth == $1.depth ? $0.name < $1.name : $0.depth > $1.depth
            }
            .compactMap { seen.insert($0.name).inserted ? $0.name : nil }
    }
}
#endif
