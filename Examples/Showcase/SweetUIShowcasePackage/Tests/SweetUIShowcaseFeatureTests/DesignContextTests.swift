import Foundation
import SweetUIFoundations
import Testing
@testable import SweetUIDesignSurface

/// `design-context.json` is the agent's eyes: the items on screen with their
/// frames and tokens, the selection, the theme, the switches, and the last
/// screenshot. It must list what the tool state lists, in the window's
/// coordinate space, and keep the screenshot name a rewrite did not take.
@MainActor
struct DesignContextTests {
    @Test func `The context lists the visible items with frames, tokens, and knobs`() throws {
        let state = DesignSurfaceState.shared
        state.stage = CGRect(x: 0, y: 0, width: 393, height: 852)
        let id = UUID()
        state.report(RegistryItemReport(id: id, name: "button", frame: CGRect(x: 16, y: 200, width: 120, height: 36), ancestors: ["card"]))
        let offscreen = UUID()
        state.report(RegistryItemReport(id: offscreen, name: "badge", frame: CGRect(x: 16, y: 2000, width: 40, height: 20)))
        state.knobs.register(["button": [ItemKnob("height", in: 24...60, shipped: 36)]])
        state.knobs.set("button", ItemKnob("height", in: 24...60, shipped: 36), to: 40)
        state.selection = ItemSelection(item: "button", chain: ["button", "card"])
        defer {
            state.forget(id)
            state.forget(offscreen)
            state.knobs.reset("button")
            state.selection = ItemSelection()
        }
        var tuning = ThemeTuning.default
        tuning.rightToLeft = true

        let context = DesignContext.capture(state: state, tuning: tuning, screenshot: "notes/x.png")
        #expect(context.items.map(\.name) == ["button"], "An item outside the stage is not on screen.")
        let button = try #require(context.items.first)
        #expect(button.frame.y == 200 && button.frame.width == 120)
        #expect(button.ancestors == ["card"])
        #expect(button.tokens == RegistryItemTokens.tokens(for: "button"))
        #expect(button.knobs == ["height": 40])
        #expect(context.selectedItem == "button")
        #expect(context.selectionChain == ["button", "card"])
        #expect(context.stage.width == 393)
        #expect(context.presetCode == tuning.presetCode)
        #expect(context.rightToLeft)
        #expect(context.screenshot == "notes/x.png")
    }

    @Test func `The file spells dates in ISO 8601`() throws {
        let context = DesignContext.capture(state: .shared, tuning: .default, screenshot: nil)
        let data = try DesignNote.fileEncoder.encode(context)
        let document = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect((document["capturedAt"] as? String)?.hasSuffix("Z") == true)
        #expect(document["screenshot"] == nil, "An absent screenshot is an absent key.")
        #expect(document["items"] as? [Any] != nil)
    }
}
