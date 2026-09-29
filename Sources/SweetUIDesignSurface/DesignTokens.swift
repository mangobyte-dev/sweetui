#if canImport(UIKit)
import Foundation
import Sharing

extension SharedKey where Self == FileStorageKey<ThemeTuning>.Default {
    /// The design tokens under tuning, shared by every view of the surface and
    /// persisted as `registry-tokens.json` in the app's Documents directory
    /// (`design-tokens.json` is the name seeFood's own token store already
    /// uses there; measured 2026-09-08, the two clobbered each other). The
    /// file is the export: it carries the preset code the registry tools read
    /// (`sweetui preset decode`, `preset apply`, the MCP
    /// `describe_preset` and `apply_preset`) beside every knob, in the shape
    /// `ThemeTuning`'s `Codable` conformance describes. A tuning survives a
    /// relaunch through it.
    public static var designTokens: Self {
        Self[
            .fileStorage(ThemeTuning.fileURL, decoder: nil, encoder: ThemeTuning.fileEncoder),
            default: .default
        ]
    }
}

extension ThemeTuning {
    /// Where the surface keeps the tokens. On a simulator the file is readable
    /// from the host through the app's data container (`xcrun simctl
    /// get_app_container <udid> <bundle id> data`); on a device the code and
    /// the Swift leave through the panel's copy actions and the share sheet.
    public static let fileURL = URL.documentsDirectory.appending(component: "registry-tokens.json")

    /// Pretty-printed with sorted keys, so the file reads as a document and a
    /// diff of it shows the knob that moved.
    static var fileEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
#endif
