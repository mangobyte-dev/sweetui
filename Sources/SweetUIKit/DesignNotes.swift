import Dependencies
import Foundation

/// The notes a person leaves in Tune, read back from the app's
/// `design-notes.json` (`DesignNote` in `SweetUIDesignSurface` writes it):
/// each carries its subject (the item and its chain, or the screen), the
/// tokens the item reads, its knobs, its frame, the design's code, its
/// screenshot, and `inReplyTo` when it follows a note or a proposal. The
/// agent's side, answers and read dates, lives in `design-agent.json`.
public enum DesignNotes {
  public static let fileName = "design-notes.json"

  /// The path of the notes file: `file` as given, or the simulator app
  /// container of `bundleId` on `udid`.
  public static func locate(file: String?, udid: String?, bundleId: String?) throws -> String {
    try AppContainer.locate(fileName, file: file, udid: udid, bundleId: bundleId)
  }

  /// The notes oldest first, unanswered ones only unless asked, each with
  /// its answer and the date this listing read it, and every proposal with
  /// the state the person's decisions in `design-history.json` give it.
  /// Stamps a read date in `design-agent.json` per note returned.
  public static func list(file: String, includeAnswered: Bool) throws -> (
    notes: [JSON], proposals: [JSON]
  ) {
    @Dependency(\.date.now) var now
    let agentFile = DesignAgentFile.beside(file, DesignAgentFile.fileName)
    let record = try DesignAgentFile.read(agentFile)
    let answers = record["answers"]?.object ?? [:]
    var listed: [JSON] = []
    for var note in try notes(file) {
      let id = note["id"].text
      if let answer = answers[id] { note["answer"] = answer }
      guard includeAnswered || answers[id] == nil else { continue }
      note["readAt"] = .string(ISO8601DateFormatter().string(from: now))
      listed.append(note)
    }
    try DesignAgentFile.stampRead(listed.map { $0["id"].text }, as: "notes", in: agentFile)
    let decided = try DesignDecisions(beside: file)
    let proposals = (record["proposals"]?.array ?? []).map { proposal in
      var joined = proposal
      let id = proposal["id"].text
      joined["state"] = .string(decided.state(id))
      if let date = decided.dates[id] { joined["decidedAt"] = .string(date) }
      return joined
    }
    return (listed, proposals)
  }

  /// Writes the agent's answer to a note into `design-agent.json`: the
  /// reply the person reads under it and the files changed for it. Refuses
  /// an id the notes file does not hold, writing nothing.
  public static func answer(id: String, reply: String, changedFiles: [String], file: String) throws
    -> JSON
  {
    guard let canonical = Self.id(id, in: try notes(file)) else {
      throw RegistryError("no note \(id) in \(file)")
    }
    let answer = try DesignAgentFile.writeAnswer(
      id: canonical, reply: reply, changedFiles: changedFiles,
      in: DesignAgentFile.beside(file, DesignAgentFile.fileName))
    return ["id": .string(canonical), "answer": answer]
  }

  /// The notes in `file`; a 0-byte file, which Sharing creates before the
  /// first note, holds none.
  static func notes(_ file: String) throws -> [JSON] {
    @Dependency(\.registryFileSystem) var fs
    guard fs.isFile(file) else { throw RegistryError("no \(fileName) at \(file)") }
    let data = try fs.read(file)
    if data.isEmpty { return [] }
    guard let notes = try JSON.read(data).array else {
      throw RegistryError("\(file) is not an array of notes")
    }
    return notes
  }

  /// A note's id as the file spells it, matched without regard to case.
  static func id(_ id: String, in notes: [JSON]) -> String? {
    notes.lazy.map { $0["id"].text }.first { $0.lowercased() == id.lowercased() }
  }
}

/// What the person decided about each proposal, from `design-history.json`
/// beside the notes: the open trial and a decision (tried, kept, discarded)
/// per proposal id. A missing or 0-byte file has decided nothing.
struct DesignDecisions {
  static let fileName = "design-history.json"
  var trying: String?
  var states: [String: String] = [:]
  var dates: [String: String] = [:]

  init(beside file: String) throws {
    @Dependency(\.registryFileSystem) var fs
    let path = DesignAgentFile.beside(file, Self.fileName)
    guard fs.isFile(path) else { return }
    let data = try fs.read(path)
    guard !data.isEmpty else { return }
    let history = try JSON.read(data)
    trying = history["trial"]["proposal"].string
    for (id, decision) in history["decisions"].object ?? [:] {
      states[id] = decision["state"].string
      dates[id] = decision["date"].string
    }
  }

  /// Offered, trying, kept, or discarded, as Tune shows it: the trial is
  /// trying, a proposal another one replaced on trial is offered again.
  func state(_ id: String) -> String {
    if trying == id { return "trying" }
    switch states[id] {
    case "kept": return "kept"
    case "discarded": return "discarded"
    default: return "offered"
    }
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

/// The screen the person is looking at, as Tune writes it to
/// `design-context.json`: the named screen, every registry item with its
/// frame, tokens, and knobs, the selection, the design's code, the proposal
/// trying, whether the host tunes the theme, Preview's overrides, and the
/// last screenshot. The screenshots sit under `notes/`.
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

/// The hand-off the person sends from Tune's Versions, `design-handoff.json`
/// beside the tokens: its id, the design's code (empty under Source) and its
/// Swift, the moved knobs, the changes from Default, the open notes with
/// their screenshots, and the previous hand-off, which still takes an answer.
public enum DesignHandoffs {
  public static let fileName = "design-handoff.json"

  /// The hand-off, with every screenshot path made absolute; stamps its
  /// read date in `design-agent.json`.
  public static func read(file: String) throws -> JSON {
    @Dependency(\.registryFileSystem) var fs
    var handoff = try load(file)
    let documents = (file as NSString).deletingLastPathComponent
    if let shot = handoff["screenshot"].string {
      handoff["screenshotPath"] = .string(documents + "/" + shot)
    }
    if var notes = handoff["openNotes"].array {
      for index in notes.indices {
        if let shot = notes[index]["screenshot"].string {
          notes[index]["screenshotPath"] = .string(documents + "/" + shot)
        }
      }
      handoff["openNotes"] = .array(notes)
    }
    if let id = handoff["id"].string {
      try DesignAgentFile.stampRead(
        [id], as: "handoffs", in: DesignAgentFile.beside(file, DesignAgentFile.fileName))
    }
    return handoff
  }

  /// Writes the agent's answer to the current or the previous hand-off.
  /// Returns the answer, and the newer hand-off when the previous one was
  /// answered; refuses any other id, writing nothing.
  public static func answer(id: String, reply: String, changedFiles: [String], file: String) throws
    -> (id: String, answer: JSON, newer: JSON?)
  {
    let handoff = try load(file)
    let current = handoff["id"].text
    let previous = handoff["previous"]["id"].text
    let canonical: String
    var newer: JSON?
    if !current.isEmpty, current.lowercased() == id.lowercased() {
      canonical = current
    } else if !previous.isEmpty, previous.lowercased() == id.lowercased() {
      canonical = previous
      newer = ["id": .string(current), "sentAt": handoff["sentAt"]]
    } else {
      throw RegistryError(
        "no hand-off \(id) takes an answer; the current one is \(current.isEmpty ? "none" : current)"
          + (previous.isEmpty ? "" : " and the previous one \(previous)"))
    }
    let answer = try DesignAgentFile.writeAnswer(
      id: canonical, reply: reply, changedFiles: changedFiles,
      in: DesignAgentFile.beside(file, DesignAgentFile.fileName))
    return (canonical, answer, newer)
  }

  private static func load(_ file: String) throws -> JSON {
    @Dependency(\.registryFileSystem) var fs
    guard fs.isFile(file) else { throw RegistryError("no \(fileName) at \(file)") }
    let handoff = try JSON.read(fs.read(file))
    guard handoff.object != nil else { throw RegistryError("\(file) is not a hand-off object") }
    return handoff
  }
}
