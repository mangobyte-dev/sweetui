import Foundation
import Testing
@testable import SweetUIDesignSurface

/// The generic token engine is what a host app hands its own design tokens
/// to, so a change must reach the app at once (apply), the file must carry
/// only what moved for knobs, and reset must return to the shipped values.
@MainActor
struct TokenStoreTests {
    struct SampleTokens: TokenDocument {
        var spacing: Double = 16
        var design: String = "default"
        var accent = TokenColor(light: ThemeTuning.RGB(red: 0.2, green: 0.4, blue: 0.6))

        static let shipped = SampleTokens()
        static let fileName = "sample-tokens-test.json"
        static let pages: [TokenPage<SampleTokens>] = [
            TokenPage("Layout", knobs: [
                .number("Spacing", \.spacing, in: 0...40),
                .choice("Design", \.design, options: ["default", "rounded"]),
                .color("Accent", \.accent),
            ])
        ]

        nonisolated(unsafe) static var applied: [SampleTokens] = []
        func apply() { Self.applied.append(self) }
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appending(component: "tokens-\(UUID().uuidString).json")
    }

    @Test func `A change writes the file and applies at once`() async throws {
        SampleTokens.applied = []
        let url = temporaryURL()
        let store = TokenStore<SampleTokens>(url: url)
        store.binding(\.spacing).wrappedValue = 24
        #expect(store.document.spacing == 24)
        #expect(SampleTokens.applied.last?.spacing == 24, "apply must run after every change")
        // In a test process Sharing's file storage is in memory, so the proof
        // of persistence is a second store over the same file seeing the value.
        try await store.$document.save()
        let reopened = TokenStore<SampleTokens>(url: url)
        #expect(reopened.document.spacing == 24)
        #expect(store.pageTitles == ["Layout"])
    }

    @Test func `Reset returns the shipped document`() {
        let store = TokenStore<SampleTokens>(url: temporaryURL())
        store.binding(\.design).wrappedValue = "rounded"
        store.reset()
        #expect(store.document == .shipped)
        #expect(SampleTokens.applied.last == .shipped)
    }

    @Test func `A knob at its shipped default leaves the file`() {
        let store = KnobStore()
        let padding = ItemKnob("padding", in: 0...32, shipped: 12)
        store.register(["button": [padding]])
        store.set("button", padding, to: 20)
        #expect(store.values["button"]?["padding"] == 20)
        #expect(store.environmentValue.value("button", "padding", default: 12) == 20)
        store.set("button", padding, to: 12)
        #expect(store.values["button"] == nil, "the shipped value is never stored")
        #expect(store.environmentValue.value("button", "padding", default: 12) == 12)
    }
}
