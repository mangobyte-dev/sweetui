import Dependencies
import Foundation

/// Command output is an effect so command tests can capture both streams
/// without redirecting the test runner's own process descriptors.
public struct RegistryConsole: Sendable {
  public var stdout: @Sendable (String) -> Void
  public var stderr: @Sendable (String) -> Void
  public init(
    stdout: @escaping @Sendable (String) -> Void, stderr: @escaping @Sendable (String) -> Void
  ) {
    self.stdout = stdout
    self.stderr = stderr
  }
}
private enum RegistryConsoleKey: DependencyKey {
  static let liveValue = RegistryConsole(
    stdout: { FileHandle.standardOutput.write(Data($0.utf8)) },
    stderr: { FileHandle.standardError.write(Data($0.utf8)) }
  )
}
extension DependencyValues {
  public var registryConsole: RegistryConsole {
    get { self[RegistryConsoleKey.self] }
    set { self[RegistryConsoleKey.self] = newValue }
  }
}
