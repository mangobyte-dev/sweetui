---
name: sweetui-theming
description: Theme a SwiftUI app on the registry with RegistryTheme, the seven presets, preset codes, the MANGO sample design system, and the Create studio, using the sweetui preset commands.
metadata:
  short-description: Presets, preset codes, MANGO, and the Create studio.
---

# SweetUI theming

## Goal

One `RegistryTheme` at scene root gives coherent brand. Preset code survives copy-paste. MANGO: system to extend.

Two pain points (`docs/mango.md`):

- Drift: rebuilt primitives, different padding/radii/color each sprint. One `RegistryTheme` fixes it.
- Sameness: apps converge on one skin; preset code, Create studio, MANGO give distinct looks.

## Quick start

1. Apply a preset at scene root: `ContentView().registryTheme(.graphite)`.
2. Decode: `sweetui preset decode a13GkaOXWwIF`.
3. Write into app: `sweetui preset apply a13GkaOXWwIF --destination path/to/YourApp`.
4. Apply: `ContentView().registryTheme(.app)`.
5. Read back to code: `sweetui preset resolve path/to/YourApp/RegistryTheme+App.swift`.

## API interface

- Theme, metrics, presets, root modifiers: `references/foundations-interface.md` (shared `SweetUIFoundations.swiftinterface`)
- Preset code layout, versions `a` and `b`: `references/preset-format.md`
- MANGO design system, build-your-own steps: `references/mango.md` (pointer to `docs/mango.md`)

Quote every API, code from these, never memory; codes come from codec, never hand-typed.

## How to apply a theme once at the root

`RegistryTheme`: set-up-once contract. Items inherit accent, surfaces, borders, metrics; Apple controls follow accent via tint.

1. Seven presets: `system`, `graphite`, `indigo`, `rose`, `emerald`, `amber`, `mango`. Apply at root: `ContentView().registryTheme(.mango)`.
2. `.system` inherits app tint in place; others declare accent, tint subtree.

- **DO** apply once, before scene appears; tokens flow via environment.
- **DO NOT** toggle accent nil/value at runtime: `tint(nil)` resets, not inherits, resetting subtree. Use `Color.accentColor`, not `nil`.
- **DO NOT** define tokens as `Color` statics; they live on the theme value.

## How to pick a preset and read its code

A preset code is one short `RegistryTheme` string; tool, Showcase, website, MCP read/write it.

1. `sweetui preset decode a13GkaOXWwIF`: code, version, accent, ..., website URL.
2. `--json`: machine-readable knobs, same payload as MCP `describe_preset`.
3. `preset url a13GkaOXWwIF`: just the URL.

- **DO** treat the code as portable: `a13GkaOXWwIF` = Indigo preset, foundation metrics; never hand-assemble characters, decode it.

## How to write a code into an app

`preset apply` turns a code into `RegistryTheme+App.swift`; not a registry item, no receipt.

1. `sweetui preset apply a74hGF01CVunaG0vzZJG --destination path/to/YourApp` writes:

   ```swift
   import SwiftUI
   import SweetUIFoundations
   import UIKit

   // sweetui preset a74hGF01CVunaG0vzZJG
   // https://sweetui.dev/create?preset=a74hGF01CVunaG0vzZJG
   // Written by `sweetui preset apply`. Edit freely; `sweetui preset resolve` reads it back into a code.

   extension RegistryTheme {
       /// Apply once at the scene root: `ContentView().registryTheme(.app)`.
       static let app = RegistryTheme(
   ```

2. Apply at root: `ContentView().registryTheme(.app)`.
3. Edit initializer in place; it's your source now.
4. `preset resolve path/to/YourApp/RegistryTheme+App.swift` reads it back to a code.

- **DO** edit the theme freely; `resolve` parses the initializer, never trusting a hand-typed header.
- **DO** pass `--force` to replace an edited file; else it replaces while resolving to header's code.

## How to build a brand the MANGO way

MANGO is the template for `docs/mango.md`'s Layers order.

1. Domain (audience), Conceptual model (theme value, environment, presets, code, owned copies), Surface (tokens, typography, motion).
2. MANGO `RegistryTheme`: mango accent (light/dark pair), `onAccent: .black`, `surface: .primary.opacity(0.07)`, `border: .primary.opacity(0)`. Radii 10/14/24, spacing 8/16/28, padding 16, disabled 0.4.
3. `.fontDesign(.rounded)` at root; `.monospacedDigit()` on changing values.
4. Motion: default `.spring(response: 0.4, dampingFraction: 1.0)`; `dampingFraction: 0.8` after momentum only. Press: scale 0.97 on `isPressed`. Cross-fade `.opacity` under `accessibilityReduceMotion`.
5. `preset resolve` reads the code back; MANGO's is `a74hGF01CVunaG0vzZJG`, pinned in `Registry/preset_vectors.json`.

- **DO** keep customized items as owned copies, receipt-tracked; header names item, version, edits. MANGO: `MangoButtonStyle`, `MangoMetricCard`.
- **DO NOT** add a `theme` item kind.

## How to use the Create studio and the tuning panel

Create studio, Showcase tuning panel: the theme creator; a slider move updates open demo.

1. Create page at the code's URL: CSS token board, capture (six presets); `?preset=<code>` on website.
2. Showcase: tap Tune in accent strip; slide, Copy Swift (initializer), Copy Code (preset code), or Import.
3. Export tab: `RegistryTheme+App.swift`, `THEME.md`; copy buttons, no downloads.

- **DO NOT** expect Create to render SwiftUI.

## How to tune on device with the design surface

The agent's pass MUST see tuning, not Showcase. `SweetUIDesignSurface` puts panel in app's debug build.

1. Link: `.product(name: "SweetUIDesignSurface", package: "sweetui")`.
2. Apply inside the theme call:

   ```swift
   import SweetUIDesignSurface

   ContentView()
       .designSurface()
       .registryTheme(.app)
   ```

   Debug: floating Tune button; release: unchanged.
3. Copy Code/Swift: preset code/initializer; `registry-tokens.json` in Documents holds both; simulator: `cat "$(xcrun simctl get_app_container booted <bundle id> data)/Documents/registry-tokens.json"`.
4. Select, tap an item: panel scopes to its tokens (`RegistryItemTokens`); All tokens restores full theme.
5. Agent push: write `{"code": "a74hGF01CVunaG0vzZJG"}`; surface loads it.
6. Own tokens: conform to `TokenDocument` (value, file name, `.number`/`.choice`/`.color` knobs, `apply()`). `designSurface(tokens: MyTokens.self, knobs: ["button": [ItemKnob("padding", in: 0...32, shipped: 12)]])`; panel gains App tokens, item knobs. Read via `environment.registryKnob("button", "padding", default: 12)`.

- **DO** feed `code` to `preset apply` or MCP `apply_preset`.
- **DO NOT** apply `designSurface()` outside `registryTheme(_:)`; inner theme wins.
- **DO NOT** add to an item-only app; pulls swift-sharing in.

## How to use the version b fields

`Registry/preset_vectors.json`: `version: "b"`, `maxLength: 48`. Version `b` appends fields after `a`; every `a` code still decodes.

1. `preset decode b3nbXHeB3DzH`: version `b`, ..., `fontDesign` rounded, `surfaceStep` 0.02, `chartPalette` accent, `background`/`foreground`/`secondaryForeground` none.
2. Appended, in order: `fontDesign` (default, rounded, serif, monospaced), `surfaceStep` (elevation-ladder step), `chartPalette` (accent, spectrum, monochrome). Optional light/dark pairs for `background`, `foreground`, `secondaryForeground`.

- **DO** expect a default `b` tuning to encode as `a`; `b` only when field or pair leaves default.
- **DO NOT** carry a font family in code; it lives in Swift export, theme package.
