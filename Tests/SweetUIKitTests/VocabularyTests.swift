import Foundation
import Testing

@testable import SweetUIKit

/// One name per concept (`docs/design-surface.md`, Glossary): Tune's copy and
/// the agent's tool descriptions use the glossary's words, so the person and
/// the agent call each thing by the same name. A retired word back in a string
/// literal of the design surface, or in an MCP description, fails here with
/// the place it sits.
struct VocabularyTests {
  /// The contract's retired words, each a case-insensitive pattern over a
  /// literal's text. `registryVariant` never matches `variant`: no word
  /// boundary sits inside it.
  static let retired: [(word: String, pattern: String)] = [
    ("piece", #"\bpieces?\b"#),
    ("Picked", #"\bpicked\b"#),
    ("checkpoint", #"\bcheckpoints?\b"#),
    ("states as a count", #"(\d|#)\s+states?\b"#),
    ("variant", #"\bvariants?\b"#),
    ("resolved", #"\bresolved\b"#),
    ("Reopen", #"\breopen"#),
    ("Dismiss", #"\bdismiss"#),
    ("Send to agent", #"\bsend to (the )?agent\b"#),
    ("Export", #"\bexport"#),
    ("Capture the screen", #"\bcapture the screen\b"#),
    ("Tuning panel", #"\btuning panel\b"#),
    ("Tune panel", #"\btune panel\b"#),
    ("design surface panel", #"\bdesign surface panel\b"#),
    ("shipped theme", #"\bshipped theme\b"#),
    ("knob applied to a theme field", #"\b(theme|tuning) knobs?\b|\btuning fields?\b"#),
  ]

  /// Each retired word a text holds.
  static func hits(in text: String) -> [String] {
    retired.filter {
      text.range(of: $0.pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    .map(\.word)
  }

  @Test func theDesignSurfaceCopyUsesNoRetiredWord() throws {
    let folder = repositoryRoot + "/Sources/SweetUIDesignSurface"
    let files = try directoryEntries(folder).filter { $0.hasSuffix(".swift") }.sorted()
    var scanned = 0
    var found: [String] = []
    for file in files {
      for literal in Self.literals(in: try fileText(folder + "/" + file)) {
        scanned += 1
        found += Self.hits(in: literal).map { "\(file): \"\(literal)\" (\($0))" }
      }
    }
    #expect(scanned > 500, "The scan read \(scanned) literals; Tune's copy has hundreds.")
    #expect(found.isEmpty, "Retired words in Tune's copy:\n\(found.joined(separator: "\n"))")
  }

  @Test func theMCPDescriptionsUseNoRetiredWord() {
    let texts = [MCPServer.instructions] + Self.descriptions(in: MCPServer.tools)
    #expect(texts.count > 13 * 2, "Every tool has a title and a description.")
    let found = texts.flatMap { text in Self.hits(in: text).map { "\"\(text)\" (\($0))" } }
    #expect(
      found.isEmpty, "Retired words in the MCP descriptions:\n\(found.joined(separator: "\n"))")
  }

  /// The scan must see copy wherever Swift puts it, and nothing else: a
  /// planted word in a plain, multi-line, raw, or interpolated literal is
  /// found, while a comment and the `registryVariant` API are not copy.
  @Test func theScanFindsPlantedWordsAndSkipsCommentsAndCode() {
    let source = """
      // Dismiss the sheet. A comment is not copy.
      /* An Export section, /* nested */ still a comment. */
      let label = "Send to agent"
      let alert = InlineAlert("Saved") { }.registryVariant(.positive)
      let block = \"""
        A piece of the screen
        \"""
      let raw = #"The "checkpoint" list"#
      let count = "\\(items.count) states, \\(isOn ? "Reopen" : "Close")"
      """
    let literals = Self.literals(in: source)
    #expect(
      literals == [
        "Send to agent", "Saved", "A piece of the screen", #"The "checkpoint" list"#,
        "# states, #", "Reopen", "Close",
      ])
    #expect(
      literals.flatMap(Self.hits) == [
        "Send to agent", "piece", "checkpoint", "states as a count", "Reopen",
      ])
    #expect(Self.hits(in: "registryVariant(.positive)").isEmpty)
  }

  /// Every `title` and `description` in the tool declarations.
  static func descriptions(in json: OrderedJSON) -> [String] {
    switch json {
    case .object(let fields):
      fields.flatMap { key, value in
        (key == "title" || key == "description" ? value.string.map { [$0] } ?? [] : [])
          + descriptions(in: value)
      }
    case .array(let values): values.flatMap(descriptions)
    case .scalar, .numberToken: []
    }
  }

  /// The text of every string literal in Swift source, comments skipped and
  /// each interpolation read as `#`; a literal inside an interpolation is an
  /// entry of its own, after the literal that holds it.
  static func literals(in source: String) -> [String] {
    var scanner = LiteralScanner(characters: Array(source))
    scanner.code(insideInterpolation: false)
    return scanner.found
  }
}

/// Walks Swift source as code, comments, and string literals: plain,
/// multi-line, and raw (`#"..."#`), with `\(` interpolations of any depth.
private struct LiteralScanner {
  let characters: [Character]
  var index = 0
  var found: [String] = []

  private func at(_ offset: Int) -> Character? {
    characters.indices.contains(index + offset) ? characters[index + offset] : nil
  }

  /// Code up to the end, or past the `)` that closes an interpolation.
  mutating func code(insideInterpolation: Bool) {
    var depth = 0
    while let character = at(0) {
      if character == "/", at(1) == "/" {
        while let next = at(0), next != "\n" { index += 1 }
      } else if character == "/", at(1) == "*" {
        comment()
      } else if character == "#" || character == "\"" {
        var hashes = 0
        while at(hashes) == "#" { hashes += 1 }
        if at(hashes) == "\"" {
          index += hashes
          literal(hashes: hashes)
        } else {
          index += max(hashes, 1)
        }
      } else {
        if insideInterpolation, character == "(" { depth += 1 }
        if insideInterpolation, character == ")" {
          index += 1
          if depth == 0 { return }
          depth -= 1
          continue
        }
        index += 1
      }
    }
  }

  /// A block comment, nested ones included.
  private mutating func comment() {
    var depth = 0
    while let character = at(0) {
      if character == "/", at(1) == "*" {
        depth += 1
        index += 2
      } else if character == "*", at(1) == "/" {
        depth -= 1
        index += 2
        if depth == 0 { return }
      } else {
        index += 1
      }
    }
  }

  /// A literal from its opening quote, closed by as many quotes as opened
  /// it and then `hashes` number signs.
  private mutating func literal(hashes: Int) {
    let quotes = at(1) == "\"" && at(2) == "\"" ? 3 : 1
    index += quotes
    var text = ""
    let held = found.count
    while let character = at(0) {
      if character == "\"", (0..<quotes).allSatisfy({ at($0) == "\"" }),
        (0..<hashes).allSatisfy({ at(quotes + $0) == "#" })
      {
        index += quotes + hashes
        break
      }
      if character == "\\", (0..<hashes).allSatisfy({ at(1 + $0) == "#" }),
        let escaped = at(1 + hashes)
      {
        index += 2 + hashes
        if escaped == "(" {
          text.append("#")
          code(insideInterpolation: true)
        } else {
          text.append(escaped == "n" ? " " : escaped)
        }
        continue
      }
      text.append(character)
      index += 1
    }
    let multiline = quotes == 3
    found.insert(
      multiline ? text.trimmingCharacters(in: .whitespacesAndNewlines) : text, at: held)
  }
}
