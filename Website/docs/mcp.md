# MCP server

`sweetui mcp`: registry as tools over stdio (CLI engine: search, describe, plan, diff, install, preset). Register Homebrew binary; Claude Code `.mcp.json`:

```json
{
  "mcpServers": {
    "sweetui": {
      "command": "sweetui",
      "args": ["mcp"]
    }
  }
}
```

For checkout vs snapshot, add `"--registry", "/path/to/clone"`.

## What the tools do

- Read-only (`readOnlyHint`): search ranks results, `describe_item` matches `describe --format json`, plan previews without writing, diff reports edits.
- `install_item` (`destructiveHint`): prompts, resolves, copies, writes receipt; refuses modified files without force.
- `describe_preset`/`apply_preset`: read/write preset codes, push theme from code.
- A recipe: native guidance, no install.

## Ground truth for an agent

Quote tool, not memory: `describe <item>` for usage, `install --plan` for requirement, `preset decode` for knobs. Three `Skills/` cover consuming, theming, authoring.
