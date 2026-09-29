# MANGO

MANGO: MangoByte's sample design system, a team-brand template for the registry. Order: domain, conceptual model, surface (Layers of Product Design); model first, most neglected.

## Goal

Pain points, MANGO's answer:

- Drift: one `RegistryTheme` via `registryTheme(_:)` at scene root, tokens from environment (docs/architecture.md, Foundations)
- Agent drift: `usage` snippets, `sweetui mcp`, skills (docs/registry-spec.md, Agent usage)
- No `MaterialTheme` equivalent: `RegistryTheme` plus preset code (docs/registry-spec.md, Preset codes)
- `Color`-extension trap: tokens on theme value, never statics (Sources/SweetUIFoundations/RegistryTheme.swift)
- Unmaintained libraries: source ownership plus receipt, foundations pinned `upToNextMinor` from 0.5.0, `--diff`/`--update` (docs/architecture.md, Installation behavior and Update policy)
- Sameness: Create studio, MANGO as worked brand

## Domain

MANGO stands in for banking-adjacent, Kuwaiti, bilingual Arabic/English client work. Right-to-left MUST be first-class (docs/philosophy.md, Accessible and adaptive by default). Brand guidelines pin accent, surfaces, radii, spacing; controls stay Apple's.

Brand: warmth, generosity, calm. Accent once per screen. Radii, spacing generous. Strokeless surface reads as depth.

## Conceptual model

Five parts:

- Theme value: `RegistryTheme`, small `Sendable` struct (Sources/SweetUIFoundations/RegistryTheme.swift): optional `accent`, `onAccent`, `surface`, `border`, `positive`, `negative`, `disabledOpacity`, `RegistryMetrics`
- Environment: `@Entry` injects it; apply once via `registryTheme(_:)`; tints Apple controls when accent set (docs/architecture.md, Foundations)
- Presets: plain `static let` starts (`system`, `graphite`, `indigo`, `rose`, `emerald`, `amber`), no theme engine; MANGO adds `mango`
- Code: theme as shareable `--preset` string; tool, Showcase, website, MCP server read/write it (docs/registry-spec.md, Preset codes)
- Owned copies: copied in, receipt-tracked, edited in place, `--diff`-audited (docs/architecture.md, Installation behavior)

Not an item kind: `RegistryTheme+App.swift` carries no receipt entry, installer-untouched (docs/registry-spec.md, "The theme file is not a registry item"). shadcn ships `registry:theme` items; CSS variables need files, Swift doesn't.

## Surface

### Tokens

Light/dark pair per color; unlisted values inherit `RegistryMetrics`/`RegistryTheme` defaults (Sources/SweetUIFoundations/RegistryTheme.swift):

| Token | Value | Why |
|---|---|---|
| accent | light `#FFA033`, dark `#FFB84D` | readable on black |
| onAccent | `.black` (`darkLabelOnAccent: true`) | `amber` precedent, line 124 |
| surface | `.primary.opacity(0.07)` | luminance-step depth |
| border | `.primary.opacity(0)` | strokeless; kept for shadcn parity and hairline themes |
| borderWidth, emphasizedBorderWidth | 1, 2 | unchanged |
| compactRadius, controlRadius, cardRadius | 10, 14, 24 | generous, rounded-type pair |
| compactSpacing, standardSpacing, sectionSpacing | 8, 16, 28 | more air |
| controlHorizontalPadding | 16 | wider controls |
| disabledOpacity | 0.4 | stronger dimming |
| positive, negative | `.green`, `.red` | defaults, uncoded |

### Typography

`.fontDesign(.rounded)` once at scene root; not a theme field, code unchanged. Every changing value carries `.monospacedDigit()`.

### Motion

From Emil Kowalski's `apple-design` skill (an outside-skill example):

- Damping/response, not duration: default `.spring(response: 0.4, dampingFraction: 1.0)`, critically-damped; `0.8` only after gesture momentum (§4, "Behavior over animation")
- Feedback on press, not release: button scales to 0.97 on `isPressed` (§1, "Response")
- Reduced motion as cross-fade: `accessibilityReduceMotion` swaps `.opacity` cross-fades, no movement (§14, "Reduced motion and accessibility")

### The MANGO preset code

Never type the code by hand: write the `RegistryTheme` value, run `sweetui preset resolve <path>`, or encode via SweetUIKit's `Preset` (docs/registry-spec.md, Preset codes). MANGO's code: `a74hGF01CVunaG0vzZJG`, pinned in `Registry/preset_vectors.json`; all three codecs reproduce it byte-for-byte.

## Do the same for your brand

1. `sweetui preset apply <code> --destination <dir>` writes `RegistryTheme+App.swift` (`RegistryTheme.app`; apply once at scene root)
2. Edit accent, radii, surface, spacing
3. `sweetui preset resolve <path>` prints new code (never trusts file header)
4. `sweetui install <item> --destination <dir>` copies source, writes `.sweetui/receipt.json`
5. Edit owned copy
6. `sweetui install <item> --diff --destination <dir>` prints unified diff (exit 0 parity, 1 differences)
7. `sweetui install <item> --destination <dir> --update` merges upstream via `git merge-file`, keeps edits, `.merge` only on real conflict
8. Share: Create page at `?preset=<code>`; Showcase's Copy Code or Import

## What MANGO customized in the Showcase

Canonical items under `Examples/Showcase/SweetUIShowcasePackage/Sources/SweetUIShowcaseFeature/Installed/`, byte-identical to registry source (`--diff`, generator freshness tests; docs/architecture.md, Installation behavior and Presentation policy). MANGO's copies sit beside them under `.../Mango/`, renamed, header per copy names item, version, edits:

- `MangoButtonStyle`: `button` style plus MANGO's motion (press scale 0.97, critically-damped spring; cross-fade under Reduce Motion)
- `MangoMetricCard`: `metric-card` with `.monospacedDigit()` on its changing value

Renamed: the Showcase consumes untouched originals under `Installed/` too (one target, two types, no shared name). A consumer app has its copy, edited in place, diffed with `--diff` (docs/architecture.md, Installation behavior; Examples/TodoCounter/README.md, `RegistryBadge`).
