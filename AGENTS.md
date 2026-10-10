# SweetUI agent guide

## Purpose

Validate a native first, source owned, registry driven SwiftUI composition layer. Version 0 stays small.

One loop: edit `Registry/sources/` and `Registry/items/`, validate, regenerate `docs/catalog/`, reinstall into the Showcase, compile, verify visually. Everything downstream of metadata is derived. You MUST NOT hand edit it.

## Document map

Each fact has one home in four classes.

Contracts:

| File | Covers |
| --- | --- |
| this file | developing the registry |
| `docs/philosophy.md` | why |
| `docs/architecture.md` | how |
| `docs/registry-spec.md` | data and installer contract; "Agent usage" covers a consuming app |
| `docs/visual-testing.md` | visual evidence rules |
| `docs/mango.md` | the design system template |
| `docs/case-studies.md` | four apps an agent built from the registry and what the friction study found |

State: `CHANGELOG.md` alone holds what shipped and the known limitations. A status claim elsewhere is a pointer.

Generated, MUST NOT hand edit:

| Path | Holds |
| --- | --- |
| `docs/catalog/` | markdown catalog |
| `Website/content/registry.json` | site data |
| `Website/content/docs/` | changelog and contracts copied for the site's Docs pages |
| `Website/public/images/` | site captures |
| `Examples/Showcase/.../RegistryCatalogManifest.swift`, `Examples/Showcase/SweetUIShowcaseUITests/RegistryItemNames.swift` | Showcase manifest |
| `Examples/Showcase/.../UsageSnippetChecks.swift` | one `View` per installable item that compiles its `usage` snippet |
| `Sources/SweetUIDesignSurface/RegistryItemTokens.swift` | item to token map that scopes the design surface's panel |
| `docs/images/items/`, `docs/images/themes/` | captures |

`docs/images/case-studies/` holds the study apps' screens, captured once from the agents' builds. Those apps are not in the repository, so the folder is hand made and never regenerated.

Counts and per item pages live there, not in prose. `Website/` is Next.js with shadcn/ui; its hand written docs pages sit in `Website/docs/`.

Archives: 7 closed dated records (roadmap, research records, direction review, Stage 1 validation, clean room trial, CLI migration contract, handoff brief). They sit untracked in `~/Projects/swiftui-cn-local/` beside an `INDEX.md`. `CHANGELOG.md` carries what an adopter needs from them.

Conflicts: state beats archives, the later archive wins, contracts govern rules. Surface the conflict and fix the stale text. MUST NOT average.

## Boundaries

- `Sources/SweetUIFoundations/`: stable interface, design foundations only.
- `Sources/SweetUIDesignSurface/`: optional product: tuning panel, preset codec, `designSurface()`, the `registry-tokens.json` store on `swift-sharing`. Compiles only with UIKit, inert in release. Depends on foundations, never on items (native chrome). The Showcase consumes it; its tests run through the Showcase scheme, since the root package builds it empty on macOS.
- `Sources/SweetUIKit/`: SwiftUI free engine behind `sweetui` (`Sources/SweetUICLI/`): loading, the single structural validator, resolution, receipts, install and merge, search, preset codes, the MCP server, the generators. Never imports `SweetUIFoundations`. Contracts and captured fixtures: `Tests/SweetUIKitTests/`.
- `Registry/sources/components/`: source owned styles, focused modifiers, reusable compositions.
- `Registry/sources/blocks/`: source owned compositions of components.
- `Registry/items/`: metadata and the dependency graph. `Registry/preset_vectors.json` pins the codes every codec reproduces.
- `Distribution/homebrew/`: the tap's formula template. `.github/workflows/release.yml` builds the universal binary on a GitHub release. Neither is in the verification list.
- `Examples/TodoCounter/`: second consumer from a fresh Xcode project: package by URL, the Composable Architecture, 7 items installed with the released tool, a customized preset theme, 1 locally edited component. Not in the verification list; its test plan runs from its workspace.
- `Examples/Showcase/`: proves installation, integration, and the visual contracts. Components, Blocks, and Recipes tabs beside the tuning panel; item list and usage snippets from the generated manifest. Every item has a demo in `ItemDemos.swift`; `-item <name>` renders one alone for capture.
- `Skills/`: 3 agent skills, mirrored to `~/.claude/skills/`. They quote the tool's help and the catalog; regenerate them when either changes.

## Rules

- Keep raw controls and containers visible at the call site. Style protocols set appearance; a focused `ViewModifier` adds optional behavior. MUST NOT wrap an Apple control only to rename it.
- Configure views with prepared values, bindings, actions, and defaults. Use `@ViewBuilder` when a container wraps caller content in structure or chrome.
- Prefer a modifier over a parameter for an independent optional decoration or behavior.
- One home per concern:

  | Concern | Home |
  | --- | --- |
  | content, bindings, actions, required accessibility input | the initializer |
  | variant, tone, tint, a future size or emphasis | a `registry` prefixed copy and return method, before generic modifiers |
  | presentation of a native control | a `registry` style |
  | a text treatment | a `registry` modifier with a variant argument |
  | the theme | the environment |
  | sizes | Apple's `controlSize` |
  | an optional decoration outside internal layout | a `ViewModifier` |

  Example: `InlineAlert(...) { }.registryVariant(.positive)`.

- Controlled state stays with the caller through bindings. A component MAY own transient `@State` only for a self contained interaction.
- Registry source MUST NOT import app architecture, networking, or persistence libraries.
- A copied item stays understandable alone; metadata lists every source dependency.
- Use semantic tokens, not repeated hardcoded colors or metrics. Add a token only when 2 real items need it.
- A treatment stays source owned until 2 items share it exactly; only then consider foundations.
- Respect environment values and layout proposals: Dynamic Type, color scheme, layout direction, enabled state, flexible parent sizing. MUST NOT hardcode one context.
- Require accessibility input that visible content cannot supply. An icon only control's label MUST NOT be optional.
- Preview every meaningful variant, including dark appearance and an accessibility Dynamic Type size.
- A new reusable abstraction needs 2 concrete consumers or named roadmap usages.
- Every installable component or block needs a version, preview, accessibility notes, platform metadata, and a compile path. A `recipe` installs nothing: empty `files`, non empty `docs`, no preview. No installable item MAY depend on a recipe (value gate, `docs/registry-spec.md`).
- Every installable item applies `.registryItem("<name>")` once, last in its root view's or style's chain. A recipe carries the tag in its `usage` snippet instead, unless that snippet's root is a `Scene`. For an item exposed through an extension, that chain is a private modifier's `body`. The tag is foundations API, inert without a surface. The validator rejects a foundations dependent item whose first source lacks it.
- Every item needs a non empty `usage` snippet quoted from its canonical public API, never from memory. A recipe reuses the native snippet from its `docs`.
- Five generators, five outputs:

  | Command | Output |
  | --- | --- |
  | `swift run sweetui generate catalog` | `docs/catalog/` |
  | `swift run sweetui generate site-data` | website data |
  | `swift run sweetui generate showcase-manifest` | Showcase manifest |
  | `swift run sweetui generate item-tokens` | item to token map |
  | `swift run sweetui generate usage-checks` | Showcase usage-snippet checks |

  `item-tokens` scans each item's sources and dependency closure for the theme fields they read. `usage-checks` wraps each installable item's `usage` snippet in a `View` so a snippet naming an undeclared symbol fails the Showcase build; the names a snippet leaves to the adopter live in the hand-written `UsageSnippetPlaceholders.swift`. Regenerate all five after any metadata or source change; `generatedOutputsMatchCanonicalBytes` in `Tests/SweetUIKitTests/GeneratorTests.swift` rejects drift byte for byte. `Website/app` is hand written React over that JSON and `Website/content/docs/`; `npm run build` in `Website/` exports it statically.

- Item screenshots come from `python3 Scripts/capture_previews.py` on the pinned simulator, never hand made. Recapture after a visible change, then regenerate the catalog and site.
- MUST NOT regenerate a visual reference merely to pass a test (`docs/visual-testing.md`).
- Add a dependency only when a vertical slice proves it necessary.
- `Sources/SweetUIKit/Validation.swift` is the only place that enforces registry structure (Validation, `docs/registry-spec.md`).

## Environment pins

| Pin | Value |
| --- | --- |
| visual contract and UI tests | light mode iPhone 17, iOS 27.0, UDID `1807166B-C557-4F6B-B177-D5F3F701CBD7` (`docs/visual-testing.md`) |
| capture launch arguments | `-AppleLanguages (en) -AppleLocale en_US` |
| wide block captures | iPad Pro 13 inch, also `en_US` (`ar_SA` until 2026-09-06) |
| toolchain | Xcode 27.0, Swift 6.4 |
| CI | GitHub `macos-26` image, default Xcode 26.6, Swift tools 6.2 (`.github/workflows/ci.yml`) |
| package identity | `sweetui` at `github.com/mangobyte-dev/sweetui` |
| published tags | `0.1.0` (2026-09-06), `0.2.0` (2026-09-07), `0.3.0` (2026-09-09), `0.3.1` (2026-09-13), `0.4.0` (2026-09-19), `0.5.0` (2026-09-29), `0.5.1` (2026-10-05), `0.6.0` (2026-10-10), each with a GitHub release; each but `0.5.1` with the Homebrew tap |

The launch arguments keep dates, currency, and the calendar in an image independent of the region; the iPad's status bar date comes from the device, hence its pin. No iOS 26 runtime is installed. A floor 26 claim rests on compilation plus iOS 27 runtime evidence. CI runs the registry gate, the website build, and a secret scan on every push and pull request. `0.5.0` renames the package, products, modules, and tool to SweetUI. Every installable item therefore declares the `0.5.0` floor (`docs/registry-spec.md`).

## Verification

Run from the root, cheapest first:

```sh
swift build
swift run sweetui validate
swift run sweetui generate catalog
swift run sweetui generate showcase-manifest
swift run sweetui generate site-data
swift run sweetui generate item-tokens
swift run sweetui generate usage-checks
git diff --exit-code -- docs/catalog Examples/Showcase Website/content Sources/SweetUIDesignSurface/RegistryItemTokens.swift
swift test
make format-check
swift run sweetui search nutrition dashboard --kind block --platform iOS --target-version 26.0
swift run sweetui install finance-overview --destination Examples/Showcase/SweetUIShowcasePackage/Sources/SweetUIShowcaseFeature/Installed --force
swift run sweetui install nutrition-overview --destination Examples/Showcase/SweetUIShowcasePackage/Sources/SweetUIShowcaseFeature/Installed
xcodebuildmcp simulator build --workspace-path Examples/Showcase/SweetUIShowcase.xcworkspace --scheme SweetUIShowcase --simulator-name 'iPhone 17'
xcodebuildmcp simulator test --workspace-path Examples/Showcase/SweetUIShowcase.xcworkspace --scheme SweetUIShowcase --simulator-id 1807166B-C557-4F6B-B177-D5F3F701CBD7
(cd Website && npm ci && npm run typecheck && npm run build)
```

Scope to the change: metadata only stops after `make format-check`; registry source needs the install and compile steps; only a visible UI change needs the simulator test; a change under `Website/` needs the typecheck and build. `swift test` needs `git` and Node 22 on PATH (`git merge-file`; `Website/lib/preset.ts` under `node --experimental-strip-types`). A visible item change also needs `python3 Scripts/capture_previews.py <item>`, then the four generators. That is the one remaining Python script; it lists items through the built tool. A change is incomplete if generated source differs from registry source or any command fails. Name a skipped step in the done claim.
