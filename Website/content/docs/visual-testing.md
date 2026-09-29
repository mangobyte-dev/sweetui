# Visual testing

## Contract

Showcase UI tests compare 6 screens (finance, nutrition, authentication, settings, activity, command-search) to `Examples/Showcase/SweetUIShowcaseUITests/ReferenceImages/`

Pin: light-mode iPhone 17, iOS 27.0; controls/tabs vary by platform, other runtimes are evidence only

## Comparison

`SweetUIShowcaseUITests.swift`:

1. captures via `XCUIApplication.screenshot()`
2. removes top `7%` (status-bar)
3. normalizes to `192x384` `RGBA`
4. computes mean absolute channel difference
5. fails above `1.5%` difference

Semantic UI assertions separate; image check protects layout, hierarchy, surfaces, color distribution, major typography, ignores clock

iPhone pin only for pixel comparison; iPad gets evidence screenshots, no comparison, semantic assertions run. 3 known limits (`CHANGELOG.md`): iPad's intermittent idle stall after keyboard input, that test's measured skip, `-disable-animations` on iPad

## Approved references

`finance-light.png`, `nutrition-light.png`, `auth-light.png`, `settings-light.png`, `activity-light.png`, `command-light.png`

Reference change MUST carry a GOLDEN-CHANGE note; each captured via kept attachments, reviewed before approval, unless noted:

- Initial: iPhone+iPad review, both domains; iOS-18 floor run; accessibility-size run
- Floor to iOS 26: iPhone 16 Pro iOS-18 pin can't launch it, refs unrunnable not stale. Recaptured (Liquid Glass, floating tab bar), content/hierarchy/copy unchanged. iOS-26 deferred; 27.0 only runtime running app
- 2026-09-01: `auth-light.png`/`settings-light.png` added, 2 Stage-2 blocks, pristine light-mode. Auth: `Welcome back` card, empty Email/Password, `Sign in`, `Forgot password?` link. Settings: `Notifications` header, 5 rows + separators, dimmed org-managed `Marketing messages` row + explanation, `Currency` select, destructive `Sign out`, footer, binding caption. `finance-light.png`/`nutrition-light.png` also recaptured. Prior refs predated these tabs, stale 2-tab bar grown to 4. `2%` tolerance absorbed it. Only diff: 4-tab Liquid Glass bar
- 2026-09-05, pending owner's copy: tuning panel left its tab. Catalog screens show 3 tabs (`Components`, `Blocks`, `Recipes`), accent strip + `Tune` button above. `activity`/`command`/`finance`/`settings` absorb within `1.5%`. `auth-light` (already stale, audit) at 2.67%, `nutrition-light` at 1.53%, don't: blocks reach strip, content above strip unchanged. Replacements: suite's kept attachments. Harness refuses agent-session writes to `ReferenceImages/`, so owner copies, 2 tests fail till then
- 2026-09-05: all 4 refs recaptured, `activity-light.png` added. Showcase became a browsable catalog. Each block: pushed detail screen (`Blocks` tab), nav title, description. 4-tab bar (`Components`, `Blocks`, `Recipes`, `Tune`) replaces prior 5. Content/hierarchy/copy unchanged, accent Indigo at root. Activity ref: Stage-3 feed (`Card delivery delayed` + `Dismiss`; Recent: unread `Mishmash Bakery`, `Salary received`, `Statement ready`). Closes fifth-tab deferral. `command-light.png` added, Stage-4 block: `Search` title, empty field + magnifying glass, Actions (`New transfer` + command-T keycap, `Freeze card`, `Download statement`), Recent (`Mishmash Bakery`, `Salary`), shortcut legend

## Item captures

Every capture launches `-AppleLanguages (en) -AppleLocale en_US` (capture's locale, not simulator's). iPad Pro 13-inch also en_US; status-bar date is device's own. Region was `ar_SA` until 2026-09-06: Hijri dates + spaced currency in first wall captures

Per-item light/dark (`docs/images/items/`), presets (`docs/images/themes/`): `Scripts/capture_previews.py`, Showcase `-item` launch, pinned simulator. iPad per-item light/dark (`docs/images/ipad/`): same script + `--ipad`, iPad Pro 13-inch. Site-data copies to `Website/public/images/ipad/` ("On iPad") and `Website/public/images/`. Review evidence, not baselines

GOLDEN-CHANGE (2026-09-05, threshold): `96x192` at `2%` moved to `192x384` at `1.5%`; a tab/nav bar can't hide in tolerance. All 5 refs passed without recapture

## Updating a reference

MUST NOT regenerate only because a test failed.

1. inspect failure attachment, identify intended change
2. run full UI suite on pinned runtime
3. export kept attachments (`.xcresult`, `xcrun xcresulttool export attachments`)
4. replace only affected reference
5. review image directly
6. record `GOLDEN-CHANGE` note describing the difference

Threshold change is a visual-contract change: same review

## Limits

Normalized comparison: small/deterministic, can miss a glyph-only change; explicit UI assertions cover copy + accessibility. Current-platform iPhone/iPad screenshots (`docs/images/`): review evidence, not baselines
