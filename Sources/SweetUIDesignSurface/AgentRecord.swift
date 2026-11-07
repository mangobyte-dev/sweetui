#if canImport(UIKit)
import Foundation
import Sharing

/// What the agent wrote, `design-agent.json` beside the tokens: when it read
/// each note and hand-off, its answers keyed by note or hand-off id, and its
/// proposals. MCP is the file's one writer; Tune holds it through
/// `@SharedReader` and never saves it, so a write of the agent's is never lost
/// to one of Tune's.
public struct AgentRecord: Codable, Equatable, Sendable {
    public struct Reads: Codable, Equatable, Sendable {
        /// Note ids to the date the agent last listed them.
        public var notes: [String: Date] = [:]
        public var handoffs: [String: Date] = [:]

        public init(notes: [String: Date] = [:], handoffs: [String: Date] = [:]) {
            self.notes = notes
            self.handoffs = handoffs
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            notes = try container.decodeIfPresent([String: Date].self, forKey: .notes) ?? [:]
            handoffs = try container.decodeIfPresent([String: Date].self, forKey: .handoffs) ?? [:]
        }
    }

    /// The agent's reply to a note or a hand-off, with the files it changed.
    public struct Answer: Codable, Equatable, Sendable {
        public var reply: String
        public var changedFiles: [String]
        public var date: Date

        public init(reply: String, changedFiles: [String] = [], date: Date) {
            self.reply = reply
            self.changedFiles = changedFiles
            self.date = date
        }
    }

    public var read = Reads()
    /// Keyed by the note's or the hand-off's id as its file spells it.
    public var answers: [String: Answer] = [:]
    public var proposals: [Proposal] = []

    public init(read: Reads = Reads(), answers: [String: Answer] = [:], proposals: [Proposal] = []) {
        self.read = read
        self.answers = answers
        self.proposals = proposals
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        read = try container.decodeIfPresent(Reads.self, forKey: .read) ?? Reads()
        answers = try container.decodeIfPresent([String: Answer].self, forKey: .answers) ?? [:]
        proposals = try container.decodeIfPresent([Proposal].self, forKey: .proposals) ?? []
    }

    public static let fileURL = URL.documentsDirectory.appending(component: "design-agent.json")

    /// A 0-byte file is an empty record: Sharing creates the file it watches
    /// with no bytes before the agent writes it, and reads it again on each
    /// change.
    @Sendable static func decode(_ data: Data) throws -> AgentRecord {
        data.isEmpty ? AgentRecord() : try DesignNote.fileDecoder.decode(AgentRecord.self, from: data)
    }

    @Sendable static func encode(_ record: AgentRecord) throws -> Data {
        try DesignNote.fileEncoder.encode(record)
    }
}

/// A design the agent offers: a full code, or tokens as a delta merged over
/// the version it is tried on, and knob values with `nil` for a knob's
/// default. With `apply` Tune tries it as soon as it arrives.
public struct Proposal: Codable, Equatable, Identifiable, Sendable {
    public enum State: String, Sendable {
        case offered, trying, kept, discarded
    }

    public var id: String
    public var date: Date
    public var name: String
    public var reason: String?
    /// The id of the note it answers.
    public var note: String?
    public var code: String?
    public var tokens: [String: TokenValue]?
    public var knobs: [String: [String: Double?]]?
    public var apply: Bool

    public init(
        id: String, date: Date, name: String, reason: String? = nil, note: String? = nil, code: String? = nil,
        tokens: [String: TokenValue]? = nil, knobs: [String: [String: Double?]]? = nil, apply: Bool = true
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.reason = reason
        self.note = note
        self.code = code
        self.tokens = tokens
        self.knobs = knobs
        self.apply = apply
    }

    /// What the tree and the decisions say together: the open trial is
    /// trying; a kept or discarded decision stands; anything else, never
    /// tried or replaced on trial by another proposal, is offered.
    public func state(in history: DesignHistory) -> State {
        if history.trial?.proposal == id { return .trying }
        switch history.decisions[id]?.state {
        case .kept: return .kept
        case .discarded: return .discarded
        case .tried, nil: return .offered
        }
    }

    /// Whether Tune should try it on arrival: it asks to be applied and was
    /// never tried, from the decisions and never from the versions' origins.
    public func needsTry(in history: DesignHistory) -> Bool {
        apply && history.decisions[id] == nil
    }

    /// The design it puts on the device over `base`: a full code replaces
    /// the theme, tokens merge over the base's theme (Default's under
    /// Source), and knobs merge with `nil` removing an override. A code is
    /// kept in the form Tune writes (a `b` code with every appended field at
    /// its default reads back as `a`), so the version equals what the theme
    /// file then holds. Throws the reason Tune cannot read it.
    public func design(over base: DesignHistory.Design) throws(Unreadable) -> DesignHistory.Design {
        var design = base
        if let code {
            guard let found = ThemeTuning.presetCode(in: code), let theme = ThemeTuning(presetCode: found) else {
                throw Unreadable("Its code is not one Tune can read. Reply to ask the agent for another.")
            }
            design.code = theme.presetCode
        } else if let tokens {
            let theme = base.code.isEmpty ? ThemeTuning.default : ThemeTuning(presetCode: base.code) ?? .default
            guard let merged = theme.applying(tokens) else {
                throw Unreadable("Its tokens are not ones Tune can read. Reply to ask the agent for another.")
            }
            design.code = merged.presetCode
        }
        for (item, values) in knobs ?? [:] {
            var stored = design.knobs[item] ?? [:]
            for (knob, value) in values { stored[knob] = value }
            design.knobs[item] = stored.isEmpty ? nil : stored
        }
        return design
    }

    public struct Unreadable: Error, Equatable, Sendable {
        public var reason: String
        init(_ reason: String) { self.reason = reason }
    }
}

/// A token value as JSON spells it in a proposal's delta.
public enum TokenValue: Codable, Equatable, Sendable {
    case string(String), number(Double), bool(Bool), null

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let flag = try? container.decode(Bool.self) { self = .bool(flag) }
        else if let number = try? container.decode(Double.self) { self = .number(number) }
        else { self = .string(try container.decode(String.self)) }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let text): try container.encode(text)
        case .number(let number): try container.encode(number)
        case .bool(let flag): try container.encode(flag)
        case .null: try container.encodeNil()
        }
    }

    /// The value as `JSONSerialization` takes it.
    var object: Any {
        switch self {
        case .string(let text): text
        case .number(let number): number
        case .bool(let flag): flag
        case .null: NSNull()
        }
    }
}

extension ThemeTuning {
    /// This tuning with a proposal's tokens set over it, through the file's
    /// own decoder so a token reads exactly as in `registry-tokens.json`;
    /// `nil` for a key a code does not carry or a value of the wrong kind.
    func applying(_ tokens: [String: TokenValue]) -> ThemeTuning? {
        guard tokens.keys.allSatisfy({ TuningKeys(rawValue: $0) != nil }),
              let data = try? Self.fileEncoder.encode(self),
              var document = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var tuning = document["tuning"] as? [String: Any]
        else { return nil }
        for (key, value) in tokens { tuning[key] = value.object }
        document["tuning"] = tuning
        document["code"] = nil
        guard let merged = try? JSONSerialization.data(withJSONObject: document) else { return nil }
        return try? JSONDecoder().decode(ThemeTuning.self, from: merged)
    }
}

extension SharedReaderKey where Self == FileStorageKey<AgentRecord>.Default {
    /// The agent's record, read only: Tune never writes it.
    static var designAgent: Self {
        Self[.fileStorage(AgentRecord.fileURL, decode: AgentRecord.decode, encode: AgentRecord.encode), default: AgentRecord()]
    }
}
#endif
