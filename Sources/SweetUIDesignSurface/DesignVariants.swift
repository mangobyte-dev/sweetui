#if canImport(UIKit)
import Foundation
import Sharing

/// Themes an agent stages for a person to flip between on the device, in
/// `design-variants.json` beside the tokens: each a name and a preset code.
/// The panel shows them as chips under the presets; a tap applies the code
/// and writes the pick back as `chosen`, which the agent reads. No build and
/// no screenshot per variant: a code is applied at runtime.
public struct DesignVariants: Codable, Equatable, Sendable {
    public struct Variant: Codable, Equatable, Identifiable, Sendable {
        public var name: String
        public var code: String
        public var id: String { name }

        public init(name: String, code: String) {
            self.name = name
            self.code = code
        }
    }

    public var variants: [Variant] = []
    /// The name of the variant the person last picked, or `nil`.
    public var chosen: String? = nil

    public init(variants: [Variant] = [], chosen: String? = nil) {
        self.variants = variants
        self.chosen = chosen
    }

    public static let fileURL = URL.documentsDirectory.appending(component: "design-variants.json")

    /// The tuning the variant decodes to over the current one (the
    /// environment switches stay), or `nil` for a code the panel cannot read.
    func tuning(for variant: Variant, base: ThemeTuning) -> ThemeTuning? {
        ThemeTuning(presetCode: variant.code, base: base)
    }

    /// The variant whose code the tuning matches right now, so the chip
    /// reads selected only while the knobs still agree with it.
    func matching(_ tuning: ThemeTuning) -> Variant? {
        variants.first { $0.code == tuning.presetCode }
    }
}

extension SharedKey where Self == FileStorageKey<DesignVariants>.Default {
    static var designVariants: Self {
        Self[
            .fileStorage(DesignVariants.fileURL, decoder: nil, encoder: ThemeTuning.fileEncoder),
            default: DesignVariants()
        ]
    }
}
#endif
