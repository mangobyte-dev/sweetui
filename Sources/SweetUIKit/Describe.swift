import Dependencies
import Foundation

/// The `describe_item` payload shared by the MCP `describe_item` tool and the CLI `describe`
/// command. Item metadata keeps the source document's field order; an installable item also
/// carries the resolved install order, package requirements, and canonical file source, while a
/// recipe stops at its metadata and `installs: false`.
public func describeItem(_ name: String, registry: Registry, fs: FileSystem, root: String)
  throws -> OrderedJSON
{
  guard let item = registry.items[name] else {
    throw RegistryError("Unknown registry item: \(name)")
  }
  // Preserve nested platform metadata order from the item document too.
  let index = try JSON.read(fs.read(root + "/Registry/registry.json"))
  var original: OrderedJSON = [:]
  for path in index["items"].strings {
    let data = try fs.read(root + "/Registry/" + path)
    if try JSON.read(data)["name"].text == name {
      original = try OrderedJSON.read(data)
      break
    }
  }
  var described = OrderedJSON.object(
    [
      "name", "kind", "version", "description", "usage", "docs", "tags", "aliases", "platforms",
      "accessibility", "registryDependencies",
    ].map { ($0, original[$0]) })
  if item["kind"] == "recipe" {
    described["installs"] = false
    return described
  }
  described["installs"] = true
  described["installOrder"] = .array(try registry.resolve(name).map(OrderedJSON.string))
  described["packageRequirements"] = .array(
    try registry.packageRequirements(name).map(packageDescription))
  let sources = try (item["files"].array ?? []).map { file in
    (file, try readText(fs, root + "/Registry/" + file["source"].text))
  }
  described["signatures"] = .array(
    sources.flatMap { publicSignatures(in: $0.1) }.map(OrderedJSON.string))
  described["files"] = .array(
    sources.map { file, content in
      [
        "source": OrderedJSON(file["source"]), "target": OrderedJSON(file["target"]),
        "content": .string(content),
      ]
    })
  return described
}

/// The public initializers, functions, static members, and enum cases a source file declares,
/// each on one line up to its body and prefixed with the owning type (`FieldGroup: init(...)`,
/// `RegistryToast.Action: init(...)`, `View: func registryBadge(...)`), so a composer sees which
/// type to spell and which cases exist without opening the file.
func publicSignatures(in source: String) -> [String] {
  let starts = [
    "public init(", "public init<", "public func ", "public static var ", "public static let ",
    "public static func ", "public mutating func ",
  ]
  // Members of a `public extension` are public without the keyword.
  let extensionStarts = ["init(", "init<", "func ", "static var ", "static let ", "static func "]
  var scopes: [SignatureScope] = []
  var signatures: [String] = []
  var current = ""
  var open = false
  var depth = 0
  var braceDepth = 0
  for rawLine in source.components(separatedBy: "\n") {
    let line = rawLine.trimmingCharacters(in: .whitespaces)
    let owner = scopes.map(\.name).joined(separator: ".")
    if !open, let scope = typeScope(opening: line, at: braceDepth) {
      scopes.append(scope)
    } else if !open, line.hasPrefix("case "), !line.hasPrefix("case ."),
      let scope = scopes.last, var cases = scope.enumCases, braceDepth == scope.depth + 1
    {
      cases.append(String(line.dropFirst("case ".count)))
      scopes[scopes.count - 1].enumCases = cases
    }
    braceDepth += line.filter { $0 == "{" }.count - line.filter { $0 == "}" }.count
    while let last = scopes.last, braceDepth <= last.depth {
      if let cases = last.enumCases, !cases.isEmpty {
        signatures.append("\(owner): enum { case " + cases.joined(separator: "; case ") + " }")
      }
      scopes.removeLast()
    }
    if !open {
      let matches =
        starts.contains(where: { line.hasPrefix($0) })
        || ((scopes.last?.isPublicExtension ?? false)
          && extensionStarts.contains(where: { line.hasPrefix($0) }))
      // A style's makeBody is the protocol's, never called by a composer.
      guard matches, !line.contains("func makeBody(") else { continue }
      open = true
      depth = 0
      current = owner.isEmpty ? "" : owner + ":"
    }
    // A declaration ends at its body's brace or, for a stored static, at its value; both sit
    // outside every parenthesis, where a default value's `=` never is.
    var ended = false
    var piece = ""
    let characters = Array(line)
    for (index, character) in characters.enumerated() {
      if character == "(" || character == "[" { depth += 1 }
      if character == ")" || character == "]" { depth -= 1 }
      if depth == 0 {
        if character == "{" {
          ended = true
          break
        }
        let previous = index > 0 ? characters[index - 1] : " "
        let next = index + 1 < characters.count ? characters[index + 1] : " "
        if character == "=", !"=!<>".contains(previous), next != "=" {
          ended = true
          break
        }
      }
      piece.append(character)
    }
    var trimmed = piece.trimmingCharacters(in: .whitespaces)
    if current.hasSuffix(":") || current.isEmpty, trimmed.hasPrefix("public ") {
      trimmed = String(trimmed.dropFirst("public ".count))
    }
    current += (current.isEmpty || trimmed.isEmpty ? "" : " ") + trimmed
    if ended {
      signatures.append(
        current.replacingOccurrences(of: "( ", with: "(").replacingOccurrences(of: " )", with: ")"))
      open = false
    }
  }
  return signatures
}

/// A type or extension declaration that encloses the members after it: its name without generic
/// parameters or a `where` clause, the brace depth it returns to, whether its members are public
/// without the keyword (a `public extension`), and the cases collected for a public enum.
private struct SignatureScope {
  var name: String
  var depth: Int
  var isPublicExtension: Bool
  var enumCases: [String]?
}

private func typeScope(opening line: String, at depth: Int) -> SignatureScope? {
  guard line.contains("{") else { return nil }
  var words = line.split(separator: " ").map(String.init)
  let isPublic = words.first == "public" || words.first == "package"
  words.removeAll { ["public", "package", "final", "indirect", "@frozen"].contains($0) }
  guard let kind = words.first, ["struct", "enum", "class", "actor", "extension"].contains(kind),
    words.count > 1
  else { return nil }
  let name = words[1].prefix { $0 != "<" && $0 != ":" && $0 != "{" }
  return SignatureScope(
    name: String(name), depth: depth, isPublicExtension: kind == "extension" && isPublic,
    enumCases: kind == "enum" && isPublic ? [] : nil)
}
