import Dependencies
import Foundation
import SweetUIKit

/// The checked-out repository, for contract tests over the real registry.
let repositoryRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
  .deletingLastPathComponent().deletingLastPathComponent().path

/// Runs against the real registry through the live filesystem, as an adopter's shell does.
func withRepository<R>(_ body: () throws -> R) rethrows -> R {
  try withDependencies {
    $0.registryFileSystem = .local
    $0.registrySource = RegistrySource { override, _ in override ?? repositoryRoot }
    $0.registrySourceMerger = .git
    $0.date = .constant(fixedNow)
  } operation: {
    try body()
  }
}

/// A fresh temporary destination, resolved the way the tool prints paths, removed afterwards.
func withTemporaryDirectory<R>(_ body: (String) throws -> R) throws -> R {
  let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("sweetui-tests-" + UUID().uuidString)
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: url) }
  return try body(FileSystem.local.resolve(url.path))
}

func repositoryText(_ relative: String) throws -> String {
  try String(contentsOfFile: repositoryRoot + "/" + relative, encoding: .utf8)
}

func repositoryData(_ relative: String) throws -> Data {
  try Data(contentsOf: URL(fileURLWithPath: repositoryRoot + "/" + relative))
}

func fileText(_ path: String) throws -> String {
  try String(contentsOfFile: path, encoding: .utf8)
}

func fileData(_ path: String) throws -> Data {
  try Data(contentsOf: URL(fileURLWithPath: path))
}

func directoryEntries(_ path: String) throws -> [String] {
  try FileManager.default.contentsOfDirectory(atPath: path)
}
