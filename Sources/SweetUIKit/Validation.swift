import Dependencies
import Foundation

public struct ValidationIssue: Equatable, Sendable, CustomStringConvertible {
  public var location: String
  public var message: String
  public var description: String { "\(location): \(message)" }
}

/// The single structural validator; every consumer loads the registry through it. All structural rules live here.
public struct RegistryValidator {
  @Dependency(\.registryFileSystem) var fs
  public init() {}

  public func validate(root: String, item name: String? = nil) -> [ValidationIssue] {
    let (catalog, loading) = load(root: root)
    guard let catalog else { return loading }
    if name != nil && !loading.isEmpty { return loading }
    var issues = loading
    let names: [String]
    if let name {
      guard catalog.items[name] != nil else {
        return [
          .init(location: "Registry/registry.json", message: "unknown registry item: \(name)")
        ]
      }
      var pending = [name]
      var seen = Set<String>()
      var closure: [String] = []
      while let current = pending.popLast() {
        guard seen.insert(current).inserted else { continue }
        closure.append(current)
        pending += catalog.items[current]!["registryDependencies"].strings.filter {
          catalog.items[$0] != nil
        }
      }
      names = closure
    } else {
      names = catalog.order
    }
    for name in names {
      check(
        catalog.items[name]!, schema: catalog.schema, root: catalog.root,
        location: catalog.locations[name]!, issues: &issues)
    }
    for name in names {
      for dependency in catalog.items[name]!["registryDependencies"].strings {
        if let target = catalog.items[dependency] {
          if target["kind"] == "recipe" {
            issues.append(
              .init(
                location: catalog.locations[name]!,
                message:
                  "depends on recipe \(dependency); recipes install nothing and cannot be dependencies"
              ))
          }
        } else {
          issues.append(
            .init(
              location: catalog.locations[name]!,
              message: "unknown registry dependency: \(dependency)"))
        }
      }
    }
    var state: [String: Int] = [:]
    func visit(_ name: String, _ trail: [String]) {
      if state[name] == 2 { return }
      if state[name] == 1 {
        let cycle = Array(trail[(trail.firstIndex(of: name) ?? 0)...]) + [name]
        issues.append(
          .init(
            location: catalog.locations[name]!,
            message: "dependency cycle: " + cycle.joined(separator: " -> ")))
        return
      }
      state[name] = 1
      for dependency in catalog.items[name]!["registryDependencies"].strings
      where catalog.items[dependency] != nil { visit(dependency, trail + [name]) }
      state[name] = 2
    }
    for name in names { visit(name, []) }
    return issues
  }

  struct Catalog {
    var root: String
    var schema: JSON
    var index: JSON
    var order: [String] = []
    var items: [String: JSON] = [:]
    var locations: [String: String] = [:]
  }
  func load(root: String) -> (Catalog?, [ValidationIssue]) {
    let root = fs.resolve(root)
    let registry = fs.resolve(root) + "/Registry"
    var issues: [ValidationIssue] = []
    func read(_ path: String, _ location: String) -> JSON? {
      do {
        let value = try JSON.read(fs.read(path))
        guard value.object != nil else {
          issues.append(.init(location: location, message: "expected a JSON object"))
          return nil
        }
        return value
      } catch {
        issues.append(.init(location: location, message: "cannot read JSON: \(error)"))
        return nil
      }
    }
    let schema = read(registry + "/schema.json", "Registry/schema.json")
    let index = read(registry + "/registry.json", "Registry/registry.json")
    guard let schema, let index else { return (nil, issues) }
    let location = "Registry/registry.json"
    if index["schemaVersion"] != 1 {
      issues.append(.init(location: location, message: "schemaVersion must be 1"))
    }
    if index["name"].text.isEmpty {
      issues.append(.init(location: location, message: "name must be a non-empty string"))
    }
    guard let listed = index["items"].array, listed.allSatisfy({ $0.string != nil }) else {
      issues.append(
        .init(location: location, message: "items must be an array of relative item paths"))
      return (nil, issues)
    }
    var catalog = Catalog(root: root, schema: schema, index: index)
    var seen = Set<String>()
    var paths = Set<String>()
    for entry in listed {
      let relative = entry.text
      let itemLocation = "Registry/" + relative
      if !seen.insert(relative).inserted {
        issues.append(
          .init(location: location, message: "item file listed more than once: \(relative)"))
        continue
      }
      guard let path = try? safeJoin(registry, relative, fs: fs) else {
        issues.append(.init(location: location, message: "unsafe item path: \(relative)"))
        continue
      }
      guard fs.isFile(path) else {
        issues.append(
          .init(location: location, message: "listed item file does not exist: \(relative)"))
        continue
      }
      paths.insert(path)
      guard let item = read(path, itemLocation) else { continue }
      let name = item["name"].text
      guard !name.isEmpty else {
        issues.append(.init(location: itemLocation, message: "item document has no usable name"))
        continue
      }
      guard catalog.items[name] == nil else {
        issues.append(
          .init(location: itemLocation, message: "duplicate registry item name: \(name)"))
        continue
      }
      catalog.order.append(name)
      catalog.items[name] = item
      catalog.locations[name] = itemLocation
    }
    for path in (try? fs.children(registry + "/items")) ?? []
    where path.hasSuffix(".json") && !paths.contains(fs.resolve(path)) {
      issues.append(
        .init(
          location: "Registry/items/" + (path as NSString).lastPathComponent,
          message: "item file exists but is not listed in registry.json"))
    }
    return (catalog, issues)
  }

  private func check(
    _ item: JSON, schema: JSON, root: String, location: String, issues: inout [ValidationIssue]
  ) {
    let props = schema["properties"]
    func add(_ message: String) { issues.append(.init(location: location, message: message)) }
    keys(item, schema, location, &issues)
    if item.object?["schemaVersion"] != nil
      && item["schemaVersion"] != props["schemaVersion"]["const"]
    {
      add("schemaVersion must be 1")
    }
    for key in ["version", "name"] where item.object?[key] != nil {
      if item[key].string == nil || !matches(item[key].text, props[key]["pattern"].text) {
        add("\(key) must match \(props[key]["pattern"].text)")
      }
    }
    let kinds = props["kind"]["enum"].strings
    let kind = item["kind"].text
    if item.object?["kind"] != nil && !kinds.contains(kind) {
      add("kind must be one of: " + kinds.joined(separator: ", "))
    }
    for key in ["description", "docs"] where item.object?[key] != nil {
      if item[key].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        add("\(key) must be a non-empty string")
      }
    }
    if item["usage"].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      add("every item requires a non-empty usage snippet")
    }
    for key in ["files", "packageDependencies"] where item.object?[key] != nil {
      if let entries = item[key].array {
        for (i, entry) in entries.enumerated() {
          object(entry, props[key]["items"], "\(location) (\(key)[\(i)])", &issues)
        }
      } else {
        add("\(key) must be an array")
      }
    }
    for key in ["registryDependencies", "tags", "aliases", "accessibility"] {
      stringArray(item, key, location, unique: key != "accessibility", issues: &issues)
    }
    for alias in item["aliases"].strings where !matches(alias, props["name"]["pattern"].text) {
      add("alias must be kebab-case: \(alias)")
    }
    let ruleSchema = props["packageDependencies"]["items"]["properties"]["swiftPM"]
    let ruleKinds = ruleSchema["properties"]["kind"]["enum"].strings
    for (i, dependency) in (item["packageDependencies"].array ?? []).enumerated()
    where dependency.object != nil {
      let at = "\(location) (packageDependencies[\(i)])"
      func ruleIssue(_ message: String) { issues.append(.init(location: at, message: message)) }
      if dependency["sourceURL"] != .null
        && dependency["sourceURL"].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        ruleIssue("sourceURL must be a non-empty string")
      }
      let rule = dependency["swiftPM"]
      if !dependency["requirement"].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && rule == .null
      {
        ruleIssue("a version requirement needs a machine-resolvable swiftPM rule")
      }
      if rule == .null { continue }
      object(rule, ruleSchema, at, &issues)
      guard rule.object != nil else { continue }
      let kind = rule["kind"].text
      if rule.object?["kind"] != nil && !ruleKinds.contains(kind) {
        ruleIssue("swiftPM kind must be one of: " + ruleKinds.joined(separator: ", "))
      }
      for key in ["minimumVersion", "maximumVersionExclusive"] {
        if let value = rule[key].string,
          !matches(value, ruleSchema["properties"]["minimumVersion"]["pattern"].text)
        {
          ruleIssue(
            "swiftPM \(key) must match \(ruleSchema["properties"]["minimumVersion"]["pattern"].text)"
          )
        }
      }
      if kind == "range" && rule.object?["maximumVersionExclusive"] == nil {
        ruleIssue("swiftPM range requires maximumVersionExclusive")
      }
      if ruleKinds.contains(kind) && kind != "range"
        && rule.object?["maximumVersionExclusive"] != nil
      {
        ruleIssue(
          "swiftPM \(kind) derives its upper bound; maximumVersionExclusive is only for range")
      }
    }
    if item.object?["platforms"] != nil {
      if let platforms = item["platforms"].array {
        if platforms.count < Int(props["platforms"]["minItems"].number ?? 1) {
          add("platforms must declare at least one platform")
        }
        for (i, platform) in platforms.enumerated() {
          let at = "\(location) (platforms[\(i)])"
          let platformSchema = props["platforms"]["items"]
          object(platform, platformSchema, at, &issues)
          guard platform.object != nil else { continue }
          let names = platformSchema["properties"]["name"]["enum"].strings
          if platform.object?["name"] != nil && !names.contains(platform["name"].text) {
            issues.append(
              .init(location: at, message: "name must be one of: " + names.joined(separator: ", ")))
          }
          if let floor = platform["minimumVersion"].string,
            !matches(floor, "^[0-9]+(\\.[0-9]+){0,2}$")
          {
            issues.append(
              .init(
                location: at,
                message: "minimumVersion must be 1 to 3 dot-separated numbers, got: \(floor)"))
          }
        }
      } else {
        add("platforms must be an array")
      }
    }
    let preview = item["preview"]
    if item.object?["preview"] != nil {
      object(preview, props["preview"], "\(location) (preview)", &issues)
      if preview["screenshots"] != .null {
        stringArray(preview, "screenshots", "\(location) (preview)", unique: true, issues: &issues)
      }
    }
    if kind == "recipe" {
      if item["docs"].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        add("recipe items require non-empty docs")
      }
      if item["files"] != .null && item["files"] != .array([]) {
        add("recipe items must declare empty files")
      }
      if preview.object?["source"] != nil || preview.object?["name"] != nil {
        add("recipe previews carry screenshots only, never a source or name")
      }
    } else if kinds.contains(kind) {
      if item.object?["preview"] == nil {
        add("installable items require a preview")
      } else if preview.object != nil {
        for key in ["source", "name"] where preview[key].text.isEmpty {
          add("installable previews require a non-empty \(key)")
        }
      }
      if item["files"] == .array([]) {
        add("installable items require at least one entry in files")
      }
    }
    func path(_ value: String, root: String, unsafe: String, missing: String) {
      guard let candidate = try? safeJoin(root, value, fs: fs) else {
        add("\(unsafe): \(value)")
        return
      }
      if !fs.isFile(candidate) { add("\(missing): \(value)") }
    }
    for entry in item["files"].array ?? [] {
      if let source = entry["source"].string {
        path(
          source, root: root + "/Registry", unsafe: "unsafe source path",
          missing: "declared source file does not exist")
      }
    }
    if let source = preview["source"].string {
      path(
        source, root: root + "/Registry", unsafe: "unsafe preview source path",
        missing: "preview source file does not exist")
    }
    // The design surface selects items by the tag their root applies, and the
    // tag is foundations API, so an installable item on foundations carries
    // it in its first source; a new item that forgets it is invisible to Select.
    let onFoundations = (item["packageDependencies"].array ?? []).contains {
      $0["product"].text == "SweetUIFoundations"
    }
    if onFoundations, kind == "component" || kind == "block",
      let source = item["files"].array?.first?["source"].string, let name = item["name"].string,
      let candidate = try? safeJoin(root + "/Registry", source, fs: fs), fs.isFile(candidate),
      let text = try? readText(fs, candidate), !text.contains(".registryItem(\"\(name)\")")
    {
      add("installable items on foundations apply .registryItem(\"\(name)\") in their first source")
    }
    for screenshot in preview["screenshots"].strings {
      path(
        screenshot, root: root, unsafe: "unsafe screenshot path",
        missing: "preview screenshot does not exist")
    }
  }

  private func keys(
    _ entry: JSON, _ schema: JSON, _ location: String, _ issues: inout [ValidationIssue]
  ) {
    let present = Set(entry.object?.keys.map { $0 } ?? [])
    let missing = Set(schema["required"].strings).subtracting(present).sorted()
    if !missing.isEmpty {
      issues.append(
        .init(
          location: location, message: "missing required keys: " + missing.joined(separator: ", ")))
    }
    let undeclared = present.subtracting(schema["properties"].object?.keys.map { $0 } ?? [])
      .sorted()
    if !undeclared.isEmpty {
      issues.append(
        .init(location: location, message: "undeclared keys: " + undeclared.joined(separator: ", "))
      )
    }
  }
  private func object(
    _ entry: JSON, _ schema: JSON, _ location: String, _ issues: inout [ValidationIssue]
  ) {
    guard let values = entry.object else {
      issues.append(.init(location: location, message: "entry must be an object"))
      return
    }
    keys(entry, schema, location, &issues)
    for key in values.keys.sorted()
    where schema["properties"][key]["type"] == "string" && values[key]?.string == nil {
      issues.append(.init(location: location, message: "\(key) must be a string"))
    }
  }
  private func stringArray(
    _ item: JSON, _ key: String, _ location: String, unique: Bool, issues: inout [ValidationIssue]
  ) {
    guard item.object?[key] != nil else { return }
    guard let array = item[key].array, array.allSatisfy({ $0.string != nil }) else {
      issues.append(.init(location: location, message: "\(key) must be an array of strings"))
      return
    }
    if unique && Set(item[key].strings).count != array.count {
      issues.append(.init(location: location, message: "\(key) entries must be unique"))
    }
  }
}
