# Changelog

## Unreleased

### Added

- Tune, the card `designSurface()` puts over a running debug build, with three places: Tokens (Start
  from, the theme's tokens in groups with the Checks, the selected item, its knobs, the host's
  sections), Notes (the conversation with the agent), and Versions (Current, Hand off, and the
  history). The
  toolbar holds Select and the item menu; the bottom bar holds Undo, Redo, Preview, and Note. Preview
  is one menu of appearance, text size, direction (System, Left to right, Right to left), outlines,
  and guides, applied beside the theme and never part of a version, also for a host that paints the
  items from its own tokens. The place picker becomes a menu at an accessibility text size and in a
  card too short to keep 120 pt for the place. `DesignSurface.card(at:tunesRegistryTheme:sample:)`
  draws the card over in-memory files for previews and render checks; the simless fixtures
  `TuneCard*` render it, the Notes states included.
- Versions. Each settled gesture is one version in `design-history.json`: a slider on release, a menu
  or a switch at once, a color 0.6 s after its last change. A version names its author (you or the
  agent), what it came from, and its parent. Versions form a tree: a change after Undo branches from
  Current and never deletes a named version. Undo goes to the parent, Redo to the newest child, and
  Undo right after Restore returns to the version left. Past 200 versions the oldest unnamed one
  drops, never Current, a trial's base, or Shipped. A device with the older list-shaped file keeps
  its history. On launch the value files are the truth, so a change lost to a kill is recorded once.
  While Tune sets no token the app shows its own theme (Source); Source and Default are versions.
  Versions shows Current (its label, author, and time, "Trying Warm" while trying, what it changed
  from the version before and from Default in words (under Source only its knobs, beside "Tokens:
  source, the app's own theme.", since Tune does not know those values), a line for the Checks
  that opens Tokens with Color open, a line for the open notes that opens Notes, the Name field,
  Copy code, Copy Swift, and the Swift to read), then Hand off, then the history newest first: each
  row has its author's mark, label, time, change count (none for Source with no knob moved), a
  check on Current, and "from Mango at 10:40" where it branched. A tap
  restores a version. Undo right after Restore onto a proposal's version that is not kept returns to
  the version Restore left and records the proposal discarded. A host that does not tune the theme
  keeps Versions without the Checks, Copy code, and Copy Swift.
- Notes. A note is about the selected item, or the screen when the item is not on it, and goes to
  `design-notes.json` with a screenshot under `notes/`, the item and its chain, the tokens it reads,
  its moved knobs, its frame, and the design's code (empty under Source). Threads list oldest first:
  the note, the agent's answer with the files it changed, the proposals that answer it, then the
  replies. A note reads Not read yet, Read, or Answered, and a line above the threads says when the
  agent last read them. Reply on any note or proposal threads the next note to it (`inReplyTo`) with
  that note's subject. Delete is a swipe, mirrored as an accessibility action. The composer sits at
  the bottom of the card.
- Proposals. The agent offers a design: a full code, or tokens as a delta, and knob values. One that
  asks to be applied is tried as soon as it arrives, card open or closed, merged over the current
  version; one that arrives while a slider is held is tried on release, on top of it. The Trying
  strip ("Trying Warm. Accent, Card radius.") offers Keep and Discard. Discard puts the base back
  exactly, Keep turns down the other proposals that answer the same note (one that answers no note
  turns down none), and an edit keeps it ("Kept
  Warm. Your change is on top."). Undo, Restore, or Apply while trying discards it; Redo or Restore
  onto a proposal's version tries it again; Undo past a kept one records it discarded. A proposal row
  shows its reason and its Changes in words, with Try, Keep, Discard, or Try again for its state.
  Notes and the Tune button count what is new from the agent ("Tune, 1 new from the agent"), and
  VoiceOver announces each try, decision, and answer.
- One writer per file. Tune writes `registry-tokens.json`, `design-knobs.json`, `design-notes.json`,
  `design-history.json`, `design-context.json`, and `design-handoff.json`. The agent writes only
  `design-agent.json`: read dates by note and hand-off id, answers keyed by id, and proposals. Tune
  reads it through `@SharedReader` and never saves it, so neither side loses the other's write. A
  0-byte `design-agent.json`, as Sharing creates the file it watches, reads as empty on both sides.
- The agent's eyes. With the surface on, card open or closed, Tune rewrites `design-context.json`
  after each version, screen change, and try, and when the keyboard hides: the named screen, every
  item with its frame, tokens, and moved knobs, the selection, the design's code, the code its last
  screenshot shows, the proposal trying, Preview's overrides, and `tunesTheme`. It saves
  `notes/context.png` once the app has drawn, never while Selecting.
- Hand off, the one prominent control in Versions, keeps a proposal that is trying, then writes `design-handoff.json` and
  `notes/handoff.png`: an id, the design's code (empty under Source) and its Swift, the moved knobs,
  the changes from Default, the notes the agent has not answered, and the previous hand-off. Its
  status reads "Handed off at 10:42. Not read yet.", "Read by the agent at 10:43.", "Shipped at
  10:51. Changed RegistryTheme+App.swift.", or the agent's answer. An answer with changed files is
  Shipped: Tune clears its token and knob overrides so the source shows. Under Source, Copy code and
  Copy Swift say there is no code, and the Checks line says Tune sets no token. An answer to the
  hand-off counts as new on Notes and the Tune button until Versions is shown.
- Six MCP design tools beside the seven released: `get_design_context`;
  `list_design_notes(includeAnswered)`, which joins answers, proposals with their state (offered,
  trying, kept, discarded), and the person's decisions, and stamps a read date per note returned;
  `propose_design(name, reason?, note?, code? or tokens?, knobs?, apply = true)`, which validates the
  code, the token keys and values (a number off its preset grid is refused with the allowed range),
  and the knobs (`null` is a knob's default), refuses code and
  tokens when `tunesTheme` is false, and never writes the value files; `answer_design_note`, which
  refuses an unknown id; `read_handoff`, which stamps the hand-off read; and `answer_handoff`, which
  takes the current or the previous hand-off and says when a newer one waits. Give `file`, or `udid`
  and `bundleId` for the simulator app container (`xcrun simctl get_app_container`). The `sweetui`
  skill walks the loop: see, read, propose, answer, ship.
- Checks, at the top of Tokens' Color group. They measure the label on the accent and the accent as
  text, plus the text pairs once the theme sets a foreground or background, as WCAG 2.2 ratios in
  light and dark and again under Increase Contrast. A row reads Passes, Passes with Increase Contrast,
  or Fails against the 4.5:1 the Human Interface Guidelines apply to text up to 17 points, with the
  ratios beside it, and the Color header counts the failures ("Color · 1 fails"). When the other label
  (white or black) would pass, Fix label applies it; Ask the agent on a failing check goes to Notes
  with the pair and its ratios drafted under any draft already there. Under Source, Tune cannot read
  the app's colors, so the Checks say so and the header counts no failure. Ratios agree with
  WebAIM's checker to two decimals (`ContrastAuditTests`).
- Tokens and Selecting. With nothing selected, Tokens shows Start from, then the theme's tokens in
  seven groups: Color open, and Type, Space, Shape, Surface, Chart, and Disabled collapsed, each header
  counting what changed ("Space · 2 changed"). A token row shows its title, value ("source" while Tune
  sets no token), key, how many items on screen it reaches, and, while it is changed, a dot and Reset
  token. A color token has Light and Dark pickers and Use the Light value. While a token's slider is
  held, only the items it reaches are outlined. Select, then a tap on an item, shows the Item section
  (title, name, size and origin, instances, the item around it, the notes about it, Copy name), its
  knobs (the agent's marked "From the agent"), only the tokens that reach it, and what it reads that
  no token moves ("Also reads negative. No token moves it."). A pick from Notes stays on Notes as the
  composer's subject and pushes no host page over it. A tap on nothing, or Cancel on the Selecting
  pill, keeps the selection. Note with nothing selected arms Selecting and returns to the focused
  composer. The item menu lists the selection's chain and the items on this screen, and says when the
  selection is not on this screen; with VoiceOver running, Select opens it. `TokenCatalog` gives
  every key a code encodes one token (`TokenCatalogTests`), and `TuningPanel(tuning:)` draws the same
  groups with Copy code, Copy Swift, and the Swift. Changes read the catalog's titles and units ("Card
  radius: 16 to 20 pt", "Label on accent: white to black", "Background, Dark: none to #1A1A1A"). Paste
  a code takes a code typed on iOS, where smart punctuation turns `--preset` into a dash, and Return
  on an empty field does nothing. Each accent swatch carries `tuning.token.accent.<accent>`.
- Knobs the agent declares, and two new kinds. `ItemKnob.bool` draws a switch stored as 0 or 1 and
  `ItemKnob.choice` draws a picker stored as the option's index, so `design-knobs.json`, proposals,
  and versions keep their numeric shape; foundations gain `registryKnob(_:_:default: Bool)` and
  `registryKnob(_:_:options:default:)` to read them. An agent writes `design-knob-specs.json` beside
  the tokens, `{"<item>": [{"name", "title", "kind": "number" | "bool" | "choice", "min", "max",
  "step", "options", "shipped"}]}`, and Tune shows the controls under the item at once; a host knob
  of the same name wins, and a spec Tune cannot draw is dropped with a log line. The item reads a new
  knob after one build.
- Two simless fixtures, `TunePanel` and `TunePanelEmerald`, render the embedded `TuningPanel` headless.
- `sweetui preset decode` and MCP `describe_preset` report contrast for the literal colors a code
  carries: `labelOnAccent` for a custom accent and `text` for a custom foreground over a custom
  background, as WCAG 2.2 ratios in light and dark with `passes` against 4.5:1. The key appears only
  when there is something to measure, so a code with a system accent prints what it always did; the
  Tune measures system accents on the device.

### Known limitations

- In a card too short to keep 120 pt for Notes, the composer drops its subject line (the field's hint
  still names it) and the bottom bar; the Trying strip stays while a proposal is trying.
- The composer field's own accessibility frame stays one line tall (about 22 pt on the iPhone Duo):
  SwiftUI's frame and padding do not resize the text view's element. Its row is a 44 pt target, and a
  tap beside the text focuses it. A color picker's frame is the system well's, 24 pt.
- A token's slider begins its hold, and its reach outlines, once the thumb moves a step; a touch
  that rests without moving shows none (iPhone Duo, iOS 27.1).
- `design-variants.json` and `design-agent-change.json` from earlier builds are ignored, not deleted.
- On the iPhone Duo cover display (iOS 27.1 simulator) Tune's Preview menu opens upward and runs past
  the top edge: Outlines and Guides sit off screen when it opens, so they take more than 2 taps.
  Whether the system color picker presents there is not checked. Unverified on the pinned iPhone 17.

- The shipped default (SwiftUI's indigo under a white label) fails in dark at 3.51:1, and Increase
  Contrast lowers it to 2.13:1, because the accessible indigo is lighter. `systemRed` under the white
  destructive label is 3.57:1 light and 3.43:1 dark, so the button style's "always dark enough for a
  white label" comment is not true at 15 points; the panel does not measure the negative color, which
  is not a knob.
- The new UI test `testContrastAuditNamesTheFailingPairAndOffersTheLabelThatFixesIt` follows the
  import test's steps but has not run on the pinned iPhone 17: the only runtime on the release machine
  is iOS 27.1 with the iPhone Duo, whose cover display puts the tab bar in a side strip, so the
  existing panel UI tests fail there too ("The Components tab must exist").

## 0.6.0 (2026-10-10)

A minor release that adds iPhone Duo support. Foundations do not change, so every item keeps the
`0.5.0` floor, and a package pinned `.upToNextMinor(from: "0.5.0")` needs no change.
`brew upgrade sweetui` installs the tool.

### Added

- `fold-companion` 0.1.0: `.foldCompanion(isPresented:content:)` shows a companion in the second pane
  on the open display of iPhone Duo, and in a sheet on every other display. The panes split on the
  fold's division reserved region, so nothing sits under the hinge: side by side around a fold down
  the display (flat or half open), stacked around a fold across it only while half open (tabletop).
  The closed cover display, an iPhone, an iPad, and a pane under 300 points use the sheet. A pose
  change keeps the companion open, and the content keeps its identity, so its focus and scroll
  position survive a fold. Right to left puts the content on the right. It builds with the iOS 27.1
  SDK and runs from iOS 26.0, where the companion always opens in a sheet.
- `fold-arrangement` 0.1.0, a recipe: Apple's `ArrangementView` (iOS 27.1) for two panes that always
  show, with the measured limits that make `fold-companion` necessary for a companion that opens and
  closes.

### Fixed

- `Scripts/capture_previews.py` cropped around the screen center when the demo started at the top
  edge, because `sips` ignores a crop offset of 0. The iPhone Duo cover display has no top status bar,
  so its captures came out shifted. The offset is now at least one pixel row; the iPhone captures do
  not change.

### Known limitations

- The pinned iPhone 17 (iOS 27.0) and iPad simulators are not on the release machine, whose only
  runtime is iOS 27.1 with the iPhone Duo. The new items' captures come from the iPhone Duo cover
  display, so its side status bar shows in them. The Showcase UI suite and its visual references did
  not run for this release; the Showcase package tests ran on the iPhone Duo.
- Verified on the iPhone Duo simulator, iOS 27.1: closed, half open (book and tabletop), flat open in
  both orientations, left to right and right to left. Real hardware is unverified.

## 0.5.1 (2026-10-05)

### Fixed

- The six Showcase visual references match the app again. They were recaptured on the pinned iPhone 17
  (iOS 27.0) after reviewed, intended changes (`docs/visual-testing.md`, GOLDEN-CHANGE 2026-09-29), and
  the full UI suite passes. `SelectionCoverageTests` counts the 74-item catalog.
- The UI tests stop at the first failure, so the stale references had hidden a scroll bug in the steps
  after each snapshot. The scroll helper swiped the tuning strip's swatch row, not the page, and a swipe
  flung targets under the navigation bar or tab bar. It now drags the page without momentum until the
  target sits mid-screen.
- Website dependencies: Next.js 16.3.3 to 16.3.6 and fast-uri 3.1.6 to 3.1.8, for security fixes.

### Known limitations

- The `0.5.1` tool reports `0.5.0` (`sweetui --version`), and the Homebrew tap stayed at `0.5.0`.
- On the pinned iPad Pro 13-inch (M5) simulator, Xcode 27.0 (27A5252f), the pointer-effect test reads a
  0.00% pixel change under hover. It fails the same way at `bd9881c`, the commit that added it and passed on
  2026-09-07, so the simulator environment changed, not the code. The iPhone pin is unaffected. The iPad's
  two auth keyboard tests stay intermittent, the known idle stall after keyboard input.

## 0.5.0 (2026-09-29)

A breaking release: the project is now SweetUI. Every product, module, and command changes name,
and every item declares the `0.5.0` floor. The repository moved to
`github.com/mangobyte-dev/sweetui`; GitHub redirects the old URL. The website moves to
`https://sweetui.dev`.

### Changed

| Before | After |
| --- | --- |
| package `SwiftUIRegistry`, repository `swiftui-ui-registry` | `SweetUI`, `sweetui` |
| `SwiftUIRegistryFoundations`, `SwiftUIRegistryDesignSurface` | `SweetUIFoundations`, `SweetUIDesignSurface` |
| `RegistryKit` | `SweetUIKit` |
| tool and Homebrew formula `swiftui-registry` | `sweetui` |
| receipts `.swiftui-registry/` | `.sweetui/` |
| cache `~/Library/Caches/swiftui-registry` | `~/Library/Caches/sweetui` |
| tap tags `swiftui-registry-<version>` | `sweetui-<version>` |
| skills `swiftui-registry`, `swiftui-registry-authoring`, `swiftui-registry-theming` | `sweetui`, `sweetui-authoring`, `sweetui-theming` |
| website `swiftui-registry.mangobytekw.workers.dev` | `sweetui.dev` (the old URL keeps serving the same site) |
| GitHub Pages mirror `mangobyte-dev.github.io/swiftui-ui-registry` | `mangobyte-dev.github.io/sweetui`, no redirect |

`RegistryTheme`, `registryTheme(_:)`, `registryItem(_:)`, and every other `registry` prefixed API
keep their names.

### Migrating an app

1. Package: `.package(url: "https://github.com/mangobyte-dev/sweetui.git", .upToNextMinor(from: "0.5.0"))`
   and `.product(name: "SweetUIFoundations", package: "sweetui")`, plus
   `.product(name: "SweetUIDesignSurface", package: "sweetui")` if the app links the design surface.
   In an Xcode project, remove the old package and add the new URL with the same products.
2. Sources: replace `SwiftUIRegistry` with `SweetUI` in every import.
3. Receipts: the tool reads only `.sweetui/` and rejects a receipt that names another registry. In
   each install destination run:

   ```sh
   mv .swiftui-registry .sweetui
   sed -i '' -e 's/SwiftUIRegistry/SweetUI/g' -e 's/swiftui-ui-registry/sweetui/g' .sweetui/receipt.json
   ```

   Step 2 changed each installed file, so `info` reports it `modified`; `install <item> --update`
   merges it back to `up-to-date`.
4. Theme file: `preset apply` reads the header `// sweetui preset <code>`. Rename the old
   `// swiftui-registry preset` header, or pass `--force`.
5. Tool: `brew uninstall swiftui-registry`, then `brew install mangobyte-dev/tap/sweetui`. Register
   the MCP server as `sweetui mcp`. The old cache MAY be deleted.

## 0.4.0 (2026-09-19)

A minor release, source compatible with 0.3.x. `brew upgrade swiftui-registry` installs the tool.
A package pinned `.upToNextMinor(from: "0.3.0")` resolves it, and every item keeps the `0.3.0`
floor, since none needs anything newer.

Three things drove it. A Point-Free audit in two passes (`docs/point-free-audit.md`) hardened the
engine with no schema change. A build of a shop front from the released tool, read by hand, found
seven problems an agent meets. A measured study then had an agent build four small apps five
times each, changed the registry one thing at a time, and kept only what lowered the count
(`docs/case-studies.md`).

### Added

- Case studies (`docs/case-studies.md`, also on the website): the four apps, their screenshots,
  the items they used, and what the measurement found.
- `validated-input` 0.1.0: a text field with a floating label, a rounded border that follows
  focus and validity, and rules checked while typing and again on blur. Rules are `required`,
  `email`, `phone`, `custom`, and the statics `password`, `matching`, `numberRange`,
  `internationalPhone`, and `pattern`; the first failing rule's message shows under the field, is
  the accessibility hint, and is announced. A `validity` binding reports every change so a form can
  gate its submit. Based on the owner's earlier enum-driven text field.
- A fifth generator, `swiftui-registry generate usage-checks`, writes `UsageSnippetChecks.swift`:
  one `View` per installable item that compiles the item's `usage` snippet, so a snippet naming an
  undeclared symbol fails the Showcase build instead of shipping. Symbols a snippet leaves to the
  adopter are stand-ins in the hand-written `UsageSnippetPlaceholders.swift`.
- `describe` lists `Signatures:`: every public initializer, function, static member, and enum of
  the item's sources, one line each, prefixed with the owning type, with labels, types, defaults,
  and enum cases. The JSON and MCP `describe_item` payloads carry them as `signatures`.

### Changed

- Thirteen items gained the words a shop developer searches first: `product`, `cart`, `price`,
  `checkout`, `rating`, and their neighbors now resolve to `item`, `badge`, `button`, `field`,
  `empty`, `metric-card`, and the rest. Search itself is unchanged: every term must still match.
- Fourteen more items gained the words a chat, settings, or finance developer searches first:
  `unread` and `counter` reach `badge`; `send`, `submit`, and `refresh-button` reach `button`;
  `composer` reaches `input-group`; `email`, `phone`, and `password` reach `input` and `field`;
  `sign-out` and `logout` reach `alert-dialog`; `notifications` reaches `settings-section`;
  `filter` reaches `accordion` and `checkbox`; `range` reaches `slider`; `total` reaches `table` and
  `metric-card`; `profile-header` reaches `avatar`; `refreshed` reaches `toast`.
- `field` 0.1.2: `Field` also takes its error as a `String?`, so a message computed at runtime no
  longer needs wrapping in a `LocalizedStringResource`. The resource initializer stays preferred.
- `attachment` 0.1.2 and `item` 0.2.2: a bare trailing closure on `AttachmentRow` or `ItemRow` now
  resolves to the content initializer instead of an ambiguity error; the actions-only and
  accessory-only initializers are disfavored.
- `signup-form` 0.1.2: `SignUpForm` takes `isSubmitEnabled` (default `true`) and disables its
  submit button and return-key submit while it is `false`.

- `Installer.FileStatus.status` and `InstalledInventory.File.status` are now enums
  (`PlanFileStatus`, `UpdateFileStatus`, `InventoryFileStatus`) instead of `String`. JSON and CLI
  text output are byte-identical; Swift code that links `RegistryKit` directly and compares
  `.status` against a string literal needs to compare against the matching case instead.
- `RegistryKit`'s `FileSystem` and `RegistrySource` are structs of closures, the shape of its
  other six dependencies, instead of protocols. `LocalFileSystem()` and `LocalRegistrySource()`
  are `FileSystem.local` and `RegistrySource.local`; `.unimplemented` is each one's test default.
  `write(_:to:)` and `repositoryRoot(override:refresh:)` stay as methods, so call sites through
  `@Dependency` do not change; a type that conformed to either protocol now builds a value instead.
  The CLI and MCP output are unchanged.
- `skeleton` 0.2.2: the doc comment names what redaction does not cover. An effect the wrapped
  content starts itself (`task`, `onAppear`, a request) still runs; gate it on the same flag. No
  visible change, no recapture.
- The tuning panel's import sheet owns its draft and its failure state; a failed paste no longer
  outlives the sheet.

### Fixed

- Five usage snippets did not compile as printed. `field` read `$name` and `emailError` without
  declaring them; `auth-form`, `signup-form`, `message-scroller`, and `settings-section` bound state
  they never declared. Each now declares the state it assumes. `toast`'s snippet shows `message:`
  and `carousel`'s names its placeholder collection.
- `swiftui-registry search ... --format names` printed nothing on zero matches. It now says
  `No item matches ...` on stderr and still exits 0.
- In a test, an un-overridden `registryFileSystem` or `registrySource` reached the real disk and the
  release snapshot. Both now fail at the boundary: the file system's throwing members throw, its
  queries report an issue, and the source throws. `RegistryKit` declares `IssueReporting` through
  `xctest-dynamic-overlay`, the identity swift-sharing already resolves; `RegistryKitTests`
  declares `CustomDump` for line diffs on multi-field assertions and generated text. Neither
  changes `Package.resolved`.

### Known limitations

- Unchanged from 0.3.1: `toggle-group`'s toggles report no frame inside a native `ControlGroup`,
  and the same six Showcase visual references fail on the pinned simulator by 4.1 to 5.5 percent
  (`activity`, `auth`, `command`, `finance`, `nutrition`, `settings`), on an unchanged tree.
- A search for `quantity` matches nothing. The native `Stepper` is the answer, and an item that
  only renames it is out of scope by the value gate.

## 0.3.1

A patch release: every change is source compatible. `brew upgrade swiftui-registry` installs the tool. A package pinned `.upToNextMinor(from: "0.3.0")` resolves it, and every item keeps the `0.3.0` floor, since none needs anything newer.

### Added

- Recipes are selectable. A recipe's usage snippet ends its root with `.registryItem("<name>")`; copy it, and the design surface selects the recipe. A recipe whose snippet uses registry items declares them, so the panel scopes to the tokens they read. `menubar` carries no tag: its root is a `Scene`, and the tag is a View modifier.
- `RegistryItemReport.ancestors`: the tagged roots an item sits inside, outermost first. `ItemSelection.chain(reports:at:)` reads it.

### Changed

- A child that fills its parent exactly is picked before the parent. Before, equal areas resolved by name, so an `attachment` won over the `item` inside it.
- The panel shows only what an export reproduces. A value that arrives off its slider grid (an import, a hand edited `registry-tokens.json`) renders and exports at the nearest step, and a custom color at 8 bits a channel.
- The System accent tints nothing while tuning. A consumer's export carries no accent for System, so its native controls keep their own colors; the tuner now shows the same.

### Fixed

- `swiftui-registry preset apply` wrote a theme file that did not compile for a code with a font design, a surface step, a chart palette, or a color pair. Those arguments now follow `metrics:`, the order `RegistryTheme.init` declares. The Swift that `preset decode` prints, the MCP tools, and the website's Create page share the fix.
- Copy Swift rounded an off-grid number or a custom color to three decimals, which changed pixels. It now prints the fewest decimals that read back. The theme file prints each color channel the same way.
- Neither export wrote `surfaceOpacity`, so `registrySurface(level:)` drew a different elevated surface in the consumer. Both write it when it leaves 0.055.

### Known limitations

- A native `ControlGroup` never places its toggles, so `toggle-group`'s toggles report no frame and Select picks the group. `registryToggleGroup(_:)`'s variant has no visible effect on iOS 27.
- Six Showcase visual references fail on the pinned simulator by 4.0 to 5.5 percent against the 1.5 percent tolerance (`activity`, `auth`, `command`, `finance`, `nutrition`, `settings`). They failed before this release too, on an unchanged tree.

## 0.3.0 (public beta)

The design surface tunes a running app on the device. It ships as a second package product. Install or upgrade: `brew install mangobyte-dev/tap/swiftui-registry` or `brew upgrade swiftui-registry`.

### Added

- `SwiftUIRegistryDesignSurface`. Add the product, `import SwiftUIRegistryDesignSurface`, apply `designSurface()` inside `registryTheme(_:)`. A debug build gains a draggable Tune button. A floating, movable, resizable panel opens in the tool's own window. The window covers the whole app, live underneath on every tab, sheet, and cover. A release build returns the content unchanged. Tokens persist as `registry-tokens.json` in the app's Documents directory. Export them as a preset code any registry tool applies, or as Swift to paste.
- Tap to select. Select arms the next tap; the panel scopes to the tokens reaching the tapped item. Every tagged item on screen is outlined with its name and listed under On this screen. `ItemSelection.chain` names every item under the pick, innermost first. A host can offer the row around a button too. A pick on nothing clears the selection.
- Host tokens. Conform the app's token value to `TokenDocument`: a shipped value, a file name, pages of `.number`, `.choice`, and `.color` knobs, and `apply()`. Pass it to `designSurface(tokens:)`. The panel gains an App tokens section that writes back to the app.
- Per item knobs. Register numeric knobs with `designSurface(knobs:)` and `ItemKnob`; read one with `registryKnob(_:_:default:)`. They persist beside the tokens in `design-knobs.json`; only a moved value is written.
- The host hooks overload `designSurface(enabled:tunesRegistryTheme:knobs:itemTitle:page:panelEnvironment:panel:)`, for an app that paints registry items from its own tokens. It compiles in every configuration.

  | Parameter | Effect |
  | --- | --- |
  | `enabled` | the app's own switch |
  | `tunesRegistryTheme: false` | drops the panel's theme sections |
  | `panel` | adds the app's sections |
  | `page` | pushes the app's page for a picked item |
  | `panelEnvironment` | wraps the panel's stack |
  | `itemTitle` | names rows and outlines |

- Foundations gained `registryItem(_:)` and `registryScreen(_:)`, the tags the surface selects and names screens by. It also gained the surface reporter and per item knobs in the environment. All are inert without a surface.
- A fourth generator, `swiftui-registry generate item-tokens`, writes the item to token map that scopes the panel. CI checks it for drift with the other outputs.
- `CHANGELOG.md`, a repository layout table in `CONTRIBUTING.md`, and `docs/RELEASE-CHECKLIST.md`, the list a release closes line by line.

### Changed

- The tuning panel moved from the Showcase into the product, which the Showcase now consumes. It is a floating card in the tool's own window, not a sheet or inspector column. A drag bar moves it, a corner grip resizes it, a chevron collapses it. It can hang off the leading, trailing, and bottom edges; its grab strip stays inside the safe area, and it never goes above the top. On iPad, a drag against the trailing edge snaps it into a full height column. Its frame is remembered per size class and re clamped on rotation.
- The tool's chrome uses fixed system values, never the tuned theme: Tune button, card, selection ring, outlines, guides. Its motion is off under Reduce Motion.
- Every installable item declares the `0.3.0` foundations floor, because every one applies `registryItem(_:)`. The installer prints `from 0.3.0 up to the next minor version`.
- `swift-sharing` is pinned to 2.9.x (from `2.9.1`, below `2.10.0`) with no traits. A consumer that already resolves `xctest-dynamic-overlay` is not forced onto a newer major.
- Planning, research, and run logs left the repository. It holds only what an adopter needs.

### Fixed

- The tool no longer advertises an older Homebrew tag as an update; the notice needs a tag newer than the running tool.
- A tap on a List row under the card pushes again. The key window follows the text field that takes focus: a field in the app takes the keyboard, a field in the panel takes it back. Before, the key window switched during hit testing, which cancelled the touch.
- The collapse control has its own accessibility frame; the drag runs over the whole bar as a simultaneous gesture.
- The card is clamped into the window's safe area. Its strip neither sits under the status bar nor stops short of it.
- Edge cases:

  | Case | Behavior |
  | --- | --- |
  | non positive step, or shipped value outside its range | knob stays usable, logged |
  | token file that fails to decode (hand edited, newer version) | shipped values stay, logged once, not rewritten until a knob moves |
  | choice knob whose options no longer list its value | value kept |
  | empty item or screen name | tags nothing |
  | empty host title | falls back to the item's name |
  | equal frames | ties resolve by name |
  | item scrolled off the screen | not listed as on it |

- Foundations compiles on macOS again after `Color(uiColor:)` crept into the selection ring. An unused anchor preference left the public API before it shipped.

### Known limitations

- Two visual references, `auth-light` and `nutrition-light`, are stale after the tuning strip change: 2.70 and 1.54 percent against the 1.5 percent tolerance. Both are recaptured and await the owner's copy into `ReferenceImages/`. Until then those two Showcase UI tests fail (`docs/visual-testing.md`).
- The iPad simulator sometimes never reports idle after keyboard input. The UI suite passes `-disable-animations` on that destination. One test records a measured skip instead of a failure (`docs/visual-testing.md`).
- The tool's window installs over the first connected scene. A second window of the same app on iPad is not covered.
- Items installed from `0.1.0` or `0.2.0` carry no `registryItem(_:)` tag. Select and the outlines find nothing in them until `swiftui-registry install <item> --update`.
- The Showcase is portrait only on iPhone. Card rotation runs on the iPad destination and in the host apps.

## 0.2.0 (2026-09-07)

The Stage 7 release. The same `brew install mangobyte-dev/tap/swiftui-registry` or `brew upgrade swiftui-registry` applies.

### Added

- 16 items, growing the catalog from 57 to 73:
    - 6 chat and feedback components: `attachment`, `bubble`, `marker`, `message`, `message-scroller`, `toast`.
    - 7 recipes: `carousel`, `chart-tooltip`, `date-picker`, `input-otp`, `menubar`, `sheet`, `typography`.
    - 3 blocks: `dashboard`, `signup-form`, `questionnaire`.
- `describe <item>` prints metadata, usage snippet, accessibility contract, install order, package requirement, and files, with `--source` and `--format json`. `info --destination <dir>` reports every owned file as up to date, modified, or missing through the receipt.
- Preset code format version `b`. It appends to the version `a` fields and the custom accent block. The new fields: font design, a surface step that drives a four level elevation ladder, a chart palette. Optional light and dark pairs cover background, foreground, and secondary foreground. A code stays `a` while nothing appended leaves its default. Every existing code still decodes to the same theme.
- The `SwiftUIRegistryFoundations` 0.2.0 API, all defaulted so existing initializers compile:
    - `fontDesign`, `surfaceOpacity`, `surfaceStep`, `chartPalette`, `background`, `foreground`, `secondaryForeground` on `RegistryTheme`.
    - The `mango` preset, the sample design system (`docs/mango.md`).
    - `RegistrySurfaceLevel` with `registrySurface(level:)`.
- Three agent skills under `Skills/` (consuming, theming, authoring), mirrored to `~/.claude/skills/`.
- iPad Pro 13 inch captures of every item, light and dark; the website shows both idioms.

### Changed

- `button`, `checkbox`, `accordion`, and `breadcrumb` keep the iPadOS pointer effect. The sidebar recipe adds the `sidebarAdaptable` tab view.
- `chart` reads the chart palette and declares the 0.2.0 foundations floor. Every other item kept 0.1.0 at this release.

## 0.1.0 (2026-09-06)

The first published contract.

### Added

- 57 source owned items (31 components, 8 blocks, 18 recipes), the `SwiftUIRegistryFoundations` theme package, and the `swiftui-registry` tool.
- The tool installs items with receipt backed three way updates. It searches and validates the catalog, reads and writes preset codes, and serves every operation over MCP. It generates the catalog, the Showcase manifest, and the website data. Outside a clone it fetches this tag's registry snapshot on first use.
- The release workflow attaches `swiftui-registry-macos-universal.tar.gz` (arm64 and x86_64) plus its `.sha256` for the Homebrew tap.
- The `TodoCounter` example, a second consumer on the Composable Architecture.
