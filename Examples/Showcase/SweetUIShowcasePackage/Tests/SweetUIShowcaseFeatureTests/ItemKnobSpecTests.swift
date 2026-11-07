import Foundation
import SweetUIFoundations
import Testing
@testable import SweetUIDesignSurface

/// `design-knob-specs.json` is how an agent gives an item a control without
/// touching the app root: the panel must draw what the file declares, a
/// switch and a choice must round-trip through the numeric store the items
/// already read, the host's own knob of the same name must win, and a spec
/// the panel cannot draw must be dropped with a log line, never a crash.
@MainActor
struct ItemKnobSpecTests {
    private static let file = #"""
        {
          "button": [
            { "name": "variant", "kind": "choice", "options": ["primary", "outline", "ghost"], "shipped": "primary" },
            { "name": "showsIcon", "title": "Shows the icon", "kind": "bool", "shipped": true },
            { "name": "height", "kind": "number", "min": 24, "max": 60, "step": 2, "shipped": 36 },
            { "name": "broken", "kind": "number", "shipped": 1 },
            { "name": "mismatch", "kind": "choice", "options": ["a"], "shipped": 3 }
          ]
        }
        """#

    @Test func `Declared knobs decode into controls by kind`() throws {
        let specs = try JSONDecoder().decode([String: [ItemKnobSpec]].self, from: Data(Self.file.utf8))
        let knobs = try #require(specs["button"]).compactMap(\.knob)
        #expect(knobs.map(\.name) == ["variant", "showsIcon", "height"], "Undrawable specs are dropped.")
        #expect(knobs[0].kind == .choice(["primary", "outline", "ghost"]))
        #expect(knobs[0].range == 0...2 && knobs[0].shipped == 0)
        #expect(knobs[1].kind == .bool && knobs[1].shipped == 1 && knobs[1].title == "Shows the icon")
        #expect(knobs[2].kind == .number && knobs[2].step == 2)
    }

    @Test func `A switch and a choice read back through the numeric store`() {
        let store = KnobStore()
        let variant = ItemKnob.choice("variant", options: ["primary", "outline", "ghost"], shipped: "primary")
        let icon = ItemKnob.bool("showsIcon", shipped: true)
        store.register(["button": [variant, icon]])
        defer { store.reset("button") }
        store.set("button", variant, to: 1)
        store.set("button", icon, to: 0)
        let environment = store.environmentValue
        #expect(environment.value("button", "variant", options: ["primary", "outline", "ghost"], default: "primary") == "outline")
        #expect(environment.value("button", "showsIcon", default: true) == false)
        #expect(variant.option(for: 1) == "outline")
        #expect(variant.option(for: 9) == nil)
        // The shipped value leaves the file, so the item reads its default.
        store.set("button", icon, to: 1)
        #expect(store.values["button"]?["showsIcon"] == nil)
        #expect(store.environmentValue.value("button", "showsIcon", default: true))
        #expect(RegistryKnobs().value("button", "variant", options: ["primary"], default: "primary") == "primary")
    }

    @Test func `The host's knob of the same name wins over the agent's`() throws {
        let store = KnobStore()
        store.register(["button": [ItemKnob("height", in: 30...50, shipped: 40)]])
        store.$declared.withLock { $0 = try! JSONDecoder().decode([String: [ItemKnobSpec]].self, from: Data(Self.file.utf8)) }
        defer {
            store.$declared.withLock { $0 = [:] }
            store.reset("button")
        }
        let knobs = store.knobs(for: "button")
        #expect(knobs.map(\.name) == ["height", "variant", "showsIcon"])
        #expect(knobs[0].range == 30...50, "The host's range, not the agent's.")
    }

    @Test func `A shipped word outside the options falls back to the first`() {
        let knob = ItemKnob.choice("tone", options: ["neutral", "positive"], shipped: "loud")
        #expect(knob.shipped == 0)
        #expect(ItemKnob.choice("tone", options: [], shipped: "only").kind == .choice(["only"]))
    }
}
