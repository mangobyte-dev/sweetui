---
name: sweetui-authoring
description: Add an item to SweetUI under AGENTS.md's rules: decide the kind against the value gate, write the source and the item JSON, then validate, install into the Showcase, capture, regenerate, and run the UI suite.
metadata:
  short-description: Author a registry item under the project's rules.
---

# SweetUI authoring

## Goal

Add component, block, or recipe (`docs/mango.md`: concepts first).

- Value gate + two-consumer rule stop redundant wrappers (`docs/registry-spec.md`; `docs/philosophy.md`).
- One validator, receipts, byte-exact outputs, `--diff`/`--update` keep auditable (`docs/architecture.md`).

Read `AGENTS.md` first: skill's contract.

## Quick start

1. Decide kind against the value gate.
2. Source: `Registry/sources/components/` or `Registry/sources/blocks/` (recipe: none).
3. Item: `Registry/items/`, add to `Registry/registry.json`.
4. Run `references/checklist.md`, cheapest first.

## API interface

- Item schema: `references/item-schema.md`
- Rules, why: `references/agents.md`
- Verification list: `references/checklist.md`
- `usage` MUST quote canonical source, never memory (`AGENTS.md`).

## Deciding the kind

MUST add reusable treatment beyond native API.

1. `component`: no native iOS control, or reusable style, modifier, small composition.
2. `block`: composes items into architecture-neutral, screen-sized composition installed whole.
3. `recipe`: one-line Apple API entire; `files: []`, guidance in `docs`; exit code 2 if installed.

- **DO** ship Apple-control rename as recipe, not component (`README.md`).
- **DO NOT** let installable item depend on recipe (guidance, not source).

## Writing the source

SwiftUI controls visible at call site; standardize via style protocols, modifiers (`docs/philosophy.md`).

1. Initializer: content, bindings, actions, accessibility input. Presentation: `registry`-prefixed copy-and-return: `InlineAlert(...) { }.registryVariant(.positive)`. Controls: `registry` style; text: `registry` modifier+variant; theme: environment; size: `controlSize`.
2. Theme values: environment. Semantic token: two-item need; style: source-owned till shared.
3. Controlled state via bindings; own transient `@State` only if self-contained.
4. Non-derivable accessibility input; icon-only label MUST NOT be optional.
5. Preview every variant: default, dark, accessibility Dynamic Type, RTL.

- **DO** support Dynamic Type, color scheme, layout direction, enabled state, flexible sizing.
- **DO NOT** import app architecture, networking, or persistence into source.
- **DO NOT** apply registry styles/`registrySurface` to toolbars, tab bars, floating chrome; use `.buttonStyle(.glass)`/`.glassProminent`.

## Writing the item JSON

Names, files, dependencies, platforms, accessibility, previews, `usage`: explicit metadata.

1. Required keys: `schemaVersion` (1), `version`, `name` (kebab-case), `kind`, `description`, `files`, `registryDependencies`, `packageDependencies`, `platforms`, `tags`, `accessibility`.
2. Non-empty `usage` quoting real public API; recipe reuses `docs` snippet.
3. Declare every dependency, incl. preview-only, in `registryDependencies` (once missed: `item` needed `avatar`).
4. `preview` (source file, Xcode preview name); recipe: `screenshots` only.
5. Package needs actionable `swiftPM` rule (else rejected); add path to `Registry/registry.json`.
6. `aliases` only from observed search miss, not thesaurus.

- **DO** `docs` non-empty, `files` empty (recipe); `files` non-empty, `preview` present (component/block; `allOf`).
- **DO NOT** add structural check anywhere but `Sources/SweetUIKit/Validation.swift`.

## Validate, install, capture, regenerate

Everything downstream, metadata-derived; byte-exact test rejects drift.

1. `swift run sweetui validate`
2. Install into Showcase:

   ```sh
   swift run sweetui install <name> --destination Examples/Showcase/SweetUIShowcasePackage/Sources/SweetUIShowcaseFeature/Installed
   ```

   `--force` only if Showcase already owns item.
3. Register demo in `ItemDemos.swift`; `-item <name>` renders alone.
4. Capture pinned simulator, regenerate all five:

   ```sh
   python3 Scripts/capture_previews.py <name>
   swift run sweetui generate catalog
   swift run sweetui generate showcase-manifest
   swift run sweetui generate site-data
   swift run sweetui generate item-tokens
   swift run sweetui generate usage-checks
   ```

5. `git diff --exit-code -- docs/catalog Examples/Showcase Website/content Sources/SweetUIDesignSurface/RegistryItemTokens.swift`, then `swift test`, `make format-check`.

- **DO** keep `Installed/` byte-identical; MANGO's renamed edits live under `Mango/` (`docs/mango.md`).
- **DO** start demo on item's named feature.
- **DO NOT** hand-edit `docs/catalog/`, `Website/content/`, Showcase manifest, or `RegistryItemTokens.swift`; regenerate.

## UI suite on both destinations

Publishable: installs, compiles at floor, passes demo-walk accessibility audit both classes.

1. Build, run suite on iPhone 17, iOS 27, UDID `1807166B-C557-4F6B-B177-D5F3F701CBD7`:

   ```sh
   xcodebuildmcp simulator test --workspace-path Examples/Showcase/SweetUIShowcase.xcworkspace --scheme SweetUIShowcase --simulator-id 1807166B-C557-4F6B-B177-D5F3F701CBD7
   ```

2. Repeat: iPad Pro 13-inch, en_US; pixel comparison gated iPhone.

- **DO** run after visible change. Checks: focus order, disabled states, validation copy, empty/placeholder states, RTL mirroring, accessibility-size typography, visual references.
- **DO NOT** regenerate visual reference to pass test; follow `docs/visual-testing.md`.

## Fresh-context verifier catches

Misses from Stage 7 catalog build:

1. Preview-only dependency missing `registryDependencies`: compiles in Showcase, fails clean install.
2. Capture missing item's named feature: demo doesn't start there.
3. Scene-level snippet needs compile-only `Scene` in demo to prove compiling.
4. New item not updating counts and recipe-name set pinned in `Tests/SweetUIKitTests/RegistryContractTests.swift`.

- **DO** re-read `AGENTS.md` item by item before done-claim; name skips in-sentence.
- **DO NOT** claim done if generated differs registry, or `references/checklist.md` command failed.
