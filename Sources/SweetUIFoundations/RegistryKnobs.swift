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
}
