---
name: sweetui
description: Consume SweetUI, the source-owned SwiftUI registry, from an app with the sweetui tool: search, describe, plan, install, compose, diff, and update items, and drive the same engine over MCP.
metadata:
  short-description: Install and own SweetUI items in a consuming app.
---

# SweetUI

## Goal

Adds SwiftUI UI via owned Swift source, not framework dependency.

Two pain points (`docs/mango.md`):

- Agent drift: three "add a settings screen" prompts, three styles; `usage` snippets, MCP server fix the API (`docs/registry-spec.md`).
- Maintenance risk: unmaintained packages. Guarded by receipt, foundations package pinned `upToNextMinor` from `0.5.0`; `--diff`/`--update` audit change (`docs/philosophy.md`; `docs/architecture.md`).

## Quick start

1. Install: `brew install mangobyte-dev/tap/sweetui`.
2. Find: `sweetui search activity --kind block --format names`.
3. Read: `sweetui describe activity-feed`.
4. Preview: `sweetui install activity-feed --destination path/to/YourTarget/Components --plan`.
5. Install: `sweetui install activity-feed --destination path/to/YourTarget/Components`.
6. Add printed package, destination folder to build target; compose via public API.

Installer never edits `.xcodeproj`, adds dependencies, or hosts content (`docs/architecture.md`); prints:

```text
add package https://github.com/mangobyte-dev/sweetui.git (from 0.5.0 up to the next minor version) and link product SweetUIFoundations
```

## API interface

- Foundations API (theme, metrics, presets, root modifiers): `references/interface/SweetUIFoundations.swiftinterface`
- Catalog, items by kind: `references/catalog.md`
- Item `usage` snippets, quoted from canonical source: `references/usage.md`

Quote every API from these files, never memory.

## Finding an item

Local, deterministic, JSON search. No model, account, or hosted registry (`docs/architecture.md`).

```sh
sweetui search nutrition dashboard --kind block --platform iOS --target-version 26.0
```

JSON fields: `name`, `kind`, `version`, `registryDependencies`, `packageDependencies`, `platforms`, `accessibility`, `preview`, `score`. `--format names` lists names; `--format json` (default) returns records.

- **DO** pass every known term; each MUST match metadata (name, alias, tag, description).
- **DO** filter with `--kind component|block|flow|recipe`, `--platform iOS`, `--target-version X.Y`.
- **DO** retry with one broader term when `--format names` prints `No item matches ...` on stderr (exit 0); domain words such as `product`, `cart`, `price`, `checkout`, `rating` are aliases, so try the noun before the feature.
- **DO NOT** browse source; `references/catalog.md` is index.

## Reading an item

```sh
sweetui describe badge
```

Output: name, kind, version, description, `Usage:`, `Signatures:`, accessibility notes, install order, requirements, file targets:

```text
badge (component 0.3.2)
Applies primary, secondary, outline, positive, and destructive badge treatments to native Text and Label content.

Usage:
  Text("New")
      .registryBadge()

  Label("Completed", systemImage: "checkmark.circle.fill")
      .registryBadge(.positive)
Signatures:
  RegistryBadgeVariant: enum { case primary; case secondary; case outline; case positive; case destructive }
  View: func registryBadge(_ variant: RegistryBadgeVariant = .primary) -> some View
```

`Signatures:` lists every public initializer, function, static member, and enum of the item's sources, one line each, prefixed with the owning type (`FieldGroup: init(...)`, `RegistryToast.Action: init(...)`, `ButtonStyle: static var registry`), with labels, types, defaults, and enum cases; the JSON payload carries them as `signatures`. `--source` prints each file's content; `--format json` returns MCP `describe_item` payload.

- **DO** `describe` a `recipe` too; reports native guidance (`docs/registry-spec.md`).
- **DO** compose past the snippet from `Signatures:`; read installed source only for behavior.
- **DO NOT** guess signature; `Usage:` carries real calls and `Signatures:` the exact API.

## Planning and installing

Both flags are read-only (`docs/architecture.md`).

```sh
sweetui install finance-overview --destination path/to/YourTarget/Components --plan
```

`--plan` prints dependency closure (versions, kinds), target write's status (`new`, `up-to-date`, `modified-would-require-force`, `would-merge`), requirements, collisions, integration steps.

```sh
sweetui install finance-overview --destination path/to/YourTarget/Components
```

Installer resolves depth first (here `metric-card`, `transaction-row`, `empty`, then `finance-overview`), copies source, writes `.sweetui/receipt.json` plus non-Swift base snapshots.

Point `--destination` inside consuming target's sources; installer never sets build-target membership.

- **DO** pass `--force` only to replace modified owned source; repeat install needs receipt match.
- **DO NOT** install a `recipe`: exits code 2, prints native guidance; copy snippet from `describe` (`docs/registry-spec.md`).

## Composing through the initializer

Initializer: content, bindings, actions, required accessibility input. Presentation: a `registry`-prefixed method before generic modifiers (`docs/architecture.md`):

Component, from `badge`:

```swift
Text("New")
    .registryBadge()

Label("Completed", systemImage: "checkmark.circle.fill")
    .registryBadge(.positive)
```

Block, from `activity-feed`:

```swift
ActivityFeed(
    "Activity",
    notice: ActivityNotice("Card delivery delayed", message: Text("Arrives Thursday.")),
    onDismissNotice: { },
    items: [
        ActivityItem(
            id: "bakery",
            title: Text("Mishmash Bakery"),
            detail: Text("Card payment of KWD 8.750"),
            timestamp: Text("09:41"),
            initials: "MB",
            senderName: Text("Mishmash Bakery"),
            isUnread: true
        )
    ],
    earlierItems: [],
    isLoading: false,
    onSelect: { id in }
)
```

Recipe installs nothing; copy snippet, from `sheet`:

```swift
@State private var isShowingDetails = false

NavigationStack {
    List {
        LabeledContent("Merchant", value: "Mishmash Bakery")
        LabeledContent("Amount", value: "KWD 8.750")
    }
    .navigationTitle("Transaction")
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Details", systemImage: "sidebar.trailing") {
                isShowingDetails.toggle()
            }
            .accessibilityLabel("Toggle details")
        }
    }
    .inspector(isPresented: $isShowingDetails) {
        List {
            LabeledContent("Category", value: "Dining")
            LabeledContent("Card", value: "Visa 4321")
            LabeledContent("Status", value: "Cleared")
        }
        .inspectorColumnWidth(min: 240, ideal: 280, max: 360)
    }
}
```

- **DO** keep caller state via bindings; block never owns `ScrollView`, navigation container, or width.
- **DO** provide accessibility input the view cannot derive, an `avatar`'s label (`docs/philosophy.md`).
- **DO NOT** ship a `usage` snippet's placeholder values: show shape, not data.

## Auditing and updating owned copies

Copied source stays owned.

```sh
sweetui info --destination path/to/YourTarget/Components
```

`info` marks each file up-to-date, modified, or missing vs install-time digest; exits 2, no receipt.

```sh
sweetui install finance-overview --destination path/to/YourTarget/Components --diff
```

`--diff` prints unified diff per receipt-backed file; exits 0 on parity, 1 on differences; requires receipt.

```sh
sweetui install finance-overview --destination path/to/YourTarget/Components --update
```

Unmodified files update; local edits stay; disjoint edits merge via `git merge-file`. Overlapping edits stay, writing `.merge` artifact under `.sweetui/conflicts/`.

- **DO** run `--diff` before `--update`.
- **DO** resolve a `.sweetui/conflicts/<id>.merge` artifact by hand; updater preflights closure: conflict blocks nothing else.
- **DO NOT** hand-edit `.sweetui/receipt.json` or `bases/*.base` snapshots; diff and merge depend on provenance.

## Using the MCP server

`sweetui mcp` is a stdio adapter over same engine.

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

Add `"--registry", "/path/to/clone"` to `args` to serve checkout, not pinned snapshot.

Seven tools, each CLI counterpart, over JSON-RPC on stdin/stdout: `search_items`, `describe_item`, `plan_install`, `diff_item`, `install_item`, `describe_preset`, `apply_preset`.

- **DO** rely on hints: read-only tools carry `readOnlyHint`; `install_item` carries `destructiveHint`.
- **DO** expect metadata reloads every call; clone edits show without restart.
- **DO NOT** parse log lines; logs go to stderr, stdout stays clean JSON-RPC.

## Working from a clone or snapshot

Resolution order: `--registry <path>` first, then nearest enclosing clone holding `Registry/registry.json`, then cached pinned-release snapshot under `~/Library/Caches/sweetui/`.

In a clone: `swift run sweetui <command>`; release build at `.build/release/sweetui`. Elsewhere: Homebrew fetches snapshot from tag once, reuses it.

- **DO** pass `--registry /absolute/path/to/clone` to point installed binary at checkout.
- **DO** pass `--refresh` to re-download snapshot; touches cache/update stamp, never source, separate from `--force`.
- **DO NOT** expect `--refresh` to affect `--registry` or enclosing clone; neither reads snapshot.
