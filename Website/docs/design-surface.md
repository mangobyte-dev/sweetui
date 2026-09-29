# Design surface

Tunes app on device via `SweetUIDesignSurface`; persists tab/sheet/cover; release unchanged.

![Card, iPhone](/images/design-surface/iphone-card-light.png)

![Panel, iPad column](/images/design-surface/ipad-column-light.png)

## Add it

Add product to scene-root target, import, apply `designSurface()` inside theme call; tuned wins over shipped.

```swift
import SweetUIDesignSurface
import SweetUIFoundations

ContentView()
    .designSurface()
    .registryTheme(.app)
```

- Items carry `registryItem(_:)`, surface's select tag.
- Screens self-name via `registryScreen(_:)` for panel list.
- Add tag pre-0.3.0 items: `sweetui install <item> --update`.

## The panel

- **Tune**: draggable, settles to side, remembers place; holds outlines, 8/24 pt guides, 16/24 pt margins.
- **Card**: drag bar moves, corner grip resizes, chevron collapses; leading/trailing/bottom in safe area, never above top. iPad trailing drag snaps full-height column, framed per size class, re-clamped on rotation.
- **On this screen**: items behind card, row = item + count; tap selects, switch outlines by name.
- **Select**: arms next tap, picks innermost tagged item, scopes tokens; "All tokens" resets theme, empty tap clears selection.
- **Presets/Export/Import**: seven presets, one tap; Copy exports code + `RegistryTheme(...)`, Import reads back.
- **Environment**: previews dark mode, larger text, right-to-left; theme untouched.

Chrome: fixed system values; motion off under Reduce Motion.

## Your own tokens and knobs

Conform value to `TokenDocument` (shipped value, file name, pages); add `.number`/`.choice`/`.color` knobs + `apply()` (every change). Per-item knobs: numbers via environment.

```swift
ContentView()
    .designSurface(
        tokens: MyTokens.self,
        knobs: ["button": [ItemKnob("padding", in: 0...32, shipped: 12)]]
    )
    .registryTheme(.app)
```

Inside: `environment.registryKnob("button", "padding", default: 12)`. Tokens persist as `registry-tokens.json`, knobs as `design-knobs.json`, Documents; surface writes moved knobs. Failed decode falls back shipped, logged once.

## Painting items from your own tokens

Host overload compiles every configuration, reviewable on TestFlight.

```swift
ContentView()
    .designSurface(
        enabled: designMode,
        tunesRegistryTheme: false,
        itemTitle: { name in MyPieces.title(for: name) },
        page: { name in MyPieces.page(for: name) },
        panelEnvironment: { panel in panel.environment(\.myTokens, tokens) }
    ) { chain in
        MyPanelSections(chain: chain)
    }
    .registryTheme(myTheme)
```

- `enabled`: switch.
- `tunesRegistryTheme: false`: drops theme sections.
- `panel`: sections under Screen, Selection.
- `page`: pushes page for covered item.
- `panelEnvironment`: pages read app environment.
- `itemTitle`: names rows, outlines.
- `chain`: tagged items, innermost first; app offers row, not just button.
- `designSurface(isPresented:)`: app owns trigger.

## Where the result goes

Reads panel's preset code. `sweetui preset decode <code>` prints knobs. `preset apply <code> --destination <app>` writes `RegistryTheme+App.swift`. [Create](/create/) opens it. Copy Swift gives initializer. Theme: one scene-root value; tool gone in release.

## Known limitations

- Window: only first connected scene, not a second iPad window of same app.
- Items from 0.1.0/0.2.0 carry no `registryItem(_:)` tag until updated: Select and outlines find nothing.
