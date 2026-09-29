<!-- Reference for the sweetui-theming skill. Quoted verbatim from the "Preset codes" section of docs/registry-spec.md (the data and installer contract). Do not hand-edit; the contract in docs/registry-spec.md governs, and this copy is refreshed when it changes. -->

# Preset code format

Quoted from `docs/registry-spec.md`, "Preset codes".

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
