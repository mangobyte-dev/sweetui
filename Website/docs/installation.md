# Installation

## 1. Add the package

`Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mangobyte-dev/sweetui.git", .upToNextMinor(from: "0.5.0"))
],
// In your target's dependencies:
.product(name: "SweetUIFoundations", package: "sweetui")
```

Or Xcode: Add Package Dependency, same URL, rule Up to Next Minor Version from 0.5.0, add `SweetUIFoundations`. `package:` = URL's last segment minus `.git`.

## 2. Theme once

```swift
import SweetUIFoundations

ContentView()
    .registryTheme(.graphite)
```

Presets: `.system` (app tint), `.graphite`, `.indigo`, `.rose`, `.emerald`, `.amber`, `.mango`. Controls follow tint. Compose on [Create](/create/) or tune on-device (step 5).

## 3. Install an item

```sh
brew install mangobyte-dev/tap/sweetui
sweetui install button --destination Sources/App/Components
```

Resolves dependencies, copies exact source (`RegistryButtonStyle.swift`), writes `.sweetui/receipt.json`, prints requirement. Never edits project files; add destination to target. Outside clone, fetches release on first use, cached under `~/Library/Caches/sweetui`.

## 4. Use it

```swift
Button("Save changes") {}
    .buttonStyle(.registry)

Button("Cancel") {}
    .buttonStyle(.registryOutline)
```

Apple's `Button` stays visible; only style changes. Each item carries snippet, accessibility contract, source.

## 5. Tune on the device

Add `SweetUIDesignSurface` to target:

```swift
import SweetUIDesignSurface

ContentView()
    .designSurface()
    .registryTheme(.graphite)
```

Debug builds add draggable Tune button; Select, then item, scopes tokens. Copy Swift gives `RegistryTheme(...)` for step 2. Release unchanged. See [design surface](/docs/design-surface/).

## Update source

```sh
sweetui install button --destination Sources/App/Components --diff
sweetui install button --destination Sources/App/Components --update
```

`--diff` shows local edits vs registry. `--update`:

- Unmodified files: registry version.
- Edits stay.
- Disjoint edits merge via `git merge-file`.
- Overlapping edits keep file, write `.merge` under `.sweetui/conflicts/`.

Conflicts never auto-resolve; customized files stay.

## Requirements

- Swift tools 6.2+, iOS 26+, Xcode building Swift 6.2
- Homebrew, or `swift run sweetui <command>` from clone
- Git for three-way merges
- Liquid Glass native, no pre-26 styling, no 27-only APIs, floor iOS 26
