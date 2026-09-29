import Dependencies
import Foundation

public struct RecipeGuidance: Error, Sendable {
  public var name: String
  public var docs: String
  public var usage: String
  public var guidance: String { usage + "\n\n" + docs }
}

public struct Registry {
  public let root: String
  public let name: String
  public var items: [String: JSON]
  public let order: [String]
  @Dependency(\.registryFileSystem) var fs

  public init(root: String) throws {
    let validator = RegistryValidator()
    let issues = validator.validate(root: root)
    guard issues.isEmpty else {
      throw RegistryError(
        "Registry validation failed:\n" + issues.map { "- \($0)" }.joined(separator: "\n"))
    }
    guard let catalog = validator.load(root: root).0 else {
      throw RegistryError("Cannot load registry")
    }
    self.root = catalog.root
    name = catalog.index["name"].text
    items = catalog.items
    order = catalog.order
  }

  public func resolve(_ name: String) throws -> [String] {
    var ordered: [String] = []
    var visiting = Set<String>()
    var visited = Set<String>()
    func visit(_ current: String) throws {
      if visited.contains(current) { return }
      if visiting.contains(current) {
        throw RegistryError("Registry dependency cycle at \(current)")
      }
      guard let item = items[current] else {
        throw RegistryError("Unknown registry item: \(current)")
      }
      if item["kind"] == "recipe" {
        throw RecipeGuidance(name: current, docs: item["docs"].text, usage: item["usage"].text)
      }
      visiting.insert(current)
      for dependency in item["registryDependencies"].strings { try visit(dependency) }
      visiting.remove(current)
      visited.insert(current)
      ordered.append(current)
    }
    try visit(name)
    return ordered
  }

  public func search(
    _ query: String = "", kind: String? = nil, platform: String? = nil, targetVersion: String? = nil
  ) throws -> [JSON] {
    func terms(_ value: String) -> Set<String> {
      Set(
        value.lowercased().split { !(($0 >= "a" && $0 <= "z") || ($0 >= "0" && $0 <= "9")) }.map(
          String.init))
    }
    func version(_ value: String) throws -> [Int] {
      let parts = value.components(separatedBy: ".").map {
        Int($0.trimmingCharacters(in: .whitespaces))
      }
      guard (1...3).contains(parts.count), parts.allSatisfy({ $0 != nil && $0! >= 0 }) else {
        throw RegistryError("Invalid platform version: \(value)")
      }
      return parts.map { $0! } + Array(repeating: 0, count: 3 - parts.count)
    }
    let queryTerms = terms(query)
    var results: [JSON] = []
    for name in order {
      let item = items[name]!
      if let kind, item["kind"].text != kind { continue }
      var platforms = item["platforms"].array ?? []
      if let platform {
        let target = try targetVersion.map(version)
        // Numeric floors compare after zero-padding, as Python's tuple comparison does.
        platforms = try (item["platforms"].array ?? []).filter { candidate in
          guard candidate["name"].text.lowercased() == platform.lowercased() else { return false }
          if let target {
            return try !target.lexicographicallyPrecedes(version(candidate["minimumVersion"].text))
          }
          return true
        }
        if platforms.isEmpty { continue }
      }
      let names = terms(name)
      let aliases = Set(item["aliases"].strings.flatMap { terms($0) })
      let tags = Set(item["tags"].strings.flatMap { terms($0) })
      let searchable = names.union(aliases).union(tags).union(terms(item["description"].text))
        .union([item["kind"].text])
      if !queryTerms.isSubset(of: searchable) { continue }
      var score = queryTerms.reduce(0) {
        $0 + (names.contains($1) ? 30 : aliases.contains($1) ? 25 : tags.contains($1) ? 20 : 5)
      }
      if query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == name { score += 100 }
      var result: JSON = [:]
      for key in [
        "name", "version", "kind", "description", "registryDependencies", "packageDependencies",
        "tags", "accessibility", "preview", "docs",
      ] { result[key] = item[key] }
      result["score"] = .number(Double(score))
      result["platforms"] = .array(platforms)
      result["aliases"] = item.object?["aliases"] ?? []
      results.append(result)
    }
    return results.sorted { lhs, rhs in
      if lhs["score"] != rhs["score"] { return lhs["score"].number! > rhs["score"].number! }
      return lhs["name"].text < rhs["name"].text
    }
  }

  public func packageRequirements(_ name: String) throws -> [JSON] {
    var seen = Set<String>()
    var result: [JSON] = []
    for member in try resolve(name) {
      for dependency in items[member]!["packageDependencies"].array ?? []
      where seen.insert(dependency.rendered()).inserted { result.append(dependency) }
    }
    return result
  }

  public static func dependencyInstruction(_ dependency: JSON) -> String {
    let rule = dependency["swiftPM"]
    let minimum = rule["minimumVersion"].text
    let requirement: String
    if rule.object != nil {
      switch rule["kind"].text {
      case "exactVersion": requirement = "exact version \(minimum)"
      case "range":
        requirement = "from \(minimum) up to \(rule["maximumVersionExclusive"].text) exclusive"
      case "upToNextMajor": requirement = "from \(minimum) up to the next major version"
      default: requirement = "from \(minimum) up to the next minor version"
      }
    } else {
      requirement = dependency["requirement"].text
    }
    return
      "add package \(dependency["sourceURL"].string ?? dependency["package"].text) (\(requirement)) and link product \(dependency["product"].text)"
  }
  public static func dependencyManifest(_ dependency: JSON) -> [String] {
    guard let url = dependency["sourceURL"].string, dependency["swiftPM"].object != nil else {
      return []
    }
    let rule = dependency["swiftPM"]
    let minimum = rule["minimumVersion"].text
    let argument: String
    switch rule["kind"].text {
    case "exactVersion": argument = "exact: \"\(minimum)\""
    case "range": argument = "\"\(minimum)\"..<\"\(rule["maximumVersionExclusive"].text)\""
    case "upToNextMajor": argument = "from: \"\(minimum)\""
    default: argument = ".upToNextMinor(from: \"\(minimum)\")"
    }
    var identity = String(url.split(separator: "/").last ?? "")
    if identity.hasSuffix(".git") { identity.removeLast(4) }
    return [
      "// Package.swift", "dependencies: [", "    .package(url: \"\(url)\", \(argument))", "]", "",
      "// In the consuming target's dependencies:",
      ".product(name: \"\(dependency["product"].text)\", package: \"\(identity)\")",
    ]
  }
  public static func dependencyXcode(_ dependency: JSON) -> String {
    "In an Xcode app project instead, choose File > Add Package Dependency, enter \(dependency["sourceURL"].string ?? dependency["package"].text) with the same version rule, and add the \(dependency["product"].text) product to your app target"
  }
}
