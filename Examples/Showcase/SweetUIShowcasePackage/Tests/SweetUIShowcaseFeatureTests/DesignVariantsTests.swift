import Foundation
import Testing
@testable import SweetUIDesignSurface

/// `design-variants.json` is the agent's side of a pick: it stages named
/// preset codes, the person taps one on the device, and the file carries the
/// choice back. The document must read what an agent writes by hand, apply a
/// code over the current tuning without touching the environment switches,
/// and refuse a code it cannot decode rather than apply something else.
struct DesignVariantsTests {
    private static let file = #"""
        {
          "variants": [
            { "name": "Warm", "code": "a74hGF01CVunaG0vzZJG" },
            { "name": "Cool", "code": "a13GkaOXWwIF" },
            { "name": "Broken", "code": "zzz" }
          ]
        }
        """#

    @Test func `An agent-written file decodes without a chosen key`() throws {
        let variants = try JSONDecoder().decode(DesignVariants.self, from: Data(Self.file.utf8))
        #expect(variants.variants.map(\.name) == ["Warm", "Cool", "Broken"])
        #expect(variants.chosen == nil)
    }

    @Test func `A variant applies over the tuning and keeps the environment`() throws {
        let variants = try JSONDecoder().decode(DesignVariants.self, from: Data(Self.file.utf8))
        var base = ThemeTuning.default
        base.appearance = .dark
        base.rightToLeft = true
        let warm = try #require(variants.tuning(for: variants.variants[0], base: base))
        #expect(warm.presetCode == "a74hGF01CVunaG0vzZJG", "MANGO's pinned code must round-trip.")
        #expect(warm.accent == .custom)
        #expect(warm.appearance == .dark)
        #expect(warm.rightToLeft)
        #expect(variants.matching(warm)?.name == "Warm")
        // A knob moved afterwards leaves no chip selected.
        var moved = warm
        moved.cardRadius += 1
        #expect(variants.matching(moved) == nil)
    }

    @Test func `A code the panel cannot read applies nothing`() throws {
        let variants = try JSONDecoder().decode(DesignVariants.self, from: Data(Self.file.utf8))
        #expect(variants.tuning(for: variants.variants[2], base: .default) == nil)
    }

    @Test func `The pick is written with the variants`() throws {
        var variants = try JSONDecoder().decode(DesignVariants.self, from: Data(Self.file.utf8))
        variants.chosen = "Cool"
        let data = try ThemeTuning.fileEncoder.encode(variants)
        let document = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(document["chosen"] as? String == "Cool")
        #expect((document["variants"] as? [[String: Any]])?.count == 3)
    }
}
