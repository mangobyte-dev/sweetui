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

  /// The path of the notes file: `file` as given, or the simulator app
  /// container of `bundleId` on `udid`.
  public static func locate(file: String?, udid: String?, bundleId: String?) throws -> String {
    try AppContainer.locate(fileName, file: file, udid: udid, bundleId: bundleId)
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

/// Where the design surface keeps its files on a simulator: the app's data
/// container, found through `xcrun simctl get_app_container`.
public enum AppContainer {
  /// `file` as given, or `Documents/<fileName>` in the container of
  /// `bundleId` on `udid`.
  public static func locate(_ fileName: String, file: String?, udid: String?, bundleId: String?)
    throws -> String
  {
    @Dependency(\.registryFileSystem) var fs
    if let file { return fs.resolve(fs.expandUser(file)) }
    guard let udid, let bundleId else {
      throw RegistryError("give file, or both udid and bundleId")
    }
    return try documents(udid: udid, bundleId: bundleId) + "/" + fileName
  }

  /// The container's Documents directory.
  public static func documents(udid: String, bundleId: String) throws -> String {
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
    return container + "/Documents"
  }
}

/// The screen the person is looking at, as the Tune panel writes it to
/// `design-context.json`: the named screen, every registry item with its
/// frame, tokens, and knobs, the selection, the preset code, the environment
/// switches, and the last screenshot. The screenshots sit under `notes/`.
public enum DesignContext {
  public static let fileName = "design-context.json"

  /// The context, with every screenshot under `notes/` as an absolute path.
  public static func read(file: String) throws -> JSON {
    @Dependency(\.registryFileSystem) var fs
    guard fs.isFile(file) else { throw RegistryError("no \(fileName) at \(file)") }
    var context = try JSON.read(fs.read(file))
    guard context.object != nil else { throw RegistryError("\(file) is not a context object") }
    let notes = (file as NSString).deletingLastPathComponent + "/notes"
    let screenshots =
      fs.isDirectory(notes)
      ? try fs.children(notes).filter { $0.hasSuffix(".png") }.sorted()
      : []
    context["screenshots"] = .array(screenshots.map(JSON.string))
    if let last = context["screenshot"].string {
      context["screenshotPath"] = .string((file as NSString).deletingLastPathComponent + "/" + last)
    }
    return context
  }
}
