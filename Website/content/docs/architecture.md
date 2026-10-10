# Architecture

## Decision

Version 0: hybrid distribution.

```text
consumer app
├── depends on SweetUIFoundations
└── owns copied component and block source
```

- Foundations: shallow, environment contract, 1 surface modifier, `registryItem(_:)` hook (environment value, anchor preference), `registryScreen(_:)`, reporter, knobs; inert without surface. Components/blocks not package products.
- `SweetUIDesignSurface`: 2nd, optional debug-build product (tuning panel, preset codec, token engine, per-item knobs), moved from Showcase 2026-09-08, behind `designSurface()`. Foundations independent; MUST NOT import registry items; item-only consumers SHOULD NOT add it; from seeFood's Design mode.

## Why this split

Copying both duplicates the foundation contract; packaging both breaks framework compatibility.

Hypothesis: finance/nutrition test, not universal-reuse. Foundation-free item SHOULD be allowed later.

## Source tree

- `Sources/SweetUIFoundations/`: stable package API
- `Registry/items/`: machine-readable item declarations
- `Registry/sources/components/`: copied styles, focused modifiers, compositions
- `Registry/sources/blocks/`: copied block source
- `Sources/SweetUIKit/`, `Sources/SweetUICLI/`: `sweetui`, SwiftUI-free: validation, resolution, receipts, install, conflict-aware updates, search, preset codes, MCP server, generators
- `Examples/Showcase/`: iOS consumer, catalog, demo per item, tuning panel, item-screenshot route
- `Examples/TodoCounter/`: 2nd consumer (Composable Architecture), URL package at published tag, Homebrew install, customized preset theme
- `sweetui generate catalog | showcase-manifest | site-data | item-tokens | usage-checks`: derived from metadata
- `Website/`: Next.js static export, shadcn/ui, reads only `content/registry.json`; `npm run deploy` → Cloudflare Workers (`Website/wrangler.jsonc`); `.github/workflows/pages.yml` → alt GitHub Pages deploy
- `Scripts/capture_previews.py`: per-item light/dark captures, pinned simulator
- `Tests/SweetUIKitTests/`: command, installer, validator, preset, MCP, generator contracts; fixtures, website codec check under `Fixtures/`

## Running the tool

3 ways, same engine: `swift run sweetui <command>` (clone); `.build/release/sweetui` (release build); Homebrew tap `sweetui <command>` (any directory).

Registry lookup order: `--registry <path>` override; nearest ancestor clone (`Registry/registry.json`); cached pinned-release snapshot, published tag, first use (`docs/registry-spec.md`, Agent usage).

`SweetUIKit`: SwiftUI-free, no `SweetUIFoundations` import. Deps: `swift-argument-parser` (parser), `swift-dependencies` (replaceable effects), `swift-snapshot-testing` (command/generator contracts). Executable owns parsing/output; foundations stays tokens only.

## View boundaries

- Prepared display values, bindings, action closures. `Text` preserves caller format/localization. IDs/actions select without store, observable model, router, persistence type.
- Transient `@State` only if self-contained; else external, coordinated by a view, block, restoration, persistence, or product logic.
- Content via `@ViewBuilder`. Interactive appearance: matching style protocol. Optional behavior: focused `ViewModifier`, not initializer growth.
- Composed-view rule: initializer = content, bindings, actions, required accessibility. Owned choice (variant, tone, tint, future size/emphasis): `registry`-prefixed copy-return, before generic modifiers: `InlineAlert("...") { }.registryVariant(.positive)`, `TransactionRow(...).registryTone(.negative)`, `MacroProgress(...).registryTint(.orange)`. Returns `Self` (mutated copy); default: prior. Controls: `registry` style (`.buttonStyle(.registryOutline)`). Text: `registry` modifier, variant (`registryBadge(.positive)`). Theme: `registryTheme(_:)`; size: `controlSize`.
- Composed block MUST NOT own `ScrollView`, navigation container, max width. Showcase applies iPad width at call site.

## Foundations

- `RegistryTheme`: `accent` (optional), `onAccent`, `surface`, `border`, `positive`, `negative`, `disabledOpacity`. `RegistryMetrics`: 3 spacings, control padding, 2 border widths, compact/control/card radii.
- `registryTheme(_:)`: `EnvironmentValues`/`@Entry`, accent→subtree tint (1 scene-root call); `nil`→app tint (default MUST NOT override). `tint(nil)` resets not inherits: SwiftUICore's `environment(\.tintColor, tint)` (package-private). Toggle at runtime resets subtree; apply pre-scene, use `Color.accentColor`.
- Presets: `system`, `graphite`, `indigo`, `rose`, `emerald`, `amber`, starting points not a theme engine. `graphite`: primary accent, background-colored label. `amber`: light accent, dark label, proves `onAccent`.
- Semantic tokens replace repeated colors/metrics; token enters foundations once 2 items need it (`everyFoundationTokenHasTwoSemanticConsumers`, `Tests/SweetUIKitTests/RegistryContractTests.swift`). Style stays source-owned until 2 items match.
- Tuning panel: theme creator. Since Stage 9, Tune button (`tabViewBottomAccessory`) above tab bar opens a floating resizable card. Tool's own window, not a sheet; app stays live. Live tokens, one-tap presets, Copy Swift (`RegistryTheme` init), Copy Code, Import.
- Custom accent: separate dark value, dynamic `UIColor`. Panel/model/tokens live in `SweetUIDesignSurface`; swift-sharing persists `registry-tokens.json`.
- Theme preview: `preview` block's `PreviewWall` (`ItemDemos` `theme-preview`), live in panel. `capture_previews.py --themes`/`--preset`: full screen/preset (not 1 strip); Create/Themes: first screen/preset, iPhone 17; else CSS board.
- Preset code (`docs/registry-spec.md`, "Preset codes"): theme as 1 string. Read/written by Create page, Showcase, `sweetui preset`, MCP server. `preset apply`→`RegistryTheme+App.swift`; `capture_previews.py --preset`: any code, pinned simulator. Create page: CSS board, real capture (6 presets), no SwiftUI render.

## Compatibility policy

Pre-1.0: patch source-compatible, minor MAY change contract. Items declare `upToNextMinor` from known-good floor, currently `0.5.0`, beta contract (`docs/registry-spec.md`). Source verified: platform floor, foundation range; receipt records requirement at install.

## Installation behavior

Installer reads `Registry/registry.json`, resolves depth first, validates safe relative paths, preflights collisions, copies exact source. Records versions, dependency declarations, target paths, source/installed digests, non-Swift base snapshots (`.sweetui/`). Prints package instruction (URL, requirement, product) for closure.

Repeated install skips exact receipt-backed source only; untracked/modified target fails unless `--force`. MUST NOT edit `.xcodeproj`, infer target membership, add package dependencies. Xcode buildable folders ease Showcase; not assumed elsewhere.

`--plan` prints only: ordered closure (versions, kinds), target status (`new`, `up-to-date`, `modified-would-require-force`, `would-merge`), package requirements, collisions, manual steps. Recipe: native guidance only. `--diff`: `difflib` unified diff per receipt-backed owned file vs canonical, exit 0 parity, 1 diff, fails loudly if receipt missing. Neither mode mutates.

## Update policy

Copied source stays consumer-owned; `--update` distinguishes upstream/local/concurrent edits via receipt base. Concurrent: `git merge-file` behind installer. Clean merge: owned source, base advances. Conflict: files unchanged, reviewable `.merge`. Preflights full closure first; 1 conflict can't partial-update; not registry-authoritative.

## Presentation policy

3 derived surfaces, same metadata, none hand-edited. Markdown catalog (`docs/catalog/`); `Website/content/registry.json` (preview paths, install order, usage, source, requirements, accessibility, presets per item); Showcase manifest. Each: byte-exact freshness test.

Website (sidebar, tabs, toggle group, command search, cards, tables) renders JSON, 1 page/item. Contents: preview, install command, usage, source, details. No HTML committed. Item images: Showcase's `-item` launch, cropped to demo frame; same code/simulator as visual contract.

## Discovery policy

`sweetui search`: deterministic adapter over existing JSON. Filters kind/platform, requires every query term match indexed metadata, emits stable pre-install JSON.

Search stays local. `sweetui mcp`: stdio adapter, same engine; agent in a consumer searches/plans/installs without leaving editor. Hosted adapter matters if distribution, auth, or catalog scale varies independently of local metadata.

## Platform decision

V0 targeted iOS 18/iPadOS (iOS SDK); 2026-08-31 reversed to iOS 26 floor. Items inherit Liquid Glass natively, no pre-26 styling/27-only APIs. One exception, 2026-10-10: `fold-companion` reads the iPhone Duo fold (`reservedRegions`, iOS 27.1) behind `#available` and opens a sheet below it, so it runs from 26.0 but builds only with the 27.1 SDK; the `fold-arrangement` recipe declares 27.1. Evidence: iOS 27 simulator only, no iOS 26 runtime here; compile-time + 27-runtime verify floor-26. No macOS, watchOS, tvOS, visionOS declared.

## Dependency direction

```text
Foundations <- Components <- Blocks <- Flows
```

Dependencies point down only. Registry source MUST NOT import application architecture. Foundations MUST NOT import registry items.

## Rejected alternatives

- 1 monolithic UI package: undermines source ownership, progressive adoption
- Copying foundation files per item: duplicates theme contracts
- Production CLI before product slices: validates packaging over product UI. Stage 6 owner authorized the rewrite, now shipped as `sweetui`
- Generic Button, Toggle, Slider, List, navigation wrapper views: hide Apple primitives instead of native style protocols/modifiers
- Mandatory TCA, MVVM, Observation model, persistence type: leaks application architecture into presentation
