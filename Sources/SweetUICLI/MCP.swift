import ArgumentParser
import SweetUIKit

struct MCP: ParsableCommand {
  @OptionGroup var options: RegistryOptions
  func run() throws { try refusal { try MCPServer(root: options.root()).serve() } }
}
