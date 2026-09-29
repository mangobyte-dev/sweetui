import Foundation
import SwiftUI
import SweetUIFoundations
import Testing
import UIKit
@testable import SweetUIDesignSurface
@testable import SweetUIShowcaseFeature

/// The round-trip instrument. Every catalog item's demo renders under each
/// tuned state the way the design surface shows it, then under the two exports
/// a consuming app takes back, compiled: the panel's Swift (`swiftSource`) and
/// the file `sweetui preset apply` writes for the preset code. A pair
/// counts only when both exports reproduce the tuned bitmap byte for byte.
/// The compiled exports live in `RoundTripFixture.swift`, written by
/// `Scripts/round_trip_fixture.sh`; a fixture that no longer matches the
/// current export fails the run instead of measuring a stale copy.
///
/// The sweep renders about 14,300 bitmaps and takes an hour, so it runs only
/// with `ROUNDTRIP_SWEEP` set: `env TEST_RUNNER_ROUNDTRIP_SWEEP=1 xcodebuild
/// test ... -only-testing:SweetUIShowcaseFeatureTests/RoundTripTests`.
/// Every other test here runs always, including the fixture's staleness check
/// and the two controls.
@MainActor
struct RoundTripTests {
    /// The best measured fidelity; the sweep fails below it. Raise it only to a measured value.
    static let floor = 100.0

    @Test func `The compiled exports match what the panel exports now`() {
        let stale = RoundTripDataset.states.filter {
            RoundTripFixture.swiftSource[$0.id] != $0.tuning.swiftSource
                || RoundTripFixture.presetCode[$0.id] != $0.tuning.presetCode
                || (RoundTripFixture.swiftTheme($0.id) == nil) == (RoundTripFixture.swiftCompileError[$0.id] == nil)
                || (RoundTripFixture.presetTheme($0.id) == nil) == (RoundTripFixture.presetCompileError[$0.id] == nil)
        }.map(\.id)
        #expect(stale.isEmpty, "Run Scripts/round_trip_fixture.sh.")
        #expect(RoundTripDataset.states.count == 65)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_SWEEP"] != nil))
    func `Every catalog item under every tuned state renders the same from both exports`() async throws {
        // Each path holds either the compiled export or the compiler's error for it.
        let stale = RoundTripDataset.states.filter {
            RoundTripFixture.swiftSource[$0.id] != $0.tuning.swiftSource
                || RoundTripFixture.presetCode[$0.id] != $0.tuning.presetCode
                || (RoundTripFixture.swiftTheme($0.id) == nil) == (RoundTripFixture.swiftCompileError[$0.id] == nil)
                || (RoundTripFixture.presetTheme($0.id) == nil) == (RoundTripFixture.presetCompileError[$0.id] == nil)
        }.map(\.id)
        try #require(stale.isEmpty, "The compiled exports are stale for \(stale); run Scripts/round_trip_fixture.sh.")

        let clock = ContinuousClock()
        let start = clock.now
        let renderer = RoundTripRenderer()
        var pairs: [PairResult] = []
        var unstable: [String] = []
        let diagnostics = ProcessInfo.processInfo.environment["ROUNDTRIP_DIAG_DIR"].map { URL(fileURLWithPath: $0) }
        for (number, entry) in RegistryCatalogManifest.entries.enumerated() {
            print("ROUNDTRIP item \(number + 1)/73 \(entry.name) at \(Int((clock.now - start) / .seconds(1))) s")
            for (index, state) in RoundTripDataset.states.enumerated() {
              for dark in [false, true] {
                let tuned = await renderer.snapshot({ AnyView(ItemDemoView(name: entry.name)) }, dark: dark) {
                    AnyView($0.modifier(TunedTheme(tuning: state.tuning)).environment(\.registryItemSurface, RegistryItemSurface()))
                }
                if index == 0 && !dark {
                    // The noise floor: the same state twice must match, or no pair of this item can be judged.
                    let again = await renderer.snapshot({ AnyView(ItemDemoView(name: entry.name)) }, dark: dark) {
                        AnyView($0.modifier(TunedTheme(tuning: state.tuning)).environment(\.registryItemSurface, RegistryItemSurface()))
                    }
                    if again != tuned { unstable.append(entry.name) }
                }
                var swift: Bitmap?
                if let theme = RoundTripFixture.swiftTheme(state.id) {
                    swift = await renderer.snapshot({ AnyView(ItemDemoView(name: entry.name)) }, dark: dark) {
                        AnyView($0.registryTheme(theme))
                    }
                }
                var preset: Bitmap?
                if let theme = RoundTripFixture.presetTheme(state.id) {
                    preset = await renderer.snapshot({ AnyView(ItemDemoView(name: entry.name)) }, dark: dark) {
                        AnyView($0.registryTheme(theme))
                    }
                }
                let pair = PairResult(
                    item: entry.name, state: state.id, appearance: dark ? "dark" : "light",
                    swift: swift.map(tuned.difference) ?? .uncompiled(RoundTripFixture.swiftCompileError[state.id]),
                    preset: preset.map(tuned.difference) ?? .uncompiled(RoundTripFixture.presetCompileError[state.id]))
                if let diagnostics, !pair.passed, pairs.filter({ !$0.passed }).count < 40 {
                    let stem = "\(entry.name)--\(state.id)--\(pair.appearance)"
                    try? tuned.png?.write(to: diagnostics.appending(component: "\(stem)--tuned.png"))
                    if pair.swift != nil { try? swift?.png?.write(to: diagnostics.appending(component: "\(stem)--swift.png")) }
                    if pair.preset != nil { try? preset?.png?.write(to: diagnostics.appending(component: "\(stem)--preset.png")) }
                }
                pairs.append(pair)
              }
            }
        }
        let report = RoundTripReport(pairs: pairs, unstable: unstable, seconds: (clock.now - start) / .seconds(1))
        print(report.summary)
        for line in report.failureLines { print("  \(line)") }
        if let path = ProcessInfo.processInfo.environment["ROUNDTRIP_REPORT"] {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(to: URL(fileURLWithPath: path))
        }
        #expect(pairs.count == 73 * RoundTripDataset.states.count * 2, "the dataset is the whole catalog under every state, light and dark")
        #expect(report.percent >= Self.floor, "fidelity fell below the best measured \(Self.floor)%")
    }

    // MARK: Controls: the instrument must be able to fail, and must not fail on noise

    @Test func `A theme one point off the tuned card radius is caught`() async {
        let renderer = RoundTripRenderer()
        let tuned = await renderer.snapshot({ AnyView(ItemDemoView(name: "card")) }) {
            AnyView($0.modifier(TunedTheme(tuning: .default)))
        }
        var exact = ThemeTuning.default.theme
        exact.metrics.cardRadius = ThemeTuning.default.cardRadius + 1
        let drifted = await renderer.snapshot({ AnyView(ItemDemoView(name: "card")) }) {
            AnyView($0.registryTheme(exact))
        }
        #expect(tuned.difference(drifted) != nil)
    }

    /// No catalog item draws a non-regular surface level, so the sweep cannot
    /// see this: `RegistryTheme.surface(at:)` steps from `surfaceOpacity`, and
    /// an export that leaves it out drifts for a consumer that uses the ladder.
    @Test func `A tuned surface opacity reaches an elevated surface through both exports`() async {
        let renderer = RoundTripRenderer()
        var tuning = ThemeTuning.default
        tuning.surfaceOpacity = 0.2
        let ladder = AnyView(
            VStack(spacing: 0) {
                Color.clear.frame(width: 120, height: 40).registrySurface(level: .high)
                Color.clear.frame(width: 120, height: 40).registrySurface(level: .low)
                Color.clear.frame(width: 120, height: 40).registrySurface(level: .lowest)
            })
        let tuned = await renderer.snapshot({ ladder }) { AnyView($0.modifier(TunedTheme(tuning: tuning))) }
        let swift = await renderer.snapshot({ ladder }) { AnyView($0.registryTheme(RoundTripFixture.swiftTheme("surfaceOpacity-max")!)) }
        let preset = await renderer.snapshot({ ladder }) { AnyView($0.registryTheme(RoundTripFixture.presetTheme("surfaceOpacity-max")!)) }
        #expect(tuned.difference(swift) == nil, "Copy Swift dropped surfaceOpacity")
        #expect(tuned.difference(preset) == nil, "the theme file dropped surfaceOpacity")
    }

    @Test func `The same state rendered twice is identical`() async {
        let renderer = RoundTripRenderer()
        for name in ["button", "card", "chart", "preview"] {
            let first = await renderer.snapshot({ AnyView(ItemDemoView(name: name)) }) {
                AnyView($0.modifier(TunedTheme(tuning: .default)))
            }
            let second = await renderer.snapshot({ AnyView(ItemDemoView(name: name)) }) {
                AnyView($0.modifier(TunedTheme(tuning: .default)))
            }
            #expect(first == second, "\(name) is not deterministic")
            #expect(first.width > 0 && first.height > 0)
        }
    }
}

/// Writes each state's Swift export and preset code for the fixture script.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["ROUNDTRIP_EXPORT_DIR"] != nil))
struct RoundTripExport {
    @Test func `Write every state's Swift export and preset code`() throws {
        let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ROUNDTRIP_EXPORT_DIR"]!)
        for state in RoundTripDataset.states {
            try state.tuning.swiftSource.write(to: directory.appending(component: "\(state.id).swift.txt"), atomically: true, encoding: .utf8)
            try state.tuning.presetCode.write(to: directory.appending(component: "\(state.id).code"), atomically: true, encoding: .utf8)
        }
    }
}

/// The fixed dataset: every numeric knob at its minimum, its maximum, and off
/// its slider grid (the shipped default plus 0.37 of a step), every named
/// accent, a custom accent alone and with a dark value, the dark label, each
/// font design and chart palette, and the color pairs. Ranges and steps are
/// the panel's sliders (`TuningPanel.swift`); custom channels sit between
/// 8-bit levels on purpose.
enum RoundTripDataset {
    static let states: [(id: String, tuning: ThemeTuning)] = {
        let base = ThemeTuning.default
        var states: [(id: String, tuning: ThemeTuning)] = [("default", base)]
        func add(_ id: String, _ change: (inout ThemeTuning) -> Void) {
            var tuning = base
            change(&tuning)
            states.append((id, tuning))
        }
        let numeric: [(String, WritableKeyPath<ThemeTuning, Double>, ClosedRange<Double>, Double)] = [
            ("surfaceOpacity", \.surfaceOpacity, 0...0.2, 0.005),
            ("surfaceStep", \.surfaceStep, 0...0.07, 0.01),
            ("borderOpacity", \.borderOpacity, 0...0.3, 0.01),
            ("borderWidth", \.borderWidth, 0.5...3, 0.5),
            ("emphasizedBorderWidth", \.emphasizedBorderWidth, 1...4, 0.5),
            ("compactRadius", \.compactRadius, 0...12, 1),
            ("controlRadius", \.controlRadius, 0...22, 1),
            ("cardRadius", \.cardRadius, 0...32, 1),
            ("compactSpacing", \.compactSpacing, 4...16, 1),
            ("standardSpacing", \.standardSpacing, 8...32, 1),
            ("sectionSpacing", \.sectionSpacing, 12...48, 1),
            ("controlHorizontalPadding", \.controlHorizontalPadding, 8...24, 1),
            ("disabledOpacity", \.disabledOpacity, 0.2...0.8, 0.05),
        ]
        for (name, key, range, step) in numeric {
            add("\(name)-min") { $0[keyPath: key] = range.lowerBound }
            add("\(name)-max") { $0[keyPath: key] = range.upperBound }
            add("\(name)-offgrid") { $0[keyPath: key] = base[keyPath: key] + 0.37 * step }
        }
        for accent in ThemeTuning.Accent.named where accent != base.accent {
            add("accent-\(accent.rawValue)") { $0.accent = accent }
        }
        let custom = ThemeTuning.RGB(red: 0.4999, green: 0.2502, blue: 0.7498)
        let customDark = ThemeTuning.RGB(red: 0.1251, green: 0.6249, blue: 0.3749)
        add("accent-custom") { $0.accent = .custom; $0.customAccent = custom }
        add("accent-custom-dark") { $0.accent = .custom; $0.customAccent = custom; $0.customAccentDark = customDark }
        add("darkLabelOnAccent") { $0.darkLabelOnAccent = true }
        for design in ThemeTuning.FontDesign.allCases where design != base.fontDesign {
            add("fontDesign-\(design.rawValue)") { $0.fontDesign = design }
        }
        for palette in ThemeTuning.ChartPalette.allCases where palette != base.chartPalette {
            add("chartPalette-\(palette.rawValue)") { $0.chartPalette = palette }
        }
        let light = ThemeTuning.RGB(red: 0.9611, green: 0.9389, blue: 0.9019)
        let dark = ThemeTuning.RGB(red: 0.1019, green: 0.0981, blue: 0.1211)
        add("background") { $0.background = light }
        add("background-dark") { $0.background = light; $0.backgroundDark = dark }
        add("foreground") { $0.foreground = ThemeTuning.RGB(red: 0.1003, green: 0.1498, blue: 0.2004) }
        add("secondaryForeground") {
            $0.foreground = ThemeTuning.RGB(red: 0.1003, green: 0.1498, blue: 0.2004)
            $0.secondaryForeground = ThemeTuning.RGB(red: 0.4002, green: 0.4497, blue: 0.5003)
        }
        return states
    }()
}

/// A rendered bitmap: its pixel size and its raw bytes.
struct Bitmap: Equatable {
    let width: Int
    let height: Int
    let bytes: Data
    let png: Data?

    static func == (a: Bitmap, b: Bitmap) -> Bool { a.width == b.width && a.height == b.height && a.bytes == b.bytes }

    /// `nil` when identical; otherwise how the two differ.
    func difference(_ other: Bitmap) -> Difference? {
        if self == other { return nil }
        guard width == other.width, height == other.height else {
            return Difference(pixels: -1, size: "\(width)x\(height) vs \(other.width)x\(other.height)")
        }
        var pixels = 0
        bytes.withUnsafeBytes { a in
            other.bytes.withUnsafeBytes { b in
                let a = a.bindMemory(to: UInt32.self), b = b.bindMemory(to: UInt32.self)
                for index in 0..<min(a.count, b.count) where a[index] != b[index] { pixels += 1 }
            }
        }
        return Difference(pixels: pixels, size: "\(width)x\(height)")
    }

    struct Difference: Codable, Equatable {
        /// Differing pixels; -1 when the sizes differ, -2 when the export does not compile.
        let pixels: Int
        let size: String

        static func uncompiled(_ error: String?) -> Difference {
            Difference(pixels: -2, size: "does not compile: \(error ?? "unknown")")
        }
    }
}

@MainActor
final class RoundTripRenderer {
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 16000))
    private final class Box { var frame: CGRect = .zero }

    init() {
        window.makeKeyAndVisible()
    }

    /// Renders the demo the way the capture screen lays it out, themed at the
    /// root, and draws the content's frame at the device scale.
    func snapshot(_ content: () -> AnyView, dark: Bool = false, themed: (AnyView) -> AnyView) async -> Bitmap {
        let box = Box()
        let root = ScrollView {
            content()
                .padding()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { box.frame = $0 }
                .frame(maxWidth: 792)
                .frame(maxWidth: .infinity)
        }
        .scrollDisabled(true)
        .background(Color(uiColor: .systemBackground))
        .transaction { $0.disablesAnimations = true }
        // Time-driven content (the preview block's visualizers) draws its still
        // frame under Reduce Motion; on for both sides, so time never differs.
        .environment(\._accessibilityReduceMotion, true)
        // The window's style drives UIKit traits and the SwiftUI environment
        // together, the way the device's appearance does; both sides get it.
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.rootViewController = UIHostingController(rootView: themed(AnyView(root)))
        window.layoutIfNeeded()
        var last = CGRect.null
        for _ in 0..<40 {
            try? await Task.sleep(for: .milliseconds(16))
            if !box.frame.isEmpty && box.frame == last { break }
            last = box.frame
        }
        return autoreleasepool {
            let rect = box.frame
            let format = UIGraphicsImageRendererFormat()
            format.scale = window.screen.scale
            format.opaque = true
            let image = UIGraphicsImageRenderer(size: rect.size, format: format).image { context in
                context.cgContext.translateBy(x: -rect.minX, y: -rect.minY)
                window.layer.render(in: context.cgContext)
            }
            let cgImage = image.cgImage
            let bytes = cgImage?.dataProvider?.data.map { $0 as Data } ?? Data()
            let wantsPNG = ProcessInfo.processInfo.environment["ROUNDTRIP_DIAG_DIR"] != nil
            return Bitmap(width: cgImage?.width ?? 0, height: cgImage?.height ?? 0, bytes: bytes, png: wantsPNG ? image.pngData() : nil)
        }
    }
}

struct PairResult: Codable {
    let item: String
    let state: String
    let appearance: String
    let swift: Bitmap.Difference?
    let preset: Bitmap.Difference?
    var passed: Bool { swift == nil && preset == nil }
}

struct RoundTripReport: Codable {
    let pairs: [PairResult]
    let unstable: [String]
    let seconds: Double

    var percent: Double { pairs.isEmpty ? 0 : 100 * Double(pairs.filter(\.passed).count) / Double(pairs.count) }

    var summary: String {
        String(
            format: "ROUNDTRIP FIDELITY: %.1f%% (%d/%d pairs); swift %d/%d; preset %d/%d; unstable items %d; %.1f s",
            percent, pairs.filter(\.passed).count, pairs.count,
            pairs.filter { $0.swift == nil }.count, pairs.count,
            pairs.filter { $0.preset == nil }.count, pairs.count, unstable.count, seconds)
    }

    /// One line per state that drifted, with how many items drifted per path.
    var failureLines: [String] {
        var order: [String] = []
        var swift: [String: Int] = [:]
        var preset: [String: Int] = [:]
        for pair in pairs where !pair.passed {
            let key = "\(pair.state) (\(pair.appearance))"
            if swift[key] == nil && preset[key] == nil { order.append(key) }
            swift[key, default: 0] += pair.swift == nil ? 0 : 1
            preset[key, default: 0] += pair.preset == nil ? 0 : 1
        }
        let uncompiled = Set(pairs.flatMap { [$0.swift, $0.preset] }.compactMap { $0?.pixels == -2 ? $0?.size : nil })
        return order.map { "DRIFT \($0): swift \(swift[$0] ?? 0) items, preset \(preset[$0] ?? 0) items" }
            + uncompiled.sorted().map { "EXPORT \($0)" }
            + (unstable.isEmpty ? [] : ["UNSTABLE \(unstable)"])
    }
}
