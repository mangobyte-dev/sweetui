#if canImport(UIKit)
import Foundation

/// What the person hands to the agent when the design on the device is the
/// one to ship: its id, the version it carries, the design's code (empty
/// under Source) and its Swift, every moved knob, the changes from Default,
/// the open notes with their screenshots, and the previous hand-off, which
/// still takes an answer. One file, `design-handoff.json` beside the tokens;
/// MCP `read_handoff` reads it, and the agent's answer with changed files
/// makes it Shipped.
public struct DesignHandoff: Codable, Equatable, Sendable {
    public struct Note: Codable, Equatable, Sendable {
        public var id: UUID
        public var text: String
        public var item: String?
        public var screen: String?
        public var screenshot: String?
    }

    /// The hand-off sent before this one: its answer still counts.
    public struct Previous: Codable, Equatable, Sendable {
        public var id: UUID
        public var sentAt: Date
        public var presetCode: String
        public var knobs: [String: [String: Double]]
    }

    public var id: UUID
    public var sentAt: Date
    /// The version current when it was sent.
    public var version: UUID?
    public var presetCode: String
    public var swift: String
    public var knobs: [String: [String: Double]]
    public var differences: [ThemeTuning.Difference]
    public var openNotes: [Note]
    public var screenshot: String?
    public var previous: Previous?

    public static let fileURL = URL.documentsDirectory.appending(component: "design-handoff.json")

    /// The design it carries.
    var design: DesignHistory.Design { DesignHistory.Design(code: presetCode, knobs: knobs) }

    /// The hand-off of `design`, the theme `tuning` shows: under Source no
    /// code, no Swift, and no changes, since the app shows its own theme.
    /// Open notes are those the agent has not answered.
    static func capture(
        id: UUID, sentAt: Date, design: DesignHistory.Design, tuning: ThemeTuning, version: UUID?,
        notes: [DesignNote], answers: [String: AgentRecord.Answer], screenshot: String?, previous: DesignHandoff?
    ) -> DesignHandoff {
        let isSource = design.code.isEmpty
        return DesignHandoff(
            id: id, sentAt: sentAt, version: version, presetCode: design.code,
            swift: isSource ? "" : tuning.swiftSource, knobs: design.knobs,
            differences: isSource ? [] : tuning.differences(from: .default),
            openNotes: notes.filter { answers[$0.id.uuidString] == nil }.map {
                Note(id: $0.id, text: $0.text, item: $0.item, screen: $0.screen, screenshot: $0.screenshot)
            },
            screenshot: screenshot,
            previous: previous.map {
                Previous(id: $0.id, sentAt: $0.sentAt, presetCode: $0.presetCode, knobs: $0.knobs)
            })
    }
}
#endif
