import CoreGraphics
import SwiftUI
import Testing
@testable import SweetUIShowcaseFeature

/// The `fold-companion` split on iPhone Duo. The simulator shows the panes, but only these numbers
/// pin WHEN the companion sits beside the content and where each pane ends. A pane under the hinge,
/// or a stacked pair on a flat portrait display, would build and screenshot fine and still read
/// badly. Fold frames marked "measured" come from `GeometryProxy.reservedRegions` on the iPhone
/// Duo simulator, iOS 27.1, in a full-screen NavigationStack with the vertical bar on the trailing
/// side.
struct FoldCompanionLayoutTests {
    /// Measured: inner display in landscape, flat open. The region frame includes its margins.
    let container = CGSize(width: 867, height: 553)
    let fold = CGRect(x: 455.5, y: -82, width: 40, height: 669)

    @Test func `A fold down the display puts each pane fully outside the fold`() throws {
        // WHY: content that runs into the crease is hard to read and to tap (Apple: keep controls
        // out of the fold), so the content pane must end where the fold starts and the companion
        // must start where it ends.
        let layout = try #require(FoldCompanionLayout.resolve(container: container, fold: fold, isActive: false))
        #expect(layout.axis == .horizontal)
        #expect(layout.contentLength == fold.minX)
        #expect(layout.foldLength == fold.width)
        #expect(layout.contentLength + layout.foldLength + layout.companionLength == container.width)
    }

    @Test func `Half open and flat open give the same panes`() {
        // WHY: the fold is inactive flat and active half open. If only the active fold split the
        // display, every small change of the hinge would move the panes under the person's eyes.
        #expect(
            FoldCompanionLayout.resolve(container: container, fold: fold, isActive: true)
                == FoldCompanionLayout.resolve(container: container, fold: fold, isActive: false))
    }

    @Test func `Right to left measures the content pane from the leading edge`() throws {
        // WHY: under right to left the content leads on the RIGHT. Measured: the default `.mirrors`
        // behavior reports the same fold at 371.5 from the leading edge, so the leading pane is the
        // narrow one. Reading the physical frame instead would push the content under the fold.
        let mirrored = CGRect(x: 371.5, y: -82, width: 40, height: 669)
        let layout = try #require(
            FoldCompanionLayout.resolve(container: container, fold: mirrored, isActive: false))
        #expect(layout.contentLength == 371.5)
        #expect(layout.companionLength == 455.5)
    }

    @Test func `A fold across the display stacks the panes only while the device is half open`() throws {
        // WHY: tabletop bends the display, so the panes go above and below the fold. Flat in
        // portrait nothing bends and one tall pane reads best, so the companion opens in a sheet.
        let portrait = CGSize(width: 669, height: 880)
        let across = CGRect(x: 0, y: 420, width: 669, height: 40)
        let tabletop = try #require(
            FoldCompanionLayout.resolve(container: portrait, fold: across, isActive: true))
        #expect(tabletop.axis == .vertical)
        #expect(tabletop.contentLength == across.minY)
        #expect(tabletop.companionLength == portrait.height - across.maxY)
        #expect(FoldCompanionLayout.resolve(container: portrait, fold: across, isActive: false) == nil)
    }

    @Test func `No fold opens the companion in a sheet`() {
        // WHY: the closed cover display, an iPhone, and an iPad report no division region. A split
        // there would squeeze two panes into a phone width.
        #expect(FoldCompanionLayout.resolve(container: CGSize(width: 402, height: 874), fold: nil, isActive: false) == nil)
        #expect(FoldCompanionLayout.resolve(container: CGSize(width: 1032, height: 1376), fold: nil, isActive: false) == nil)
    }

    @Test func `A pane narrower than the minimum opens the companion in a sheet`() {
        // WHY: measured in the Showcase catalog demo, a container offset from the fold leaves a
        // 234-point companion pane. That is too narrow to read, so the sheet takes over.
        let offset = CGSize(width: 676, height: 278)
        let offsetFold = CGRect(x: 401.8, y: -98, width: 40, height: 669)
        #expect(FoldCompanionLayout.resolve(container: offset, fold: offsetFold, isActive: true) == nil)
    }

    @Test func `The minimum pane width is inclusive`() {
        // WHY: the boundary decides between two layouts; one point either side must not flip it.
        let width = FoldCompanionLayout.minimumPaneWidth
        let exact = CGSize(width: width * 2 + 40, height: 500)
        let atMinimum = CGRect(x: width, y: 0, width: 40, height: 500)
        let pastMinimum = CGRect(x: width + 1, y: 0, width: 40, height: 500)
        #expect(FoldCompanionLayout.resolve(container: exact, fold: atMinimum, isActive: true) != nil)
        #expect(FoldCompanionLayout.resolve(container: exact, fold: pastMinimum, isActive: true) == nil)
    }
}
