import Dependencies
import Foundation

public enum Preset {
  public static let siteURL = "https://sweetui.dev"
  public static let themeFileName = "RegistryTheme+App.swift"
  public static let accents = [
    "system", "ink", "blue", "indigo", "purple", "pink", "red", "orange", "yellow", "green", "mint",
    "teal", "cyan", "brown", "custom",
  ]
  static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
  struct Field: Sendable {
    let key: String
    let bits: Int
    let minimum: Double
    let step: Double
    let count: Int
    let decimals: Int
  }
  static let fields: [Field] = [
    .init(key: "surfaceOpacity", bits: 6, minimum: 0, step: 0.005, count: 41, decimals: 3),
    .init(key: "borderOpacity", bits: 5, minimum: 0, step: 0.01, count: 31, decimals: 2),
    .init(key: "borderWidth", bits: 3, minimum: 0.5, step: 0.5, count: 6, decimals: 1),
    .init(key: "emphasizedBorderWidth", bits: 3, minimum: 1, step: 0.5, count: 7, decimals: 1),
    .init(key: "compactRadius", bits: 4, minimum: 0, step: 1, count: 13, decimals: 0),
    .init(key: "controlRadius", bits: 5, minimum: 0, step: 1, count: 23, decimals: 0),
    .init(key: "cardRadius", bits: 6, minimum: 0, step: 1, count: 33, decimals: 0),
    .init(key: "compactSpacing", bits: 4, minimum: 4, step: 1, count: 13, decimals: 0),
    .init(key: "standardSpacing", bits: 5, minimum: 8, step: 1, count: 25, decimals: 0),
    .init(key: "sectionSpacing", bits: 6, minimum: 12, step: 1, count: 37, decimals: 0),
    .init(key: "controlHorizontalPadding", bits: 5, minimum: 8, step: 1, count: 17, decimals: 0),
    .init(key: "disabledOpacity", bits: 4, minimum: 0.2, step: 0.05, count: 13, decimals: 2),
  ]
  public static let defaultTuning: JSON = [
    "accent": "system", "darkLabelOnAccent": false, "surfaceOpacity": 0.055,
    "borderOpacity": 0.08, "borderWidth": 1.0, "emphasizedBorderWidth": 2.0,
    "compactRadius": 6.0, "controlRadius": 8.0, "cardRadius": 16.0,
    "compactSpacing": 8.0, "standardSpacing": 16.0, "sectionSpacing": 24.0,
    "controlHorizontalPadding": 12.0, "disabledOpacity": 0.5,
  ]
  // Version b appends these after the a layout (and its custom accent block), in
  // this order. fontDesign and chartPalette store a value index; surfaceStep
  // stores an index into a value list, not a grid, so its default is at index 0.
  static let fontDesigns = ["default", "rounded", "serif", "monospaced"]  // 2 bits
  static let surfaceSteps = [0.02, 0.00, 0.01, 0.03, 0.04, 0.05, 0.06, 0.07]  // 3 bits
  static let chartPalettes = ["accent", "spectrum", "monochrome"]  // 2 bits, index 3 invalid
  static let colorPairs = [
    ("background", "backgroundDark"), ("foreground", "foregroundDark"),
    ("secondaryForeground", "secondaryForegroundDark"),
  ]
  public static func isCode(_ code: String) -> Bool {
    (2...48).contains(code.count) && (code.first == "a" || code.first == "b")
      && code.dropFirst().allSatisfy { alphabet.contains($0) }
  }
  public static func code(in text: String) -> String? {
    var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if let range = candidate.range(of: "^--preset\\s+", options: .regularExpression) {
      candidate.removeSubrange(range)
    }
    return isCode(candidate) ? candidate : nil
  }
  public static func decode(_ code: String) -> JSON? {
    guard isCode(code) else { return nil }
    // A version b code with every field set exceeds 128 bits, so the packed value
    // is an arbitrary-width little-endian integer read sequentially; high bits
    // past the known fields are ignored, so an older layout tolerates a newer code.
    var reader = PresetBits(base62: code.dropFirst())
    func read(_ width: Int) -> Int { reader.read(width) }
    let accent = read(4)
    guard accent < accents.count else { return nil }
    var tuning: JSON = [
      "accent": .string(accents[accent]), "darkLabelOnAccent": .bool(read(1) == 1),
    ]
    for field in fields {
      let index = read(field.bits)
      guard index < field.count else { return nil }
      let scale = pow(10, Double(field.decimals))
      tuning[field.key] = .number(
        ((field.minimum + Double(index) * field.step) * scale).rounded(.toNearestOrEven) / scale)
    }
    if accent == 14 {
      tuning["customAccent"] = .string(hex(read(24)))
      tuning["customAccentDark"] = read(1) == 1 ? .string(hex(read(24))) : .null
    }
    // Version b appends the new fields; an a code stops here with the a shape,
    // and its higher bits, if any, are ignored.
    if code.first == "b" {
      tuning["fontDesign"] = .string(fontDesigns[read(2)])
      tuning["surfaceStep"] = .number(surfaceSteps[read(3)])
      let chart = read(2)
      guard chart < chartPalettes.count else { return nil }
      tuning["chartPalette"] = .string(chartPalettes[chart])
      for (light, dark) in colorPairs {
        if read(1) == 1 {
          tuning[light] = .string(hex(read(24)))
          tuning[dark] = read(1) == 1 ? .string(hex(read(24))) : .null
        } else {
          tuning[light] = .null
          tuning[dark] = .null
        }
      }
    }
    return tuning
  }
  public static func encode(_ tuning: JSON) throws -> String {
    guard let accent = accents.firstIndex(of: tuning["accent"].text) else {
      throw RegistryError(
        "accent must be one of \(accents.joined(separator: ", ")), not '\(tuning["accent"].text)'")
    }
    var writer = PresetBits()
    writer.write(accent, width: 4)
    guard tuning["darkLabelOnAccent"] == .bool(true) || tuning["darkLabelOnAccent"] == .bool(false)
    else { throw RegistryError("darkLabelOnAccent must be one of False, True") }
    writer.write(tuning["darkLabelOnAccent"] == .bool(true) ? 1 : 0, width: 1)
    for field in fields {
      guard let number = tuning[field.key].number, number.isFinite else {
        throw RegistryError("\(field.key) must be a number")
      }
      let value = max(
        0,
        min(
          Double(field.count - 1), ((number - field.minimum) / field.step).rounded(.toNearestOrEven)
        ))
      writer.write(Int(value), width: field.bits)
    }
    if accent == 14 {
      writer.write(try rgb(tuning["customAccent"].text), width: 24)
      if let dark = tuning["customAccentDark"].string, !dark.isEmpty {
        writer.write(1, width: 1)
        writer.write(try rgb(dark), width: 24)
      } else {
        writer.write(0, width: 1)
      }
    }
    // Version b appends the new fields; when every one is at its default the bits
    // are zero and the code is written as a, so an unchanged tuning keeps its a code.
    let fontIndex = try index(tuning["fontDesign"].string, in: fontDesigns, field: "fontDesign")
    let chartIndex = try index(
      tuning["chartPalette"].string, in: chartPalettes, field: "chartPalette")
    let stepIndex =
      tuning["surfaceStep"].number.map { step in
        surfaceSteps.indices.min {
          abs(surfaceSteps[$0] - step) < abs(surfaceSteps[$1] - step)
        } ?? 0
      } ?? 0
    var appended = fontIndex != 0 || stepIndex != 0 || chartIndex != 0
    writer.write(fontIndex, width: 2)
    writer.write(stepIndex, width: 3)
    writer.write(chartIndex, width: 2)
    for (light, dark) in colorPairs {
      if let color = tuning[light].string, !color.isEmpty {
        appended = true
        writer.write(1, width: 1)
        writer.write(try rgb(color), width: 24)
        if let darkColor = tuning[dark].string, !darkColor.isEmpty {
          writer.write(1, width: 1)
          writer.write(try rgb(darkColor), width: 24)
        } else {
          writer.write(0, width: 1)
        }
      } else {
        writer.write(0, width: 1)
      }
    }
    return (appended ? "b" : "a") + writer.base62()
  }
  /// The packed preset value as an arbitrary-width little-endian integer over
  /// base-256 limbs, so a full version b code (more than 128 bits) neither
  /// overflows nor loses a field. Fields are written and read LSB first, and the
  /// base62 form matches the version a packing byte for byte.
  struct PresetBits {
    private var limbs: [UInt8] = []
    private var cursor = 0
    init() {}
    init(base62 digits: Substring) {
      for character in digits {
        let digit = Preset.alphabet.firstIndex(of: character) ?? 0
        var carry = digit
        for i in limbs.indices {
          let value = Int(limbs[i]) * 62 + carry
          limbs[i] = UInt8(value & 0xff)
          carry = value >> 8
        }
        while carry > 0 {
          limbs.append(UInt8(carry & 0xff))
          carry >>= 8
        }
      }
    }
    mutating func write(_ value: Int, width: Int) {
      for i in 0..<width where (value >> i) & 1 == 1 {
        let bit = cursor + i
        while limbs.count <= bit / 8 { limbs.append(0) }
        limbs[bit / 8] |= UInt8(1 << (bit % 8))
      }
      cursor += width
    }
    mutating func read(_ width: Int) -> Int {
      var value = 0
      for i in 0..<width {
        let bit = cursor + i
        if bit / 8 < limbs.count, (limbs[bit / 8] >> (bit % 8)) & 1 == 1 { value |= 1 << i }
      }
      cursor += width
      return value
    }
    func base62() -> String {
      var value = limbs
      var digits: [Character] = []
      repeat {
        var remainder = 0
        for i in stride(from: value.count - 1, through: 0, by: -1) {
          let current = (remainder << 8) + Int(value[i])
          value[i] = UInt8(current / 62)
          remainder = current % 62
        }
        digits.append(Preset.alphabet[remainder])
        while value.last == 0 { value.removeLast() }
      } while !value.isEmpty
      return String(digits.reversed())
    }
  }
  static func index(_ value: String?, in values: [String], field: String) throws -> Int {
    guard let value else { return 0 }
    guard let index = values.firstIndex(of: value) else {
      throw RegistryError(
        "\(field) must be one of \(values.joined(separator: ", ")), not '\(value)'")
    }
    return index
  }
  static func rgb(_ color: String) throws -> Int {
    guard matches(color, "^#[0-9A-Fa-f]{6}$"), let bits = Int(color.dropFirst(), radix: 16) else {
      throw RegistryError("a custom accent must be #RRGGBB, not '\(color)'")
    }
    return bits
  }
  static func hex(_ bits: Int) -> String { String(format: "#%06X", bits & 0xffffff) }
  public static func url(_ code: String) -> String { siteURL + "/create?preset=" + code }
  /// A channel with the fewest decimals, never under three, that reads back as
  /// the 8-bit value, so the compiled color is the one the code decodes to.
  static func channelLiteral(_ value: Double) -> String {
    for digits in 3...15 {
      let text = String(format: "%.\(digits)f", value)
      if let read = Double(text), abs(read - value) <= 1e-12 { return text }
    }
    return "\(value)"
  }
  public static func initializerLines(_ tuning: JSON) throws -> [String] {
    func color(_ value: String, ui: Bool) throws -> String {
      let bits = try rgb(value)
      let values = [16, 8, 0].map { channelLiteral(Double((bits >> $0) & 255) / 255) }
      return
        "\(ui ? "UIColor" : "Color")(red: \(values[0]), green: \(values[1]), blue: \(values[2])\(ui ? ", alpha: 1" : ""))"
    }
    func decimal(_ key: String) -> String { String(format: "%.3f", tuning[key].number ?? 0) }
    func points(_ key: String) -> String {
      let number = tuning[key].number ?? 0
      return String(format: number.rounded() == number ? "%.0f" : "%.1f", number)
    }
    let accent = tuning["accent"].text
    var lines = ["RegistryTheme("]
    if accent == "custom", let dark = tuning["customAccentDark"].string, !dark.isEmpty {
      lines += [
        "    accent: Color(uiColor: UIColor { traits in",
        "        traits.userInterfaceStyle == .dark", "            ? \(try color(dark, ui: true))",
        "            : \(try color(tuning["customAccent"].text, ui: true))", "    }),",
      ]
    } else if accent == "custom" {
      lines.append("    accent: \(try color(tuning["customAccent"].text, ui: false)),")
    } else if accent != "system" {
      lines.append("    accent: .\(accent == "ink" ? "primary" : accent),")
    }
    let onAccent =
      accent == "ink"
      ? "Color(uiColor: .systemBackground)"
      : tuning["darkLabelOnAccent"] == .bool(true) ? ".black" : ".white"
    lines += [
      "    onAccent: \(onAccent),", "    surface: .primary.opacity(\(decimal("surfaceOpacity"))),",
      "    border: .primary.opacity(\(decimal("borderOpacity"))),",
      "    disabledOpacity: \(decimal("disabledOpacity")),",
    ]
    // Version b fields print only when non-default, so an a-shaped tuning exports
    // the same Swift it always did. They follow metrics, the order RegistryTheme's
    // initializer declares, or the file does not compile.
    var appended: [String] = []
    if let font = tuning["fontDesign"].string, font != "default" {
      appended.append("    fontDesign: .\(font),")
    }
    // The surface fill alone does not carry surfaceOpacity, and `surface(at:)`
    // steps an elevated level from it.
    if let opacity = tuning["surfaceOpacity"].number, opacity != 0.055 {
      appended.append("    surfaceOpacity: \(decimal("surfaceOpacity")),")
    }
    if let step = tuning["surfaceStep"].number, step != 0.02 {
      appended.append("    surfaceStep: \(String(format: "%.2f", step)),")
    }
    if let palette = tuning["chartPalette"].string, palette != "accent" {
      appended.append("    chartPalette: .\(palette),")
    }
    for (light, dark) in colorPairs {
      guard let value = tuning[light].string, !value.isEmpty else { continue }
      if let darkValue = tuning[dark].string, !darkValue.isEmpty {
        appended += [
          "    \(light): Color(uiColor: UIColor { traits in",
          "        traits.userInterfaceStyle == .dark",
          "            ? \(try color(darkValue, ui: true))",
          "            : \(try color(value, ui: true))", "    }),",
        ]
      } else {
        appended.append("    \(light): \(try color(value, ui: false)),")
      }
    }
    lines.append("    metrics: RegistryMetrics(")
    let metrics = [
      "compactSpacing", "standardSpacing", "sectionSpacing", "controlHorizontalPadding",
      "borderWidth", "emphasizedBorderWidth", "compactRadius", "controlRadius", "cardRadius",
    ]
    for key in metrics {
      lines.append("        \(key): \(points(key))\(key == metrics.last ? "" : ",")")
    }
    guard !appended.isEmpty else { return lines + ["    )", ")"] }
    appended[appended.count - 1].removeLast()
    return lines + ["    ),"] + appended + [")"]
  }
  // Whether the Swift export uses the dynamic UIColor(uiColor:) form, which needs UIKit:
  // the ink label, a custom accent pair, or any color field carrying a dark value.
  static func exportNeedsUIKit(_ tuning: JSON) -> Bool {
    if tuning["accent"] == "ink" { return true }
    if tuning["accent"] == "custom", let dark = tuning["customAccentDark"].string, !dark.isEmpty {
      return true
    }
    return colorPairs.contains { light, dark in
      (tuning[light].string?.isEmpty == false) && (tuning[dark].string?.isEmpty == false)
    }
  }
  public static func swiftSource(_ tuning: JSON) throws -> String {
    var lines = try initializerLines(tuning)
    lines[0] = "let theme = " + lines[0]
    lines += [
      "", "// Apply once at the root of your scene; every registry item below inherits it.",
      "ContentView()", "    .registryTheme(theme)",
    ]
    return lines.joined(separator: "\n")
  }
  public static func themeFile(_ tuning: JSON, code: String) throws -> String {
    let body = try initializerLines(tuning)
    var lines = ["import SwiftUI", "import SweetUIFoundations"]
    if exportNeedsUIKit(tuning) {
      lines.append("import UIKit")
    }
    lines += [
      "", "// sweetui preset \(code)", "// \(url(code))",
      "// Written by `sweetui preset apply`. Edit freely; `sweetui preset resolve` reads it back into a code.",
      "", "extension RegistryTheme {",
      "    /// Apply once at the scene root: `ContentView().registryTheme(.app)`.",
      "    static let app = \(body[0])",
    ]
    lines += body.dropFirst().map { "    " + $0 }
    return (lines + ["}", ""]).joined(separator: "\n")
  }
  static func captures(_ pattern: String, _ text: String) -> [[String]] {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { match in
      (1..<match.numberOfRanges).map {
        Range(match.range(at: $0), in: text).map { String(text[$0]) } ?? ""
      }
    }
  }
  public static func parseSwift(_ text: String, base: JSON = defaultTuning) throws -> JSON {
    guard text.contains("RegistryTheme(") else {
      throw RegistryError("no RegistryTheme( initializer found")
    }
    var tuning = base
    let flat = text.replacingOccurrences(of: "\n", with: " ")
    let channels = "red:\\s*([0-9.]+),\\s*green:\\s*([0-9.]+),\\s*blue:\\s*([0-9.]+)"
    let rgbs = captures("(?:UI)?Color\\(" + channels, flat)
    func hexChannels(_ values: [String]) -> JSON {
      let channels = values.map {
        max(0, min(255, Int(((Double($0) ?? 0) * 255).rounded(.toNearestOrEven))))
      }
      return .string(hex((channels[0] << 16) | (channels[1] << 8) | channels[2]))
    }
    if flat.contains("accent: Color(uiColor: UIColor {") && rgbs.count >= 2 {
      tuning["accent"] = "custom"
      tuning["customAccentDark"] = hexChannels(rgbs[0])
      tuning["customAccent"] = hexChannels(rgbs[1])
    } else if let word = captures("accent:\\s*\\.([a-zA-Z]+)", flat).first?.first {
      let accent =
        [
          "primary": "ink", "graphite": "ink", "rose": "pink", "emerald": "green",
          "amber": "yellow",
        ][word] ?? word
      guard accents.contains(accent), accent != "custom" else {
        throw RegistryError("unknown accent .\(word)")
      }
      tuning["accent"] = .string(accent)
      var object = tuning.object!
      object.removeValue(forKey: "customAccent")
      object.removeValue(forKey: "customAccentDark")
      tuning = .object(object)
    } else if let values = captures("accent:\\s*Color\\(" + channels, flat).first {
      tuning["accent"] = "custom"
      tuning["customAccent"] = hexChannels(values)
      tuning["customAccentDark"] = .null
    }
    if flat.contains("onAccent: .black") {
      tuning["darkLabelOnAccent"] = true
    } else if flat.contains("onAccent: .white") {
      tuning["darkLabelOnAccent"] = false
    }
    for key in ["surface", "border"] {
      if let value = captures("\\b\(key):\\s*\\.primary\\.opacity\\(([0-9.]+)\\)", flat).first?
        .first, let number = Double(value)
      {
        tuning[key + "Opacity"] = .number(number)
      }
    }
    for field in fields where field.key != "surfaceOpacity" && field.key != "borderOpacity" {
      if let value = captures("\\b\(field.key):\\s*([0-9]+(?:\\.[0-9]+)?)", flat).first?.first,
        let number = Double(value)
      {
        tuning[field.key] = .number(number)
      }
    }
    // Version b fields; absent lines leave the a shape, which encodes to an a code.
    if let word = captures("fontDesign:\\s*\\.([a-zA-Z]+)", flat).first?.first {
      tuning["fontDesign"] = .string(word)
    }
    if let value = captures("surfaceStep:\\s*([0-9.]+)", flat).first?.first,
      let number = Double(value)
    {
      tuning["surfaceStep"] = .number(number)
    }
    if let word = captures("chartPalette:\\s*\\.([a-zA-Z]+)", flat).first?.first {
      tuning["chartPalette"] = .string(word)
    }
    for (light, dark) in colorPairs {
      let dynamic = captures(
        "\(light):\\s*Color\\(uiColor: UIColor \\{ traits in\\s*traits\\.userInterfaceStyle == \\.dark\\s*\\? UIColor\\("
          + channels + ", alpha: 1\\)\\s*: UIColor\\(" + channels + ", alpha: 1\\)", flat)
      if let values = dynamic.first {
        tuning[dark] = hexChannels(Array(values[0..<3]))
        tuning[light] = hexChannels(Array(values[3..<6]))
      } else if let values = captures("\(light):\\s*Color\\(" + channels, flat).first {
        tuning[light] = hexChannels(values)
        tuning[dark] = .null
      }
    }
    return tuning
  }
  public static func resolveFile(_ path: String) throws -> String {
    @Dependency(\.registryFileSystem) var fs
    let target = fs.isDirectory(path) ? path + "/" + themeFileName : path
    guard fs.isFile(target) else { throw RegistryError("no theme file at \(target)") }
    return try encode(parseSwift(String(decoding: fs.read(target), as: UTF8.self)))
  }
  @discardableResult public static func apply(
    _ code: String, destination: String, force: Bool = false
  ) throws -> String {
    @Dependency(\.registryFileSystem) var fs
    guard let tuning = decode(code) else { throw RegistryError("invalid preset code: \(code)") }
    let target = destination + "/" + themeFileName
    if fs.exists(target) && !force {
      let existing = String(decoding: try fs.read(target), as: UTF8.self)
      let header = captures("(?m)^// sweetui preset (\\S+)$", existing).first?.first
      let written = header.flatMap { isCode($0) ? $0 : nil }
      let current = try? encode(parseSwift(existing))
      if written == nil || current != written {
        throw RegistryError(
          "\(target) was edited since it was written (it resolves to \(current ?? "no theme"), its header says \(written ?? "nothing")); pass --force to replace it"
        )
      }
    }
    try fs.createDirectory(destination)
    try fs.write(Data(themeFile(tuning, code: code).utf8), to: target)
    return target
  }
  public static func description(_ code: String, json: Bool = false) throws -> String {
    guard let tuning = decode(code) else { throw RegistryError("invalid preset code: \(code)") }
    let version = String(code.prefix(1))
    let appendedKeys = [
      "fontDesign", "surfaceStep", "chartPalette", "background", "backgroundDark", "foreground",
      "foregroundDark", "secondaryForeground", "secondaryForegroundDark",
    ]
    let keys =
      ["accent", "darkLabelOnAccent"] + fields.map(\.key)
      + (tuning["accent"] == "custom" ? ["customAccent", "customAccentDark"] : [])
      + appendedKeys.filter { tuning.object?[$0] != nil }
    func value(_ key: String) -> String {
      if let number = tuning[key].number { return String(number) }
      return tuning[key].rendered()
    }
    if json {
      let body = keys.map { "    \"\($0)\": \(value($0))" }.joined(separator: ",\n")
      return
        "{\n  \"code\": \"\(code)\",\n  \"version\": \"\(version)\",\n  \"tuning\": {\n\(body)\n  },\n  \"swift\": \(try JSON.string(swiftSource(tuning)).rendered()),\n  \"url\": \(JSON.string(url(code)).rendered())\n}"
    }
    func row(_ key: String, _ value: String) -> String {
      "  " + key + String(repeating: " ", count: max(0, 26 - key.count)) + value
    }
    var lines = ["Preset", row("code", code), row("version", version)]
    for key in keys {
      lines.append(row(key, tuning[key] == .null ? "none" : tuning[key].string ?? value(key)))
    }
    lines += [row("url", url(code)), "", try swiftSource(tuning)]
    return lines.joined(separator: "\n")
  }
}
