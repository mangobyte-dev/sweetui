# Registry specification version 1

Schema: `Registry/schema.json`, `JSON`: inspectable, widely supported, no `Swift` tool needed

## Registry index

`Registry/registry.json`: `schemaVersion` (`1`), `name` (registry name), `items` (relative paths, item documents)

## Item fields

- `schemaVersion`: compatibility number
- `version`: semantic, provenance
- `name`: kebab-case install name
- `kind`: `component`, `block`, `flow`, `recipe`
- `description`: one-sentence product purpose
- `usage`: compiling public-API snippet; optional in v1, required here; installables quote source, recipes reuse `docs`
- `docs`: optional markdown guidance, required non-empty for `recipe`
- `files`: source + target filename, empty for `recipe`
- `registryDependencies`: items resolved first
- `packageDependencies`: package/product/version MUST provide, MAY add `sourceURL`; requirement needs `swiftPM` rule
- `platforms`: platform + min version
- `tags`: discovery terms only
- `aliases`: missed search terms (`dropdown`, `modal`, `loading`), ranked between name/tag hit, from observed misses only
- `accessibility`: behavior, requirements
- `preview`: source file + preview name required, screenshots optional; `recipe`: screenshots only, no source/name

## Item value gate

Installable `component`/`block` MUST add treatment beyond native API; native-modifier-only guidance ships as `recipe` (one-line native-style alias, preview-only example)

`recipe`: native guidance, not installable: `files: []`, guidance in `docs`; discovery, platform, accessibility metadata kept. Resolving/installing fails loudly (prints `docs`, exits `2`). Installable MUST NOT depend on one

A recipe's `usage` SHOULD end its primary root with `.registryItem("<name>")`, so a consumer who copies it can select the recipe on the design surface; the recipe then declares the foundations package dependency, and `registryDependencies` for any registry item its snippet uses. A snippet whose root is a `Scene` (`menubar`) carries no tag: `registryItem` is a View modifier. Tokens for a recipe come from its snippet and those dependencies, so a native-only recipe scopes to none and the panel hides every scoped section

## Resolution

Depth-first, deterministic declaration order, installs once. Fails loudly: unknown items, cycles, missing source, duplicate targets, unsafe paths, untracked collisions, modified receipt-backed targets

## Validation

`Sources/SweetUIKit/Validation.swift`: single structural validator, checks:

- schema constraints: required keys, types, enums, undeclared keys, recipe conditionals
- index completeness both directions
- source/preview file existence
- dependency closure: unknown items, cycles, recipe-as-dep
- numeric platform floor format
- package dependency shape
- non-empty `usage`
- design-surface root tag

Item depending on `SweetUIFoundations` MUST apply `.registryItem("<name>")` in first source file: surface selects by tag, missing tag hides item from `Select`

Same validator: installer (pre-resolve), search, `MCP` server, generators. `sweetui validate` runs standalone, exits `0`/`1`, scoped to items/closures. `ValidationTests.swift` proves each defect rejected, issues in `Fixtures/validation-cases.json`. Unenforced: not in validator

## Generated catalog

`docs/catalog/`: from `sweetui generate catalog`, one page per item + kind-grouped index. Page:

- description
- lead screenshot + alternate links
- install command + package requirement (recipe: `"Nothing to install. Copy the snippet below"`, no `Install` heading)
- `usage` snippet
- recipe's `"Why native is enough"` guidance (`docs`)

`Details` list: kind, version, platforms, deps/install order, accessibility contract, source link + preview name

No timestamps: byte-stable, `GeneratorTests.swift` asserts equality. MUST NOT hand-edit, edit item + regenerate

## Generated website data and Showcase manifest

`Sources/SweetUIDesignSurface/RegistryItemTokens.swift` (`generate item-tokens`): per component/block, sorted `RegistryTheme`/`RegistryMetrics` fields the sources + dependency closure read (`theme.<field>`, `theme.metrics.<field>`, + foundations' `registrySurface(level:)`/`surface(at:)`). Scopes design-surface panel per item. MUST NOT hand-edit

`Website/content/registry.json` (captures to `Website/public/images/`) from `generate site-data`; `RegistryCatalogManifest.swift`/`RegistryItemNames.swift` from `generate showcase-manifest`. Both validated-path, deterministic, byte-equal to checked-in files

`UsageSnippetChecks.swift` (`generate usage-checks`): one `View` per installable item wrapping its `usage` snippet, so a snippet naming an undeclared symbol fails the Showcase build. Names a snippet leaves to the adopter are stand-ins in the hand-written `UsageSnippetPlaceholders.swift`. Deterministic, byte-equal, MUST NOT hand-edit

`Next.js` site (`Website/`) reads only that `JSON`. Page: preview, install command, `usage`, then full source + accessibility contract. `python3 Scripts/capture_previews.py` produces `preview.screenshots`

## File ownership

Target path relative to destination; v1: no groups, targets, module names, project-file mutation. After copy, consumer owns target file: registry is provenance, not remote authority

Installer stores provenance under `.sweetui/`. `receipt.json` records item versions, registry/package deps (`swiftPM` rule at install-time), content digests, targets, base snapshot paths. Base/conflict artifacts use non-`Swift` extensions, avoiding duplicate declarations

## Package dependencies

Prototype reports deps via metadata, doesn't install: avoids unsafe `.xcodeproj` mutation, keeps approval consumer-side

Entry: `sourceURL` (location), `swiftPM` (requirement); `kind`: `upToNextMinor`/`upToNextMajor`/`exactVersion`/`range`, all with `minimumVersion`, `range` adding `maximumVersionExclusive`. Validator rejects version requirement lacking `swiftPM`. Install prints package URL, requirement, product, records receipt entries

## Compatibility policy

Pre-1.0 foundations evolve by minor version. `0.minor.patch`: patch stays source-compatible; minor MAY change contract, items pin `upToNextMinor` from known-good floor. Source verified against platform floor + foundation range; receipt records install-time requirement

`SwiftUIRegistryFoundations` 0.1.0 (`SweetUIFoundations` from 0.5.0): initial contract, tagged 2026-09-05 (commit introducing accent/onAccent tokens); resolves once pushed

## Evolution rules

- MAY add optional fields within v1
- Field removal/meaning-change MUST use new schema version
- Item API evolution MUST NOT silently overwrite copied code
- Receipts identify source + installed content, not item name
- Modified-file update needs clean three-way merge or explicit conflict review

## Preset codes

Preset code: `RegistryTheme` as shadcn's `--preset` counterpart. `a13GkaOXWwIF` = `Indigo` preset

- ref: `Preset.swift` (`SweetUIKit`), `sweetui preset`
- reproduced by `Website/lib/preset.ts` (`Create`) + Showcase `ThemePreset.swift` (`Copy Code`, `Import`, `-preset <code>`)
- `Registry/preset_vectors.json` pins codes; all three MUST match byte-for-byte
- checked by `PresetTests.swift`/`PresetContractTests.swift` (`SweetUIKit` + `Node`/`TypeScript`); Showcase's `ThemePresetTests`

Version `a`: version letter + base62 (`0-9A-Za-z`) little-endian packed-knob integer. Fields, `name (bits: range/step or enum)`:

- `accent (4: system|ink|blue|indigo|purple|pink|red|orange|yellow|green|mint|teal|cyan|brown|custom)`
- `darkLabelOnAccent (1)`
- `surfaceOpacity (6; 0-0.2/0.005)`
- `borderOpacity (5; 0-0.3/0.01)`
- `borderWidth (3; 0.5-3/0.5)`
- `emphasizedBorderWidth (3; 1-4/0.5)`
- `compactRadius (4; 0-12)`
- `controlRadius (5; 0-22)`
- `cardRadius (6; 0-32)`
- `compactSpacing (4; 4-16)`
- `standardSpacing (5; 8-32)`
- `sectionSpacing (6; 12-48)`
- `controlHorizontalPadding (5; 8-24)`
- `disabledOpacity (4; 0.2-0.8/0.05)`

`61` bits. Numeric: snapped slider-grid index. Custom accent: +24 `RGB` bits +flag, set adds +24 dark-accent bits. `positive`/`negative`/environment switches MUST NOT appear

Rules:

- MUST NOT reorder/resize field, append-only, default index 0
- new fields after custom-accent block
- out-of-range index invalidates code, MUST NOT clamp
- decoders MUST ignore unknown bits (forward-tolerance)
- `a` code: max 22 chars; rule change needs new version letter

Format `b`: Create studio appends fields after `a` block, `a`-decodable, default `b` fields encode to `a` code. Base62, arbitrary-width; `b` code exceeds 128 bits. After `a` layout + custom-accent:

- `fontDesign (2: default|rounded|serif|monospaced)`
- `surfaceStep (3: 0.02/0.00/0.01/0.03/0.04/0.05/0.06/0.07, default 0)`
- `chartPalette (2: accent|spectrum|monochrome; index 3 rejected)`
- 3 color pairs (`background`/`foreground`/`secondaryForeground`): flag bit; set adds 24 light-RGB bits, dark flag, +24 dark-RGB bits if set

Decoded `b`: `fontDesign`/`surfaceStep`/`chartPalette` + `background(Dark)`/`foreground(Dark)`/`secondaryForeground(Dark)` (`#RRGGBB`/`null`). Decoded `a`: none, defaults. Max 48 chars. Custom font family: `Swift` export + theme package only, never in code

`CLI`:
- `preset apply <code> --destination <path>`: writes `RegistryTheme+App.swift` (`RegistryTheme.app`, scene-root use); replaces only if header resolves to code (`--force` overrides)
- `resolve <path>`: parses initializer to code, ignoring header
- `decode <code>`: prints knobs/`Swift`/`URL`
- `MCP`: `describe_preset`/`apply_preset`; not registry item: no receipt, installer-ignored

Design tokens: `SweetUIDesignSurface` (optional) keeps tuning as `registry-tokens.json` in `Documents`, `@Shared(.designTokens)` (swift-sharing)

- `code`/`version`: preset-code knobs
- `tuning`: keys from `preset decode --json` (always present, colors `#RRGGBB`)
- `environment`: appearance, text-size, direction (never in code)
- forgiving reads: `tuning` MAY name subset over defaults; `code`-only document loads that code
- wrong code/color/accent refused, not guessed (`ThemeTuning+File.swift`, `DesignTokensFileTests`)
- `code` feeds `preset apply`/`apply_preset`, same non-registry status

Since Stage 9, two more files:

- `design-knobs.json`: per-item numeric knobs, host-registered via `designSurface(knobs:)`, read via `registryKnob(_:_:default:)`. Keyed item then knob, only non-default values
- host's `TokenDocument`: app declares knob pages, named by document. Surface reapplies it after every change

## Agent usage

Lookup order (`docs/architecture.md`): `--registry <path>`, enclosing clone, cached pinned-release snapshot (fetched from published tag, first use)

Agent steps:

1. search metadata by name/kind/tags/platform/min version (`sweetui search`)
2. read dependency closure + package requirements
3. read usage snippet, accessibility notes, deps, requirements, source (`sweetui describe <item>`)
4. preview install (`sweetui install <item> --plan --destination <path>`): read-only, prints closure, target statuses, requirements, collisions, manual steps, writes nothing
5. install item sources
6. compose via public initializer. MUST NOT rewrite from memory
7. compile consumer at deployment floor
8. before `--update`, audit owned source (`sweetui install <item> --diff --destination <path>`): needs receipt, exits `0` parity / `1` diffs

Same steps as `MCP` tools (`sweetui mcp`, `stdio`): `search_items`, `describe_item`, `plan_install`, `diff_item`, `install_item`, `describe_preset`, `apply_preset`. `MCPTests.swift` pins wire shape (inline snapshots); `MCPContractTests.swift` drives registry
