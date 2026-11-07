#if canImport(UIKit)
import Foundation
import Sharing

/// What the agent last changed on the device, as MCP `set_tuning` and
/// `set_knobs` record it in `design-agent-change.json`: the panel shows it
/// and offers Undo, which restores the previous values and clears the
/// record. A new write replaces the record, so Undo is one step deep.
public struct AgentChange: Codable, Equatable, Sendable {
    public enum What: String, Codable, Sendable {
        case tuning, knobs
    }

    public var what: What
    public var changedAt: Date
    /// For a tuning change: the code the device had, `nil` when it had none.
    public var previousCode: String?
    public var code: String?
    /// For a knobs change: the item and its values before the write.
    public var item: String?
    public var previousKnobs: [String: Double]?

    /// What the banner says.
    var summary: String {
        switch what {
        case .tuning: "The agent changed the theme" + (code.map { " to \($0)" } ?? "")
        case .knobs: "The agent changed \(item ?? "an item")'s knobs"
        }
    }

    /// Undoes the change against the live stores. A tuning change goes back
    /// to the previous code over the current tuning (the switches stay); a
    /// knobs change puts the item's previous values back, or clears them.
    @MainActor
    func undo(tuning: inout ThemeTuning, knobs: KnobStore) {
        switch what {
        case .tuning:
            if let previousCode, let previous = ThemeTuning(presetCode: previousCode, base: tuning) {
                tuning = previous
            } else if previousCode == nil {
                tuning = ThemeTuning(presetCode: ThemeTuning.default.presetCode, base: tuning) ?? tuning
            }
        case .knobs:
            guard let item else { return }
            knobs.restore(item, previousKnobs ?? [:])
        }
    }
}

extension SharedKey where Self == FileStorageKey<AgentChange?>.Default {
    static var agentChange: Self {
        Self[
            .fileStorage(
                URL.documentsDirectory.appending(component: "design-agent-change.json"),
                decoder: DesignNote.fileDecoder, encoder: DesignNote.fileEncoder),
            default: nil
        ]
    }
}
#endif
