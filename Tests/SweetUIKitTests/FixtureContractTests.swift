import Foundation
import Testing

@Test func fixturesMatchCanonicalContracts() throws {
  let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent()
  for (fixture, canonical) in [
    ("schema.json", "Registry/schema.json"),
    ("preset_vectors.json", "Registry/preset_vectors.json"),
  ] {
    let copy = try #require(
      Bundle.module.url(forResource: fixture, withExtension: nil, subdirectory: "Fixtures"))
    #expect(try Data(contentsOf: copy) == Data(contentsOf: root.appendingPathComponent(canonical)))
  }
}
