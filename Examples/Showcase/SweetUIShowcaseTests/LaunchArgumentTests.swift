import Testing
import UIKit

// App-hosted: these run inside the launched SweetUIShowcase process, so they see what the app's
// `init()` did to process-wide state.
@MainActor
struct LaunchArgumentTests {
    /// `-disable-animations` is a UI-suite switch for the iPad keyboard-animation hang, never set
    /// by a person. A normal launch must keep UIKit animations on, or every demo and capture
    /// renders without its transitions.
    @Test func normalLaunchKeepsAnimationsEnabled() {
        #expect(!ProcessInfo.processInfo.arguments.contains("-disable-animations"))
        #expect(UIView.areAnimationsEnabled)
    }
}
