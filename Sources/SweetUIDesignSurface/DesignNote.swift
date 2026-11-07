#if canImport(UIKit)
import Foundation
import Sharing

/// What a person says about an item while looking at it, with everything an
/// agent needs to act on it without the screen: the item and the items around
/// it, the tokens it reads, its knob values, where it sat, and the design
/// that was up. Notes persist in `design-notes.json` beside the tokens file,
/// which Tune alone writes; the agent's answer and the date it read the note
/// live in `design-agent.json`.
public struct DesignNote: Codable, Equatable, Identifiable, Sendable {
    public struct Frame: Codable, Equatable, Sendable {
        public var x, y, width, height: Double
    }

    public var id: UUID
    public var createdAt: Date
    public var text: String
    /// The selected item's name, or `nil` for a note about the screen.
    public var item: String?
    /// Every tagged item under the tap that selected it, innermost first; the first is `item`.
    public var chain: [String]
    /// The named screen the note was taken on.
    public var screen: String?
    /// The theme tokens the item reads, from the generated map.
    public var tokens: [String]
    /// The item's tuned knobs by name; only values off their shipped default.
    public var knobs: [String: Double]
    /// The first visible instance's frame in window points.
    public var frame: Frame?
    /// The design's code when the note was taken; empty under Source, while
    /// the app showed its own theme.
    public var presetCode: String
    /// The screenshot taken with the note, relative to Documents (`notes/<id>.png`).
    public var screenshot: String? = nil
    /// The note or proposal this one replies to, by id.
    public var inReplyTo: String? = nil

    public init(
        id: UUID = UUID(), createdAt: Date = .now, text: String, item: String?, chain: [String],
        screen: String?, tokens: [String], knobs: [String: Double], frame: Frame?, presetCode: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.item = item
        self.chain = chain
        self.screen = screen
        self.tokens = tokens
        self.knobs = knobs
        self.frame = frame
        self.presetCode = presetCode
    }
}

extension SharedKey where Self == FileStorageKey<[DesignNote]>.Default {
    /// The notes, oldest first, in `design-notes.json` beside the design tokens.
    static var designNotes: Self {
        Self[
            .fileStorage(DesignNote.fileURL, decoder: DesignNote.fileDecoder, encoder: DesignNote.fileEncoder),
            default: []
        ]
    }
}

extension DesignNote {
    public static let fileURL = URL.documentsDirectory.appending(component: "design-notes.json")

    /// ISO 8601 dates, so the file reads the same from a shell and from Swift.
    static var fileEncoder: JSONEncoder {
        let encoder = ThemeTuning.fileEncoder
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static var fileDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// A note about the current selection, filled from the tool state: the
    /// chain and screen from the selection, the tokens from the generated
    /// map, the knobs and frame from the stores, and `code`, the design's
    /// code (empty under Source).
    @MainActor
    static func take(_ text: String, selection: ItemSelection, code: String, state: DesignSurfaceState) -> DesignNote {
        let item = selection.item
        var knobs: [String: Double] = [:]
        if let item {
            for knob in state.knobs.knobs(for: item) {
                let value = state.knobs.value(item, knob)
                if value != knob.shipped { knobs[knob.name] = value }
            }
        }
        let frame = item.flatMap { name in state.visibleItems.first { $0.name == name }?.frame }
        return DesignNote(
            text: text,
            item: item,
            chain: selection.chain.isEmpty ? (item.map { [$0] } ?? []) : selection.chain,
            screen: state.screen,
            tokens: item.flatMap(RegistryItemTokens.tokens(for:)) ?? [],
            knobs: knobs,
            frame: frame.map { Frame(x: $0.minX, y: $0.minY, width: $0.width, height: $0.height) },
            presetCode: code
        )
    }
}
#endif
