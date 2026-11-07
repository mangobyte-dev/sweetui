#if canImport(UIKit)
import Foundation

/// What the person hands to the agent when the design on the device is the
/// one to ship: the theme as a preset code and as Swift, the variant they
/// chose, every moved knob, each knob that differs from the shipped theme,
/// the open notes with their screenshots, and the named checkpoints. One
/// file, `design-handoff.json` beside the tokens; MCP `read_handoff` reads
/// it and the agent writes the theme and the knob defaults into source.
public struct DesignHandoff: Codable, Equatable, Sendable {
    public struct Note: Codable, Equatable, Sendable {
        public var id: UUID
        public var text: String
        public var item: String?
        public var screen: String?
        public var screenshot: String?
    }

    public struct Checkpoint: Codable, Equatable, Sendable {
        public var name: String
        public var code: String
        public var knobs: [String: [String: Double]]
    }

    public var sentAt: Date
    public var presetCode: String
    public var swift: String
    public var chosenVariant: String?
    public var knobs: [String: [String: Double]]
    public var differences: [ThemeTuning.Difference]
    public var openNotes: [Note]
    public var checkpoints: [Checkpoint]
    public var screenshot: String?

    public static let fileURL = URL.documentsDirectory.appending(component: "design-handoff.json")

    static func capture(
        tuning: ThemeTuning, knobs: [String: [String: Double]], variants: DesignVariants,
        notes: [DesignNote], history: DesignHistory, screenshot: String?
    ) -> DesignHandoff {
        DesignHandoff(
            sentAt: .now, presetCode: tuning.presetCode, swift: tuning.swiftSource,
            chosenVariant: variants.matching(tuning)?.name ?? variants.chosen, knobs: knobs,
            differences: tuning.differences(from: .default),
            openNotes: notes.filter { !$0.resolved }.map {
                Note(id: $0.id, text: $0.text, item: $0.item, screen: $0.screen, screenshot: $0.screenshot)
            },
            checkpoints: history.named.map { Checkpoint(name: $0.name ?? "", code: $0.design.code, knobs: $0.design.knobs) },
            screenshot: screenshot)
    }
}

#endif
