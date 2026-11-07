import Dependencies
import DependenciesTestSupport
import Foundation
import Sharing
import SwiftUI
import Testing
@testable import SweetUIDesignSurface

/// A version is the person's unit of Undo and the agent's record of what
/// changed, so one settled gesture must be exactly one version, by the
/// author who made it: a drag is one version and not ten, leaving a held
/// control still lands it, and a change from outside Tune's controls is
/// recorded even with the card closed and told to the agent at once.
@Suite(
    .serialized,
    .dependencies {
        $0.date.now = Date(timeIntervalSince1970: 1_800_000_000)
        $0.uuid = .incrementing
        $0.continuousClock = ImmediateClock()
        let record = OutboxRecord()
        $0.outboxRecord = record
        $0.designOutbox = record.outbox
    }
)
struct TuneModelTests {
    /// The model at launch: the value files are its first version.
    @MainActor
    static func launched(_ stage: DesignSurfaceState = DesignSurfaceState()) -> TuneModel {
        let model = TuneModel(stage: stage)
        model.$history.withLock { $0.reconcile(values: model.liveDesign) }
        return model
    }

    /// Launches the model as the live surface does, with the listener for
    /// outside changes running, so a control's own write must not count a
    /// second time as an outside one. Cancel the task when the test ends.
    @MainActor
    static func listening(_ model: TuneModel) async -> Task<Void, Never> {
        let task = Task { await model.task() }
        await Task.megaYield()
        return task
    }
}

extension TuneModelTests {
    @MainActor
    @Suite struct Settling {
        @Test func `Ten slider steps between touch down and release record one version by you`() async throws {
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let before = model.history.entries.count

            model.sliderEditingChanged(true)
            for step in 1...10 {
                model.tuningEdit.cardRadius = 16 + Double(step)
                await Task.megaYield()
            }
            #expect(model.history.entries.count == before, "A step while the slider is held is not a version.")
            #expect(model.tuning.cardRadius == 26, "The app follows every step live.")

            model.sliderEditingChanged(false)
            await Task.megaYield()
            #expect(model.history.entries.count == before + 1)
            let version = try #require(model.current)
            #expect(version.author == .you)
            #expect(version.origin == .edit)
            #expect(version.design.code == model.tuning.presetCode, "The version holds the value at release.")
        }

        @Test func `A place change while a slider is held settles it as one version`() async {
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let before = model.history.entries.count

            model.sliderEditingChanged(true)
            model.tuningEdit.cardRadius = 20
            await Task.megaYield()
            model.tuningEdit.cardRadius = 24
            await Task.megaYield()
            model.place = .versions
            await Task.megaYield()
            #expect(model.history.entries.count == before + 1, "Leaving the place settles the held slider.")
            #expect(model.place == .versions)
            #expect(TuneModel(stage: DesignSurfaceState()).place == .versions, "The next open shows the last place.")

            // The slider is gone with its place; a late release adds nothing.
            model.sliderEditingChanged(false)
            await Task.megaYield()
            #expect(model.history.entries.count == before + 1)
        }

        @Test func `A menu or a switch records one version at once`() async {
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let before = model.history.entries.count

            model.tuningEdit.fontDesign = .rounded
            #expect(model.history.entries.count == before + 1)
            #expect(model.current?.author == .you)
            await Task.megaYield()
            #expect(model.history.entries.count == before + 1, "The listener does not count the menu's write again.")

            model.tuningEdit.darkLabelOnAccent = true
            await Task.megaYield()
            #expect(model.history.entries.count == before + 2)
        }

        @Test(.dependency(\.continuousClock, TestClock()))
        func `A color settles once, 0.6 s after its last change`() async throws {
            @Dependency(\.continuousClock) var continuousClock
            let clock = try #require(continuousClock as? TestClock<Duration>)
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let before = model.history.entries.count

            // A drag across the wheel: each change comes before the last one settled.
            for color in [Color.red, .orange, .yellow] {
                model.colorEdit.customAccentColor = color
                await clock.advance(by: .milliseconds(500))
            }
            #expect(model.history.entries.count == before, "A color waits for the picker to rest.")
            let settle = model.colorSettle
            await clock.advance(by: .milliseconds(100))
            await settle?.value
            #expect(model.history.entries.count == before + 1)
            #expect(model.current?.design.code == model.tuning.presetCode)
        }

        @Test func `Preview is never a version`() async {
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            let before = model.history.entries.count

            model.appearance = .dark
            model.direction = .leftToRight
            model.textSize = .accessibility
            await Task.megaYield()
            #expect(model.history.entries.count == before)
            #expect(model.previewOverrides == ["Dark", "AX3", "LTR"])
        }
    }

    @MainActor
    @Suite struct OutsideWrites {
        @Test func `An outside write records one version with the card closed and tells the agent`() async throws {
            @Dependency(\.outboxRecord) var record
            let stage = DesignSurfaceState()
            let model = TuneModel(stage: stage)
            let task = Task { await model.task() }
            defer { task.cancel() }
            await Task.megaYield()
            #expect(model.current?.origin == .first, "Launch makes the value files the first version.")
            #expect(model.current?.design == DesignHistory.Design(), "Nothing set yet is Source.")
            let before = model.history.entries.count
            let contexts = record.contexts.count

            // The Showcase's accent strip writes the shared tuning itself.
            @Shared(.designTokens) var tuning
            $tuning.withLock { $0.accent = .green }
            await Task.megaYield()

            #expect(!stage.isPresented)
            #expect(model.history.entries.count == before + 1)
            let version = try #require(model.current)
            #expect(version.author == .you)
            #expect(version.design.code == tuning.presetCode)
            #expect(record.contexts.count > contexts, "The agent's context follows the outside write.")
            #expect(record.contexts.value.last?.presetCode == tuning.presetCode)
        }

        @Test func `An outside write the agent's record names is the agent's`() async throws {
            let model = TuneModel(stage: DesignSurfaceState())
            let task = Task { await model.task() }
            defer { task.cancel() }
            await Task.megaYield()

            var agentTheme = ThemeTuning.default
            agentTheme.accent = .teal
            model.$agentChange.withLock {
                $0 = AgentChange(what: .tuning, changedAt: .now, previousCode: nil, code: agentTheme.presetCode)
            }
            @Shared(.designTokens) var tuning
            $tuning.withLock { $0.accent = .teal }
            await Task.megaYield()

            let version = try #require(model.current)
            #expect(version.author == .agent)
            #expect(version.origin == .edit)
        }
    }

    @MainActor
    @Suite struct Context {
        @Test func `A settle while Selecting writes the context without a screenshot`() async {
            @Dependency(\.outboxRecord) var record
            let stage = DesignSurfaceState()
            stage.selection.isSelecting = true
            let model = TuneModelTests.launched(stage)

            model.tuningEdit.fontDesign = .serif
            #expect(record.contexts.count == 1)
            #expect(model.contextCapture == nil)
            await Task.megaYield()
            #expect(record.screenshots.value.isEmpty, "The app is outlined for the tap while Selecting.")

            stage.selection.isSelecting = false
            model.tuningEdit.fontDesign = .rounded
            await model.contextCapture?.value
            #expect(record.screenshots.value == ["context"])
            #expect(record.contexts.value.last?.screenshot == "notes/context.png")
            #expect(record.contexts.value.last?.screenshotCode == model.tuning.presetCode)
        }

        /// Under Source the theme file holds the default theme while the app
        /// shows its own, so naming the default code would tell the agent
        /// the screenshot shows a theme it does not.
        @Test func `Under Source the context names no code, since the app shows its own theme`() async {
            @Dependency(\.outboxRecord) var record
            let model = TuneModel(stage: DesignSurfaceState())
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            await model.contextCapture?.value
            #expect(model.tuning.presetCode == ThemeTuning.default.presetCode)
            #expect(record.contexts.value.last?.presetCode == "", "A fresh launch is Source.")
            #expect(record.contexts.value.last?.screenshotCode == "")

            model.presetChipTapped("Mango")
            await model.contextCapture?.value
            #expect(record.contexts.value.last?.presetCode == model.tuning.presetCode)
            #expect(record.contexts.value.last?.screenshotCode == model.tuning.presetCode)

            model.sourceButtonTapped()
            await model.contextCapture?.value
            #expect(record.contexts.value.last?.presetCode == "")
            #expect(record.contexts.value.last?.screenshotCode == "", "The screenshot shows the app's own theme.")
        }
    }

    @MainActor
    @Suite struct Hosts {
        @Test func `A host that does not tune the theme has no Start from and records knob-only designs`() {
            let stage = DesignSurfaceState()
            stage.tunesTheme = false
            let knob = ItemKnob("height", in: 24...60, shipped: 36)
            stage.knobs.register(["button": [knob]])
            let model = TuneModelTests.launched(stage)

            #expect(!model.showsStartFrom)
            #expect(TuneModelTests.launched().showsStartFrom, "A host that tunes the theme starts from presets.")

            // Its designs are knob-only: they sit on Source.
            model.knobChanged("button", knob, to: 44)
            #expect(model.current?.design == DesignHistory.Design(knobs: ["button": ["height": 44]]))
        }

        @Test func `Source clears every override and Default is a version of its own`() async {
            let stage = DesignSurfaceState()
            let knob = ItemKnob("height", in: 24...60, shipped: 36)
            stage.knobs.register(["button": [knob]])
            let model = TuneModel(stage: stage)
            let listener = await TuneModelTests.listening(model)
            defer { listener.cancel() }
            model.presetChipTapped("Mango")
            model.knobChanged("button", knob, to: 44)
            await Task.megaYield()
            let before = model.history.entries.count

            model.sourceButtonTapped()
            await Task.megaYield()
            #expect(model.history.entries.count == before + 1, "Source is one version, not one per file it clears.")
            #expect(model.current?.design == DesignHistory.Design())
            #expect(model.current?.origin == .source)
            #expect(stage.knobs.values.isEmpty)
            #expect(model.history.design(code: model.tuning.presetCode, knobs: [:]).code.isEmpty, "The app's own theme shows.")

            model.defaultButtonTapped()
            await Task.megaYield()
            #expect(model.history.entries.count == before + 2)
            #expect(model.current?.origin == .defaultTheme)
            #expect(model.current?.design.code == ThemeTuning.default.presetCode, "Default paints the default theme.")
        }
    }
}

/// What Tune wrote for the agent, in order.
final class OutboxRecord: Sendable {
    let contexts = LockIsolated<[DesignContext]>([])
    let screenshots = LockIsolated<[String]>([])

    var outbox: DesignOutbox {
        DesignOutbox(
            writeContext: { [contexts] context in contexts.withValue { $0.append(context) } },
            writeHandOff: { _ in true },
            saveScreenshot: { [screenshots] name, _ in
                screenshots.withValue { $0.append(name) }
                return "notes/\(name).png"
            })
    }
}

private enum OutboxRecordKey: TestDependencyKey {
    static var testValue: OutboxRecord { OutboxRecord() }
}

extension DependencyValues {
    var outboxRecord: OutboxRecord {
        get { self[OutboxRecordKey.self] }
        set { self[OutboxRecordKey.self] = newValue }
    }
}
