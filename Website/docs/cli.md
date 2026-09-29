# CLI

`sweetui`: one binary, no dependencies. `brew install mangobyte-dev/tap/sweetui`, or `swift run sweetui <command>` from clone.

Registry source:

- `--registry <path>`: that checkout.
- Inside clone: enclosing one.
- Elsewhere: cached snapshot; `--refresh` rechecks tap.

```text
USAGE: sweetui <subcommand>

SUBCOMMANDS:
  validate
  search
  describe                Print an item's metadata, usage, dependency closure,
                          and file targets.
  install
  info                    Report the installed items and file status in a
                          destination from its receipt.
  preset
  generate
  mcp
```

## search

Local, deterministic, JSON-first, no model/account/hosted service. Results: closure, package/accessibility/compatibility, previews.

```sh
sweetui search nutrition dashboard --kind block --platform iOS --target-version 26.0
sweetui search activity --kind block --format names
```

## describe

Prints item: name, kind, version, description, usage, signatures (every public initializer, function, static member, and enum, prefixed with its owning type), accessibility notes; installables: closure, requirement, targets. `--source`: content; `--format json`: MCP `describe_item` payload; recipes: native guidance.

```sh
sweetui describe activity-feed
sweetui describe button --source
```

## install

```text
USAGE: sweetui install [--registry <registry>] [--refresh] <item> --destination <destination> [--force] [--update] [--plan] [--diff]
```

- `--plan`: dry run: closure, status (`new`/`up-to-date`/`modified-would-require-force`/`would-merge`), requirement, collisions, steps.
- Default: copies closure, writes `.sweetui/receipt.json` + non-Swift base snapshots, prints requirement; repeat needs matching receipt.
- `--diff`: unified diff vs registry, exit 1 on difference, needs receipt.
- `--update`: unmodified takes registry, edits stay, disjoint merges via `git merge-file`, overlapping keeps file, writes `.merge` under `.sweetui/conflicts/`.
- `--force` replaces modified source, skips cache.
- Recipe: installs nothing, exit 2.

Checks tap daily, prints upgrade if newer; failures silent.

## info

Reads receipt, lists items, marks files up-to-date/modified/missing vs install-time digests. Never touches registry; exits 2 without one.

```sh
sweetui info --destination Sources/App/Components
```

## preset

Preset code: one `RegistryTheme` string, read/written by tool, Showcase, website, MCP.

```sh
sweetui preset decode a13GkaOXWwIF          # the knobs, the Swift, the website URL (--json for the payload)
sweetui preset url a13GkaOXWwIF             # the Create page for the code
sweetui preset apply a74hGF01CVunaG0vzZJG --destination path/to/YourApp   # writes RegistryTheme+App.swift
sweetui preset resolve path/to/YourApp/RegistryTheme+App.swift          # an edited theme file back into a code
sweetui preset random                        # a code to start from
```

Theme file: not registry item, no receipt; apply via `.registryTheme(.app)`.

## validate and generate

`validate`: structural check over catalog, exits 0/1 with report; scopes to items, closures.

`generate catalog`/`showcase-manifest`/`site-data`/`item-tokens`/`usage-checks`: files committed, synced with metadata: site, catalog, Showcase manifest, token map, one compiled `View` per usage snippet.

## mcp

`sweetui mcp` serves engine over stdio; see [MCP server](/docs/mcp/).
