import Foundation
import Testing

@testable import SweetUIKit

private let vectorDocument = try! JSON.read(
  Data(
    contentsOf: Bundle.module.url(
      forResource: "preset_vectors", withExtension: "json", subdirectory: "Fixtures")!))

/// The vector whose name starts with the preset or scenario word before the colon.
private func vector(named prefix: String) throws -> PresetVector {
  try #require(presetVectors.first { $0.name.components(separatedBy: ":")[0] == prefix })
}

@Test func presetTableFitsTheDocumentedBudget() throws {
  // A resized or reordered field is a format change; the vectors would break first, this
  // names the reason. Decode reads the accent (4 bits) and the label flag (1 bit) first.
  let accentBits = 4
  let labelBits = 1
  #expect(accentBits + labelBits + Preset.fields.map(\.bits).reduce(0, +) == 61)
  #expect(Preset.accents.count <= 1 << accentBits)
  for field in Preset.fields { #expect(field.count <= 1 << field.bits, "\(field.key)") }
  #expect(vectorDocument["alphabet"].text == String(Preset.alphabet))
  #expect(vectorDocument["version"] == "b")
  #expect(vectorDocument["maxLength"] == 48)
  #expect(Preset.isCode("a" + String(repeating: "0", count: 47)))
  #expect(!Preset.isCode("a" + String(repeating: "0", count: 48)))
  #expect(Preset.isCode("b" + String(repeating: "0", count: 47)))
  #expect(try Preset.encode(Preset.defaultTuning) == presetVectors[0].code)
}

@Test func accentsAreValidatedAndOffGridValuesSnap() throws {
  // A named accent carries no custom color, and a custom accent needs one.
  var teal = Preset.defaultTuning
  teal["accent"] = "teal"
  #expect(try Preset.decode(Preset.encode(teal))?.object?["customAccent"] == nil)
  var custom = Preset.defaultTuning
  custom["accent"] = "custom"
  #expect(throws: RegistryError.self) { try Preset.encode(custom) }
  var magenta = Preset.defaultTuning
  magenta["accent"] = "magenta"
  #expect(throws: RegistryError.self) { try Preset.encode(magenta) }
  // aF: accent index 15 has no value, so the code is invalid rather than clamped.
  #expect(!(Preset.isCode("aF") && Preset.decode("aF") != nil))
  #expect(Preset.code(in: "  a13GkaOXWwIC \n") == "a13GkaOXWwIC")
  #expect(Preset.code(in: "zz") == nil)
}

@Test func swiftSpellsEachAccentTheWayTheTunePanelExportsIt() throws {
  let graphite = try Preset.swiftSource(vector(named: "Graphite").tuning)
  #expect(graphite.contains("accent: .primary,"))
  #expect(graphite.contains("onAccent: Color(uiColor: .systemBackground),"))
  #expect(graphite.contains("surface: .primary.opacity(0.050),"))
  let amber = try Preset.swiftSource(vector(named: "Amber").tuning)
  #expect(amber.contains("accent: .yellow,"))
  #expect(amber.contains("onAccent: .black,"))
  let system = try Preset.swiftSource(vector(named: "System").tuning)
  #expect(!system.components(separatedBy: "onAccent")[0].contains("accent:"))
  #expect(system.contains("onAccent: .white,"))
  #expect(system.hasSuffix("ContentView()\n    .registryTheme(theme)"))
  let tuned = try Preset.swiftSource(vector(named: "Tuned metrics off the defaults").tuning)
  for marker in [
    "borderWidth: 1.5,", "emphasizedBorderWidth: 3,", "disabledOpacity: 0.350,",
    "border: .primary.opacity(0.160),",
  ] { #expect(tuned.contains(marker), "\(marker)") }
  let custom = try Preset.swiftSource(vector(named: "Custom accent without a dark accent").tuning)
  #expect(
    custom.contains(
      "accent: Color(red: 0.349019607843, green: 0.341176470588, blue: 0.839215686275),"))
}

@Test func mangoDecodesStrokelessWithASeparateDarkAccentPair() throws {
  // MANGO's identity is strokeless (border opacity zero) and a light and dark
  // accent that differ. A decoder that clamped the zero border back to the
  // default, dropped the dark accent, or reused the light one would still pass
  // the round-trip yet fail here.
  let mango = try vector(named: "Mango")
  let decoded = try #require(Preset.decode(mango.code))
  #expect(decoded["accent"] == "custom")
  #expect(decoded["darkLabelOnAccent"] == .bool(true))
  #expect(decoded["borderOpacity"] == 0.0)
  #expect(decoded["customAccent"] == "#FFA033")
  #expect(decoded["customAccentDark"] == "#FFB84D")
  #expect(decoded["customAccent"] != decoded["customAccentDark"])
  let swift = try Preset.swiftSource(mango.tuning)
  #expect(swift.contains("accent: Color(uiColor: UIColor { traits in"))
  #expect(swift.contains("border: .primary.opacity(0.000),"))
}

@Test func swiftParsesBackWhatItWritesForEveryShape() throws {
  for vector in presetVectors {
    let file = try Preset.themeFile(vector.tuning, code: vector.code)
    #expect(try Preset.encode(Preset.parseSwift(file)) == vector.code, "\(vector.name)")
  }
  // The export lists the dark color first; a parse that read the first color as the light
  // one would silently swap a designer's two accents.
  var dual = Preset.defaultTuning
  dual["accent"] = "custom"
  dual["customAccent"] = "#112233"
  dual["customAccentDark"] = "#AABBCC"
  let parsed = try Preset.parseSwift(Preset.swiftSource(dual))
  #expect(parsed["customAccent"] == "#112233")
  #expect(parsed["customAccentDark"] == "#AABBCC")
  // A labeled subset keeps the base, and preset words map to colors.
  let subset = try Preset.parseSwift(
    "RegistryTheme(accent: .rose, disabledOpacity: 0.3, metrics: RegistryMetrics(cardRadius: 20))")
  #expect(subset["accent"] == "pink")
  #expect(subset["disabledOpacity"] == 0.3)
  #expect(subset["cardRadius"] == 20)
  #expect(subset["standardSpacing"] == 16)
  #expect(try Preset.parseSwift("RegistryTheme(onAccent: .white)")["accent"] == "system")
  // The theme file imports UIKit only when the Swift needs it.
  #expect(!(try Preset.themeFile(Preset.defaultTuning, code: "a0")).contains("import UIKit"))
  var ink = Preset.defaultTuning
  ink["accent"] = "ink"
  let inkFile = try Preset.themeFile(ink, code: "a0")
  #expect(inkFile.contains("import UIKit"))
  #expect(inkFile.contains("static let app = RegistryTheme("))
}

@Test func versionBAppendsTheCreateStudioFieldsAfterTheACustomBlock() throws {
  // Craft raw b codes with the a portion at its defaults so the appended fields
  // can be set to values encode itself would never produce, proving the layout.
  func craft(font: Int, step: Int, chart: Int) -> String {
    var writer = Preset.PresetBits()
    writer.write(0, width: 4)  // accent system
    writer.write(0, width: 1)  // no dark label
    for field in Preset.fields {
      let index = Int(
        ((Preset.defaultTuning[field.key].number! - field.minimum) / field.step).rounded())
      writer.write(index, width: field.bits)
    }
    writer.write(font, width: 2)
    writer.write(step, width: 3)
    writer.write(chart, width: 2)
    return "b" + writer.base62()
  }
  // The reserved chartPalette index 3 has no value, so the code is invalid rather
  // than clamped; index 2 (monochrome) is the last valid one.
  #expect(Preset.decode(craft(font: 0, step: 0, chart: 3)) == nil)
  let monochrome = try #require(Preset.decode(craft(font: 0, step: 0, chart: 2)))
  #expect(monochrome["chartPalette"] == "monochrome")
  // A b code whose appended fields are all default decodes to the a defaults and
  // re-encodes to the a code, so an unchanged tuning never gains a b code.
  let allDefault = craft(font: 0, step: 0, chart: 0)
  let decoded = try #require(Preset.decode(allDefault))
  #expect(decoded["fontDesign"] == "default")
  #expect(decoded["surfaceStep"] == 0.02)
  #expect(decoded["chartPalette"] == "accent")
  #expect(decoded["background"] == .null)
  #expect(try Preset.encode(decoded) == presetVectors[0].code)
  #expect(presetVectors[0].code.first == "a")
  // An a code decodes without the b keys, so the a shape and its Swift are unchanged.
  let aTuning = try #require(Preset.decode(presetVectors[0].code))
  #expect(aTuning.object?["fontDesign"] == nil)
  #expect(aTuning.object?["chartPalette"] == nil)
  // Encode rejects an unknown value for an appended enum field.
  var badFont = Preset.defaultTuning
  badFont["fontDesign"] = "cursive"
  #expect(throws: RegistryError.self) { try Preset.encode(badFont) }
  var badPalette = Preset.defaultTuning
  badPalette["chartPalette"] = "rainbow"
  #expect(throws: RegistryError.self) { try Preset.encode(badPalette) }
}

@Test func swiftExportsEachAppendedFieldOnlyWhenItLeavesTheDefault() throws {
  // The rounded, elevation, and spectrum vectors each print one appended line.
  let rounded = try Preset.swiftSource(vector(named: "Rounded").tuning)
  #expect(rounded.contains("fontDesign: .rounded"))
  #expect(!rounded.contains("surfaceStep:"))
  #expect(!rounded.contains("chartPalette:"))
  let elevation = try Preset.swiftSource(vector(named: "Elevation").tuning)
  #expect(elevation.contains("surfaceStep: 0.04"))
  let spectrum = try Preset.swiftSource(vector(named: "Spectrum chart").tuning)
  #expect(spectrum.contains("chartPalette: .spectrum"))
  // A color pair with a dark value exports the dynamic UIColor form, dark first.
  let pair = try Preset.swiftSource(vector(named: "Background pair").tuning)
  #expect(pair.contains("background: Color(uiColor: UIColor { traits in"))
  #expect(
    pair.contains(
      "? UIColor(red: 0.07843137255, green: 0.066666666667, blue: 0.050980392157, alpha: 1)"))
  #expect(
    pair.contains(
      ": UIColor(red: 0.96862745098, green: 0.949019607843, blue: 0.917647058824, alpha: 1)"))
  // A single-value color pair exports the plain Color form and needs no UIKit.
  let single = try Preset.swiftSource(vector(named: "Foreground pair without dark").tuning)
  #expect(
    single.contains(
      "foreground: Color(red: 0.105882352941, green: 0.105882352941, blue: 0.12156862745)"))
  #expect(
    !(try Preset.themeFile(vector(named: "Foreground pair without dark").tuning, code: "b0"))
      .contains("import UIKit"))
  // An a vector prints none of the appended lines.
  let system = try Preset.swiftSource(vector(named: "System").tuning)
  for marker in ["fontDesign:", "surfaceStep:", "chartPalette:", "background:", "foreground:"] {
    #expect(!system.contains(marker), "\(marker)")
  }
}

@Test func swiftArgumentsFollowTheInitializerOrderSoAThemeFileCompiles() throws {
  // Swift rejects labeled arguments out of their declared order, so a theme file
  // whose fields leave RegistryTheme.init's order never builds in the consuming app.
  let source = try String(
    contentsOfFile: repositoryRoot + "/Sources/SweetUIFoundations/RegistryTheme.swift",
    encoding: .utf8)
  let initializer = try #require(source.range(of: "public init(")).upperBound
  let end = try #require(source.range(of: ") {", range: initializer..<source.endIndex)).lowerBound
  let order = Preset.captures("(?m)^\\s+([a-zA-Z]+):", String(source[initializer..<end])).map {
    $0[0]
  }
  #expect(order.first == "accent" && order.contains("metrics") && order.contains("fontDesign"))
  for vector in presetVectors {
    let labels = Preset.captures(
      "(?m)^    ([a-zA-Z]+):", try Preset.initializerLines(vector.tuning).joined(separator: "\n")
    )
    .map { $0[0] }
    let positions = labels.map { order.firstIndex(of: $0) ?? -1 }
    #expect(!positions.contains(-1) && positions == positions.sorted(), "\(vector.name): \(labels)")
  }
}

@Test func websiteCodecReproducesEveryVector() throws {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [
    "node", "--experimental-strip-types",
    repositoryRoot + "/Tests/SweetUIKitTests/Fixtures/preset-vectors-check.ts",
    repositoryRoot + "/Registry/preset_vectors.json",
  ]
  let output = Pipe()
  let errors = Pipe()
  process.standardOutput = output
  process.standardError = errors
  try process.run()
  let data = output.fileHandleForReading.readDataToEndOfFile()
  let errorText = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
  process.waitUntilExit()
  #expect(process.terminationStatus == 0, "\(errorText)")
  let results = try #require(JSON.read(data).array)
  #expect(results.count == presetVectors.count + 1)
  for (vector, result) in zip(presetVectors, results) {
    #expect(result["encoded"].text == vector.code, "\(vector.name)")
    #expect(result["decoded"] == vector.tuning, "\(vector.name)")
    #expect(result["swift"].text == (try Preset.swiftSource(vector.tuning)), "\(vector.name)")
  }
  let invalid = try #require(results.last)
  #expect(invalid["rejected"] == .array(Array(repeating: true, count: 6)))
  #expect(invalid["isCode"] == ["a0", "a13GkaOXWwIC", "a13GkaOXWwIC", .null])
  #expect(invalid["bareIsCode"] == true)
}

extension Commands {
  @Test func presetCommandsSpeakTheSameCode() throws {
    let fs = try fixture()
    try withFixture(fs) {
      let amber = try vector(named: "Amber").code
      let indigo = try vector(named: "Indigo").code
      let destination = "/app/Components"
      let path = destination + "/" + Preset.themeFileName
      func resolved() throws -> String {
        try JSON.read(Data(command(["preset", "resolve", destination, "--json"]).stdout.utf8))[
          "code"
        ].text
      }
      #expect(try command(["preset", "apply", amber, "--destination", destination]).code == 0)
      let text = try readText(fs.fileSystem, path)
      for marker in [
        "// sweetui preset \(amber)", "accent: .yellow,", "onAccent: .black,",
        ".registryTheme(.app)",
      ] { #expect(text.contains(marker), "\(marker)") }
      #expect(try resolved() == amber)
      // Untouched: a second apply replaces it with another code.
      #expect(try command(["preset", "apply", indigo, "--destination", destination]).code == 0)
      #expect(try resolved() == indigo)
      // Edited by hand: refused without --force, and the edit is what resolves.
      try fs.put(path, text.replacingOccurrences(of: "cardRadius: 16", with: "cardRadius: 20"))
      let refused = try command(["preset", "apply", indigo, "--destination", destination])
      #expect(refused.code == 2)
      #expect(refused.stderr.contains("edited since it was written"))
      #expect(try readText(fs.fileSystem, path).contains("cardRadius: 20"))
      #expect(try resolved() != amber)
      #expect(
        try command(["preset", "apply", indigo, "--destination", destination, "--force"]).code == 0)
      #expect(try readText(fs.fileSystem, path).contains("accent: .indigo,"))
      // decode, url, and random speak the same code.
      let dual = try vector(named: "Custom accent with a separate dark accent")
      let decoded = try command(["preset", "decode", dual.code])
      #expect(decoded.code == 0)
      for marker in ["customAccentDark", "UIColor { traits in", Preset.url(dual.code)] {
        #expect(decoded.stdout.contains(marker), "\(marker)")
      }
      #expect(
        try JSON.read(Data(command(["preset", "decode", dual.code, "--json"]).stdout.utf8))[
          "tuning"]
          == dual.tuning)
      #expect(
        try command(["preset", "url", dual.code]).stdout.trimmingCharacters(
          in: .whitespacesAndNewlines) == Preset.url(dual.code))
      func random() throws -> String {
        try command(["preset", "random", "--seed", "3"]).stdout.trimmingCharacters(
          in: .whitespacesAndNewlines)
      }
      let first = try random()
      #expect(try random() == first)
      #expect(Preset.decode(first) != nil)
    }
  }
}

@Test func siteDataCarriesEveryPresetCodeAsPinned() throws {
  // The website's Themes and Create pages read each preset's code from the
  // generated site data, whose table keeps the codes as literals; a preset
  // added or re-encoded without updating that table would ship a stale code.
  let site = try withRepository {
    try JSON.read(Data(try SiteDataGenerator(root: repositoryRoot).render().utf8))
  }
  let presets = try #require(site["presets"].array)
  #expect(presets.count == 7)
  for preset in presets {
    let name = preset["name"].text
    #expect(preset["code"].text == (try vector(named: name)).code, Comment(rawValue: name))
  }
}
