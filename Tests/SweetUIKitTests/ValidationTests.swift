import Foundation
import Testing

@testable import SweetUIKit

struct ValidationCase: Decodable, Sendable, CustomTestStringConvertible {
  var testDescription: String { name }
  var name: String
  var items: [String]
  var files: [String: String]
  var issues: [String]
}
let validationCases = try! JSONDecoder().decode(
  [ValidationCase].self,
  from: Data(
    contentsOf: Bundle.module.url(
      forResource: "validation-cases", withExtension: "json", subdirectory: "Fixtures")!))

extension Commands {
  @Test(arguments: validationCases) func pythonValidationCases(_ test: ValidationCase) throws {
    let fs = try fixture()
    try fs.remove("/registry/Registry/items")
    try fs.remove("/registry/Registry/sources")
    for (path, text) in test.files { try fs.put("/registry/" + path, text) }
    try withFixture(fs) {
      let output = try command(["validate"] + test.items)
      #expect(output.code == (test.issues.isEmpty ? 0 : 1), "\(test.name)")
      let expected =
        test.issues.isEmpty
        ? ""
        : "Registry validation failed with \(test.issues.count) issue(s):\n"
          + test.issues.map { "- \($0)\n" }.joined()
      #expect(output.stderr == expected, "\(test.name)")
      let success =
        "Registry validation passed: \(test.items.isEmpty ? "full catalog" : test.items.joined(separator: ", "))\n"
      #expect(output.stdout == (test.issues.isEmpty ? success : ""))
    }
  }

  @Test(arguments: ["../escape", "/absolute", ".", "", "folder/../../escape"])
  func unsafeSources(_ path: String) throws {
    let fs = try fixture()
    var item = example
    item["files"] = [["source": .string(path), "target": "Example.swift"]]
    try fs.put("/registry/Registry/items/example.json", item.rendered())
    try withFixture(fs) {
      let result = try command(["validate"])
      #expect(result.code == 1)
      #expect(result.stderr.contains("unsafe source path: \(path)"))
    }
  }
}
