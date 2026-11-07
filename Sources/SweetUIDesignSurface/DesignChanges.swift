#if canImport(UIKit)
import Foundation

/// The token and knob differences between two designs, in words: "Card
/// radius: 16 to 20 pt", "Button height: 36 to 44". Source reads as Default,
/// the only baseline whose token values Tune knows.
enum DesignChanges {
    struct Change: Equatable, Identifiable, Sendable {
        var key: String
        var title: String
        /// The item a knob belongs to; `nil` for a token.
        var item: String?
        var from: String
        var to: String

        var id: String { (item.map { $0 + "." } ?? "") + key }
        var words: String { "\(title): \(from) to \(to)" }
    }

    /// Every token, then every knob, that `b` moves from `a`. `title` names
    /// an item and `knobTitle` an item's knob, as the host titles them.
    static func between(
        _ a: DesignHistory.Design, _ b: DesignHistory.Design,
        title: (String) -> String = { $0 }, knobTitle: (String, String) -> String = { $1 }
    ) -> [Change] {
        let from = a.code.isEmpty ? ThemeTuning.default : ThemeTuning(presetCode: a.code) ?? .default
        let to = b.code.isEmpty ? ThemeTuning.default : ThemeTuning(presetCode: b.code) ?? .default
        var changes = to.differences(from: from).map { difference in
            let unit = Self.isPoints(difference.key) ? " pt" : ""
            return Change(
                key: difference.key, title: Self.words(difference.key), item: nil,
                from: difference.from, to: difference.to + unit)
        }
        for item in Set(a.knobs.keys).union(b.knobs.keys).sorted() {
            let before = a.knobs[item] ?? [:]
            let after = b.knobs[item] ?? [:]
            for knob in Set(before.keys).union(after.keys).sorted() where before[knob] != after[knob] {
                changes.append(Change(
                    key: knob, title: "\(title(item)) \(knobTitle(item, knob).lowercased())", item: item,
                    from: before[knob].map { ThemeTuning.RGB.format($0, minimum: 0) } ?? "default",
                    to: after[knob].map { ThemeTuning.RGB.format($0, minimum: 0) } ?? "default"))
            }
        }
        return changes
    }

    /// A key in sentence case: `cardRadius` reads "Card radius".
    static func words(_ key: String) -> String {
        var text = ""
        for character in key {
            if character.isUppercase, !text.isEmpty { text.append(" ") }
            text.append(text.isEmpty ? Character(character.uppercased()) : Character(character.lowercased()))
        }
        return text
    }

    /// Metrics in points: radii, spacing, padding, and border widths.
    private static func isPoints(_ key: String) -> Bool {
        ["Radius", "Spacing", "Padding", "Width"].contains { key.hasSuffix($0) }
    }
}
#endif
