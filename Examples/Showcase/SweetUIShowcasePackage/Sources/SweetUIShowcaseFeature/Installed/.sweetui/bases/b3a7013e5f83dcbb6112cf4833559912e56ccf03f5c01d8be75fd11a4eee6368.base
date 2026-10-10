import SwiftUI
import SweetUIFoundations

extension View {
    /// Shows `content` as a companion to this view: in the second pane on the open display of a
    /// foldable iPhone, and in a sheet on every other display.
    ///
    /// The fold divides the display into two panes, and nothing sits under the hinge. `isPresented`
    /// stays with the caller. A pose change moves an open companion between the pane and the sheet
    /// and keeps it open; only the person closes it. The view keeps its identity in every pose, so
    /// its scroll position and focus survive a fold or an unfold.
    public func foldCompanion<Companion: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Companion
    ) -> some View {
        modifier(FoldCompanionModifier(isPresented: isPresented, companion: content()))
    }
}

/// How a fold divides a container into a content pane, the fold itself, and a companion pane.
///
/// Apple's guidance for iPhone Duo: lay out around the fold's division reserved region, not around
/// the hinge angle. A fold that runs down the display splits it side by side, active (half open) or
/// inactive (flat open), so the panes do not move when the device folds. A fold that runs across
/// the display splits it only while it is active (tabletop); flat in portrait, one tall pane reads
/// best. The cover display, an iPhone, an iPad, and a narrow window report no fold, so the
/// companion opens in a sheet there.
struct FoldCompanionLayout: Equatable, Sendable {
    /// `.horizontal`: side by side, content on the leading side. `.vertical`: content on top.
    let axis: Axis
    let contentLength: CGFloat
    let foldLength: CGFloat
    let companionLength: CGFloat

    /// The narrowest pane worth showing beside another. Below it, the companion opens in a sheet.
    static let minimumPaneWidth: CGFloat = 300
    /// The shortest stacked pane worth showing.
    static let minimumPaneHeight: CGFloat = 220

    /// The panes for a container and the fold's frame in the container's space, or nil when the
    /// companion belongs in a sheet: no fold, an inactive fold across the display, or a pane that
    /// does not fit outside the fold.
    static func resolve(container: CGSize, fold: CGRect?, isActive: Bool) -> Self? {
        guard let fold else { return nil }
        if fold.height > fold.width {
            return split(
                axis: .horizontal, start: fold.minX, end: fold.maxX, length: container.width,
                minimum: minimumPaneWidth)
        }
        guard isActive else { return nil }
        return split(
            axis: .vertical, start: fold.minY, end: fold.maxY, length: container.height,
            minimum: minimumPaneHeight)
    }

    private static func split(
        axis: Axis, start: CGFloat, end: CGFloat, length: CGFloat, minimum: CGFloat
    ) -> Self? {
        let companion = length - end
        guard start >= minimum, companion >= minimum else { return nil }
        return Self(axis: axis, contentLength: start, foldLength: end - start, companionLength: companion)
    }
}

private struct FoldCompanionModifier<Companion: View>: ViewModifier {
    @Binding var isPresented: Bool
    let companion: Companion
    @State private var layout: FoldCompanionLayout?

    func body(content: Content) -> some View {
        let pane = isPresented ? layout : nil
        let stack =
            pane?.axis == .vertical
            ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
        stack {
            content
                .paneFrame(length: pane?.contentLength, axis: pane?.axis)
            if let pane {
                Color.clear
                    .paneFrame(length: pane.foldLength, axis: pane.axis)
                    .accessibilityHidden(true)
                companion
                    .paneFrame(length: pane.companionLength, axis: pane.axis)
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear.onChange(of: Self.layout(in: proxy), initial: true) { _, newValue in
                    layout = newValue
                }
            }
        }
        .sheet(isPresented: sheetIsPresented) {
            companion
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .registryItem("fold-companion")
    }

    /// The sheet shows only where no fold splits the display. When an unfold moves the companion
    /// into its pane, SwiftUI dismisses the sheet and writes `false` here. That write is not the
    /// person closing the companion, so it is dropped.
    private var sheetIsPresented: Binding<Bool> {
        Binding {
            layout == nil && isPresented
        } set: { newValue in
            guard newValue || layout == nil else { return }
            isPresented = newValue
        }
    }

    /// The division region in the container's space. The default `.mirrors` behavior measures it
    /// from the leading edge, the same edge the stack starts from, so right to left needs no flip.
    private static func layout(in proxy: GeometryProxy) -> FoldCompanionLayout? {
        guard #available(iOS 27.1, *),
            let region = proxy.reservedRegions(kind: .division, options: .includeInactive).first
        else { return nil }
        // `frame` already includes the region's margins.
        return .resolve(container: proxy.size, fold: region.frame, isActive: region.isActive)
    }
}

extension View {
    /// At most `length` along the split axis and the whole proposal across it, or the whole
    /// proposal both ways when there is no split. A maximum, not a fixed size: when the container
    /// shrinks before the fold is measured again (a rotation that brings in a vertical bar), the
    /// panes shrink with it, so the measured size follows the container and the next pass fixes
    /// the split.
    fileprivate func paneFrame(length: CGFloat?, axis: Axis?) -> some View {
        frame(
            maxWidth: axis == .horizontal ? length : .infinity,
            maxHeight: axis == .vertical ? length : .infinity
        )
    }
}

private struct FoldCompanionPreview: View {
    @State private var isShowingDetails = true

    var body: some View {
        NavigationStack {
            List {
                LabeledContent("Merchant", value: "Mishmash Bakery")
                LabeledContent("Amount", value: "KWD 8.750")
                LabeledContent("Date", value: "10 Oct 2026")
            }
            .navigationTitle("Transaction")
            .toolbar {
                Button("Details", systemImage: "sidebar.trailing") {
                    isShowingDetails.toggle()
                }
            }
            .foldCompanion(isPresented: $isShowingDetails) {
                List {
                    LabeledContent("Category", value: "Dining")
                    LabeledContent("Card", value: "Visa 4321")
                    LabeledContent("Status", value: "Cleared")
                }
            }
        }
    }
}

#Preview("Fold Companion") {
    FoldCompanionPreview()
}

#Preview("Fold Companion Dark") {
    FoldCompanionPreview().preferredColorScheme(.dark)
}

#Preview("Fold Companion Accessibility Size") {
    FoldCompanionPreview().dynamicTypeSize(.accessibility3)
}

#Preview("Fold Companion Right to Left") {
    FoldCompanionPreview().environment(\.layoutDirection, .rightToLeft)
}
