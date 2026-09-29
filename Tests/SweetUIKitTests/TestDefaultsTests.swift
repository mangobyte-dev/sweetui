import Dependencies
import Foundation
import Testing

@testable import SweetUIKit

extension Commands {
  /// A test that forgets `withFixture` must fail at the boundary. The live file system would
  /// read this file and create that one; the test default may do neither.
  @Test func unoverriddenFileSystemFailsInsteadOfReachingTheDisk() throws {
    @Dependency(\.registryFileSystem) var fs
    let scratch = FileManager.default.temporaryDirectory
      .appendingPathComponent("sweetui-unimplemented-" + UUID().uuidString).path
    #expect(throws: RegistryError.self) { try fs.read("/etc/hosts") }
    #expect(throws: RegistryError.self) { try fs.write(Data("x".utf8), to: scratch) }
    #expect(!FileManager.default.fileExists(atPath: scratch))
    withKnownIssue("a query cannot throw, so it reports an issue and answers as an empty disk") {
      #expect(!fs.exists("/etc/hosts"))
    }
  }

  /// The live source walks the disk and then fetches the release snapshot; a test that forgets
  /// to pin one must stop before either.
  @Test func unoverriddenRegistrySourceThrows() {
    @Dependency(\.registrySource) var source
    #expect(throws: RegistryError.self) { try source.repositoryRoot(override: nil) }
  }
}
