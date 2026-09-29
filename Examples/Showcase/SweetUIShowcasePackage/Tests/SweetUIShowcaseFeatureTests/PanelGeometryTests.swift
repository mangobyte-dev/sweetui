import CoreGraphics
import Testing
@testable import SweetUIDesignSurface

/// The floating card's frame rules, as a value the view applies: the card may
/// hang off the leading, trailing, and bottom edges so the screen behind it
/// stays visible, but its grab strip always stays inside the safe area so it
/// can be pulled back; it never goes above the top, where the strip would be
/// unreachable; it is re-clamped when the area changes (rotation) and kept
/// per size class.
struct PanelGeometryTests {
    let area = CGRect(x: 0, y: 59, width: 402, height: 780)

    @Test func `The card keeps its grab strip inside on every edge and never leaves the top`() {
        let size = CGSize(width: 340, height: 500)
        let leading = PanelGeometry.clamp(CGRect(origin: CGPoint(x: -1000, y: 100), size: size), in: area)
        #expect(leading.maxX == area.minX + PanelGeometry.grab.width)
        let trailing = PanelGeometry.clamp(CGRect(origin: CGPoint(x: 1000, y: 100), size: size), in: area)
        #expect(trailing.minX == area.maxX - PanelGeometry.grab.width)
        let bottom = PanelGeometry.clamp(CGRect(origin: CGPoint(x: 0, y: 5000), size: size), in: area)
        #expect(bottom.minY == area.maxY - PanelGeometry.grab.height)
        let top = PanelGeometry.clamp(CGRect(origin: CGPoint(x: 0, y: -500), size: size), in: area)
        #expect(top.minY == area.minY, "the strip is at the top of the card, so the card never hangs off the top")
    }

    @Test func `The size stays between the minimum and the area`() {
        let tiny = PanelGeometry.clamp(CGRect(x: 0, y: 100, width: 10, height: 10), in: area)
        #expect(tiny.size == PanelGeometry.minimumSize)
        let huge = PanelGeometry.clamp(CGRect(x: 0, y: 100, width: 9000, height: 9000), in: area)
        #expect(huge.size == area.size)
    }

    @Test func `Resizing stops at the far edges so the grip stays on screen`() {
        let grown = PanelGeometry.resized(CGRect(x: 40, y: 200, width: 9000, height: 9000), in: area)
        #expect(grown.maxX == area.maxX && grown.maxY == area.maxY)
        #expect(grown.minX == 40 && grown.minY == 200, "the origin holds while the grip is dragged")
        let shrunk = PanelGeometry.resized(CGRect(x: 40, y: 200, width: 1, height: 1), in: area)
        #expect(shrunk.size == PanelGeometry.minimumSize)
    }

    @Test func `The minimum grows at an accessibility text size`() {
        #expect(PanelGeometry.minimumSize(accessibility: true).height > PanelGeometry.minimumSize.height)
        let small = PanelGeometry.clamp(CGRect(x: 0, y: 100, width: 10, height: 10), in: area, accessibility: true)
        #expect(small.size == PanelGeometry.minimumSize(accessibility: true))
    }

    @Test func `A frame remembered in a taller area is pulled into a shorter one`() {
        let portrait = area
        let landscape = CGRect(x: 59, y: 0, width: 780, height: 402)
        let remembered = PanelGeometry.clamp(CGRect(x: 30, y: 300, width: 340, height: 500), in: portrait)
        let rotated = PanelGeometry.clamp(remembered, in: landscape)
        #expect(rotated.height <= landscape.height)
        #expect(rotated.minY >= landscape.minY)
        #expect(rotated.minY <= landscape.maxY - PanelGeometry.grab.height, "the grab strip stays inside")
    }

    @Test func `The default card sits above a tab bar on a compact width and is a trailing column on a regular one`() {
        let compact = PanelGeometry.defaultFrame(in: area, regular: false)
        #expect(compact.minX == area.minX && compact.width == area.width)
        #expect(compact.maxY < area.maxY, "the whole card is reachable before the person moves it")
        let wide = CGRect(x: 0, y: 24, width: 1032, height: 1352)
        let regular = PanelGeometry.defaultFrame(in: wide, regular: true)
        #expect(regular == PanelGeometry.column(in: wide))
        #expect(regular.maxX == wide.maxX && regular.height == wide.height)
    }

    @Test func `A drag that ends against the trailing edge of a wide area snaps into the column`() {
        let wide = CGRect(x: 0, y: 24, width: 1032, height: 1352)
        let near = CGRect(x: wide.maxX - 360 - 10, y: 200, width: 360, height: 500)
        #expect(PanelGeometry.snapped(near, in: wide) == PanelGeometry.column(in: wide))
        let far = CGRect(x: 100, y: 200, width: 360, height: 500)
        #expect(PanelGeometry.snapped(far, in: wide) == nil)
        let phone = CGRect(x: area.maxX - 340 - 4, y: 200, width: 340, height: 500)
        #expect(PanelGeometry.snapped(phone, in: area) == nil, "a phone has no room for a column")
    }

    @Test func `A frame round-trips through its stored text and garbage restores nothing`() {
        let frame = CGRect(x: 12.5, y: 300, width: 340, height: 500)
        #expect(PanelGeometry.decode(PanelGeometry.encode(frame)) == frame)
        #expect(PanelGeometry.decode("") == nil)
        #expect(PanelGeometry.decode("1,2,3") == nil)
        #expect(PanelGeometry.decode("a,b,c,d") == nil)
    }

    @Test func `The compact and regular frames are kept apart`() {
        #expect(PanelGeometry.storageKey(regular: true) != PanelGeometry.storageKey(regular: false))
    }
}
