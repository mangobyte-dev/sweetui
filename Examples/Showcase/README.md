# Showcase sample app

Universal iOS app: compile/integration/visual consumer for registry; tune every item.

Feature package depends only on `SweetUIFoundations`; `sweetui install` copies components/blocks into `Sources/SweetUIShowcaseFeature/Installed/`, receipt/non-Swift snapshots: `.sweetui/`.

## What it shows

- Components, Blocks, Recipes: searchable list per kind (`RegistryCatalogManifest.swift`); demo, install command, usage snippet, details; `ItemDemos.swift` compiles each item's real usage snippet
- Tuning panel: Tune opens floating card, tool's own window; every foundation token live-tunable (presets, appearance, text size, right-to-left); Copy Swift: `RegistryTheme`, paste once at app root; applied at catalog root (adoption pattern)

## Launch arguments

- `-item <name>`: one demo alone; `-appearance dark`, `-theme <preset>`, `-capture-info <path>`: `Scripts/capture_previews.py`
- `-default-tuning`: skips persisted tuning; UI suite always passes it
- `-stage-one`: Stage 1 fixture; `-accessibility-size`, `-right-to-left`, `-empty-finance`: UI tests

## Regenerate

From repository root:

```sh
DEST=Examples/Showcase/SweetUIShowcasePackage/Sources/SweetUIShowcaseFeature/Installed
swift run sweetui install activity-feed --destination "$DEST" --force
swift run sweetui generate showcase-manifest
```

Build shared `SweetUIShowcase` scheme in `SweetUIShowcase.xcworkspace`; UI suite: iPhone 17 iOS 27.0 (`docs/visual-testing.md`).
