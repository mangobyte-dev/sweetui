#if canImport(UIKit)
import Foundation
import Sharing

/// Every design the device showed, in `design-history.json` beside the
/// tokens, as a tree of versions. Each version names its author, what it came
/// from, and its parent; the person may name it. A change after Undo branches
/// from Current and deletes nothing. A trial is the one proposal on the device
/// on top of its base, decisions say what became of each proposal, and
/// Shipped is the last hand-off the agent answered with changed files.
public struct DesignHistory: Codable, Equatable, Sendable {
    /// The theme code and every knob value. An empty design is Source: the
    /// app's own compiled theme with no knob moved.
    public struct Design: Codable, Equatable, Sendable {
        public var code: String
        public var knobs: [String: [String: Double]]

        public init(code: String = "", knobs: [String: [String: Double]] = [:]) {
            self.code = code
            self.knobs = knobs
        }
    }

    public enum Author: String, Codable, Sendable {
        case you, agent
    }

    /// What a version came from.
    public enum Origin: Codable, Equatable, Sendable {
        case first, edit, preset(name: String), proposal(id: String), defaultTheme, source, code
    }

    public struct Entry: Codable, Equatable, Identifiable, Sendable {
        public var id: UUID
        public var date: Date
        public var design: Design
        public var author: Author
        public var origin: Origin
        public var name: String? = nil
        public var parent: UUID? = nil

        public init(
            id: UUID = UUID(), date: Date = .now, design: Design, author: Author, origin: Origin,
            name: String? = nil, parent: UUID? = nil
        ) {
            self.id = id
            self.date = date
            self.design = design
            self.author = author
            self.origin = origin
            self.name = name
            self.parent = parent
        }
    }

    /// The proposal on the device: its version is a child of the base.
    public struct Trial: Codable, Equatable, Sendable {
        public var proposal: String
        public var version: UUID
        public var base: UUID
    }

    public struct Decision: Codable, Equatable, Sendable {
        public enum State: String, Codable, Sendable {
            case tried, kept, discarded
        }

        public var state: State
        public var date: Date
    }

    /// A hand-off the agent answered with changed files: the design it
    /// carried now lives in source.
    public struct Shipped: Codable, Equatable, Sendable {
        public var handoff: UUID
        public var design: Design
        public var date: Date
        public var changedFiles: [String]
    }

    /// Past this many versions the oldest one that may drop goes first.
    static let capacity = 200

    public var entries: [Entry] = []
    public var current: UUID? = nil
    public var trial: Trial? = nil
    /// Keyed by proposal id.
    public var decisions: [String: Decision] = [:]
    public var shipped: Shipped? = nil
    /// The version the last Restore left; Undo returns to it until Current moves again.
    public var returnTo: UUID? = nil

    public init(entries: [Entry] = [], current: UUID? = nil) {
        self.entries = entries
        self.current = current
    }

    public static let fileURL = URL.documentsDirectory.appending(component: "design-history.json")

    public func entry(_ id: UUID?) -> Entry? {
        guard let id else { return nil }
        return entries.first { $0.id == id }
    }

    public var canUndo: Bool { trial != nil || returnTo != nil || entry(current)?.parent != nil }
    public var canRedo: Bool { entries.contains { $0.parent != nil && $0.parent == current } }
    public var named: [Entry] { entries.filter { $0.name != nil } }

    /// Records a design as a child of Current and makes it current. Nothing
    /// happens when it equals Current's design. While a proposal is on trial,
    /// an edit keeps it and any other origin discards it first.
    public mutating func record(_ design: Design, author: Author, origin: Origin) {
        guard design != entry(current)?.design else { return }
        if trial != nil {
            if origin == .edit { keep() } else { discard() }
            guard design != entry(current)?.design else { return }
        }
        append(Entry(design: design, author: author, origin: origin, parent: current))
    }

    /// Moves Current back and returns the version it lands on: the base while
    /// a proposal is on trial, which discards it; the version the last Restore
    /// left, right after it; otherwise the parent, which discards a kept
    /// proposal whose version it leaves. `nil` at a root.
    @discardableResult
    public mutating func undo() -> Entry? {
        if trial != nil {
            discard()
            return entry(current)
        }
        if let returnTo {
            current = returnTo
            self.returnTo = nil
            return entry(returnTo)
        }
        guard let leaving = entry(current), let parent = leaving.parent else { return nil }
        if case .proposal(let id) = leaving.origin, decisions[id]?.state == .kept {
            decisions[id] = Decision(state: .discarded, date: .now)
        }
        current = parent
        return entry(parent)
    }

    /// Moves Current to its newest child and returns it; `nil` at a leaf.
    /// A proposal's version that is not kept goes back on trial.
    @discardableResult
    public mutating func redo() -> Entry? {
        guard let current, let child = entries.last(where: { $0.parent == current }) else { return nil }
        self.current = child.id
        returnTo = nil
        resumeTrial(child)
        return child
    }

    /// Makes a past version current and remembers the one it left, deleting
    /// nothing; a trial is discarded first, and a proposal's version that is
    /// not kept goes back on trial. `nil` for an id the history lacks.
    @discardableResult
    public mutating func restore(_ id: UUID) -> Entry? {
        guard let target = entry(id) else { return nil }
        if let trial, trial.version != id { discard() }
        if id != current {
            returnTo = current
            current = id
        }
        resumeTrial(target)
        return target
    }

    /// The tree decides the state: Current on a proposal's version puts the
    /// proposal on trial again over that version's parent, unless it is kept.
    private mutating func resumeTrial(_ entry: Entry) {
        guard case .proposal(let id) = entry.origin, !id.isEmpty, let base = entry.parent,
              trial?.version != entry.id, decisions[id]?.state != .kept else { return }
        trial = Trial(proposal: id, version: entry.id, base: base)
        decisions[id] = Decision(state: .tried, date: .now)
    }

    /// Names Current; an empty name clears it.
    public mutating func name(_ name: String) {
        guard let index = entries.firstIndex(where: { $0.id == current }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        entries[index].name = trimmed.isEmpty ? nil : trimmed
    }

    /// Puts a proposal on the device as a version by the agent, a child of
    /// the base: the base of the trial already open, or Current. The proposal
    /// reads tried. Returns the version, or `nil` with no Current to return
    /// to; reconcile the live values first.
    @discardableResult
    public mutating func tryProposal(_ id: String, design: Design) -> Entry? {
        guard let base = trial?.base ?? current else { return nil }
        let version = Entry(design: design, author: .agent, origin: .proposal(id: id), parent: base)
        trial = Trial(proposal: id, version: version.id, base: base)
        decisions[id] = Decision(state: .tried, date: .now)
        append(version)
        return version
    }

    /// Keeps the proposal on trial, whose version stays current, and
    /// discards the Offered siblings named.
    public mutating func keep(discarding offered: [String] = []) {
        guard let trial else { return }
        decisions[trial.proposal] = Decision(state: .kept, date: .now)
        for id in offered { decisions[id] = Decision(state: .discarded, date: .now) }
        self.trial = nil
    }

    /// Turns down a proposal that is offered, not on trial; the device keeps
    /// what it shows.
    public mutating func discard(offered id: String) {
        guard trial?.proposal != id else { return }
        decisions[id] = Decision(state: .discarded, date: .now)
    }

    /// Makes the trial's base current again and discards the proposal. Its
    /// version stays in the tree.
    public mutating func discard() {
        guard let trial else { return }
        decisions[trial.proposal] = Decision(state: .discarded, date: .now)
        current = trial.base
        returnTo = nil
        self.trial = nil
    }

    /// Records a hand-off the agent answered with changed files, then clears
    /// to Source as a version by the agent.
    public mutating func ship(handoff: UUID, design: Design, files: [String]) {
        shipped = Shipped(handoff: handoff, design: design, date: .now, changedFiles: files)
        record(Design(), author: .agent, origin: .source)
    }

    /// Records the live values as an edit when they differ from Current: the
    /// value files are the truth, and a save lost to a kill leaves the
    /// history behind them. With no versions yet, they are the first. Values
    /// equal to an open trial's base mean the trial's save was lost, so the
    /// proposal is discarded, not kept.
    public mutating func reconcile(values: Design) {
        guard values != entry(current)?.design else { return }
        if let trial, values == entry(trial.base)?.design {
            discard()
        } else {
            record(values, author: .you, origin: entries.isEmpty ? .first : .edit)
        }
    }

    private mutating func append(_ entry: Entry) {
        entries.append(entry)
        current = entry.id
        returnTo = nil
        trim()
    }

    /// Drops the oldest version that is unnamed, not Current, not the trial's
    /// base, and not Shipped, until the history fits or nothing may drop.
    /// Shipped is the first version with the design that shipped; a later
    /// return to that design may drop. The dropped version's children take
    /// its parent.
    private mutating func trim() {
        let shippedVersion = entries.first { $0.design == shipped?.design }?.id
        while entries.count > Self.capacity,
            let index = entries.firstIndex(where: { mayDrop($0, shipped: shippedVersion) })
        {
            let dropped = entries.remove(at: index)
            for child in entries.indices where entries[child].parent == dropped.id {
                entries[child].parent = dropped.parent
            }
        }
    }

    private func mayDrop(_ entry: Entry, shipped shippedVersion: UUID?) -> Bool {
        entry.name == nil && entry.id != current && entry.id != trial?.base && entry.id != shippedVersion
    }

    private enum CodingKeys: String, CodingKey {
        case entries, current, trial, decisions, shipped, returnTo
    }

    private enum LegacyKeys: String, CodingKey {
        case cursor
    }

    /// The file before the tree: a list in order, a cursor index, and a
    /// source per entry.
    private struct Legacy: Decodable {
        struct Entry: Decodable {
            enum Source: String, Decodable {
                case person, agent, variant, shipped
            }

            var id: UUID
            var date: Date
            var code: String
            var knobs: [String: [String: Double]]
            var source: Source
            var name: String?
        }

        var entries: [Entry]
        var cursor: Int?
    }

    public init(from decoder: any Decoder) throws {
        if try decoder.container(keyedBy: LegacyKeys.self).contains(.cursor) {
            self.init(legacy: try Legacy(from: decoder))
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            entries: try container.decode([Entry].self, forKey: .entries),
            current: try container.decodeIfPresent(UUID.self, forKey: .current))
        trial = try container.decodeIfPresent(Trial.self, forKey: .trial)
        decisions = try container.decodeIfPresent([String: Decision].self, forKey: .decisions) ?? [:]
        shipped = try container.decodeIfPresent(Shipped.self, forKey: .shipped)
        returnTo = try container.decodeIfPresent(UUID.self, forKey: .returnTo)
    }

    /// A legacy list as a linear chain, each entry the child of the one
    /// before, with the cursor's entry current.
    private init(legacy: Legacy) {
        let chain = legacy.entries.enumerated().map { index, old in
            let (author, origin): (Author, Origin) =
                switch old.source {
                case .person: (.you, .edit)
                case .agent: (.agent, .edit)
                case .variant: (.agent, .proposal(id: ""))
                case .shipped: (.you, .first)
                }
            return Entry(
                id: old.id, date: old.date, design: Design(code: old.code, knobs: old.knobs), author: author,
                origin: origin, name: old.name, parent: index == 0 ? nil : legacy.entries[index - 1].id)
        }
        let current = legacy.cursor.flatMap { chain.indices.contains($0) ? chain[$0].id : nil }
        self.init(entries: chain, current: current)
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
