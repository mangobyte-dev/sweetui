import Foundation
import SwiftUI
import SweetUIShowcaseFeature

@main
struct SweetUIShowcaseApp: App {
    init() {
        // A test-harness switch, never set by a person: the UI suite passes it
        // on the iPad destination, where the iOS 27.0 simulator's in-process
        // keyboard animation intermittently never reports completion and every
        // later XCTest step waits its full idle timeout (CHANGELOG.md, Known
        // limitations). With UIKit animations off there is nothing to wait on.
        if ProcessInfo.processInfo.arguments.contains("-disable-animations") {
            UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .transformEnvironment(\.dynamicTypeSize) { size in
                    if ProcessInfo.processInfo.arguments.contains("-accessibility-size") {
                        size = .accessibility3
                    }
                }
                .transformEnvironment(\.layoutDirection) { direction in
                    if ProcessInfo.processInfo.arguments.contains("-right-to-left") {
                        direction = .rightToLeft
                    }
                }
        }
    }
}
