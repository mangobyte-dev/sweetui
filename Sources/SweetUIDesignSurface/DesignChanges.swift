#if canImport(UIKit)
import Foundation

/// The token and knob differences between two designs, in words: "Card
/// radius: 16 to 20 pt", "Label on accent: white to black", "Button height:
/// 36 to 44". Titles and units come from `TokenCatalog`. Source reads as
/// Default, the only baseline whose token values Tune knows.
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
            let token = TokenCatalog.token(owning: difference.key)
            var (before, after) = (difference.from, difference.to)
            // A choice reads as the word its picker shows, not its stored value.
            if let token, case .choice = token.kind {
                (before, after) = (token.value(from).lowercased(), token.value(to).lowercased())
            }
            return Change(
                key: difference.key, title: TokenCatalog.title(ofKey: difference.key), item: nil,
                from: before, to: after + (token?.unit.map { " " + $0 } ?? ""))
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
}
#endif
