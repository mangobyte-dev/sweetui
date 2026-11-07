#if canImport(UIKit)
import Foundation
import Sharing

/// Every settled state the design passed through on the device, in
/// `design-history.json` beside the tokens: the preset code and the knob
/// values, who moved it (the person, the agent, or a variant pick), and a
/// name when the person checkpoints it. The cursor is the entry the device
/// shows now; Undo and Redo walk it, and a new change after an Undo drops
/// the entries past the cursor, as an editor's history does.
public struct DesignHistory: Codable, Equatable, Sendable {
    public enum Source: String, Codable, Sendable {
        case person, agent, variant, shipped
    }

    public struct Entry: Codable, Equatable, Identifiable, Sendable {
        public var id: UUID
        public var date: Date
        public var code: String
        public var knobs: [String: [String: Double]]
        public var source: Source
        public var name: String? = nil

        public init(id: UUID = UUID(), date: Date = .now, code: String, knobs: [String: [String: Double]], source: Source, name: String? = nil) {
            self.id = id
            self.date = date
            self.code = code
            self.knobs = knobs
            self.source = source
            self.name = name
        }

        /// What the entry and the live state compare on.
        var state: State { State(code: code, knobs: knobs) }
    }

    /// The part of the device's state the history records.
    public struct State: Equatable, Sendable {
        public var code: String
        public var knobs: [String: [String: Double]]
    }

    /// At most this many entries are kept; the oldest unnamed ones go first.
    static let capacity = 200

    public var entries: [Entry] = []
    public var cursor: Int? = nil

    public init(entries: [Entry] = [], cursor: Int? = nil) {
        self.entries = entries
        self.cursor = cursor
    }

    public static let fileURL = URL.documentsDirectory.appending(component: "design-history.json")

    public var current: Entry? { cursor.flatMap { entries.indices.contains($0) ? entries[$0] : nil } }
    public var canUndo: Bool { (cursor ?? 0) > 0 }
    public var canRedo: Bool { cursor.map { $0 < entries.count - 1 } ?? false }
    public var named: [Entry] { entries.filter { $0.name != nil } }

    /// Records a settled state. Nothing happens when it equals the current
    /// entry (a rewrite that moved nothing); otherwise the entries past the
    /// cursor go, the state is appended, and the cursor moves to it.
    public mutating func record(_ state: State, source: Source) {
        if let current, current.state == state { return }
        if let cursor, cursor < entries.count - 1 { entries.removeSubrange((cursor + 1)...) }
        entries.append(Entry(code: state.code, knobs: state.knobs, source: source))
        trim()
        cursor = entries.count - 1
    }

    /// The entry one step back, moving the cursor; `nil` at the start.
    public mutating func undo() -> Entry? {
        guard canUndo, let cursor else { return nil }
        self.cursor = cursor - 1
        return entries[cursor - 1]
    }

    /// The entry one step forward, moving the cursor; `nil` at the end.
    public mutating func redo() -> Entry? {
        guard canRedo, let cursor else { return nil }
        self.cursor = cursor + 1
        return entries[cursor + 1]
    }

    /// Moves the cursor to an entry; `nil` for an id the history lacks.
    public mutating func restore(_ id: UUID) -> Entry? {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return nil }
        cursor = index
        return entries[index]
    }

    /// Names the current entry; an empty name clears it.
    public mutating func name(_ name: String) {
        guard let cursor, entries.indices.contains(cursor) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        entries[cursor].name = trimmed.isEmpty ? nil : trimmed
    }

    private mutating func trim() {
        while entries.count > Self.capacity, let index = entries.firstIndex(where: { $0.name == nil }) {
            entries.remove(at: index)
            if let cursor, cursor >= index { self.cursor = cursor - 1 }
        }
    }
}

extension SharedKey where Self == FileStorageKey<DesignHistory>.Default {
    static var designHistory: Self {
        Self[
            .fileStorage(DesignHistory.fileURL, decoder: DesignNote.fileDecoder, encoder: DesignNote.fileEncoder),
            default: DesignHistory()
        ]
    }
}
#endif
