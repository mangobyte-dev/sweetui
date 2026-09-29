import Dependencies
import Foundation
import InlineSnapshotTesting
import Synchronization
import Testing

@testable import SweetUIKit

private func mcpCommand(_ lines: [Data]) throws -> CommandOutput {
  let queue = Mutex(lines)
  return try withDependencies {
    $0.registryInput = RegistryInput {
      queue.withLock { $0.isEmpty ? nil : $0.removeFirst() }
    }
  } operation: {
    try command(["mcp"])
  }
}

extension Commands {
  @Test func mcpToolsThroughRealCommand() throws {
    let fs = try fixture()
    try withFixture(fs) {
      let payload = #"""
        {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "search_items", "arguments": {"query": "test"}}}
        {"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "describe_item", "arguments": {"name": "example"}}}
        {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "plan_install", "arguments": {"name": "example", "destination": "/app"}}}
        {"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {"name": "install_item", "arguments": {"name": "example", "destination": "/app"}}}
        {"jsonrpc": "2.0", "id": 5, "method": "tools/call", "params": {"name": "diff_item", "arguments": {"name": "example", "destination": "/app"}}}
        {"jsonrpc": "2.0", "id": 6, "method": "tools/call", "params": {"name": "describe_preset", "arguments": {"code": "a13GkaOXWwIF"}}}
        {"jsonrpc": "2.0", "id": 7, "method": "tools/call", "params": {"name": "apply_preset", "arguments": {"code": "a13GkaOXWwIF", "destination": "/app"}}}
        """#
      let result = try mcpCommand(payload.split(separator: "\n").map { Data($0.utf8) })
      #expect(result.code == 0)
      #expect(result.stderr.isEmpty)
      // Expected wire bytes come from the Python server over this same fixture.
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        #"""
        {"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"{\n  \"items\": [\n    {\n      \"name\": \"example\",\n      \"kind\": \"component\",\n      \"version\": \"0.1.0\",\n      \"description\": \"Test item.\",\n      \"score\": 20,\n      \"registryDependencies\": [],\n      \"tags\": [\n        \"test\"\n      ],\n      \"aliases\": []\n    }\n  ]\n}"}],"structuredContent":{"items":[{"name":"example","kind":"component","version":"0.1.0","description":"Test item.","score":20,"registryDependencies":[],"tags":["test"],"aliases":[]}]},"isError":false}}
        {"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"{\n  \"name\": \"example\",\n  \"kind\": \"component\",\n  \"version\": \"0.1.0\",\n  \"description\": \"Test item.\",\n  \"usage\": \"Example()\",\n  \"docs\": null,\n  \"tags\": [\n    \"test\"\n  ],\n  \"aliases\": null,\n  \"platforms\": [\n    {\n      \"minimumVersion\": \"26.0\",\n      \"name\": \"iOS\"\n    }\n  ],\n  \"accessibility\": [],\n  \"registryDependencies\": [],\n  \"installs\": true,\n  \"installOrder\": [\n    \"example\"\n  ],\n  \"packageRequirements\": [],\n  \"signatures\": [],\n  \"files\": [\n    {\n      \"source\": \"sources/Example.swift\",\n      \"target\": \"Example.swift\",\n      \"content\": \"source\\n\"\n    }\n  ]\n}"}],"structuredContent":{"name":"example","kind":"component","version":"0.1.0","description":"Test item.","usage":"Example()","docs":null,"tags":["test"],"aliases":null,"platforms":[{"minimumVersion":"26.0","name":"iOS"}],"accessibility":[],"registryDependencies":[],"installs":true,"installOrder":["example"],"packageRequirements":[],"signatures":[],"files":[{"source":"sources/Example.swift","target":"Example.swift","content":"source\n"}]},"isError":false}}
        {"jsonrpc":"2.0","id":3,"result":{"content":[{"type":"text","text":"{\n  \"item\": \"example\",\n  \"destination\": \"/app\",\n  \"closure\": [\n    {\n      \"name\": \"example\",\n      \"version\": \"0.1.0\",\n      \"kind\": \"component\"\n    }\n  ],\n  \"files\": [\n    {\n      \"item\": \"example\",\n      \"target\": \"/app/Example.swift\",\n      \"status\": \"new\"\n    }\n  ],\n  \"packageRequirements\": [],\n  \"collisions\": [],\n  \"stale\": [],\n  \"nextSteps\": [\n    \"Add each package requirement to the consuming project; the installer never edits project files\",\n    \"Ensure the destination folder is a member of the consuming build target\",\n    \"Call install_item with name example and this destination\"\n  ]\n}"}],"structuredContent":{"item":"example","destination":"/app","closure":[{"name":"example","version":"0.1.0","kind":"component"}],"files":[{"item":"example","target":"/app/Example.swift","status":"new"}],"packageRequirements":[],"collisions":[],"stale":[],"nextSteps":["Add each package requirement to the consuming project; the installer never edits project files","Ensure the destination folder is a member of the consuming build target","Call install_item with name example and this destination"]},"isError":false}}
        {"jsonrpc":"2.0","id":4,"result":{"content":[{"type":"text","text":"{\n  \"item\": \"example\",\n  \"installed\": [\n    {\n      \"item\": \"example\",\n      \"target\": \"/app/Example.swift\"\n    }\n  ],\n  \"upToDate\": false,\n  \"packageRequirements\": []\n}"}],"structuredContent":{"item":"example","installed":[{"item":"example","target":"/app/Example.swift"}],"upToDate":false,"packageRequirements":[]},"isError":false}}
        {"jsonrpc":"2.0","id":5,"result":{"content":[{"type":"text","text":"{\n  \"item\": \"example\",\n  \"identical\": true,\n  \"files\": [\n    {\n      \"item\": \"example\",\n      \"target\": \"/app/Example.swift\",\n      \"diff\": \"\"\n    }\n  ]\n}"}],"structuredContent":{"item":"example","identical":true,"files":[{"item":"example","target":"/app/Example.swift","diff":""}]},"isError":false}}
        {"jsonrpc":"2.0","id":6,"result":{"content":[{"type":"text","text":"{\n  \"code\": \"a13GkaOXWwIF\",\n  \"version\": \"a\",\n  \"tuning\": {\n    \"accent\": \"indigo\",\n    \"darkLabelOnAccent\": false,\n    \"surfaceOpacity\": 0.055,\n    \"borderOpacity\": 0.08,\n    \"borderWidth\": 1.0,\n    \"emphasizedBorderWidth\": 2.0,\n    \"compactRadius\": 6.0,\n    \"controlRadius\": 8.0,\n    \"cardRadius\": 16.0,\n    \"compactSpacing\": 8.0,\n    \"standardSpacing\": 16.0,\n    \"sectionSpacing\": 24.0,\n    \"controlHorizontalPadding\": 12.0,\n    \"disabledOpacity\": 0.5\n  },\n  \"swift\": \"let theme = RegistryTheme(\\n    accent: .indigo,\\n    onAccent: .white,\\n    surface: .primary.opacity(0.055),\\n    border: .primary.opacity(0.080),\\n    disabledOpacity: 0.500,\\n    metrics: RegistryMetrics(\\n        compactSpacing: 8,\\n        standardSpacing: 16,\\n        sectionSpacing: 24,\\n        controlHorizontalPadding: 12,\\n        borderWidth: 1,\\n        emphasizedBorderWidth: 2,\\n        compactRadius: 6,\\n        controlRadius: 8,\\n        cardRadius: 16\\n    )\\n)\\n\\n// Apply once at the root of your scene; every registry item below inherits it.\\nContentView()\\n    .registryTheme(theme)\",\n  \"url\": \"https://sweetui.dev/create?preset=a13GkaOXWwIF\"\n}"}],"structuredContent":{"code":"a13GkaOXWwIF","version":"a","tuning":{"accent":"indigo","darkLabelOnAccent":false,"surfaceOpacity":0.055,"borderOpacity":0.08,"borderWidth":1.0,"emphasizedBorderWidth":2.0,"compactRadius":6.0,"controlRadius":8.0,"cardRadius":16.0,"compactSpacing":8.0,"standardSpacing":16.0,"sectionSpacing":24.0,"controlHorizontalPadding":12.0,"disabledOpacity":0.5},"swift":"let theme = RegistryTheme(\n    accent: .indigo,\n    onAccent: .white,\n    surface: .primary.opacity(0.055),\n    border: .primary.opacity(0.080),\n    disabledOpacity: 0.500,\n    metrics: RegistryMetrics(\n        compactSpacing: 8,\n        standardSpacing: 16,\n        sectionSpacing: 24,\n        controlHorizontalPadding: 12,\n        borderWidth: 1,\n        emphasizedBorderWidth: 2,\n        compactRadius: 6,\n        controlRadius: 8,\n        cardRadius: 16\n    )\n)\n\n// Apply once at the root of your scene; every registry item below inherits it.\nContentView()\n    .registryTheme(theme)","url":"https://sweetui.dev/create?preset=a13GkaOXWwIF"},"isError":false}}
        {"jsonrpc":"2.0","id":7,"result":{"content":[{"type":"text","text":"{\n  \"code\": \"a13GkaOXWwIF\",\n  \"file\": \"/app/RegistryTheme+App.swift\",\n  \"nextSteps\": [\n    \"Ensure the destination folder is a member of the consuming build target\",\n    \"Apply the theme once at the scene root: ContentView().registryTheme(.app)\"\n  ]\n}"}],"structuredContent":{"code":"a13GkaOXWwIF","file":"/app/RegistryTheme+App.swift","nextSteps":["Ensure the destination folder is a member of the consuming build target","Apply the theme once at the scene root: ContentView().registryTheme(.app)"]},"isError":false}}

        """#
      }
      #expect(try fs.read("/app/Example.swift") == Data("source\n".utf8))
      #expect(fs.exists("/app/.sweetui/receipt.json"))
      #expect(fs.exists("/app/RegistryTheme+App.swift"))
    }
  }
}

extension Commands {
  @Test func mcpProtocolAndRefusals() throws {
    let fs = try fixture()
    try withFixture(fs) {
      let lines = [
        " ", "not json",
        #"{"id":1,"method":"ping"}"#,
        #"{"method":"notifications/initialized"}"#,
        #"{"method":"ping"}"#,
        #"{"id":2,"method":"missing"}"#,
        #"{"id":3,"method":"tools/call","params":{"name":"search_items","arguments":"wrong"}}"#,
        #"{"id":4,"method":"tools/call","params":{"name":"unknown"}}"#,
        #"{"id":5,"method":"tools/call","params":{"name":"install_item","arguments":{"name":"example","destination":"/app","force":"yes"}}}"#,
        #"{"id":6,"method":"tools/call","params":{"name":"describe_item","arguments":{"name":"absent"}}}"#,
      ]
      let result = try mcpCommand(lines.map { Data($0.utf8) } + [Data([255])])
      #expect(result.code == 0)
      #expect(result.stderr.isEmpty)
      assertInlineSnapshot(of: result.stdout, as: .lines) {
        #"""
        {"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"Parse error"}}
        {"jsonrpc":"2.0","id":1,"result":{}}
        {"jsonrpc":"2.0","id":2,"error":{"code":-32601,"message":"Method not found: missing"}}
        {"jsonrpc":"2.0","id":3,"error":{"code":-32602,"message":"arguments must be an object"}}
        {"jsonrpc":"2.0","id":4,"error":{"code":-32602,"message":"Unknown tool: unknown"}}
        {"jsonrpc":"2.0","id":5,"result":{"content":[{"type":"text","text":"Invalid arguments: force must be a boolean"}],"isError":true}}
        {"jsonrpc":"2.0","id":6,"result":{"content":[{"type":"text","text":"Unknown registry item: absent"}],"isError":true}}
        {"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"Parse error"}}

        """#
      }
      #expect(!fs.exists("/app"))
      for version in ["2025-06-18", "2025-03-26", "2024-11-05", "1999-01-01"] {
        let line: JSON = [
          "id": 1, "method": "initialize", "params": ["protocolVersion": .string(version)],
        ]
        let initialized = try mcpCommand([Data(line.rendered().utf8)])
        let response = try JSON.read(Data(initialized.stdout.utf8))
        #expect(
          response["result"]["protocolVersion"].text
            == (version == "1999-01-01" ? "2025-06-18" : version))
      }
    }
  }
  @Test func mcpReloadsMetadataAndPreservesReadOnlyPlans() throws {
    let fs = try fixture()
    try withFixture(fs) {
      let server = MCPServer(root: "/registry")
      let message: JSON = [
        "id": 1, "method": "tools/call",
        "params": ["name": "describe_item", "arguments": ["name": "example"]],
      ]
      let first = try #require(try server.response(to: Data(message.rendered().utf8)))
      #expect(
        try JSON.read(Data(first.utf8))["result"]["structuredContent"]["description"]
          == "Test item.")
      var edited = example
      edited["description"] = "Edited metadata."
      try fs.put("/registry/Registry/items/example.json", edited.rendered())
      let second = try #require(try server.response(to: Data(message.rendered().utf8)))
      #expect(
        try JSON.read(Data(second.utf8))["result"]["structuredContent"]["description"]
          == "Edited metadata.")
      let plan: JSON = [
        "id": 2, "method": "tools/call",
        "params": [
          "name": "plan_install", "arguments": ["name": "example", "destination": "~/Components"],
        ],
      ]
      let planned = try #require(try server.response(to: Data(plan.rendered().utf8)))
      #expect(
        try JSON.read(Data(planned.utf8))["result"]["structuredContent"]["destination"]
          == "/home/test/Components")
      #expect(!fs.exists("/home/test"))
      edited["files"] = []
      try fs.put("/registry/Registry/items/example.json", edited.rendered())
      let invalid = try #require(try server.response(to: Data(message.rendered().utf8)))
      #expect(try JSON.read(Data(invalid.utf8))["result"]["isError"] == true)
      #expect(
        try JSON.read(Data(invalid.utf8))["result"]["content"].array?.first?["text"].text.contains(
          "Registry validation failed:") == true)
    }
  }
}
