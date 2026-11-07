import SwiftUI

/// Per-item numeric knobs a design surface can tune: values keyed by item
/// name and knob name, injected through the environment. `nil`, the default,
/// means no surface, and ``SwiftUI/View/registryKnob(_:_:default:)`` returns
/// the shipped default. An item that wants a knob reads it once in its body
/// and draws with the value, so the surface reaches it without a rebuild.
public struct RegistryKnobs: Equatable, Sendable {
    /// Tuned values by item name, then knob name. A missing entry means the
    /// shipped default.
    public var values: [String: [String: Double]]

    public init(values: [String: [String: Double]] = [:]) {
        self.values = values
    }

    /// The tuned value for a knob, or `default` when none is tuned.
    public func value(_ item: String, _ knob: String, default fallback: Double) -> Double {
        values[item]?[knob] ?? fallback
    }

    /// A switch knob: stored as 0 or 1, read as a Bool.
    public func value(_ item: String, _ knob: String, default fallback: Bool) -> Bool {
        guard let stored = values[item]?[knob] else { return fallback }
        return stored != 0
    }

    /// A choice knob: stored as the option's index, read as the word. An
    /// index outside `options` reads as the default.
    public func value(_ item: String, _ knob: String, options: [String], default fallback: String) -> String {
        guard let stored = values[item]?[knob], stored.isFinite else { return fallback }
        let index = Int(stored.rounded())
        return options.indices.contains(index) ? options[index] : fallback
    }
}

public extension EnvironmentValues {
    @Entry var registryKnobs: RegistryKnobs? = nil
}

public extension EnvironmentValues {
    /// The knob's tuned value from the surface, or its shipped default. Read
    /// it from `@Environment(\.self)` in an item's body:
    /// `environment.registryKnob("button", "padding", default: 12)`.
    func registryKnob(_ item: String, _ knob: String, default fallback: Double) -> Double {
        registryKnobs?.value(item, knob, default: fallback) ?? fallback
    }

    /// A switch knob, stored as 0 or 1:
    /// `environment.registryKnob("card", "showsBorder", default: true)`.
    func registryKnob(_ item: String, _ knob: String, default fallback: Bool) -> Bool {
        registryKnobs?.value(item, knob, default: fallback) ?? fallback
    }

    /// A choice knob, stored as the index into `options`:
    /// `environment.registryKnob("button", "variant", options: ["primary", "outline"], default: "primary")`.
    func registryKnob(_ item: String, _ knob: String, options: [String], default fallback: String) -> String {
        registryKnobs?.value(item, knob, options: options, default: fallback) ?? fallback
    }
}
