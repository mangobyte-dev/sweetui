import Foundation
import SwiftUI
import SweetUIFoundations

/// The Showcase root. Three launch modes:
///
/// - default: the browsable catalog (Components, Blocks, Recipes) with the
///   tuning panel beside it; `-preset <code>` starts from that theme
/// - `-item <name>`: one item's demo alone, for screenshot capture; honors
///   `-appearance dark`, `-preset <code>` or `-theme <preset name>`, and
///   `-capture-info <path>`
/// - `-stage-one`: the Stage 1 test fixture screen
public struct ContentView: View {
    public init() {}

    public var body: some View {
        let arguments = LaunchArguments.current
        if arguments.contains("-stage-one") {
            StageOneShowcase()
        } else if let item = arguments.value(after: "-item") {
            ItemCaptureScreen(name: item, arguments: arguments)
        } else {
            CatalogRoot(arguments: arguments)
        }
    }
}

/// Process arguments read once so views stay testable with fixed values.
struct LaunchArguments: Sendable {
    let values: [String]

    static var current: LaunchArguments {
        LaunchArguments(values: ProcessInfo.processInfo.arguments)
    }

    func contains(_ flag: String) -> Bool {
        values.contains(flag)
    }

    func value(after flag: String) -> String? {
        guard let index = values.firstIndex(of: flag), values.indices.contains(index + 1) else {
            return nil
        }
        return values[index + 1]
    }
}

#Preview("Catalog") {
    ContentView()
}
