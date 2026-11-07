import Foundation
import Testing

@testable import SweetUIKit

/// The MCP read-back of `design-notes.json`, the file the Tune panel writes.
/// An agent must see every open note with what the panel put in it, must not
/// see a resolved one unless it asks, and resolving must change that one
/// note's flag and nothing else in the file, so the panel and the agent keep
/// reading the same notes.
struct DesignNotesTests {
  /// Two notes as `DesignNote`'s encoder writes them: sorted keys, ISO dates,
  /// a screen note without `item` or `frame`.
  private static let file = #"""
    [
      {
        "chain" : [],
        "createdAt" : "2026-11-07T00:11:49Z",
        "id" : "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1",
        "knobs" : {},
        "presetCode" : "a13GkaOXWwIF",
        "resolved" : false,
        "screen" : "Components",
        "text" : "Lift the card off the background",
        "tokens" : []
      },
      {
        "chain" : ["button", "card"],
        "createdAt" : "2026-11-07T00:12:30Z",
        "frame" : { "height" : 36, "width" : 120, "x" : 16, "y" : 200 },
        "id" : "6F3C1B2A-0000-4000-8000-000000000002",
        "item" : "button",
        "knobs" : { "height" : 40 },
        "presetCode" : "a13GkaOXWwIF",
        "resolved" : true,
        "screen" : "button",
        "text" : "Taller",
        "tokens" : ["accent", "onAccent"]
      }
    ]
    """#

  private func withNotes<R>(_ body: (InMemoryFileSystem) throws -> R) throws -> R {
    let fs = try fixture()
    try fs.createDirectory("/app")
    try fs.write(Data(Self.file.utf8), to: "/app/design-notes.json")
    return try withFixture(fs) { try body(fs) }
  }

  @Test func listsOpenNotesUnlessAskedForAll() throws {
    try withNotes { _ in
      let open = try DesignNotes.list(file: "/app/design-notes.json", includeResolved: false)
      #expect(open.map { $0["text"].text } == ["Lift the card off the background"])
      let all = try DesignNotes.list(file: "/app/design-notes.json", includeResolved: true)
      #expect(all.map { $0["text"].text } == ["Lift the card off the background", "Taller"])
      // What the panel wrote reaches the agent whole.
      #expect(all[1]["chain"].strings == ["button", "card"])
      #expect(all[1]["tokens"].strings == ["accent", "onAccent"])
      #expect(all[1]["knobs"]["height"] == 40)
      #expect(all[1]["frame"]["width"] == 120)
      #expect(all[0]["item"] == .null)
    }
  }

  @Test func resolvingFlipsOneNoteAndKeepsTheRest() throws {
    try withNotes { fs in
      let resolved = try DesignNotes.resolve(
        id: "cebef0aa-20fe-420e-b251-b3a7fcff3fc1", file: "/app/design-notes.json",
        reply: "Raised the card's elevation to high.", changedFiles: ["Sources/App/Theme.swift"])
      #expect(resolved["resolved"] == true)
      #expect(resolved["text"] == "Lift the card off the background")
      #expect(resolved["reply"] == "Raised the card's elevation to high.")
      #expect(resolved["changedFiles"].strings == ["Sources/App/Theme.swift"])
      #expect(resolved["resolvedAt"].string?.hasSuffix("Z") == true)
      let written = try JSON.read(fs.read("/app/design-notes.json"))
      #expect(written.array?.count == 2)
      #expect(written.array?[0]["resolved"] == true)
      #expect(written.array?[0]["createdAt"] == "2026-11-07T00:11:49Z")
      #expect(written.array?[1]["knobs"]["height"] == 40, "The other note must keep its knobs.")
      #expect(try DesignNotes.list(file: "/app/design-notes.json", includeResolved: false).isEmpty)
    }
  }

  @Test func refusesAnUnknownNoteAndAMissingFile() throws {
    try withNotes { _ in
      #expect(throws: RegistryError.self) {
        try DesignNotes.resolve(id: "nope", file: "/app/design-notes.json")
      }
      #expect(throws: RegistryError.self) {
        try DesignNotes.list(file: "/app/missing.json", includeResolved: false)
      }
      #expect(throws: RegistryError.self) {
        try DesignNotes.locate(file: nil, udid: "X", bundleId: nil)
      }
    }
  }

  @Test func mcpToolsReadAndResolveTheFile() throws {
    try withNotes { _ in
      let server = MCPServer(root: "/registry")
      func call(_ id: Int, _ name: String, _ arguments: JSON) throws -> JSON {
        let request: JSON = [
          "jsonrpc": "2.0", "id": .number(Double(id)), "method": "tools/call",
          "params": ["name": .string(name), "arguments": arguments],
        ]
        let response = try #require(try server.response(to: Data(request.rendered().utf8)))
        return try JSON.read(Data(response.utf8))
      }
      let listed = try call(1, "list_design_notes", ["file": "/app/design-notes.json"])
      #expect(listed["result"]["isError"] == false)
      #expect(listed["result"]["structuredContent"]["notes"].array?.count == 1)
      #expect(listed["result"]["structuredContent"]["file"] == "/app/design-notes.json")
      let resolved = try call(
        2, "resolve_design_note",
        [
          "id": "CEBEF0AA-20FE-420E-B251-B3A7FCFF3FC1", "file": "/app/design-notes.json",
          "reply": "Done.", "changedFiles": ["a.swift"],
        ])
      #expect(resolved["result"]["structuredContent"]["note"]["resolved"] == true)
      #expect(resolved["result"]["structuredContent"]["note"]["reply"] == "Done.")
      let badFiles = try call(
        6, "resolve_design_note",
        [
          "id": "6F3C1B2A-0000-4000-8000-000000000002", "file": "/app/design-notes.json",
          "changedFiles": "a.swift",
        ])
      #expect(badFiles["result"]["isError"] == true)
      let empty = try call(3, "list_design_notes", ["file": "/app/design-notes.json"])
      #expect(empty["result"]["structuredContent"]["notes"] == [])
      // Neither a file nor a device is a tool error, not a crash.
      let none = try call(4, "list_design_notes", [:])
      #expect(none["result"]["isError"] == true)
      let typed = try call(
        5, "list_design_notes", ["file": "/app/design-notes.json", "includeResolved": "yes"])
      #expect(typed["result"]["isError"] == true)
    }
  }

  @Test func contextReadsTheScreenAndListsScreenshots() throws {
    let fs = try fixture()
    try fs.createDirectory("/app")
    try fs.createDirectory("/app/notes")
    try fs.write(Data([0x89, 0x50]), to: "/app/notes/screen-1.png")
    try fs.write(Data("not a capture".utf8), to: "/app/notes/readme.txt")
    try fs.write(
      Data(
        #"""
        {
          "capturedAt" : "2026-11-07T00:40:00Z",
          "screen" : "button",
          "stage" : { "height" : 852, "width" : 393, "x" : 0, "y" : 0 },
          "selectedItem" : "button",
          "selectionChain" : ["button"],
          "items" : [ { "name" : "button", "title" : "button", "frame" : { "x" : 16, "y" : 200, "width" : 120, "height" : 36 }, "ancestors" : [], "tokens" : ["accent"], "knobs" : {} } ],
          "presetCode" : "a13GkaOXWwIF",
          "appearance" : "system",
          "textSize" : "system",
          "rightToLeft" : false,
          "screenshot" : "notes/screen-1.png"
        }
        """#.utf8), to: "/app/design-context.json")
    try withFixture(fs) {
      let context = try DesignContext.read(file: "/app/design-context.json")
      #expect(context["screen"] == "button")
      #expect(context["items"].array?.first?["tokens"].strings == ["accent"])
      #expect(context["screenshots"].strings == ["/app/notes/screen-1.png"])
      #expect(context["screenshotPath"] == "/app/notes/screen-1.png")
      #expect(throws: RegistryError.self) { try DesignContext.read(file: "/app/missing.json") }

      let server = MCPServer(root: "/registry")
      let request: JSON = [
        "jsonrpc": "2.0", "id": 9, "method": "tools/call",
        "params": [
          "name": "get_design_context", "arguments": ["file": "/app/design-context.json"],
        ],
      ]
      let response = try JSON.read(
        Data(try #require(try server.response(to: Data(request.rendered().utf8))).utf8))
      #expect(response["result"]["isError"] == false)
      #expect(response["result"]["structuredContent"]["context"]["presetCode"] == "a13GkaOXWwIF")
    }
  }
}
