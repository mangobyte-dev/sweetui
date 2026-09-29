import Dependencies
import Foundation
import Testing

@testable import SweetUIKit

private func rpc(_ server: MCPServer, _ message: JSON) throws -> JSON {
  try JSON.read(Data(#require(try server.response(to: Data(message.rendered().utf8))).utf8))
}

private func call(_ id: Int, _ tool: String, _ arguments: JSON) -> JSON {
  [
    "jsonrpc": "2.0", "id": .number(Double(id)), "method": "tools/call",
    "params": ["name": .string(tool), "arguments": arguments],
  ]
}

extension Commands {
  @Test func mcpListsEveryToolAndSearchesByAlias() throws {
    try withRepository {
      let server = MCPServer(root: repositoryRoot)
      let initialized = try rpc(
        server,
        [
          "jsonrpc": "2.0", "id": 1, "method": "initialize",
          "params": [
            "protocolVersion": "2025-06-18", "capabilities": [:],
            "clientInfo": ["name": "test", "version": "0"],
          ],
        ])
      #expect(initialized["result"]["protocolVersion"] == "2025-06-18")
      #expect(initialized["result"]["capabilities"]["tools"] != .null)
      #expect(
        try server.response(
          to: Data(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#.utf8))
          == nil)
      let listed = try rpc(server, ["jsonrpc": "2.0", "id": 2, "method": "tools/list"])
      let tools = try #require(listed["result"]["tools"].array)
      #expect(
        Set(tools.map { $0["name"].text }) == [
          "search_items", "describe_item", "plan_install", "diff_item", "install_item",
          "describe_preset", "apply_preset",
        ])
      for tool in tools { #expect(tool["inputSchema"]["type"] == "object") }
      let search = try rpc(server, call(3, "search_items", ["query": "dropdown"]))
      #expect(search["result"]["isError"] == false)
      #expect(
        search["result"]["structuredContent"]["items"].array?.first?["name"] == "dropdown-menu")
      // An unsupported client version gets the server's latest, never an echo.
      let old = try rpc(
        server,
        [
          "jsonrpc": "2.0", "id": 4, "method": "initialize",
          "params": [
            "protocolVersion": "1999-01-01", "capabilities": [:],
            "clientInfo": ["name": "old", "version": "0"],
          ],
        ])
      #expect(old["result"]["protocolVersion"] == "2025-06-18")
      let missing = try rpc(server, ["jsonrpc": "2.0", "id": 5, "method": "no/such/method"])
      #expect(missing["error"]["code"] == -32601)
    }
  }

  @Test func mcpPlansWithoutWritingAndInstallsTheClosure() throws {
    try withRepository {
      let server = MCPServer(root: repositoryRoot)
      try withTemporaryDirectory { directory in
        let destination = directory + "/Components"
        let arguments: JSON = ["name": "finance-overview", "destination": .string(destination)]
        let plan = try rpc(server, call(1, "plan_install", arguments))["result"][
          "structuredContent"]
        #expect(
          plan["closure"].array?.map { $0["name"].text } == [
            "metric-card", "transaction-row", "empty", "finance-overview",
          ])
        #expect(plan["files"].array?.allSatisfy { $0["status"] == "new" } == true)
        #expect(
          !FileManager.default.fileExists(atPath: destination),
          "plan_install must not create the destination")
        let described = try rpc(server, call(2, "describe_item", ["name": "finance-overview"]))[
          "result"]["structuredContent"]
        #expect(described["installs"] == true)
        #expect(
          described["files"].array?.first?["content"].text.contains("public struct FinanceOverview")
            == true)
        let installed = try rpc(server, call(1, "install_item", arguments))["result"][
          "structuredContent"]
        #expect(installed["installed"].array?.count == 4)
        #expect(
          FileManager.default.fileExists(atPath: destination + "/.sweetui/receipt.json"))
        #expect(
          try rpc(server, call(2, "install_item", arguments))["result"]["structuredContent"][
            "upToDate"]
            == true)
        #expect(
          try rpc(server, call(3, "diff_item", arguments))["result"]["structuredContent"][
            "identical"]
            == true)
        try "// edited\n".write(
          toFile: destination + "/MetricCard.swift", atomically: true, encoding: .utf8)
        let refused = try rpc(server, call(1, "install_item", arguments))["result"]
        #expect(refused["isError"] == true, "modified owned source must be refused without force")
        #expect(
          refused["content"].array?.first?["text"].text.contains(
            "Refusing to overwrite owned source")
            == true)
      }
    }
  }

  @Test func mcpRecipesReportGuidanceAndPresetToolsWriteTheThemeFile() throws {
    try withRepository {
      let server = MCPServer(root: repositoryRoot)
      try withTemporaryDirectory { directory in
        let tabs = try rpc(
          server, call(1, "install_item", ["name": "tabs", "destination": .string(directory)]))[
            "result"]["structuredContent"]
        #expect(tabs["installs"] == false)
        #expect(tabs["guidance"].text.contains(".pickerStyle(.segmented)"))
        #expect(try directoryEntries(directory).isEmpty, "a recipe must write nothing")
        #expect(
          try rpc(server, call(2, "describe_item", ["name": "tabs"]))["result"][
            "structuredContent"][
              "installs"] == false)
        #expect(
          try rpc(server, call(3, "describe_item", ["name": "no-such-item"]))["result"]["isError"]
            == true)
        let destination = directory + "/Components"
        let described = try rpc(
          server, call(4, "describe_preset", ["code": "--preset a13GkaOXWwIa"]))[
            "result"]
        #expect(described["isError"] == false)
        #expect(described["structuredContent"]["code"] == "a13GkaOXWwIa")
        #expect(described["structuredContent"]["tuning"]["accent"] == "yellow")
        #expect(described["structuredContent"]["tuning"]["darkLabelOnAccent"] == true)
        #expect(described["structuredContent"]["swift"].text.contains("accent: .yellow,"))
        #expect(described["structuredContent"]["url"].text.hasSuffix("/create?preset=a13GkaOXWwIa"))
        let applied = try rpc(
          server,
          call(5, "apply_preset", ["code": "a13GkaOXWwIa", "destination": .string(destination)]))[
            "result"]
        #expect(applied["isError"] == false)
        let file = destination + "/RegistryTheme+App.swift"
        #expect(applied["structuredContent"]["file"].text == file)
        #expect(try fileText(file).contains("static let app = RegistryTheme("))
        #expect(
          applied["structuredContent"]["nextSteps"].array?.last?.text.contains(
            ".registryTheme(.app)")
            == true)
        let invalid = try rpc(server, call(6, "describe_preset", ["code": "not a code"]))["result"]
        #expect(invalid["isError"] == true)
        #expect(
          invalid["content"].array?.first?["text"].text.contains("invalid preset code") == true)
        let forced = try rpc(
          server,
          call(
            7, "apply_preset",
            ["code": "a13GkaOXWwIF", "destination": .string(destination), "force": "yes"]))[
            "result"]
        #expect(forced["isError"] == true)
        #expect(
          forced["content"].array?.first?["text"].text.contains("force must be a boolean") == true)
      }
    }
  }
}
