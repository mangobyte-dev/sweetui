# SweetUI 0.5.1 Release

## Summary
A patch release that includes visual reference updates, test improvements, and dependency security fixes.

## Changes

### Fixed

- The six Showcase visual references match the app again. They were recaptured on the pinned iPhone 17 (iOS 27.0) after reviewed, intended changes, and the full UI suite passes. `SelectionCoverageTests` now counts the 74-item catalog.
- The UI tests stop at the first failure, so the stale references had hidden a scroll bug in the steps after each snapshot. The scroll helper swiped the tuning strip's swatch row, not the page, and a swipe flung targets under the navigation bar or tab bar. It now drags the page without momentum until the target sits mid-screen.
- Updated Next.js from 16.3.3 to 16.3.6 for security fixes and improvements.
- Updated fast-uri to 3.1.8 for security updates.

### Updated

- Website dependencies: Next.js and build system packages updated to latest stable versions.

### Known Limitations

- On the pinned iPad Pro 13-inch (M5) simulator, Xcode 27.0, the pointer-effect test reads a 0.00% pixel change under hover. The iPhone pin is unaffected. The iPad's two auth keyboard tests stay intermittent, the known idle stall after keyboard input.

## Installation

```bash
brew upgrade sweetui
```

Or with Swift Package Manager:
```swift
.package(url: "https://github.com/mangobyte-dev/sweetui.git", .upToNextMinor(from: "0.5.0"))
```
