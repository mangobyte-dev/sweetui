#if canImport(UIKit)
import Foundation
import Sharing
import SweetUIFoundations

/// One tunable number an item exposes: its name in the item's source, the
/// title the panel shows, its range and step, and the shipped default. A step
/// that is not positive becomes 1 and a shipped value outside the range is
/// clamped into it, with a line in the log, so a host's slip never traps the
/// slider in a build that ships.
public struct ItemKnob: Identifiable, Sendable, Equatable {
    /// How the panel draws the knob and how the item reads it: a slider over
    /// a number, a switch stored as 0 or 1, or a picker stored as the index
    /// into its options (`registryKnob(_:_:options:default:)`).
    public enum Kind: Sendable, Equatable {
        case number, bool, choice([String])
    }

    public let name: String
    public let title: String
    public let range: ClosedRange<Double>
    public let step: Double
    public let shipped: Double
    public let kind: Kind
    public var id: String { name }

    public init(_ name: String, title: String? = nil, in range: ClosedRange<Double>, step: Double = 1, shipped: Double) {
        self.init(name, title: title, in: range, step: step, shipped: shipped, kind: .number)
    }

    /// A switch, read with `registryKnob(_:_:default: Bool)`.
    public static func bool(_ name: String, title: String? = nil, shipped: Bool) -> ItemKnob {
        ItemKnob(name, title: title, in: 0...1, step: 1, shipped: shipped ? 1 : 0, kind: .bool)
    }

    /// A choice among words, read with `registryKnob(_:_:options:default:)`;
    /// a shipped word outside the options falls back to the first.
    public static func choice(_ name: String, title: String? = nil, options: [String], shipped: String) -> ItemKnob {
        let options = options.isEmpty ? [shipped] : options
        let index = options.firstIndex(of: shipped) ?? 0
        if options.firstIndex(of: shipped) == nil {
            SurfaceLog.logger.error("Knob \(name, privacy: .public): shipped '\(shipped, privacy: .public)' is not an option; using the first")
        }
        return ItemKnob(name, title: title, in: 0...Double(options.count - 1), step: 1, shipped: Double(index), kind: .choice(options))
    }

    private init(_ name: String, title: String?, in range: ClosedRange<Double>, step: Double, shipped: Double, kind: Kind) {
        self.name = name
        self.title = title ?? name
        self.range = range
        self.kind = kind
        if step > 0 {
            self.step = step
        } else {
            SurfaceLog.logger.error("Knob \(name, privacy: .public): step \(step) is not positive; using 1")
            self.step = 1
        }
        if range.contains(shipped) {
            self.shipped = shipped
        } else {
            SurfaceLog.logger.error("Knob \(name, privacy: .public): shipped \(shipped) is outside \(range.lowerBound)...\(range.upperBound); clamped")
            self.shipped = min(max(range.lowerBound, shipped), range.upperBound)
        }
    }

    /// The option a stored value names, for a choice knob.
    func option(for value: Double) -> String? {
        guard case .choice(let options) = kind else { return nil }
        let index = Int(value.rounded())
        return options.indices.contains(index) ? options[index] : nil
    }
}

/// A knob as an agent declares it in `design-knob-specs.json`: the file is
/// `{"<item>": [spec, ...]}`, each spec `{"name", "title"?, "kind": "number" |
/// "bool" | "choice", "min", "max", "step"? (number), "options" (choice),
/// "shipped"}` with `shipped` a number, a bool, or a word by kind. The panel
/// shows the controls after the file lands; the item reads the knob once it
/// calls `registryKnob` for it, which takes one build.
public struct ItemKnobSpec: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case number, bool, choice }
    public enum Shipped: Codable, Equatable, Sendable {
        case number(Double), bool(Bool), word(String)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let flag = try? container.decode(Bool.self) { self = .bool(flag) }
            else if let number = try? container.decode(Double.self) { self = .number(number) }
            else { self = .word(try container.decode(String.self)) }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .number(let number): try container.encode(number)
            case .bool(let flag): try container.encode(flag)
            case .word(let word): try container.encode(word)
            }
        }
    }

    public var name: String
    public var title: String?
    public var kind: Kind
    public var min: Double?
    public var max: Double?
    public var step: Double?
    public var options: [String]?
    public var shipped: Shipped

    /// The knob, or `nil` with a log line for a spec the panel cannot draw.
    public var knob: ItemKnob? {
        switch (kind, shipped) {
        case (.number, .number(let value)):
            guard let min, let max, min < max else {
                SurfaceLog.logger.error("Knob spec \(name, privacy: .public): a number needs min < max")
                return nil
            }
            return ItemKnob(name, title: title, in: min...max, step: step ?? 1, shipped: value)
        case (.bool, .bool(let flag)):
            return .bool(name, title: title, shipped: flag)
        case (.choice, .word(let word)):
            guard let options, !options.isEmpty else {
                SurfaceLog.logger.error("Knob spec \(name, privacy: .public): a choice needs options")
                return nil
            }
            return .choice(name, title: title, options: options, shipped: word)
        default:
            SurfaceLog.logger.error("Knob spec \(name, privacy: .public): shipped does not match kind \(kind.rawValue, privacy: .public)")
            return nil
        }
    }
}

extension SharedKey where Self == FileStorageKey<[String: [ItemKnobSpec]]>.Default {
    /// The agent-declared knobs, beside the design tokens.
    static var designKnobSpecs: Self {
        Self[
            .fileStorage(
                URL.documentsDirectory.appending(component: "design-knob-specs.json"),
                decoder: nil, encoder: ThemeTuning.fileEncoder),
            default: [:]
        ]
    }
}

extension SharedKey where Self == FileStorageKey<[String: [String: Double]]>.Default {
    /// The tuned knob values by item and knob name, in `design-knobs.json`
    /// beside the design tokens file. A value equal to its shipped default
    /// is never stored, so the file lists only what moved.
    static var designKnobs: Self {
        Self[
            .fileStorage(
                URL.documentsDirectory.appending(component: "design-knobs.json"),
                decoder: nil, encoder: ThemeTuning.fileEncoder),
            default: [:]
        ]
    }
}

/// The knobs the host registered per item, and the tuned values.
@MainActor
final class KnobStore {
    @Shared(.designKnobs) var values
    @Shared(.designKnobSpecs) var declared
    /// The host's knobs, registered in code.
    private(set) var specs: [String: [ItemKnob]] = [:]

    init() {}

    func register(_ knobs: [String: [ItemKnob]]) {
        specs.merge(knobs) { _, new in new }
    }

    /// The host's knobs for the item, then the agent's declared ones whose
    /// names the host did not take.
    func knobs(for item: String) -> [ItemKnob] {
        let host = specs[item] ?? []
        let taken = Set(host.map(\.name))
        return host + (declared[item] ?? []).compactMap(\.knob).filter { !taken.contains($0.name) }
    }

    /// The names of the item's knobs the agent declared and the host did not take.
    func declaredNames(for item: String) -> Set<String> {
        Set((declared[item] ?? []).map(\.name)).subtracting((specs[item] ?? []).map(\.name))
    }

    func value(_ item: String, _ knob: ItemKnob) -> Double {
        values[item]?[knob.name] ?? knob.shipped
    }

    /// Writes a value; writing the shipped default deletes the override.
    func set(_ item: String, _ knob: ItemKnob, to value: Double) {
        $values.withLock { values in
            if value == knob.shipped {
                values[item]?[knob.name] = nil
                if values[item]?.isEmpty == true { values[item] = nil }
            } else {
                values[item, default: [:]][knob.name] = value
            }
        }
    }

    func reset(_ item: String) {
        $values.withLock { $0[item] = nil }
    }

    /// Replaces every stored value, as a history entry restores them.
    func replaceAll(_ stored: [String: [String: Double]]) {
        $values.withLock { $0 = stored }
    }

    /// Puts an item's stored values back as they were; empty clears them.
    func restore(_ item: String, _ stored: [String: Double]) {
        $values.withLock { $0[item] = stored.isEmpty ? nil : stored }
    }

    /// What the items read from the environment.
    var environmentValue: RegistryKnobs { RegistryKnobs(values: values) }
}
#endif
