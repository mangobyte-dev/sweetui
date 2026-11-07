import Dependencies
import Foundation

/// The notes a person leaves in the design surface's Tune panel, read back
/// from the app's `design-notes.json` (`DesignNote` in `SweetUIDesignSurface`
/// writes it): each carries the item, its chain, the tokens it reads, its
/// knobs, its frame, the preset code that was up, and `resolved`. The file
/// is the hand-off from the screen to an agent that cannot see it; the agent
/// marks a note resolved when the work is done and the panel drops it.
public enum DesignNotes {
  public static let fileName = "design-notes.json"

  /// The path of the file: `file` as given, or the simulator app container
  /// of `bundleId` on `udid` through `xcrun simctl get_app_container`.
  public static func locate(file: String?, udid: String?, bundleId: String?) throws -> String {
    @Dependency(\.registryFileSystem) var fs
    if let file { return fs.resolve(fs.expandUser(file)) }
    guard let udid, let bundleId else {
      throw RegistryError("give file, or both udid and bundleId")
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["simctl", "get_app_container", udid, bundleId, "data"]
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let container = String(decoding: data, as: UTF8.self).trimmingCharacters(
      in: .whitespacesAndNewlines)
    guard process.terminationStatus == 0, !container.isEmpty else {
      throw RegistryError("no app container for \(bundleId) on \(udid); is the app installed?")
    }
    return container + "/Documents/" + fileName
  }

  /// Every note in the file, oldest first; open ones only unless asked.
  public static func list(file: String, includeResolved: Bool) throws -> [JSON] {
    let notes = try read(file)
    return includeResolved ? notes : notes.filter { $0["resolved"] != true }
  }

  /// Marks the note resolved and writes the file back; the other notes keep
  /// their bytes' meaning (the keys are re-rendered in the file's own
  /// sorted order). Returns the note as written.
  public static func resolve(id: String, file: String) throws -> JSON {
    @Dependency(\.registryFileSystem) var fs
    var notes = try read(file)
    guard let index = notes.firstIndex(where: { $0["id"].string?.lowercased() == id.lowercased() })
    else {
      throw RegistryError("no note \(id) in \(file)")
    }
    guard var note = notes[index].object else { throw RegistryError("note \(id) is not an object") }
    note["resolved"] = true
    notes[index] = .object(note)
    try fs.write(Data(JSON.array(notes).rendered().utf8), file)
    return notes[index]
  }

  private static func read(_ file: String) throws -> [JSON] {
    @Dependency(\.registryFileSystem) var fs
    guard fs.isFile(file) else { throw RegistryError("no \(fileName) at \(file)") }
    guard let notes = try JSON.read(fs.read(file)).array else {
      throw RegistryError("\(file) is not an array of notes")
    }
    return notes
  }
}
