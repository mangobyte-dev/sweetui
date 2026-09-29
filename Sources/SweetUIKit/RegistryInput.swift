import Dependencies
import Foundation
import Synchronization

public struct RegistryInput: Sendable {
  public var nextLine: @Sendable () throws -> Data?
  public init(nextLine: @escaping @Sendable () throws -> Data?) { self.nextLine = nextLine }
}
private enum RegistryInputKey: DependencyKey {
  static let liveValue: RegistryInput = {
    let pending = Mutex(Data())
    return RegistryInput {
      pending.withLock { buffer in
        while true {
          if let newline = buffer.firstIndex(of: 10) {
            let line = Data(buffer[...newline])
            buffer.removeSubrange(...newline)
            return line
          }
          let chunk = FileHandle.standardInput.availableData
          if chunk.isEmpty {
            guard !buffer.isEmpty else { return nil }
            let line = buffer
            buffer.removeAll()
            return line
          }
          buffer.append(chunk)
        }
      }
    }
  }()
  static let testValue = RegistryInput {
    throw RegistryError("no stdin in tests")
  }
}
extension DependencyValues {
  public var registryInput: RegistryInput {
    get { self[RegistryInputKey.self] }
    set { self[RegistryInputKey.self] = newValue }
  }
}
