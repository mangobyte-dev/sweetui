<!-- Reference for the sweetui skill. Regenerated from docs/catalog/index.md, itself a build product of `sweetui generate catalog`. Do not hand-edit; regenerate when the catalog changes. -->

# SweetUI catalog

76 items you copy into your app and own. Install the `sweetui` tool with `brew install mangobyte-dev/tap/sweetui`; it fetches the pinned registry snapshot on first use, and `--registry <path to a clone>` points it at a checkout instead. Components and blocks install with one command:

```sh
sweetui install <name> --destination Sources/YourFeature/Components
```

Point `--destination` at a folder inside the consuming target's sources, such as `Sources/YourFeature/Components`, so the copied files are members of that build target

## Blocks (11)

Compositions of components. Installing one installs its whole closure

- [activity-feed](activity-feed.md): Composes alert, avatar, item, skeleton, empty, accordion; caller-owned loading, items, notice, selection.
- [auth-form](auth-form.md): Composes input, button, card into sign-in form; caller owns credentials, validation, submission state.
- [command-search](command-search.md): Composes command, keycap; caller owns query, filtering, sections, legend.
- [dashboard](dashboard.md): Composes metrics, bar chart, table; caller-owned values, selection.
- [finance-overview](finance-overview.md): Composes metrics, selectable transactions; caller-owned navigation, state.
- [nutrition-overview](nutrition-overview.md): Composes energy, macro values; embeddable.
- [preview](preview.md): Theme wall: 33 cards, registry + native; adaptive grid, compact one-column.
- [preview-02](preview-02.md): Theme wall: 35 cards, registry + native; adaptive grid, compact one-column.
- [questionnaire](questionnaire.md): Composes field, checkbox, textarea, progress, button, card; drives choice, freeform, skippable steps.
- [settings-section](settings-section.md): Composes select, separator, button; structure, separators, messages, caller-owned toggle/picker/action rows.
- [signup-form](signup-form.md): Composes input, button, card, checkbox; caller owns fields, validation, terms, submission state.

## Components (39)

One installable style, modifier, or view each

- [accordion](accordion.md): Styles DisclosureGroup: full-width header, trailing chevron; keeps caller styling.
- [alert](alert.md): Inline alert: informational, positive, destructive; optional caller actions.
- [attachment](attachment.md): Row: square media, name, detail, caller actions. States: idle, uploading, processing, failed, completed.
- [avatar](avatar.md): Identity image, circular; initials/symbol fallback. Sizes via controlSize; needs label.
- [badge](badge.md): Primary, secondary, outline, positive, destructive: Text/Label treatments.
- [breadcrumb](breadcrumb.md): Horizontal nav trail: chevron separators, current page; overflow holds excess crumbs. iOS: no native breadcrumb.
- [bubble](bubble.md): Wraps text: incoming, outgoing, muted; aligns with message row.
- [button](button.md): Styles SwiftUI buttons: shadcn-inspired variants; preserves roles, sizing.
- [button-group](button-group.md): ControlGroup: buttons side by side, one variant; keeps roles, labels.
- [card](card.md): Styles GroupBox: bordered surface, adaptive label, content spacing.
- [chart](chart.md): Styles Swift Charts to theme: accent palette, theme grid, footnote axis, legend; bar/line/area/pie.
- [checkbox](checkbox.md): Styles Toggle as checkbox; preserves binding, label, state.
- [combobox](combobox.md): Searchable single-selection: search field, filtered list, binding-driven selection, native empty state.
- [command](command.md): Composes input group, rows, keycaps, empty state into search field.
- [empty](empty.md): Places ContentUnavailableView on registry surface, where rows appear.
- [field](field.md): Labeled form field, native control; optional description; error drives invalid state.
- [fold-companion](fold-companion.md): Companion pane across the iPhone Duo fold; sheet on every other display.
- [input](input.md): Styles TextField/SecureField: fill, focus, disabled, invalid.
- [input-group](input-group.md): Wraps field in registry chrome; accessories add search symbol or clear button.
- [item](item.md): Composes content row: media, title, description, accessory; selection at call site.
- [kbd](kbd.md): Styles Text as a keycap for shortcuts.
- [label](label.md): Controls Label icon placement with semantic spacing.
- [macro-progress](macro-progress.md): Nutrition progress via ProgressView.
- [marker](marker.md): Marker style: note, status, separator variants (system line, delivery pill, date rule).
- [message](message.md): One turn: optional author/timestamp header, bubble content, status line, side alignment.
- [message-scroller](message-scroller.md): Chat ScrollView: newest-turn open, follows streamed replies, holds scrolled-up reader, requests history at top.
- [metric-card](metric-card.md): Formatted, semantic metric text.
- [progress](progress.md): Linear ProgressView: determinate, indeterminate, accent, positive, negative.
- [select](select.md): Adds chrome to menu-style Picker.
- [separator](separator.md): Orientation, insets, native Divider.
- [skeleton](skeleton.md): Turns any view into loading placeholder with native redaction.
- [spinner](spinner.md): Compact circular indeterminate ProgressView style.
- [table](table.md): Identifiable rows in aligned columns; numeric monospaced; optional summary rows.
- [textarea](textarea.md): Focus, disabled, invalid chrome.
- [toast](toast.md): Transient status toast: informational, positive, destructive; optional action; swipe/tap/timed dismissal.
- [toggle](toggle.md): Button treatment, Toggle.
- [toggle-group](toggle-group.md): Toggle treatment, ControlGroup.
- [transaction-row](transaction-row.md): Transaction content; caller Button selects.
- [validated-input](validated-input.md): Text field with floating label, rounded border by focus and validity, rules checked while typing and on blur.

## Recipes (26)

Native guidance. Nothing installs; copy the snippet

- [alert-dialog](alert-dialog.md): Modal .alert decision.
- [aspect-ratio](aspect-ratio.md): Native aspectRatio guidance.
- [calendar](calendar.md): Calendar guidance.
- [carousel](carousel.md): Paging ScrollView of cards.
- [chart-tooltip](chart-tooltip.md): chartXSelection + RuleMark annotation.
- [collapsible](collapsible.md): Native DisclosureGroup, distinct from accordion.
- [context-menu](context-menu.md): Native .contextMenu: labeled, role-tagged buttons.
- [date-picker](date-picker.md): Compact DatePicker, closed range, presets Menu.
- [dialog](dialog.md): `.sheet`: system owns detents, drag-dismissal, focus.
- [direction](direction.md): layoutDirection guidance.
- [drawer](drawer.md): Drawer guidance.
- [dropdown-menu](dropdown-menu.md): Menu trigger guidance.
- [fold-arrangement](fold-arrangement.md): Two panes around the iPhone Duo fold: native ArrangementView.
- [input-otp](input-otp.md): One-time-code TextField, not a boxed control.
- [menubar](menubar.md): Scene-level commands via CommandMenu.
- [native-select](native-select.md): Picker menu.
- [popover](popover.md): `.popover` guidance.
- [radio-group](radio-group.md): Picker: inline exclusive group.
- [scroll-area](scroll-area.md): Scrollable content: margins, indicators, clipping.
- [sheet](sheet.md): Side sheet: iPad inspector, iPhone sheet.
- [sidebar](sidebar.md): Sidebar: NavigationSplitView + selection-bound List (iPad).
- [slider](slider.md): Slider: tint, sizing; caller-owned value, labels.
- [switch](switch.md): Toggle: switch style; inherits tint, environment.
- [tabs](tabs.md): Picker segmented; local selection, TabView nav.
- [tooltip](tooltip.md): Tooltip: hint, popover.
- [typography](typography.md): Styles = type scale: weight, design, monospaced digits.
