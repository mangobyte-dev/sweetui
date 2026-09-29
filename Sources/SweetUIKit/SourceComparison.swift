import Dependencies
import Foundation

public struct MergeResult: Sendable {
  public var content: Data
  public var hasConflict: Bool
  public init(content: Data, hasConflict: Bool) {
    self.content = content
    self.hasConflict = hasConflict
  }
}
public struct SourceMerger: Sendable {
  public var merge: @Sendable (Data, Data, Data, String) throws -> MergeResult
  public init(merge: @escaping @Sendable (Data, Data, Data, String) throws -> MergeResult) {
    self.merge = merge
  }
}
extension SourceMerger {
  public static let git = SourceMerger { current, base, incoming, target in
    @Dependency(\.uuid) var uuid
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(uuid().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    for (name, data) in [("current", current), ("base", base), ("incoming", incoming)] {
      try data.write(to: directory.appendingPathComponent(name))
    }
    // File-backed streams avoid pipe capacity deadlocks on large merge results.
    let output = directory.appendingPathComponent("stdout")
    let errors = directory.appendingPathComponent("stderr")
    FileManager.default.createFile(atPath: output.path, contents: nil)
    FileManager.default.createFile(atPath: errors.path, contents: nil)
    let out = try FileHandle(forWritingTo: output)
    let err = try FileHandle(forWritingTo: errors)
    defer {
      try? out.close()
      try? err.close()
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments =
      ["git", "merge-file", "-p", "-L", target, "-L", "registry base", "-L", "registry incoming"]
      + ["current", "base", "incoming"].map { directory.appendingPathComponent($0).path }
    process.standardOutput = out
    process.standardError = err
    try process.run()
    process.waitUntilExit()
    if process.terminationStatus == 127 {
      throw RegistryError("git is required to merge concurrent source changes")
    }
    guard [0, 1].contains(process.terminationStatus) else {
      throw RegistryError(
        "git merge-file failed for \(target): "
          + String(decoding: try Data(contentsOf: errors), as: UTF8.self).trimmingCharacters(
            in: .whitespacesAndNewlines))
    }
    return MergeResult(
      content: try Data(contentsOf: output), hasConflict: process.terminationStatus == 1)
  }
}
private enum SourceMergerKey: DependencyKey {
  static let liveValue = SourceMerger.git
  static let testValue = SourceMerger { _, _, _, target in
    throw RegistryError("no source merge in tests: \(target)")
  }
}
extension DependencyValues {
  public var registrySourceMerger: SourceMerger {
    get { self[SourceMergerKey.self] }
    set { self[SourceMergerKey.self] = newValue }
  }
}

/// SequenceMatcher's longest contiguous match and autojunk rule, followed by
/// unified_diff's three-line grouping. Git diff uses a different algorithm.
public func unifiedDiff(_ owned: Data, _ incoming: Data, from: String, to: String) -> String {
  func lines(_ data: Data) -> [String] {
    let scalars = Array(String(decoding: data, as: UTF8.self).unicodeScalars)
    let boundaries: Set<UInt32> = [10, 11, 12, 13, 28, 29, 30, 133, 8232, 8233]
    var result: [String] = []
    var start = 0
    var index = 0
    while index < scalars.count {
      let scalar = scalars[index].value
      index += 1
      if boundaries.contains(scalar) {
        if scalar == 13 && index < scalars.count && scalars[index].value == 10 { index += 1 }
        result.append(String(String.UnicodeScalarView(scalars[start..<index])))
        start = index
      }
    }
    if start < scalars.count { result.append(String(String.UnicodeScalarView(scalars[start...]))) }
    return result
  }
  let a = lines(owned)
  let b = lines(incoming)
  var positions: [String: [Int]] = [:]
  for (i, line) in b.enumerated() { positions[line, default: []].append(i) }
  if b.count >= 200 { positions = positions.filter { $0.value.count <= b.count / 100 + 1 } }
  var pending = [(0, a.count, 0, b.count)]
  var blocks: [(Int, Int, Int)] = []
  while let (alo, ahi, blo, bhi) = pending.popLast() {
    var bestI = alo
    var bestJ = blo
    var size = 0
    var previous: [Int: Int] = [:]
    for i in alo..<ahi {
      var current: [Int: Int] = [:]
      for j in positions[a[i]] ?? [] where j >= blo && j < bhi {
        let length = (previous[j - 1] ?? 0) + 1
        current[j] = length
        if length > size {
          bestI = i - length + 1
          bestJ = j - length + 1
          size = length
        }
      }
      previous = current
    }
    while bestI > alo && bestJ > blo && a[bestI - 1] == b[bestJ - 1] {
      bestI -= 1
      bestJ -= 1
      size += 1
    }
    while bestI + size < ahi && bestJ + size < bhi && a[bestI + size] == b[bestJ + size] {
      size += 1
    }
    if size > 0 {
      blocks.append((bestI, bestJ, size))
      if alo < bestI && blo < bestJ { pending.append((alo, bestI, blo, bestJ)) }
      if bestI + size < ahi && bestJ + size < bhi {
        pending.append((bestI + size, ahi, bestJ + size, bhi))
      }
    }
  }
  blocks.sort { $0.0 == $1.0 ? $0.1 < $1.1 : $0.0 < $1.0 }
  var collapsed: [(Int, Int, Int)] = []
  for block in blocks {
    if let last = collapsed.last, last.0 + last.2 == block.0 && last.1 + last.2 == block.1 {
      collapsed[collapsed.count - 1].2 += block.2
    } else {
      collapsed.append(block)
    }
  }
  collapsed.append((a.count, b.count, 0))
  typealias Op = (tag: String, a0: Int, a1: Int, b0: Int, b1: Int)
  var ops: [Op] = []
  var i = 0
  var j = 0
  for (ai, bj, size) in collapsed {
    if i < ai || j < bj {
      ops.append((i < ai ? (j < bj ? "replace" : "delete") : "insert", i, ai, j, bj))
    }
    if size > 0 { ops.append(("equal", ai, ai + size, bj, bj + size)) }
    i = ai + size
    j = bj + size
  }
  guard !ops.isEmpty else { return "" }
  if ops[0].tag == "equal" {
    ops[0].a0 = max(ops[0].a0, ops[0].a1 - 3)
    ops[0].b0 = max(ops[0].b0, ops[0].b1 - 3)
  }
  let last = ops.count - 1
  if ops[last].tag == "equal" {
    ops[last].a1 = min(ops[last].a1, ops[last].a0 + 3)
    ops[last].b1 = min(ops[last].b1, ops[last].b0 + 3)
  }
  var groups: [[Op]] = []
  var group: [Op] = []
  for var op in ops {
    if op.tag == "equal" && op.a1 - op.a0 > 6 {
      group.append(("equal", op.a0, op.a0 + 3, op.b0, op.b0 + 3))
      groups.append(group)
      group = []
      op.a0 = op.a1 - 3
      op.b0 = op.b1 - 3
    }
    group.append(op)
  }
  if !(group.count == 1 && group[0].tag == "equal") && !group.isEmpty { groups.append(group) }
  guard !groups.isEmpty else { return "" }
  func range(_ start: Int, _ end: Int) -> String {
    let count = end - start
    return count == 1 ? "\(start + 1)" : "\(count == 0 ? start : start + 1),\(count)"
  }
  var output = "--- \(from)\n+++ \(to)\n"
  for group in groups {
    output +=
      "@@ -\(range(group[0].a0, group.last!.a1)) +\(range(group[0].b0, group.last!.b1)) @@\n"
    for op in group {
      if op.tag == "equal" {
        for line in a[op.a0..<op.a1] { output += " " + line }
      } else {
        if op.tag != "insert" { for line in a[op.a0..<op.a1] { output += "-" + line } }
        if op.tag != "delete" { for line in b[op.b0..<op.b1] { output += "+" + line } }
      }
    }
  }
  return output
}
