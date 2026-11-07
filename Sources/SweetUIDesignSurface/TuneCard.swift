#if canImport(UIKit)
import Dependencies
import Sharing
import SwiftUI

/// Tune's card under the drag bar: the toolbar with Select and the item
/// menu, the place picker, the place, and the bottom bar with Undo, Redo,
/// Preview, and Note. At an accessibility text size, or when the card is
/// too short to keep 120 pt for the place under the picker, the picker
/// moves into the toolbar as a menu. The toolbar is the card's own 44 pt
/// row under an empty inline navigation bar, which takes no height on the
/// place and carries Back on a pushed host page (measured 2026-11-07 at
/// 300 × 260: toolbar items in the navigation bar left the place 114 pt,
/// and a hidden bar stayed hidden over a host's own NavigationLink page).
struct TuneCard: View {
    @Bindable var model: TuneModel
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The item names pushed as host pages.
    @State private var path: [String] = []
    @State private var height: CGFloat = .infinity

    /// The card's height under the drag bar below which the picker row
    /// would leave the place less than 120 pt: the toolbar, the picker row,
    /// and the bottom bar take the rest.
    static let heightForPickerRow: CGFloat = 44 + 40 + 44 + 120

    private var placeIsMenu: Bool {
        typeSize.isAccessibilitySize || height < Self.heightForPickerRow
    }

    var body: some View {
        if let wrap = model.stage.panelWrap {
            wrap(AnyView(stack))
        } else {
            stack
        }
    }

    private var stack: some View {
        NavigationStack(path: $path) {
            place
                .safeAreaInset(edge: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        Toolbar(model: model, placeIsMenu: placeIsMenu)
                        if !placeIsMenu {
                            PlacePicker(model: model)
                                .padding(.horizontal, ToolChrome.spacing)
                                .padding(.bottom, ToolChrome.compactSpacing)
                        }
                    }
                    .background(.bar)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: String.self) { name in
                    if let page = model.stage.hostPage?(name) { page } else { Text(verbatim: name) }
                }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomBar(model: model)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            self.height = height
        }
        // A pick lands on the innermost item the host has a page for; an
        // item without one leaves the card on its place.
        .onChange(of: model.stage.selection.chain) { _, chain in
            guard let hostPage = model.stage.hostPage,
                  let name = chain.first(where: { hostPage($0) != nil }) else { return }
            path = [name]
        }
        // Clearing the selection also leaves a pushed host page, which was
        // about the selected item.
        .onChange(of: model.stage.selection.item) { _, item in
            if item == nil { path = [] }
        }
    }

    @ViewBuilder
    private var place: some View {
        switch model.place {
        case .tokens: TokensPlace(model: model)
        case .notes: NotesPlace(model: model)
        case .versions: VersionsPlace(model: model)
        }
    }
}

/// Select, the item menu, and, when the picker does not fit, the place menu.
private struct Toolbar: View {
    let model: TuneModel
    let placeIsMenu: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Arms the next tap on the app to select the item under it.
            Button {
                withAnimation(ToolChrome.animation) { model.selectButtonTapped() }
            } label: {
                Label("Select", systemImage: "scope").barTarget()
            }
            .buttonStyle(.borderless)
            .accessibilityAddTraits(model.stage.selection.isSelecting ? [.isSelected] : [])
            .accessibilityIdentifier("tuning.select")
            ItemMenu(model: model)
                .frame(maxWidth: .infinity, alignment: .leading)
            if placeIsMenu {
                PlaceMenu(model: model)
            }
        }
        .padding(.horizontal, ToolChrome.compactSpacing)
    }
}

/// Tokens, Notes, and Versions as segments.
private struct PlacePicker: View {
    @Bindable var model: TuneModel

    var body: some View {
        Picker("Place", selection: $model.place) {
            ForEach(TuneModel.Place.allCases) { place in
                Text(place.title)
                    .tag(place)
                    .accessibilityIdentifier("tuning.place.\(place.rawValue)")
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

/// The place picker as a menu in the toolbar, at an accessibility text size
/// or in a card too short for the segments.
private struct PlaceMenu: View {
    @Bindable var model: TuneModel

    var body: some View {
        Menu {
            Picker("Place", selection: $model.place) {
                ForEach(TuneModel.Place.allCases) { place in
                    Text(place.title)
                        .tag(place)
                        .accessibilityIdentifier("tuning.place.\(place.rawValue)")
                }
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: 4) {
                Text(model.place.title)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, ToolChrome.compactSpacing)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Place")
        .accessibilityValue(model.place.title)
        .accessibilityIdentifier("tuning.place")
    }
}

/// The items on this screen, one entry per item, and Clear selection; its
/// label says the selection and its container, or the screen and its count.
private struct ItemMenu: View {
    let model: TuneModel

    var body: some View {
        let stage = model.stage
        let items = stage.visibleItemNames
        Menu {
            if items.isEmpty {
                Text("No registry item is on this screen. An item shows here once its view applies registryItem(_:).")
            }
            ForEach(items, id: \.name) { item in
                let title = item.count > 1 ? "\(stage.title(item.name)) (\(item.count))" : stage.title(item.name)
                Button {
                    withAnimation(ToolChrome.animation) { model.itemMenuSelected(item.name) }
                } label: {
                    if stage.selection.item == item.name {
                        Label(title, systemImage: "checkmark")
                    } else {
                        Text(verbatim: title)
                    }
                }
                .accessibilityIdentifier("tuning.screen.\(item.name)")
            }
            if stage.selection.item != nil {
                Divider()
                Button("Clear selection", systemImage: "xmark.circle") {
                    withAnimation(ToolChrome.animation) { model.clearSelectionTapped() }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(verbatim: model.itemMenuTitle)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(model.itemMenuTitle)
        .accessibilityHint("Lists the items on this screen, to select one.")
        .accessibilityIdentifier("tuning.screen")
    }
}

/// Undo, Redo, Preview, and Note, in thumb reach.
private struct BottomBar: View {
    @Bindable var model: TuneModel

    var body: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(ToolChrome.animation) { model.undoButtonTapped() }
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward").barTarget()
            }
            .disabled(!model.history.canUndo)
            .accessibilityHint(model.undoTarget.map { "Makes \(model.label($0)) current." } ?? "")
            .accessibilityIdentifier("tuning.undo")
            Button {
                withAnimation(ToolChrome.animation) { model.redoButtonTapped() }
            } label: {
                Label("Redo", systemImage: "arrow.uturn.forward").barTarget()
            }
            .disabled(!model.history.canRedo)
            .accessibilityHint(model.redoTarget.map { "Makes \(model.label($0)) current." } ?? "")
            .accessibilityIdentifier("tuning.redo")
            Spacer(minLength: ToolChrome.compactSpacing)
            PreviewMenu(model: model)
            Button {
                model.noteButtonTapped()
            } label: {
                Label("Note", systemImage: "square.and.pencil").barTarget()
            }
            .accessibilityHint("Writes a note to the agent about the selection or the screen.")
            .accessibilityIdentifier("tuning.note")
        }
        .buttonStyle(.borderless)
        .padding(.leading, ToolChrome.compactSpacing)
        // The floating card's resize grip owns the trailing 44 pt corner.
        .padding(.trailing, 44)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}

/// Appearance, text size, direction, outlines, and guides, applied beside
/// the theme and never part of a version; the label shows what is on.
private struct PreviewMenu: View {
    @Bindable var model: TuneModel

    var body: some View {
        let overrides = model.previewOverrides
        // Each choice is a titled group of checked rows, so an override is
        // two taps: Preview, then the choice. (An inline Picker in a Section
        // drops the Section's title, measured on the iOS 27 simulator.)
        Menu {
            PreviewChoices("Appearance", selection: $model.appearance, optionTitle: \.title)
            PreviewChoices("Text size", selection: $model.textSize, optionTitle: \.title)
            PreviewChoices("Direction", selection: $model.direction, optionTitle: \.title)
            Section {
                Toggle("Outlines", systemImage: "rectangle.dashed", isOn: $model.showsOutlines)
                    .accessibilityIdentifier("tuning.outlines")
                Toggle("Guides", systemImage: "grid", isOn: $model.showsGuides)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "eye")
                    .accessibilityHidden(true)
                if !overrides.isEmpty {
                    Text(verbatim: overrides.joined(separator: " · "))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
            }
            .barTarget()
        }
        .accessibilityLabel("Preview")
        .accessibilityValue(overrides.isEmpty ? "Nothing overridden" : overrides.joined(separator: ", "))
        .accessibilityIdentifier("tuning.preview")
    }
}

/// One titled group of Preview's choices, each a row checked when it is on.
private struct PreviewChoices<Value: CaseIterable & Hashable & Identifiable>: View
where Value.AllCases: RandomAccessCollection {
    let title: LocalizedStringKey
    @Binding var selection: Value
    let optionTitle: KeyPath<Value, String>

    init(_ title: LocalizedStringKey, selection: Binding<Value>, optionTitle: KeyPath<Value, String>) {
        self.title = title
        _selection = selection
        self.optionTitle = optionTitle
    }

    var body: some View {
        Section(title) {
            ForEach(Value.allCases) { option in
                Toggle(option[keyPath: optionTitle], isOn: Binding(
                    get: { selection == option },
                    set: { if $0 { selection = option } }))
            }
        }
    }
}

extension View {
    /// An icon-only bar control with the whole 44 point square as its target.
    func barTarget() -> some View {
        labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// The card's grab strip and Collapse. The floating card adds the drag that
/// moves it.
struct CardDragBar: View {
    let collapse: () -> Void

    var body: some View {
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
            Button(action: collapse) {
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
    }
}

extension View {
    /// The card's material and corners.
    func tuneCardSurface() -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: ToolChrome.cardRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: ToolChrome.cardRadius, style: .continuous))
    }
}

extension DesignSurface {
    /// Tune's card open at a place, drawn as the surface draws it, over a
    /// stage and files of its own kept in memory, so a preview or a render
    /// check shows the card without its window. Its controls work on that
    /// copy and write nothing for the agent.
    @MainActor
    public static func card(at place: Place, tunesRegistryTheme: Bool = true) -> some View {
        TuneCardPreview(place: place, tunesTheme: tunesRegistryTheme)
    }
}

private struct TuneCardPreview: View {
    @State private var model: TuneModel

    init(place: TuneModel.Place, tunesTheme: Bool) {
        let model = withDependencies {
            $0.defaultFileStorage = .inMemory
            $0.defaultAppStorage = .inMemory
            $0.designOutbox = .inert
        } operation: {
            let stage = DesignSurfaceState()
            stage.tunesTheme = tunesTheme
            return TuneModel(stage: stage)
        }
        // A first open: the files are the first version.
        model.$history.withLock { $0.reconcile(values: model.liveDesign) }
        model.place = place
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 0) {
            CardDragBar {}
            TuneCard(model: model)
        }
        .tuneCardSurface()
        .tint(ToolChrome.accent)
    }
}
#endif
