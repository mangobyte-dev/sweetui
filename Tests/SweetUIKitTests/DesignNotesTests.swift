import Foundation
import Testing

@testable import SweetUIKit

/// The agent's half of Tune's loop. Each file has one writer: the panel
/// writes the notes, the values, the history, the context, and the hand-off;
/// the agent writes only `design-agent.json`. So no tool may touch a panel
/// file, a refusal must write nothing, and every read the person relies on
/// (Read, Answered, Shipped, a proposal's state) must come from what the tools
/// wrote or what the panel decided.
struct DesignNotesTests {
  /// Two notes as `DesignNote`'s encoder writes them: sorted keys, ISO dates,
  /// a screen note without `item` or `frame`, and a reply that follows it.
  static let notes = #"""
    [
      {
        "chain" : [],
        "createdAt" : "2026-11-07T00:11:49Z",
        "id" : "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1",
        "knobs" : {},
        "presetCode" : "",
        "screen" : "Components",
        "text" : "Lift the card off the background",
        "tokens" : []
      },
      {
        "chain" : ["button", "card"],
        "createdAt" : "2026-11-07T00:12:30Z",
        "frame" : { "height" : 36, "width" : 120, "x" : 16, "y" : 200 },
        "id" : "6F3C1B2A-0000-4000-8000-000000000002",
        "inReplyTo" : "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1",
        "item" : "button",
        "knobs" : { "height" : 40 },
        "presetCode" : "a13GkaOXWwIF",
        "screen" : "button",
        "text" : "Taller",
        "tokens" : ["accent", "onAccent"]
      }
    ]
    """#
  static let tokens = #"{"code":"a13GkaOXWwIF","environment":{"appearance":"dark"}}"#
  static let knobs = #"{"button":{"height":40}}"#

  /// The app's Documents folder as Tune leaves it: the notes, the values,
  /// and the 0-byte agent file Sharing creates before the agent writes it.
  private func withDocuments<R>(
    agent: String = "", context: String? = nil, _ body: (InMemoryFileSystem) throws -> R
  ) throws -> R {
    let fs = try fixture()
    try fs.put("/app/design-notes.json", Self.notes)
    try fs.put("/app/registry-tokens.json", Self.tokens)
    try fs.put("/app/design-knobs.json", Self.knobs)
    try fs.put("/app/design-agent.json", agent)
    if let context { try fs.put("/app/design-context.json", context) }
    return try withFixture(fs) { try body(fs) }
  }

  private func call(_ name: String, _ arguments: JSON) throws -> JSON {
    let request: JSON = [
      "jsonrpc": "2.0", "id": 1, "method": "tools/call",
      "params": ["name": .string(name), "arguments": arguments],
    ]
    let server = MCPServer(root: "/registry")
    let response = try #require(try server.response(to: Data(request.rendered().utf8)))
    return try JSON.read(Data(response.utf8))["result"]
  }

  private func record(_ fs: InMemoryFileSystem) throws -> JSON {
    try JSON.read(fs.read("/app/design-agent.json"))
  }

  // MARK: propose_design

  /// A proposal is an offer, not a change: the person's values stay as they
  /// were until Tune tries it, so Discard can always put the base back.
  @Test func proposingLeavesThePanelsFilesByteIdentical() throws {
    try withDocuments { fs in
      let before = try ["registry-tokens.json", "design-knobs.json", "design-notes.json"].map {
        try fs.read("/app/" + $0)
      }
      let result = try call(
        "propose_design",
        [
          "name": "Warm", "reason": "The indigo reads cold on a food app.",
          "note": "cebef0aa-20fe-420e-b251-b3a7fcff3fc1", "tokens": ["accent": "orange"],
          "knobs": ["button": ["height": 44]], "file": "/app/design-agent.json",
        ])
      #expect(result["isError"] == false)
      let after = try ["registry-tokens.json", "design-knobs.json", "design-notes.json"].map {
        try fs.read("/app/" + $0)
      }
      #expect(after == before, "propose_design wrote a file the panel owns.")
      let proposal = try #require(try record(fs)["proposals"].array?.first)
      #expect(proposal["name"] == "Warm")
      #expect(proposal["tokens"] == ["accent": "orange"], "A delta stays a delta.")
      #expect(
        proposal["note"] == "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1", "The note's own spelling.")
      #expect(proposal["apply"] == true, "Trying at once is the default.")
      #expect(proposal["date"] == "2027-01-15T08:00:00Z")
    }
  }

  /// Sharing creates the file it watches with 0 bytes, so the agent's first
  /// write meets an empty file, not a missing one, and must not fail on it.
  @Test func theFirstProposalLandsInTheUnseeded0ByteFile() throws {
    try withDocuments(agent: "") { fs in
      #expect(try fs.read("/app/design-agent.json").isEmpty)
      let proposal = try DesignProposals.propose(
        .init(name: "Mango", code: "--preset a74hGF01CVunaG0vzZJG", apply: false),
        file: "/app/design-agent.json")
      #expect(proposal["code"] == "a74hGF01CVunaG0vzZJG")
      let written = try record(fs)
      #expect(written["proposals"].array?.count == 1)
      #expect(written["answers"] == [:])
      #expect(written["read"] == ["handoffs": [:], "notes": [:]])
      #expect(!fs.exists("/app/design-agent.json.writing"), "The temporary file is replaced away.")
    }
  }

  /// A refusal must leave nothing behind: a half-valid proposal on the
  /// device would put a design there that no code describes.
  @Test func refusesABadCodeAndAKeyOutsideTheDecodeKeysAndWritesNothing() throws {
    try withDocuments { fs in
      for arguments: JSON in [
        ["name": "Bad", "code": "not a code"],
        ["name": "Bad", "code": "a"],
        ["name": "Bad", "tokens": ["cornerRadius": 20]],
        ["name": "Bad", "tokens": ["accent": "plaid"]],
        ["name": "Bad", "tokens": ["cardRadius": "big"]],
        ["name": "Bad", "tokens": ["background": "white"]],
        ["name": "Bad", "code": "a13GkaOXWwIF", "tokens": ["accent": "teal"]],
        ["name": "Bad", "knobs": ["button": ["height": "tall"]]],
        ["name": "Bad"],
        ["name": " ", "tokens": ["accent": "teal"]],
        ["name": "Bad", "tokens": ["accent": "teal"], "note": "no-such-note"],
      ] {
        var withFile = arguments
        withFile["file"] = "/app/design-agent.json"
        let result = try call("propose_design", withFile)
        #expect(result["isError"] == true, "Accepted \(arguments)")
        #expect(try fs.read("/app/design-agent.json").isEmpty, "Refused \(arguments) but wrote.")
      }
      let unknown = try call(
        "propose_design",
        ["name": "Bad", "tokens": ["cornerRadius": 20], "file": "/app/design-agent.json"])
      #expect(unknown["content"].array?.first?["text"].text.contains("cardRadius") == true)
    }
  }

  /// A host that paints the items from its own tokens never shows a theme,
  /// so a theme proposal could only mislead; its knobs still apply.
  @Test func refusesCodeAndTokensWhenTheHostDoesNotTuneTheTheme() throws {
    try withDocuments(context: #"{"tunesTheme":false,"items":[]}"#) { fs in
      for theme: JSON in [["code": "a13GkaOXWwIF"], ["tokens": ["accent": "teal"]]] {
        var arguments = theme
        arguments["name"] = "Teal"
        arguments["file"] = "/app/design-agent.json"
        let result = try call("propose_design", arguments)
        #expect(result["isError"] == true)
        #expect(result["content"].array?.first?["text"].text.contains("tunesTheme") == true)
      }
      #expect(try fs.read("/app/design-agent.json").isEmpty)
      let knobs = try call(
        "propose_design",
        ["name": "Taller", "knobs": ["button": ["height": 44]], "file": "/app/design-agent.json"])
      #expect(knobs["isError"] == false, "Knobs reach every host.")
    }
  }

  /// `null` is how the agent returns a knob to its default, so it must
  /// survive validation and reach the file as null, never as 0.
  @Test func aNullKnobMeansTheDefault() throws {
    try withDocuments { fs in
      _ = try DesignProposals.propose(
        .init(name: "Reset height", knobs: ["button": ["height": .null, "radius": 12]]),
        file: "/app/design-agent.json")
      let knobs = try record(fs)["proposals"].array?.first?["knobs"]
      #expect(knobs?["button"].object?["height"] == .null)
      #expect(knobs?["button"]["radius"] == 12)
      #expect(
        String(decoding: try fs.read("/app/design-agent.json"), as: UTF8.self).contains(
          #""height": null"#))
    }
  }

  // MARK: answer_design_note

  /// An answer to a note the person never wrote would sit under nothing;
  /// the agent must learn the id is wrong, and the file must not change.
  @Test func answeringRefusesAnUnknownIdAndLeavesTheFileByteIdentical() throws {
    let seeded = #"{"answers":{},"proposals":[],"read":{"handoffs":{},"notes":{}}}"#
    try withDocuments(agent: seeded) { fs in
      let before = try fs.read("/app/design-agent.json")
      let refused = try call(
        "answer_design_note",
        ["id": "nope", "reply": "Done.", "file": "/app/design-notes.json"])
      #expect(refused["isError"] == true)
      #expect(try fs.read("/app/design-agent.json") == before)

      let answered = try call(
        "answer_design_note",
        [
          "id": "6f3c1b2a-0000-4000-8000-000000000002", "reply": "Raised the height to 44.",
          "changedFiles": ["Sources/App/Button.swift"], "file": "/app/design-notes.json",
        ])
      #expect(answered["isError"] == false)
      let answer = try record(fs)["answers"]["6F3C1B2A-0000-4000-8000-000000000002"]
      #expect(answer["reply"] == "Raised the height to 44.")
      #expect(answer["changedFiles"].strings == ["Sources/App/Button.swift"])
      #expect(
        try fs.read("/app/design-notes.json") == Data(Self.notes.utf8), "The notes are the panel's."
      )
      let badFiles = try call(
        "answer_design_note",
        [
          "id": "6F3C1B2A-0000-4000-8000-000000000002", "reply": "x", "changedFiles": "a.swift",
          "file": "/app/design-notes.json",
        ])
      #expect(badFiles["isError"] == true)
    }
  }

  // MARK: list_design_notes

  /// The person sees Read per note, so a listing stamps exactly the notes
  /// it returned; and the agent learns the person's decisions only by this
  /// join, so every proposal carries the state the history gives it.
  @Test func listingJoinsAnswersProposalsAndDecisionsAndStampsPerId() throws {
    let agent = #"""
      {
        "answers" : { "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1" : { "changedFiles" : [], "date" : "2026-11-07T00:20:00Z", "reply" : "Raised the card." } },
        "proposals" : [
          { "apply" : true, "date" : "2026-11-07T00:21:00Z", "id" : "P1", "name" : "Warm", "note" : "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1", "tokens" : { "accent" : "orange" } },
          { "apply" : true, "date" : "2026-11-07T00:22:00Z", "id" : "P2", "name" : "Cool", "tokens" : { "accent" : "teal" } },
          { "apply" : false, "date" : "2026-11-07T00:23:00Z", "id" : "P3", "name" : "Mango", "code" : "a74hGF01CVunaG0vzZJG" },
          { "apply" : false, "date" : "2026-11-07T00:24:00Z", "id" : "P4", "name" : "Plain", "tokens" : { "accent" : "ink" } }
        ],
        "read" : { "handoffs" : {}, "notes" : {} }
      }
      """#
    let history = #"""
      {
        "decisions" : {
          "P1" : { "date" : "2026-11-07T00:30:00Z", "state" : "kept" },
          "P2" : { "date" : "2026-11-07T00:31:00Z", "state" : "tried" },
          "P3" : { "date" : "2026-11-07T00:32:00Z", "state" : "discarded" }
        },
        "entries" : [],
        "trial" : { "base" : "6F1C2A10-0000-4000-8000-000000000001", "proposal" : "P2", "version" : "6F1C2A10-0000-4000-8000-000000000002" }
      }
      """#
    try withDocuments(agent: agent) { fs in
      try fs.put("/app/design-history.json", history)
      let open = try call("list_design_notes", ["file": "/app/design-notes.json"])
      #expect(open["isError"] == false)
      let content = open["structuredContent"]
      #expect(
        content["notes"].array?.map { $0["text"].text } == ["Taller"],
        "The answered note waits for includeAnswered.")
      #expect(content["notes"].array?.first?["inReplyTo"] == "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1")
      #expect(
        content["proposals"].array?.map { "\($0["id"].text) \($0["state"].text)" } == [
          "P1 kept", "P2 trying", "P3 discarded", "P4 offered",
        ])
      #expect(content["proposals"].array?.first?["decidedAt"] == "2026-11-07T00:30:00Z")
      #expect(
        try record(fs)["read"]["notes"] == [
          "6F3C1B2A-0000-4000-8000-000000000002": "2027-01-15T08:00:00Z"
        ],
        "Only the returned note reads Read.")

      let all = try call(
        "list_design_notes", ["file": "/app/design-notes.json", "includeAnswered": true])
      let first = try #require(all["structuredContent"]["notes"].array?.first)
      #expect(first["answer"]["reply"] == "Raised the card.")
      #expect(first["readAt"] == "2027-01-15T08:00:00Z")
      #expect(try record(fs)["read"]["notes"].object?.count == 2)
      #expect(
        try fs.read("/app/design-history.json") == Data(history.utf8), "The history is the panel's."
      )

      let typed = try call(
        "list_design_notes", ["file": "/app/design-notes.json", "includeAnswered": "yes"])
      #expect(typed["isError"] == true)
      let none = try call("list_design_notes", [:])
      #expect(none["isError"] == true, "Neither a file nor a device is a tool error, not a crash.")
    }
  }

  /// Sharing creates the notes file with 0 bytes before the first note:
  /// that is no notes, and listing them stamps nothing.
  @Test func a0ByteNotesFileListsNothingAndStampsNothing() throws {
    try withDocuments { fs in
      try fs.put("/app/design-notes.json", "")
      let listed = try DesignNotes.list(file: "/app/design-notes.json", includeAnswered: true)
      #expect(listed.notes.isEmpty && listed.proposals.isEmpty)
      #expect(try fs.read("/app/design-agent.json").isEmpty)
    }
  }

  // MARK: The captured files

  /// `design-agent.json` and `design-history.json` as the real MCP server
  /// and Tune wrote them on the iPhone Duo; the Showcase suite decodes the
  /// same bytes. The agent learns the person's decisions only by this join,
  /// so the kit must read Tune's history as Tune writes it.
  @Test func theCapturedFilesJoinIntoTheDecisionsTheDeviceShowed() throws {
    func fixture(_ name: String) throws -> String {
      try String(
        contentsOf: #require(
          Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures")),
        encoding: .utf8)
    }
    let agent = try fixture("design-agent.json")
    try withDocuments(agent: agent) { fs in
      try fs.put("/app/design-history.json", fixture("design-history.json"))
      let record = try DesignAgentFile.read("/app/design-agent.json")
      #expect(record["proposals"]?.array?.count == 2)
      #expect(record["read"]?["handoffs"].object?.count == 1)
      let listed = try DesignNotes.list(file: "/app/design-notes.json", includeAnswered: true)
      #expect(
        listed.proposals.map { "\($0["name"].text) \($0["state"].text)" } == [
          "Warm kept", "Mango discarded",
        ])
      #expect(listed.proposals.last?["knobs"]["card"].object?["elevation"] == .null)
      #expect(
        listed.notes.first?["answer"]["changedFiles"].strings == [
          "Sources/App/RegistryTheme+App.swift"
        ])
    }
  }

  // MARK: Hand-offs

  /// The person hands off, then hands off again before the agent answers:
  /// the agent may still be working from the first, so the previous one
  /// takes its answer and the agent learns a newer one waits; anything older
  /// is gone from the device and must be refused.
  @Test func answeringAHandOffAcceptsThePreviousIdAndRefusesAnOlderOne() throws {
    try withDocuments { fs in
      try fs.put(
        "/app/design-handoff.json",
        #"""
        {
          "id" : "H2", "sentAt" : "2026-11-07T01:20:00Z", "presetCode" : "a74hGF01CVunaG0vzZJG",
          "swift" : "let theme = RegistryTheme(...)", "knobs" : { "button" : { "height" : 40 } },
          "differences" : [], "openNotes" : [ { "id" : "N", "text" : "Taller", "screenshot" : "notes/x.png" } ],
          "previous" : { "id" : "H1", "sentAt" : "2026-11-07T01:10:00Z", "presetCode" : "a13GkaOXWwIF", "knobs" : {} },
          "screenshot" : "notes/handoff.png"
        }
        """#)
      let read = try call("read_handoff", ["file": "/app/design-handoff.json"])
      #expect(read["isError"] == false)
      #expect(read["structuredContent"]["handoff"]["screenshotPath"] == "/app/notes/handoff.png")
      #expect(
        read["structuredContent"]["handoff"]["openNotes"].array?.first?["screenshotPath"]
          == "/app/notes/x.png")
      #expect(try record(fs)["read"]["handoffs"] == ["H2": "2027-01-15T08:00:00Z"])

      let previous = try call(
        "answer_handoff",
        [
          "id": "h1", "reply": "Put indigo into source.",
          "changedFiles": ["RegistryTheme+App.swift"], "file": "/app/design-handoff.json",
        ])
      #expect(previous["isError"] == false)
      #expect(previous["structuredContent"]["id"] == "H1")
      #expect(
        previous["structuredContent"]["newer"]["id"] == "H2", "The agent learns a newer one waits.")
      #expect(
        try record(fs)["answers"]["H1"]["changedFiles"].strings == ["RegistryTheme+App.swift"])

      let current = try call(
        "answer_handoff",
        ["id": "H2", "reply": "Nothing to change.", "file": "/app/design-handoff.json"])
      #expect(current["structuredContent"]["newer"] == .null)
      #expect(
        try record(fs)["answers"]["H2"]["changedFiles"] == [], "A reply alone is not Shipped.")

      let before = try fs.read("/app/design-agent.json")
      let older = try call(
        "answer_handoff", ["id": "H0", "reply": "Late.", "file": "/app/design-handoff.json"])
      #expect(older["isError"] == true)
      #expect(try fs.read("/app/design-agent.json") == before)
    }
  }

  /// Under Source the hand-off carries no code; telling the agent to apply
  /// one would overwrite the app's own theme with the default.
  @Test func aSourceHandOffSaysToLeaveTheThemeAlone() throws {
    try withDocuments { fs in
      try fs.put(
        "/app/design-handoff.json",
        #"{"id":"H1","sentAt":"2026-11-07T01:20:00Z","presetCode":"","swift":"","knobs":{},"differences":[],"openNotes":[]}"#
      )
      let read = try call("read_handoff", ["file": "/app/design-handoff.json"])
      let steps = read["structuredContent"]["nextSteps"].strings
      #expect(steps.first?.contains("Source") == true)
      #expect(!steps.joined().contains("apply_preset with code"))
    }
  }

  @Test func contextReadsTheScreenAndListsScreenshots() throws {
    let fs = try fixture()
    try fs.createDirectory("/app/notes")
    try fs.write(Data([0x89, 0x50]), to: "/app/notes/screen-1.png")
    try fs.write(Data("not a screenshot".utf8), to: "/app/notes/readme.txt")
    try fs.put(
      "/app/design-context.json",
      #"""
      {
        "capturedAt" : "2026-11-07T00:40:00Z", "screen" : "button",
        "stage" : { "height" : 852, "width" : 393, "x" : 0, "y" : 0 },
        "selectedItem" : "button", "selectionChain" : ["button"],
        "items" : [ { "name" : "button", "title" : "button", "frame" : { "x" : 16, "y" : 200, "width" : 120, "height" : 36 }, "ancestors" : [], "tokens" : ["accent"], "knobs" : {} } ],
        "presetCode" : "a13GkaOXWwIF", "appearance" : "system", "textSize" : "system", "rightToLeft" : false,
        "screenshot" : "notes/screen-1.png", "trying" : { "id" : "P1", "name" : "Warm" }, "tunesTheme" : true
      }
      """#)
    try withFixture(fs) {
      let context = try DesignContext.read(file: "/app/design-context.json")
      #expect(context["items"].array?.first?["tokens"].strings == ["accent"])
      #expect(context["screenshots"].strings == ["/app/notes/screen-1.png"])
      #expect(context["screenshotPath"] == "/app/notes/screen-1.png")
      #expect(throws: RegistryError.self) { try DesignContext.read(file: "/app/missing.json") }
      let result = try call("get_design_context", ["file": "/app/design-context.json"])
      #expect(result["isError"] == false)
      #expect(result["structuredContent"]["context"]["trying"]["name"] == "Warm")
    }
  }
}
