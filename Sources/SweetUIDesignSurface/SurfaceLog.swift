#if canImport(UIKit)
import os

/// The tool's log: a host's mistake at the boundary (a knob with no step, a
/// token file that fails to decode) is reported here and handled, never a
/// crash in the host, because the host overload ships in every configuration.
enum SurfaceLog {
    static let logger = Logger(subsystem: "dev.mangobyte.sweetui", category: "design-surface")
}
#endif
