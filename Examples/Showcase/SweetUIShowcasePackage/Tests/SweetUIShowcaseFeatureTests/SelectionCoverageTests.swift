import Foundation
import SwiftUI
import SweetUIFoundations
import Testing
import UIKit
@testable import SweetUIDesignSurface
@testable import SweetUIShowcaseFeature

/// The selection coverage instrument. Every catalog item's demo renders with a
/// surface present; every element it reports is tapped at its centroid through
/// the pick the window uses, and the chain must equal the element's structural
/// nesting (the tagged roots it sits inside, from the view tree, not from
/// geometry). An item counts only when its own root reports, every element in
/// its demo resolves, and the registry knows each selected element's token scope.
/// The printed percentage is the metric; it MUST NOT be loosened to move.
@MainActor
struct SelectionCoverageTests {
    /// The best measured coverage; the sweep fails below it, so a change that
    /// loses coverage is caught. Raise it only to a measured value.
    static let floor = 95.8

    @Test func `Every catalog item and each nested element resolves to its structural chain`() async throws {
        let clock = ContinuousClock()
        let start = clock.now
        var items: [ItemResult] = []
        for entry in RegistryCatalogManifest.entries {
            let reports = await SelectionSweep.render(ItemDemoView(name: entry.name))
            items.append(SelectionSweep.evaluate(entry.name, kind: entry.kind, declared: entry.dependencies, reports: reports))
        }
        let report = CoverageReport(items: items, seconds: (clock.now - start) / .seconds(1))
        print(report.summary)
        for item in items where !item.passed { print("  FAIL \(item.name) [\(item.kind)]: \(item.problems.joined(separator: "; "))") }
        if let path = ProcessInfo.processInfo.environment["SELECTION_COVERAGE_REPORT"] {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(to: URL(fileURLWithPath: path))
        }
        #expect(items.count == 76, "the dataset is the whole catalog")
        #expect(report.percent >= Self.floor, "coverage fell below the best measured \(Self.floor)%")
    }

    // MARK: Controls: the instrument must be able to fail

    @Test func `A child that sits inside its parent resolves child first`() async {
        let view = RoundedRectangle(cornerRadius: 8).fill(.gray).frame(width: 300, height: 200)
            .overlay { Capsule().fill(.blue).frame(width: 100, height: 40).registryItem("button") }
            .registryItem("card")
        let result = SelectionSweep.evaluate("card", kind: "component", declared: [], reports: await SelectionSweep.render(view))
        #expect(result.passed, "\(result.problems)")
        #expect(result.elements.count == 2)
    }

    @Test func `A child that fills its parent exactly resolves child first`() async {
        // Equal areas: geometry cannot order the two, and by name "alpha"
        // (the parent) would sort before "beta" (the child).
        let view = Rectangle().fill(.gray).frame(width: 200, height: 60)
            .registryItem("beta")
            .registryItem("alpha")
        let result = SelectionSweep.evaluate("alpha", kind: "component", declared: [], reports: await SelectionSweep.render(view))
        #expect(result.elements.map(\.actual) == [["beta", "alpha"], ["beta", "alpha"]])
        #expect(!result.problems.contains { $0.contains("chain") }, "\(result.problems)")
    }

    @Test func `A child that overflows its parent is flagged when the pick puts the parent first`() async {
        // The child is larger than the parent it sits inside, so the smaller
        // area, the parent, comes first, against the nesting.
        let view = Rectangle().fill(.gray).frame(width: 100, height: 40)
            .overlay { Rectangle().fill(.blue).frame(width: 200, height: 60).registryItem("button") }
            .registryItem("card")
        let result = SelectionSweep.evaluate("card", kind: "component", declared: [], reports: await SelectionSweep.render(view))
        #expect(!result.passed)
        #expect(result.problems.contains { $0.hasPrefix("button chain") })
    }

    @Test func `An item whose root reports no frame fails`() async {
        let view = Rectangle().fill(.gray).frame(width: 200, height: 60).registryItem("button")
        let result = SelectionSweep.evaluate("dialog", kind: "recipe", declared: [], reports: await SelectionSweep.render(view))
        #expect(!result.passed)
        #expect(result.problems.contains { $0.contains("no frame") })
    }
}

/// One reported element and how its centroid tap resolved.
struct ElementResult: Codable {
    let name: String
    let ancestors: [String]
    let frame: [Double]
    let expected: [String]
    let actual: [String]
    let passed: Bool
}

struct ItemResult: Codable {
    let name: String
    let kind: String
    let passed: Bool
    let problems: [String]
    let elements: [ElementResult]
    /// Declared dependencies the demo never rendered: context, not a failure,
    /// since a state-dependent part (an empty state, a skeleton) may be absent.
    let declaredNotRendered: [String]
}

struct CoverageReport: Codable {
    let items: [ItemResult]
    let seconds: Double

    var percent: Double { items.isEmpty ? 0 : 100 * Double(items.filter(\.passed).count) / Double(items.count) }

    var summary: String {
        let passed = items.filter(\.passed).count
        let elements = items.flatMap(\.elements)
        let installable = items.filter { $0.kind != "recipe" }
        return String(
            format: "SELECTION COVERAGE: %.1f%% (%d/%d items); installable %d/%d; elements %d/%d; %.1f s",
            percent, passed, items.count, installable.filter(\.passed).count, installable.count,
            elements.filter(\.passed).count, elements.count, seconds)
    }

    enum CodingKeys: String, CodingKey { case items, seconds, percent, summary }

    init(items: [ItemResult], seconds: Double) {
        self.items = items
        self.seconds = seconds
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([ItemResult].self, forKey: .items)
        seconds = try container.decode(Double.self, forKey: .seconds)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(seconds, forKey: .seconds)
        try container.encode(percent, forKey: .percent)
        try container.encode(summary, forKey: .summary)
    }
}

@MainActor
enum SelectionSweep {
    /// Renders a view in its own window with a surface present, as the design
    /// surface's modifier would, and returns what the tagged roots reported
    /// once the reports stop changing. The window is tall so no element sits
    /// below the fold; the wrapper matches the capture screen's.
    static func render(_ content: some View) async -> [RegistryItemReport] {
        let recorder = Recorder()
        let reporter = RegistrySurfaceReporter(
            itemChanged: { recorder.reports[$0.id] = $0; recorder.changes += 1 },
            itemLeft: { recorder.reports[$0] = nil; recorder.changes += 1 },
            screenAppeared: { _ in },
            screenLeft: { _ in })
        let root = ScrollView {
            content
                .padding()
                .frame(maxWidth: 792)
                .frame(maxWidth: .infinity)
        }
        .scrollDisabled(true)
        .environment(\.registryItemSurface, RegistryItemSurface())
        .environment(\.registrySurfaceReporter, reporter)
        .registryTheme(.indigo)

        let frame = CGRect(x: 0, y: 0, width: 402, height: 3000)
        let window = if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            UIWindow(windowScene: scene)
        } else {
            UIWindow(frame: frame)
        }
        window.frame = frame
        window.rootViewController = UIHostingController(rootView: root)
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        // Settled once three polls in a row see no new report, capped at 3 s.
        var last = -1
        var quiet = 0
        for _ in 0..<60 {
            try? await Task.sleep(for: .milliseconds(50))
            if recorder.changes == last {
                quiet += 1
                if quiet >= 3 { break }
            } else {
                quiet = 0
                last = recorder.changes
            }
        }
        return Array(recorder.reports.values)
    }

    /// Taps every reported element at its centroid. The expected chain is the
    /// structural one: the deepest tagged element under the point and the
    /// roots it sits inside, innermost first, each name once.
    static func evaluate(_ name: String, kind: String, declared: [String], reports: [RegistryItemReport]) -> ItemResult {
        var problems: [String] = []
        if !reports.contains(where: { $0.name == name && !$0.frame.isEmpty }) {
            problems.append("root \(name) reports no frame")
        }
        let elements = reports
            .sorted { ($0.frame.minY, $0.frame.minX, $0.name) < ($1.frame.minY, $1.frame.minX, $1.name) }
            .map { element -> ElementResult in
                let point = CGPoint(x: element.frame.midX, y: element.frame.midY)
                let actual = ItemSelection.chain(reports: reports, at: point)
                let under = reports.filter { !$0.frame.isEmpty && $0.frame.contains(point) }
                let deepest = under.max {
                    ($0.ancestors.count, -$0.frame.width * $0.frame.height) < ($1.ancestors.count, -$1.frame.width * $1.frame.height)
                }
                let expected = deepest.map { unique(($0.ancestors + [$0.name]).reversed()) } ?? []
                var passed = !element.frame.isEmpty && actual == expected
                if element.frame.isEmpty {
                    problems.append("\(element.name) reports an empty frame")
                } else if actual != expected {
                    problems.append("\(element.name) chain \(actual) expected \(expected)")
                }
                // A known scope, empty included: a native recipe reads no theme
                // field of its own, and the panel then hides every scoped section,
                // which is the right answer for it. An unknown name is the failure.
                if RegistryItemTokens.tokens(for: element.name) == nil {
                    passed = false
                    problems.append("\(element.name) has no token scope")
                }
                let f = element.frame
                return ElementResult(
                    name: element.name, ancestors: element.ancestors,
                    frame: [f.minX, f.minY, f.width, f.height].map(Double.init),
                    expected: expected, actual: actual, passed: passed)
            }
        let rendered = Set(reports.map(\.name))
        return ItemResult(
            name: name, kind: kind, passed: problems.isEmpty, problems: unique(problems),
            elements: elements, declaredNotRendered: declared.filter { !rendered.contains($0) })
    }

    private static func unique(_ names: some Sequence<String>) -> [String] {
        var seen: Set<String> = []
        return names.filter { seen.insert($0).inserted }
    }

    @MainActor
    final class Recorder {
        var reports: [UUID: RegistryItemReport] = [:]
        var changes = 0
    }
}
