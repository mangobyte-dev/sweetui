import Foundation
import Testing
@testable import SweetUIDesignSurface

/// The catalog is everything Tokens can edit and what scopes it to an item.
/// A key the code carries with no token is a value the person cannot reach;
/// a key with two tokens is edited from two rows; and a field an item reads
/// that no token moves, unless the catalog names it fixed, drops out of the
/// item's tokens without a word.
struct TokenCatalogTests {
    /// The keys a code encodes, as `registry-tokens.json` and `sweetui preset
    /// decode --json` spell them under `tuning`.
    static func codeKeys() throws -> Set<String> {
        let data = try JSONEncoder().encode(ThemeTuning.default)
        let file = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let tuning = try #require(file["tuning"] as? [String: Any])
        return Set(tuning.keys)
    }

    /// Every field the generated map lists for some item.
    static let itemFields = Set(RegistryItemTokens.tokens.values.joined())

    /// What a catalog leaves uncovered: a code key owned by no token or by
    /// more than one, a token key no code carries, and an item field that no
    /// token moves and is not fixed.
    static func gaps(_ tokens: [TokenCatalog.Token], fixed: Set<String>) throws -> [String] {
        let keys = try codeKeys()
        var gaps: [String] = []
        for key in keys.sorted() {
            let owners = tokens.filter { $0.codeKeys.contains(key) }.map(\.key)
            if owners.count != 1 { gaps.append("\(key) belongs to \(owners)") }
        }
        for token in tokens {
            for key in token.codeKeys where !keys.contains(key) { gaps.append("\(key) is no code key") }
        }
        let driven = tokens.reduce(into: Set<String>()) { $0.formUnion($1.drives) }
        for field in itemFields.sorted() where !driven.contains(field) && !fixed.contains(field) {
            gaps.append("\(field) is neither driven nor fixed")
        }
        return gaps
    }

    @Test func `Every key the code encodes belongs to exactly one token`() throws {
        #expect(try Self.codeKeys().count == 25, "The code carries 25 keys today; a new one needs a token.")
        #expect(try Self.gaps(TokenCatalog.theme, fixed: TokenCatalog.fixed) == [])
        #expect(Set(TokenCatalog.theme.map(\.key)).count == TokenCatalog.theme.count, "One row per key.")
    }

    @Test func `Every field an item reads is moved by a token or listed as fixed`() throws {
        #expect(!Self.itemFields.isEmpty)
        #expect(TokenCatalog.fixed == ["negative", "positive"], "Only the status colors have no token.")
        #expect(try Self.gaps(TokenCatalog.theme, fixed: TokenCatalog.fixed) == [])
    }

    /// The completeness check is only worth its pass if it notices a hole:
    /// dropping any one token or fixed field must leave one.
    @Test func `Removing any one token or fixed field leaves a gap`() throws {
        for token in TokenCatalog.theme {
            let rest = TokenCatalog.theme.filter { $0.key != token.key }
            #expect(try !Self.gaps(rest, fixed: TokenCatalog.fixed).isEmpty, "Without \(token.key)")
        }
        for field in TokenCatalog.fixed {
            #expect(try !Self.gaps(TokenCatalog.theme, fixed: TokenCatalog.fixed.subtracting([field])).isEmpty, "Without \(field)")
        }
    }

    /// The root modifier applies the accent, the font design, the text
    /// colors, and the background to every item; the rest reach an item only
    /// through a field it reads.
    @Test func `A card is reached by its surface, radius, and spacing, and the root tokens`() {
        #expect(TokenCatalog.reaching("card").map(\.key) == [
            "accent", "background", "foreground", "secondaryForeground", "fontDesign",
            "standardSpacing", "cardRadius", "surfaceOpacity", "borderOpacity", "borderWidth",
        ])
        #expect(TokenCatalog.fixedFields(of: "card") == [])
    }

    @Test func `A button is reached by its label, radius, and disabled opacity, and reads negative fixed`() {
        #expect(TokenCatalog.reaching("button").map(\.key) == [
            "accent", "darkLabelOnAccent", "background", "foreground", "secondaryForeground", "fontDesign",
            "controlRadius", "surfaceOpacity", "borderOpacity", "borderWidth", "disabledOpacity",
        ])
        #expect(TokenCatalog.fixedFields(of: "button") == ["negative"])
    }

    @Test func `An item that reads no token is reached by the root tokens alone`() {
        #expect(RegistryItemTokens.tokens(for: "alert-dialog") == [])
        #expect(TokenCatalog.reaching("alert-dialog").map(\.key).sorted() == TokenCatalog.reachesEveryItem.sorted())
        #expect(TokenCatalog.reaching("a-host-item").count == TokenCatalog.theme.count, "An unknown item may read anything.")
    }

    @Test func `Reset puts a token back to Default and Use the Light value clears only the Dark value`() throws {
        let background = try #require(TokenCatalog.theme.first { $0.key == "background" })
        var tuning = ThemeTuning.default
        tuning.background = .init(red: 1, green: 0.9, blue: 0.8)
        tuning.backgroundDark = .init(red: 0.1, green: 0.1, blue: 0.1)
        tuning.cardRadius = 24
        #expect(background.isChanged(tuning))
        #expect(background.value(tuning) == "#FFE6CC, dark #1A1A1A")

        background.useLightValue(&tuning)
        #expect(tuning.background == .init(red: 1, green: 0.9, blue: 0.8))
        #expect(tuning.backgroundDark == nil)

        background.reset(&tuning)
        #expect(!background.isChanged(tuning))
        #expect(background.value(tuning) == "System")
        #expect(tuning.cardRadius == 24, "A reset touches its own token only.")
    }

    /// Changes are the words the person reads in Notes and Versions, so a
    /// change must carry the title its row shows, its unit, and a choice's
    /// word, never a file key or a stored flag.
    @Test func `Changes read the catalog's titles and units, and a choice reads as its word`() throws {
        var tuning = ThemeTuning.default
        tuning.cardRadius = 20
        tuning.borderWidth = 1.5
        tuning.surfaceStep = 0.03
        tuning.darkLabelOnAccent = true
        tuning.fontDesign = .monospaced
        tuning.background = .init(red: 1, green: 0.9, blue: 0.8)
        tuning.backgroundDark = .init(red: 0.1, green: 0.1, blue: 0.1)
        let changes = DesignChanges.between(DesignHistory.Design(), DesignHistory.Design(code: tuning.presetCode))
        let words = Set(changes.map(\.words))
        #expect(words.isSuperset(of: [
            "Card radius: 16 to 20 pt", "Border width: 1 to 1.5 pt", "Surface step: 0.02 to 0.03",
            "Label on accent: white to black", "Font design: default to mono",
            "Background: none to #FFE6CC", "Background, Dark: none to #1A1A1A",
        ]), "\(words.sorted())")
        #expect(changes.count == 7)
        for change in changes {
            #expect(TokenCatalog.title(ofKey: change.key) == change.title)
            #expect(change.title != change.key, "\(change.key) reads as its file key.")
        }

        tuning.accent = .custom
        tuning.customAccent = .init(red: 1, green: 0, blue: 0)
        tuning.customAccentDark = .init(red: 0, green: 0, blue: 1)
        let accent = DesignChanges.between(DesignHistory.Design(), DesignHistory.Design(code: tuning.presetCode)).map(\.title)
        #expect(accent.contains("Custom accent"))
        #expect(accent.contains("Custom accent, Dark"))
    }
}
