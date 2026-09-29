import Foundation
import SwiftUI
import SweetUIDesignSurface
import SweetUIFoundations

/// Renders one item's demo alone for screenshot capture. Launched by
/// `Scripts/capture_previews.py` with `-item <name>`, optionally
/// `-appearance dark`, `-preset <code>` or `-theme <preset name>`, and
/// `-capture-info <path>`, where the screen writes the demo's frame so the
/// script can crop the screenshot to the content.
struct ItemCaptureScreen: View {
    let name: String
    let arguments: LaunchArguments

    @Environment(\.displayScale) private var displayScale

    private var theme: RegistryTheme {
        if let code = arguments.value(after: "-preset"), let tuned = ThemeTuning(presetCode: code) {
            return tuned.theme
        }
        return arguments.value(after: "-theme").flatMap(RegistryTheme.preset(named:)) ?? .indigo
    }

    private var colorScheme: ColorScheme {
        arguments.value(after: "-appearance") == "dark" ? .dark : .light
    }

    var body: some View {
        ScrollView {
            ItemDemoView(name: name)
                .padding()
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { frame in
                    writeCaptureInfo(frame)
                }
                .frame(maxWidth: 792)
                .frame(maxWidth: .infinity)
        }
        .scrollDisabled(true)
        .background(Color(uiColor: .systemBackground))
        .registryTheme(theme)
        .preferredColorScheme(colorScheme)
    }

    private func writeCaptureInfo(_ frame: CGRect) {
        guard let path = arguments.value(after: "-capture-info") else { return }
        let info: [String: Double] = [
            "x": frame.minX,
            "y": frame.minY,
            "width": frame.width,
            "height": frame.height,
            "scale": displayScale,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: info, options: [.sortedKeys]) else {
            return
        }
        try? data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }
}
