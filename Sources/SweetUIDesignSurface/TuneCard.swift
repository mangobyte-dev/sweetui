#if canImport(UIKit)
import Dependencies
import Sharing
import SwiftUI
import SweetUIFoundations

/// Tune's card under the drag bar: the toolbar with Select and the item
/// menu, the place picker, the place, the Trying strip while a proposal is
/// trying, and the bottom bar with Undo, Redo, Preview, and Note. At an
/// accessibility text size, or when the card is too short to keep 120 pt for
/// the place under the picker, the picker moves into the toolbar as a menu;
/// in a card that short the bottom bar gives way to Notes' composer, which
/// drops its subject line, and to the strip while it shows. The toolbar is the card's own 44 pt
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

    private var isShort: Bool { height < Self.heightForPickerRow }

    private var placeIsMenu: Bool {
        typeSize.isAccessibilitySize || isShort
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
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottom(composes: model.place == .notes)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: String.self) { name in
                    Group {
                        if let page = model.stage.hostPage?(name) { page } else { Text(verbatim: name) }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        bottom(composes: false)
                    }
                }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            self.height = height
        }
        // A selection lands on the innermost item the host has a page for; an
        // item without one leaves the card on its place. The card is gone
        // while Selecting, so the page waits on the model until it is back.
        .onChange(of: model.hostPageToPush, initial: true) { _, name in
            guard let name else { return }
            path = [name]
            model.hostPageToPush = nil
        }
        // Clearing the selection also leaves a pushed host page, which was
        // about the selected item.
        .onChange(of: model.stage.selection.item) { _, item in
            if item == nil { path = [] }
        }
    }

    /// The rows at the bottom, inside each page of the stack so its scroll
    /// view keeps its last row above them (an inset outside the stack does
    /// not reach the page): Notes' composer, the strip, the bottom bar.
    private func bottom(composes: Bool) -> some View {
        VStack(spacing: 0) {
            if composes {
                NotesComposer(model: model, compact: isShort)
            }
            TryingStrip(model: model)
            if !(isShort && (composes || model.showsStrip)) {
                BottomBar(model: model)
            }
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
/// With VoiceOver running, Select opens the item menu: a tap on the app
/// cannot be aimed by ear.
private struct Toolbar: View {
    let model: TuneModel
    let placeIsMenu: Bool
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if voiceOver {
                    Menu {
                        ItemMenuItems(model: model)
                    } label: {
                        Label("Select", systemImage: "scope").barTarget()
                    }
                    .accessibilityHint("Lists the items on this screen, to select one.")
                } else {
                    // Arms the next tap on the app to select the item under it.
                    Button {
                        withAnimation(ToolChrome.animation) { model.selectButtonTapped() }
                    } label: {
                        Label("Select", systemImage: "scope").barTarget()
                    }
                    .buttonStyle(.borderless)
                    .accessibilityAddTraits(model.stage.selection.isSelecting ? [.isSelected] : [])
                }
            }
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

/// Tokens, Notes, and Versions as segments; Notes counts what is new from
/// the agent.
private struct PlacePicker: View {
    @Bindable var model: TuneModel

    var body: some View {
        Picker("Place", selection: $model.place) {
            ForEach(TuneModel.Place.allCases) { place in
                Text(verbatim: model.title(place))
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
                    Text(verbatim: model.title(place))
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

/// The selection's chain and the items on this screen, and Clear selection;
/// its label says the selection and its container, the screen and its count,
/// or that the selection is not on this screen.
private struct ItemMenu: View {
    let model: TuneModel

    var body: some View {
        Menu {
            ItemMenuItems(model: model)
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

/// The item menu's entries: the selection and each item around it, then
/// every item on this screen by its first instance, then Clear selection.
private struct ItemMenuItems: View {
    let model: TuneModel

    var body: some View {
        let stage = model.stage
        let items = stage.visibleItemNames
        let chain = stage.selection.chain
        if chain.count > 1 {
            Section {
                ForEach(Array(chain.enumerated()), id: \.offset) { index, name in
                    let title = index == 0 ? stage.title(name) : "Inside: \(stage.title(name))"
                    Button {
                        withAnimation(ToolChrome.animation) { model.itemMenuSelected(name) }
                    } label: {
                        if index == 0 {
                            Label(title, systemImage: "checkmark")
                        } else {
                            Text(verbatim: title)
                        }
                    }
                    .accessibilityIdentifier("tuning.chain.\(name)")
                }
            }
        }
        Section {
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
        }
        if stage.selection.item != nil {
            Button("Clear selection", systemImage: "xmark.circle") {
                withAnimation(ToolChrome.animation) { model.clearSelectionTapped() }
            }
            .accessibilityIdentifier("tuning.scope.all")
        }
    }
}

/// While a proposal is trying: "Trying Warm. Accent, Card radius." with Keep
/// and Discard, the one colored block on the card; then for 2 s what became
/// of it. The name opens Notes at the proposal.
private struct TryingStrip: View {
    let model: TuneModel

    var body: some View {
        Group {
            if let proposal = model.trying {
                HStack(spacing: ToolChrome.compactSpacing) {
                    Button {
                        model.stripNameTapped()
                    } label: {
                        Text(verbatim: model.tryingLine(proposal))
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .accessibilityHint("Shows the proposal in Notes.")
                    Button {
                        withAnimation(ToolChrome.animation) { model.discardButtonTapped() }
                    } label: {
                        Text("Discard").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("tuning.trying.discard")
                    Button {
                        withAnimation(ToolChrome.animation) { model.keepButtonTapped() }
                    } label: {
                        Text("Keep").fontWeight(.semibold).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("tuning.trying.keep")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("tuning.trying")
            } else if let message = model.stripMessage {
                Text(verbatim: message)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .accessibilityIdentifier("tuning.trying")
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.white)
        .tint(.white)
        .padding(.horizontal, ToolChrome.spacing)
        .background(ToolChrome.accent)
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
            .accessibilityHint(model.undoTarget.map(model.hint) ?? "")
            .accessibilityIdentifier("tuning.undo")
            Button {
                withAnimation(ToolChrome.animation) { model.redoButtonTapped() }
            } label: {
                Label("Redo", systemImage: "arrow.uturn.forward").barTarget()
            }
            .disabled(!model.history.canRedo)
            .accessibilityHint(model.redoTarget.map(model.hint) ?? "")
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
            .accessibilityLabel("Tune drag bar")
            .accessibilityHint("Drag to move the card.")
            .accessibilityIdentifier("designSurface.dragBar")
            Button(action: collapse) {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Collapse Tune")
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
    /// What a card preview holds: nothing yet, a conversation with the
    /// agent (notes it read and answered, its proposals, a reply), that
    /// conversation with a proposal trying, that conversation with the card
    /// it is about selected inside a dashboard on the Components screen, or
    /// MANGO handed off, not read yet or Shipped by the agent's answer.
    public enum CardSample: Sendable {
        case firstOpen, conversation, trying, selection, handedOff, shipped
    }

    /// Tune's card open at a place, drawn as the surface draws it, over a
    /// stage and files of its own kept in memory, so a preview or a render
    /// check shows the card without its window. Its controls work on that
    /// copy and write nothing for the agent.
    @MainActor
    public static func card(at place: Place, tunesRegistryTheme: Bool = true, sample: CardSample = .firstOpen) -> some View {
        TuneCardPreview(place: place, tunesTheme: tunesRegistryTheme, sample: sample)
    }
}

private struct TuneCardPreview: View {
    @State private var model: TuneModel

    init(place: TuneModel.Place, tunesTheme: Bool, sample: DesignSurface.CardSample) {
        let model = withDependencies {
            $0.defaultFileStorage = .inMemory
            $0.defaultAppStorage = .inMemory
            $0.designOutbox = .inert
            $0.date.now = Self.handOffDate
        } operation: {
            if sample != .firstOpen {
                let agent = Shared(
                    wrappedValue: AgentRecord(),
                    .fileStorage(AgentRecord.fileURL, decode: AgentRecord.decode, encode: AgentRecord.encode))
                agent.withLock { $0 = Self.conversation.agent }
                if sample == .shipped {
                    agent.withLock {
                        $0.answers[Self.handOffID.uuidString] = .init(
                            reply: "Put MANGO into source.", changedFiles: ["RegistryTheme+App.swift"],
                            date: Self.shippedDate)
                    }
                }
            }
            let stage = DesignSurfaceState()
            stage.tunesTheme = tunesTheme
            if sample == .selection {
                stage.stage = CGRect(x: 0, y: 0, width: 393, height: 852)
                stage.screenAppeared("Components")
                stage.report(RegistryItemReport(
                    id: UUID(uuidString: "6F1C2A10-0000-4000-8000-0000000000B1")!, name: "dashboard",
                    frame: CGRect(x: 0, y: 96, width: 393, height: 420)))
                stage.report(RegistryItemReport(
                    id: UUID(uuidString: "6F1C2A10-0000-4000-8000-0000000000B2")!, name: "card",
                    frame: CGRect(x: 16, y: 120, width: 361, height: 132), ancestors: ["dashboard"]))
            }
            return TuneModel(stage: stage)
        }
        // A first open: the files are the first version.
        model.$history.withLock { $0.reconcile(values: model.liveDesign) }
        if sample != .firstOpen {
            model.$notes.withLock { $0 = Self.conversation.notes }
        }
        if sample == .trying {
            model.tryButtonTapped(Self.conversation.agent.proposals[0].id)
        }
        if sample == .handedOff || sample == .shipped {
            // The preview writes no hand-off file, so the one sent is set in place.
            model.presetChipTapped("Mango")
            model.handOff = DesignHandoff.capture(
                id: Self.handOffID, sentAt: Self.handOffDate, design: model.liveDesign, tuning: model.tuning,
                version: model.history.current, notes: model.notes, answers: model.agent.answers, screenshot: nil,
                previous: nil)
            model.shipAnswered()
        }
        // Each version a minute apart before the hand-off, so times read the
        // same on every render; Shipped lands when the agent answered.
        model.$history.withLock { history in
            let shipped = sample == .shipped ? history.current : nil
            let before = history.entries.indices.filter { history.entries[$0].id != shipped }
            for (offset, index) in before.enumerated() {
                let minutes = Double(offset - before.count)
                history.entries[index].date = Self.handOffDate.addingTimeInterval(minutes * 60)
            }
            if let index = history.entries.firstIndex(where: { $0.id == shipped }) {
                history.entries[index].date = Self.shippedDate
            }
        }
        model.place = place
        if sample == .selection {
            model.select(["card", "dashboard"])
        }
        _model = State(initialValue: model)
    }

    static let handOffID = UUID(uuidString: "6F1C2A10-0000-4000-8000-0000000000C1")!
    /// When the sample hands off, 42 minutes after its first note's hour.
    static let handOffDate = Date(timeIntervalSince1970: 1_794_038_400 + 42 * 60)
    /// When the agent answers it with changed files, 9 minutes later.
    static let shippedDate = handOffDate.addingTimeInterval(9 * 60)

    /// Three notes and two proposals, at fixed times on 7 November 2026.
    private static let conversation: (notes: [DesignNote], agent: AgentRecord) = {
        let day = Date(timeIntervalSince1970: 1_794_038_400)
        func at(_ minutes: Double) -> Date { day.addingTimeInterval(minutes * 60) }
        let flat = UUID(uuidString: "6F1C2A10-0000-4000-8000-0000000000A1")!
        let reply = UUID(uuidString: "6F1C2A10-0000-4000-8000-0000000000A2")!
        let crowded = UUID(uuidString: "6F1C2A10-0000-4000-8000-0000000000A3")!
        var notes = [
            DesignNote(
                id: flat, createdAt: at(2), text: "The cards sit flat on the background.", item: "card",
                chain: ["card"], screen: "Components", tokens: ["cardRadius", "surface"], knobs: [:], frame: nil,
                presetCode: ""),
            DesignNote(
                id: reply, createdAt: at(9), text: "Warmer, but keep the buttons as they are.", item: "card",
                chain: ["card"], screen: "Components", tokens: ["cardRadius", "surface"], knobs: [:], frame: nil,
                presetCode: ""),
            DesignNote(
                id: crowded, createdAt: at(12), text: "This screen feels crowded.", item: nil, chain: [],
                screen: "Components", tokens: [], knobs: [:], frame: nil, presetCode: ""),
        ]
        notes[0].screenshot = "notes/\(flat.uuidString).png"
        notes[1].inReplyTo = "warm"
        let agent = AgentRecord(
            read: .init(notes: [flat.uuidString: at(5), reply.uuidString: at(10)]),
            answers: [
                flat.uuidString: .init(
                    reply: "Raised the card surface and rounded the corners.",
                    changedFiles: ["RegistryTheme+App.swift"], date: at(6)),
            ],
            proposals: [
                Proposal(
                    id: "warm", date: at(7), name: "Warm", reason: "An orange accent with rounder cards.",
                    note: flat.uuidString, tokens: ["accent": .string("orange"), "cardRadius": .number(20)],
                    apply: false),
                Proposal(
                    id: "mango", date: at(8), name: "Mango", reason: "The MANGO preset, whole.",
                    note: flat.uuidString, code: "a74hGF01CVunaG0vzZJG", apply: false),
            ])
        return (notes, agent)
    }()

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
