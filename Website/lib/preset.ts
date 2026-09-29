// Preset codes: a RegistryTheme as a short shareable string.
//
// Mirrors SweetUIKit's Preset.swift, the reference implementation behind
// `sweetui preset`; the format rules live in docs/registry-spec.md
// and Registry/preset_vectors.json pins codes both must reproduce. Fields
// pack little-endian in FIELDS order into one integer, written in base62
// behind a version letter. Numeric fields store their slider-grid index, so a
// code is exact on the tuning panel's grid.
//
// Version b appends, after the version a block, the Create studio's typography,
// elevation, chart, and custom color pairs. An a code still decodes: the
// appended bits read as zero, which is every new field at its default.

export const PRESET_VERSION = "a"
const VERSIONS = ["a", "b"]
const ALPHABET =
  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
// Three optional pairs at 49 bits each on top of the 110-bit a maximum: 257
// bits, 44 base62 digits, plus the letter and slack.
const MAX_LENGTH = 48

export const ACCENTS = [
  "system",
  "ink",
  "blue",
  "indigo",
  "purple",
  "pink",
  "red",
  "orange",
  "yellow",
  "green",
  "mint",
  "teal",
  "cyan",
  "brown",
  "custom",
] as const
export type Accent = (typeof ACCENTS)[number]

export type NumericKey =
  | "surfaceOpacity"
  | "borderOpacity"
  | "borderWidth"
  | "emphasizedBorderWidth"
  | "compactRadius"
  | "controlRadius"
  | "cardRadius"
  | "compactSpacing"
  | "standardSpacing"
  | "sectionSpacing"
  | "controlHorizontalPadding"
  | "disabledOpacity"

/** default, rounded, serif, monospaced: SwiftUI's Font.Design cases. */
export const FONT_DESIGNS = [
  "default",
  "rounded",
  "serif",
  "monospaced",
] as const
export type FontDesign = (typeof FONT_DESIGNS)[number]

/** The chart's series palette. Two bits carry it; index 3 is invalid, not a value. */
export const CHART_PALETTES = ["accent", "spectrum", "monochrome"] as const
export type ChartPalette = (typeof CHART_PALETTES)[number]

/**
 * The surface-step value list, not a grid, so the default sits at index 0 as
 * the spec's rule requires. Elevation is a ladder derived from surface opacity
 * plus or minus this step.
 */
export const SURFACE_STEPS = [
  0.02, 0.0, 0.01, 0.03, 0.04, 0.05, 0.06, 0.07,
] as const

export type PresetTuning = Record<NumericKey, number> & {
  accent: Accent
  darkLabelOnAccent: boolean
  /** #RRGGBB, present only when the accent is custom. */
  customAccent?: string
  /** #RRGGBB for dark appearance, or null; present only when the accent is custom. */
  customAccentDark?: string | null
  fontDesign: FontDesign
  surfaceStep: number
  chartPalette: ChartPalette
  /** #RRGGBB or null. The dark keys are null unless a separate dark color is set. */
  background: string | null
  backgroundDark: string | null
  foreground: string | null
  foregroundDark: string | null
  secondaryForeground: string | null
  secondaryForegroundDark: string | null
}

export type NumericField = {
  key: NumericKey
  bits: number
  minimum: number
  step: number
  count: number
  decimals: number
  label: string
}

/** The slider grid of every numeric knob, in codec order after accent and label. */
export const NUMERIC_FIELDS: NumericField[] = [
  {
    key: "surfaceOpacity",
    bits: 6,
    minimum: 0,
    step: 0.005,
    count: 41,
    decimals: 3,
    label: "Surface opacity",
  },
  {
    key: "borderOpacity",
    bits: 5,
    minimum: 0,
    step: 0.01,
    count: 31,
    decimals: 2,
    label: "Border opacity",
  },
  {
    key: "borderWidth",
    bits: 3,
    minimum: 0.5,
    step: 0.5,
    count: 6,
    decimals: 1,
    label: "Border width",
  },
  {
    key: "emphasizedBorderWidth",
    bits: 3,
    minimum: 1,
    step: 0.5,
    count: 7,
    decimals: 1,
    label: "Emphasized border",
  },
  {
    key: "compactRadius",
    bits: 4,
    minimum: 0,
    step: 1,
    count: 13,
    decimals: 0,
    label: "Compact radius",
  },
  {
    key: "controlRadius",
    bits: 5,
    minimum: 0,
    step: 1,
    count: 23,
    decimals: 0,
    label: "Control radius",
  },
  {
    key: "cardRadius",
    bits: 6,
    minimum: 0,
    step: 1,
    count: 33,
    decimals: 0,
    label: "Card radius",
  },
  {
    key: "compactSpacing",
    bits: 4,
    minimum: 4,
    step: 1,
    count: 13,
    decimals: 0,
    label: "Compact spacing",
  },
  {
    key: "standardSpacing",
    bits: 5,
    minimum: 8,
    step: 1,
    count: 25,
    decimals: 0,
    label: "Standard spacing",
  },
  {
    key: "sectionSpacing",
    bits: 6,
    minimum: 12,
    step: 1,
    count: 37,
    decimals: 0,
    label: "Section spacing",
  },
  {
    key: "controlHorizontalPadding",
    bits: 5,
    minimum: 8,
    step: 1,
    count: 17,
    decimals: 0,
    label: "Control padding",
  },
  {
    key: "disabledOpacity",
    bits: 4,
    minimum: 0.2,
    step: 0.05,
    count: 13,
    decimals: 2,
    label: "Disabled opacity",
  },
]

export function maximum(field: NumericField): number {
  return roundTo(field.minimum + (field.count - 1) * field.step, field.decimals)
}

/** RegistryTheme() with no arguments. */
export const DEFAULT_TUNING: PresetTuning = {
  accent: "system",
  darkLabelOnAccent: false,
  surfaceOpacity: 0.055,
  borderOpacity: 0.08,
  borderWidth: 1,
  emphasizedBorderWidth: 2,
  compactRadius: 6,
  controlRadius: 8,
  cardRadius: 16,
  compactSpacing: 8,
  standardSpacing: 16,
  sectionSpacing: 24,
  controlHorizontalPadding: 12,
  disabledOpacity: 0.5,
  fontDesign: "default",
  surfaceStep: 0.02,
  chartPalette: "accent",
  background: null,
  backgroundDark: null,
  foreground: null,
  foregroundDark: null,
  secondaryForeground: null,
  secondaryForegroundDark: null,
}

function roundTo(value: number, decimals: number): number {
  const scale = 10 ** decimals
  return Math.round(value * scale) / scale
}

function fieldIndex(field: NumericField, value: number): number {
  const index = Math.round((value - field.minimum) / field.step)
  return Math.max(0, Math.min(field.count - 1, index))
}

/** Snaps a value to its field's slider grid, the value a code can carry. */
export function snap(field: NumericField, value: number): number {
  return roundTo(
    field.minimum + fieldIndex(field, value) * field.step,
    field.decimals
  )
}

/** The index of the nearest surface step in the value list (index 0 is the 0.02 default). */
export function surfaceStepIndex(value: number): number {
  let best = 0
  for (let index = 1; index < SURFACE_STEPS.length; index += 1) {
    if (
      Math.abs(SURFACE_STEPS[index] - value) <
      Math.abs(SURFACE_STEPS[best] - value)
    )
      best = index
  }
  return best
}

export function isPresetCode(value: string): boolean {
  if (
    typeof value !== "string" ||
    value.length < 2 ||
    value.length > MAX_LENGTH
  )
    return false
  if (!VERSIONS.includes(value[0])) return false
  for (let position = 1; position < value.length; position += 1) {
    if (!ALPHABET.includes(value[position])) return false
  }
  return true
}

/** The code inside pasted text: bare, or behind a `--preset` flag. */
export function presetCodeIn(text: string): string | null {
  let candidate = text.trim()
  const flagged = candidate.match(/^--preset\s+(\S+)$/)
  if (flagged) candidate = flagged[1]
  return isPresetCode(candidate) ? candidate : null
}

function toBase62(number: bigint): string {
  if (number === BigInt(0)) return "0"
  const base = BigInt(62)
  let digits = ""
  let remaining = number
  while (remaining > BigInt(0)) {
    digits = ALPHABET[Number(remaining % base)] + digits
    remaining /= base
  }
  return digits
}

function fromBase62(text: string): bigint {
  let number = BigInt(0)
  for (const character of text) {
    number = number * BigInt(62) + BigInt(ALPHABET.indexOf(character))
  }
  return number
}

function rgbBits(hex: string | undefined | null): bigint {
  const match = /^#([0-9A-Fa-f]{6})$/.exec(hex ?? "")
  if (!match)
    throw new Error(
      `a custom color must be #RRGGBB, not ${JSON.stringify(hex)}`
    )
  return BigInt(parseInt(match[1], 16))
}

function hex(bits: bigint): string {
  return (
    "#" +
    Number(bits & BigInt(0xffffff))
      .toString(16)
      .toUpperCase()
      .padStart(6, "0")
  )
}

/** A version b string's index, defaulting to 0 when the field is absent. */
function stringIndex(
  value: string | undefined | null,
  values: readonly string[],
  field: string
): number {
  if (value === undefined || value === null) return 0
  const index = values.indexOf(value)
  if (index < 0)
    throw new Error(
      `${field} must be one of ${values.join(", ")}, not ${JSON.stringify(value)}`
    )
  return index
}

export function encodePreset(tuning: PresetTuning): string {
  let bits = BigInt(0)
  let offset = 0
  const put = (index: number, width: number) => {
    bits |= BigInt(index) << BigInt(offset)
    offset += width
  }
  const putBits = (value: bigint, width: number) => {
    bits |= value << BigInt(offset)
    offset += width
  }
  const accentIndex = ACCENTS.indexOf(tuning.accent)
  if (accentIndex < 0) throw new Error(`unknown accent ${tuning.accent}`)
  put(accentIndex, 4)
  put(tuning.darkLabelOnAccent ? 1 : 0, 1)
  for (const field of NUMERIC_FIELDS) {
    put(fieldIndex(field, tuning[field.key]), field.bits)
  }
  if (tuning.accent === "custom") {
    putBits(rgbBits(tuning.customAccent), 24)
    if (tuning.customAccentDark) {
      put(1, 1)
      putBits(rgbBits(tuning.customAccentDark), 24)
    } else {
      put(0, 1)
    }
  }
  // Version b appends the new fields; when every one is at its default the bits
  // are zero and the code is written as a, so an unchanged tuning keeps its a code.
  const fontIndex = stringIndex(tuning.fontDesign, FONT_DESIGNS, "fontDesign")
  const chartIndex = stringIndex(
    tuning.chartPalette,
    CHART_PALETTES,
    "chartPalette"
  )
  const stepIndex =
    tuning.surfaceStep === undefined || tuning.surfaceStep === null
      ? 0
      : surfaceStepIndex(tuning.surfaceStep)
  let appended = fontIndex !== 0 || stepIndex !== 0 || chartIndex !== 0
  put(fontIndex, 2)
  put(stepIndex, 3)
  put(chartIndex, 2)
  const pairs: [string | null | undefined, string | null | undefined][] = [
    [tuning.background, tuning.backgroundDark],
    [tuning.foreground, tuning.foregroundDark],
    [tuning.secondaryForeground, tuning.secondaryForegroundDark],
  ]
  for (const [light, dark] of pairs) {
    if (light) {
      appended = true
      put(1, 1)
      putBits(rgbBits(light), 24)
      if (dark) {
        put(1, 1)
        putBits(rgbBits(dark), 24)
      } else {
        put(0, 1)
      }
    } else {
      put(0, 1)
    }
  }
  return (appended ? "b" : "a") + toBase62(bits)
}

export function decodePreset(code: string): PresetTuning | null {
  if (!isPresetCode(code)) return null
  const bits = fromBase62(code.slice(1))
  let offset = 0
  const mask = (width: number) => (BigInt(1) << BigInt(width)) - BigInt(1)
  const take = (width: number) => {
    const value = Number((bits >> BigInt(offset)) & mask(width))
    offset += width
    return value
  }
  const takeBits = (width: number) => {
    const value = (bits >> BigInt(offset)) & mask(width)
    offset += width
    return value
  }
  const takePair = (): [string | null, string | null] => {
    if (take(1) !== 1) return [null, null]
    const light = hex(takeBits(24))
    const dark = take(1) === 1 ? hex(takeBits(24)) : null
    return [light, dark]
  }
  const accentIndex = take(4)
  if (accentIndex >= ACCENTS.length) return null
  // The a shape carries no version b keys; only a b code appends them, exactly
  // as SweetUIKit's Preset.decode does, so an a code decodes byte for byte the
  // same tuning it always did.
  const tuning = {
    accent: ACCENTS[accentIndex],
    darkLabelOnAccent: take(1) === 1,
  } as PresetTuning
  for (const field of NUMERIC_FIELDS) {
    const index = take(field.bits)
    if (index >= field.count) return null
    tuning[field.key] = roundTo(
      field.minimum + index * field.step,
      field.decimals
    )
  }
  if (tuning.accent === "custom") {
    tuning.customAccent = hex(takeBits(24))
    tuning.customAccentDark = take(1) === 1 ? hex(takeBits(24)) : null
  }
  if (code[0] === "b") {
    tuning.fontDesign = FONT_DESIGNS[take(2)]
    tuning.surfaceStep = SURFACE_STEPS[take(3)]
    const chartIndex = take(2)
    if (chartIndex >= CHART_PALETTES.length) return null
    tuning.chartPalette = CHART_PALETTES[chartIndex]
    ;[tuning.background, tuning.backgroundDark] = takePair()
    ;[tuning.foreground, tuning.foregroundDark] = takePair()
    ;[tuning.secondaryForeground, tuning.secondaryForegroundDark] = takePair()
  }
  return tuning
}

export function randomTuning(): PresetTuning {
  const pick = (count: number) => Math.floor(Math.random() * count)
  const tuning: PresetTuning = {
    ...DEFAULT_TUNING,
    accent: ACCENTS[pick(ACCENTS.length)],
    darkLabelOnAccent: pick(2) === 1,
    fontDesign: FONT_DESIGNS[pick(FONT_DESIGNS.length)],
    surfaceStep: SURFACE_STEPS[pick(SURFACE_STEPS.length)],
    chartPalette: (["accent", "spectrum", "monochrome"] as const)[pick(3)],
  }
  for (const field of NUMERIC_FIELDS) {
    tuning[field.key] = roundTo(
      field.minimum + pick(field.count) * field.step,
      field.decimals
    )
  }
  if (tuning.accent === "custom") {
    tuning.customAccent = hex(BigInt(pick(0x1000000)))
    tuning.customAccentDark =
      pick(2) === 1 ? hex(BigInt(pick(0x1000000))) : null
  }
  return tuning
}

// MARK: Swift

const ACCENT_SWIFT: Partial<Record<Accent, string>> = { ink: ".primary" }
for (const accent of ACCENTS) {
  if (accent !== "system" && accent !== "ink" && accent !== "custom")
    ACCENT_SWIFT[accent] = `.${accent}`
}

/** A channel with the fewest decimals, never under three, that reads back as the 8-bit value. */
function channelLiteral(value: number): string {
  for (let digits = 3; digits <= 15; digits++) {
    const text = value.toFixed(digits)
    if (Math.abs(Number(text) - value) <= 1e-12) return text
  }
  return String(value)
}

function points(value: number): string {
  return Number.isInteger(value) ? String(value) : value.toFixed(1)
}

function channels(hex: string): [string, string, string] {
  const bits = Number(rgbBits(hex))
  return [16, 8, 0].map((shift) =>
    channelLiteral(((bits >> shift) & 0xff) / 255)
  ) as [string, string, string]
}

function colorSource(hex: string, ui: boolean): string {
  const [red, green, blue] = channels(hex)
  return ui
    ? `UIColor(red: ${red}, green: ${green}, blue: ${blue}, alpha: 1)`
    : `Color(red: ${red}, green: ${green}, blue: ${blue})`
}

/** A color argument, dynamic when a dark value is set (the accent's shape). */
function colorArgument(
  name: string,
  light: string,
  dark: string | null
): string[] {
  if (dark) {
    return [
      `${name}: Color(uiColor: UIColor { traits in`,
      "    traits.userInterfaceStyle == .dark",
      `        ? ${colorSource(dark, true)}`,
      `        : ${colorSource(light, true)}`,
      "})",
    ]
  }
  return [`${name}: ${colorSource(light, false)}`]
}

const METRIC_KEYS: NumericKey[] = [
  "compactSpacing",
  "standardSpacing",
  "sectionSpacing",
  "controlHorizontalPadding",
  "borderWidth",
  "emphasizedBorderWidth",
  "compactRadius",
  "controlRadius",
  "cardRadius",
]

/** The `RegistryTheme(...)` call, one argument per line, as the Showcase's Copy Swift writes it. */
export function initializerLines(tuning: PresetTuning): string[] {
  const args: string[][] = []
  if (tuning.accent === "custom" && tuning.customAccent) {
    args.push(
      colorArgument(
        "accent",
        tuning.customAccent,
        tuning.customAccentDark ?? null
      )
    )
  } else if (ACCENT_SWIFT[tuning.accent]) {
    args.push([`accent: ${ACCENT_SWIFT[tuning.accent]}`])
  }
  const onAccent =
    tuning.accent === "ink"
      ? "Color(uiColor: .systemBackground)"
      : tuning.darkLabelOnAccent
        ? ".black"
        : ".white"
  args.push([`onAccent: ${onAccent}`])
  args.push([`surface: .primary.opacity(${tuning.surfaceOpacity.toFixed(3)})`])
  args.push([`border: .primary.opacity(${tuning.borderOpacity.toFixed(3)})`])
  args.push([`disabledOpacity: ${tuning.disabledOpacity.toFixed(3)}`])
  const metrics = ["metrics: RegistryMetrics("]
  METRIC_KEYS.forEach((key, index) => {
    metrics.push(
      `    ${key}: ${points(tuning[key])}${index === METRIC_KEYS.length - 1 ? "" : ","}`
    )
  })
  metrics.push(")")
  args.push(metrics)
  // Version b fields print only when present and non-default, in the codec's
  // append order and after metrics, the order RegistryTheme's initializer
  // declares, so an a-shaped tuning exports unchanged Swift that compiles.
  if (tuning.fontDesign && tuning.fontDesign !== "default")
    args.push([`fontDesign: .${tuning.fontDesign}`])
  // The surface fill alone does not carry surfaceOpacity, and surface(at:)
  // steps an elevated level from it.
  if (tuning.surfaceOpacity !== 0.055)
    args.push([`surfaceOpacity: ${tuning.surfaceOpacity.toFixed(3)}`])
  if (typeof tuning.surfaceStep === "number" && tuning.surfaceStep !== 0.02)
    args.push([`surfaceStep: ${tuning.surfaceStep.toFixed(2)}`])
  if (tuning.chartPalette && tuning.chartPalette !== "accent")
    args.push([`chartPalette: .${tuning.chartPalette}`])
  if (tuning.background)
    args.push(
      colorArgument("background", tuning.background, tuning.backgroundDark)
    )
  if (tuning.foreground)
    args.push(
      colorArgument("foreground", tuning.foreground, tuning.foregroundDark)
    )
  if (tuning.secondaryForeground) {
    args.push(
      colorArgument(
        "secondaryForeground",
        tuning.secondaryForeground,
        tuning.secondaryForegroundDark
      )
    )
  }

  const lines = ["RegistryTheme("]
  args.forEach((block, blockIndex) => {
    const lastBlock = blockIndex === args.length - 1
    block.forEach((line, lineIndex) => {
      const lastLine = lineIndex === block.length - 1
      lines.push("    " + line + (lastLine && !lastBlock ? "," : ""))
    })
  })
  lines.push(")")
  return lines
}

/** The comment showing how a custom font family keeps Dynamic Type. */
function fontFamilyComment(family: string): string[] {
  return [
    "",
    `// Custom font family "${family}" is not part of the preset code; it scales with`,
    "// Dynamic Type through relativeTo. Register the font file in Info.plist, then:",
    `// ContentView().environment(\\.font, Font.custom("${family}", size: 17, relativeTo: .body))`,
  ]
}

/** The snippet to paste, in the tuning panel's Copy Swift shape. */
export function swiftSource(tuning: PresetTuning, fontFamily?: string): string {
  const lines = initializerLines(tuning)
  lines[0] = "let theme = " + lines[0]
  lines.push(
    "",
    "// Apply once at the root of your scene; every registry item below inherits it.",
    "ContentView()",
    "    .registryTheme(theme)"
  )
  if (fontFamily && fontFamily.trim())
    lines.push(...fontFamilyComment(fontFamily.trim()))
  return lines.join("\n")
}

export function applyCommand(code: string): string {
  return `sweetui preset apply ${code} --destination Sources/YourFeature/Components`
}

/** The canonical site, mirroring Preset.siteURL in Sources/SweetUIKit/Preset.swift. */
export const SITE_URL = "https://sweetui.dev"

export function createLink(code: string): string {
  return `${SITE_URL}/create?preset=${code}`
}

// MARK: Density and the type scale

export type DensityName = "compact" | "regular" | "generous"
type DensityKey =
  | "compactSpacing"
  | "standardSpacing"
  | "sectionSpacing"
  | "controlHorizontalPadding"
  | "compactRadius"
  | "controlRadius"
  | "cardRadius"

/** Density is not a code field: each is a bundle of the existing metrics. */
export const DENSITIES: {
  name: DensityName
  label: string
  metrics: Record<DensityKey, number>
}[] = [
  {
    name: "compact",
    label: "Compact",
    metrics: {
      compactSpacing: 6,
      standardSpacing: 12,
      sectionSpacing: 20,
      controlHorizontalPadding: 10,
      compactRadius: 4,
      controlRadius: 6,
      cardRadius: 12,
    },
  },
  {
    name: "regular",
    label: "Regular",
    metrics: {
      compactSpacing: 8,
      standardSpacing: 16,
      sectionSpacing: 24,
      controlHorizontalPadding: 12,
      compactRadius: 6,
      controlRadius: 8,
      cardRadius: 16,
    },
  },
  {
    name: "generous",
    label: "Generous",
    metrics: {
      compactSpacing: 8,
      standardSpacing: 16,
      sectionSpacing: 28,
      controlHorizontalPadding: 16,
      compactRadius: 10,
      controlRadius: 14,
      cardRadius: 24,
    },
  },
]

export function applyDensity(
  tuning: PresetTuning,
  name: DensityName
): PresetTuning {
  const density = DENSITIES.find((entry) => entry.name === name)
  return density ? { ...tuning, ...density.metrics } : tuning
}

/** The density the current metrics match exactly, or null for a custom set. */
export function matchingDensity(tuning: PresetTuning): DensityName | null {
  const density = DENSITIES.find((entry) =>
    (Object.keys(entry.metrics) as DensityKey[]).every(
      (key) => tuning[key] === entry.metrics[key]
    )
  )
  return density ? density.name : null
}

/** Apple's eleven text styles at their Large (default) Dynamic Type sizes. */
export const TEXT_STYLES: {
  style: string
  label: string
  size: number
  weight: number
}[] = [
  { style: "largeTitle", label: "Large Title", size: 34, weight: 400 },
  { style: "title", label: "Title", size: 28, weight: 400 },
  { style: "title2", label: "Title 2", size: 22, weight: 400 },
  { style: "title3", label: "Title 3", size: 20, weight: 400 },
  { style: "headline", label: "Headline", size: 17, weight: 600 },
  { style: "body", label: "Body", size: 17, weight: 400 },
  { style: "callout", label: "Callout", size: 16, weight: 400 },
  { style: "subheadline", label: "Subheadline", size: 15, weight: 400 },
  { style: "footnote", label: "Footnote", size: 13, weight: 400 },
  { style: "caption", label: "Caption", size: 12, weight: 400 },
  { style: "caption2", label: "Caption 2", size: 11, weight: 400 },
]

/** CSS font-family stand-ins for the four SwiftUI designs, for the preview only. */
export const FONT_DESIGN_CSS: Record<FontDesign, string> = {
  default: "system-ui, -apple-system, sans-serif",
  rounded: "ui-rounded, 'SF Pro Rounded', system-ui, sans-serif",
  serif: "ui-serif, Georgia, 'Times New Roman', serif",
  monospaced: "ui-monospace, 'SF Mono', 'Menlo', monospace",
}

export const FONT_DESIGN_TITLES: Record<FontDesign, string> = {
  default: "Default",
  rounded: "Rounded",
  serif: "Serif",
  monospaced: "Monospaced",
}

// MARK: Elevation and charts

export const SURFACE_LEVELS = [
  { level: "lowest", label: "Lowest", offset: -2 },
  { level: "low", label: "Low", offset: -1 },
  { level: "regular", label: "Regular", offset: 0 },
  { level: "high", label: "High", offset: 1 },
] as const

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value))
}

/** The four surface levels as opacities: surface opacity offset by the step, clamped. */
export function surfaceLadder(
  tuning: PresetTuning
): { level: string; label: string; opacity: number }[] {
  return SURFACE_LEVELS.map((entry) => ({
    level: entry.level,
    label: entry.label,
    opacity: clamp01(
      roundTo(tuning.surfaceOpacity + entry.offset * tuning.surfaceStep, 3)
    ),
  }))
}

function hexToRgb(value: string): [number, number, number] {
  const bits = Number(rgbBits(value))
  return [(bits >> 16) & 0xff, (bits >> 8) & 0xff, bits & 0xff]
}

/** Six CSS colors that stand in for the chart's series scale, for a swatch strip. */
export function chartSwatches(
  tuning: PresetTuning,
  appearance: "light" | "dark"
): string[] {
  if (tuning.chartPalette === "spectrum") {
    return (["blue", "orange", "green", "pink", "purple", "teal"] as const).map(
      (hue) => IOS_COLORS[hue][appearance]
    )
  }
  if (tuning.chartPalette === "monochrome") {
    const ink = appearance === "dark" ? 255 : 0
    return [0.9, 0.75, 0.6, 0.45, 0.3, 0.18].map(
      (alpha) => `rgba(${ink}, ${ink}, ${ink}, ${alpha})`
    )
  }
  const [red, green, blue] = hexToRgb(accentColor(tuning, appearance))
  return [1, 0.85, 0.7, 0.55, 0.4, 0.25].map(
    (alpha) => `rgba(${red}, ${green}, ${blue}, ${alpha})`
  )
}

export const CHART_PALETTE_TITLES: Record<ChartPalette, string> = {
  accent: "Accent tints",
  spectrum: "Spectrum",
  monochrome: "Monochrome",
}

// MARK: Presets and colors

/** The six foundation presets (RegistryTheme.swift) as tunings. */
export const PRESETS: { name: string; slug: string; tuning: PresetTuning }[] = [
  { name: "System", slug: "system", tuning: { ...DEFAULT_TUNING } },
  {
    name: "Graphite",
    slug: "graphite",
    tuning: {
      ...DEFAULT_TUNING,
      accent: "ink",
      surfaceOpacity: 0.05,
      borderOpacity: 0.1,
    },
  },
  {
    name: "Indigo",
    slug: "indigo",
    tuning: { ...DEFAULT_TUNING, accent: "indigo" },
  },
  { name: "Rose", slug: "rose", tuning: { ...DEFAULT_TUNING, accent: "pink" } },
  {
    name: "Emerald",
    slug: "emerald",
    tuning: { ...DEFAULT_TUNING, accent: "green" },
  },
  {
    name: "Amber",
    slug: "amber",
    tuning: { ...DEFAULT_TUNING, accent: "yellow", darkLabelOnAccent: true },
  },
  {
    name: "Mango",
    slug: "mango",
    tuning: {
      ...DEFAULT_TUNING,
      accent: "custom",
      customAccent: "#FFA033",
      customAccentDark: "#FFB84D",
      darkLabelOnAccent: true,
      surfaceOpacity: 0.07,
      borderOpacity: 0,
      compactRadius: 10,
      controlRadius: 14,
      cardRadius: 24,
      sectionSpacing: 28,
      controlHorizontalPadding: 16,
      disabledOpacity: 0.4,
    },
  },
]

export function presetMatching(
  tuning: PresetTuning
): (typeof PRESETS)[number] | undefined {
  const code = encodePreset(tuning)
  return PRESETS.find((preset) => encodePreset(preset.tuning) === code)
}

/**
 * The SwiftUI system colors as they resolve on the pinned iPhone 17, iOS 27
 * simulator, measured 2026-09-05 with Color.resolve(in:) in light and dark
 * environments (identical to UIColor.system*). `ink` is `.primary`, the label
 * color; `system` is the app tint, system blue in the Showcase.
 */
export const IOS_COLORS: Record<
  Exclude<Accent, "custom">,
  { light: string; dark: string }
> = {
  system: { light: "#0088FF", dark: "#0091FF" },
  ink: { light: "#000000", dark: "#FFFFFF" },
  blue: { light: "#0088FF", dark: "#0091FF" },
  indigo: { light: "#6155F5", dark: "#6D7CFF" },
  purple: { light: "#CB30E0", dark: "#DB34F2" },
  pink: { light: "#FF2D55", dark: "#FF375F" },
  red: { light: "#FF383C", dark: "#FF4245" },
  orange: { light: "#FF8D28", dark: "#FF9230" },
  yellow: { light: "#FFCC00", dark: "#FFD600" },
  green: { light: "#34C759", dark: "#30D158" },
  mint: { light: "#00C8B3", dark: "#00DAC3" },
  teal: { light: "#00C3D0", dark: "#00D2E0" },
  cyan: { light: "#00C0E8", dark: "#3CD3FE" },
  brown: { light: "#AC7F5E", dark: "#B78A66" },
}

export const ACCENT_TITLES: Record<Accent, string> = {
  system: "System",
  ink: "Ink",
  blue: "Blue",
  indigo: "Indigo",
  purple: "Purple",
  pink: "Pink",
  red: "Red",
  orange: "Orange",
  yellow: "Yellow",
  green: "Green",
  mint: "Mint",
  teal: "Teal",
  cyan: "Cyan",
  brown: "Brown",
  custom: "Custom",
}

/** The accent as a CSS color for an appearance. */
export function accentColor(
  tuning: PresetTuning,
  appearance: "light" | "dark"
): string {
  if (tuning.accent === "custom") {
    return (
      (appearance === "dark" ? tuning.customAccentDark : null) ??
      tuning.customAccent ??
      "#000000"
    )
  }
  return IOS_COLORS[tuning.accent][appearance]
}

/** The label drawn on accent fills. */
export function onAccentColor(
  tuning: PresetTuning,
  appearance: "light" | "dark"
): string {
  if (tuning.accent === "ink")
    return appearance === "dark" ? "#000000" : "#FFFFFF"
  return tuning.darkLabelOnAccent ? "#000000" : "#FFFFFF"
}

/** The content background as a CSS color, the system background unless set. */
export function backgroundColor(
  tuning: PresetTuning,
  appearance: "light" | "dark"
): string {
  const custom =
    appearance === "dark"
      ? (tuning.backgroundDark ?? tuning.background)
      : tuning.background
  if (custom) return custom
  return appearance === "dark" ? "#000000" : "#FFFFFF"
}

/** The primary label as a CSS color, the system label unless set. */
export function foregroundColor(
  tuning: PresetTuning,
  appearance: "light" | "dark"
): string {
  const custom =
    appearance === "dark"
      ? (tuning.foregroundDark ?? tuning.foreground)
      : tuning.foreground
  if (custom) return custom
  return appearance === "dark" ? "#FFFFFF" : "#000000"
}

// MARK: Theme package

function surfaceRgba(appearance: "light" | "dark", opacity: number): string {
  const ink = appearance === "dark" ? "255, 255, 255" : "0, 0, 0"
  return `rgba(${ink}, ${opacity})`
}

/** The RegistryTheme+App.swift a team drops in, the installer's file by hand. */
export function themeFileSource(
  tuning: PresetTuning,
  code: string,
  fontFamily?: string
): string {
  const body = initializerLines(tuning)
  const needsUIKit =
    tuning.accent === "ink" ||
    (tuning.accent === "custom" && Boolean(tuning.customAccentDark)) ||
    Boolean(tuning.backgroundDark) ||
    Boolean(tuning.foregroundDark) ||
    Boolean(tuning.secondaryForegroundDark)
  const lines = ["import SwiftUI", "import SweetUIFoundations"]
  if (needsUIKit) lines.push("import UIKit")
  lines.push(
    "",
    `// sweetui preset ${code}`,
    `// ${createLink(code)}`,
    "// Apply once at the scene root: ContentView().registryTheme(.app).",
    "",
    "extension RegistryTheme {",
    `    static let app = ${body[0]}`
  )
  for (const line of body.slice(1)) lines.push("    " + line)
  lines.push("}")
  if (fontFamily && fontFamily.trim())
    lines.push(...fontFamilyComment(fontFamily.trim()))
  lines.push("")
  return lines.join("\n")
}

function colorPairCells(
  tuning: PresetTuning,
  light: (a: "light" | "dark") => string,
  isSet: boolean,
  fallback: string
): [string, string] {
  if (!isSet) return [fallback, fallback]
  return ["`" + light("light") + "`", "`" + light("dark") + "`"]
}

/** THEME.md: every token with its light and dark value, plus the scales and the code. */
export function themeMarkdown(
  tuning: PresetTuning,
  code: string,
  fontFamily?: string
): string {
  const density = matchingDensity(tuning)
  const ladder = surfaceLadder(tuning)
  const palette = tuning.chartPalette
  const family =
    fontFamily && fontFamily.trim() ? fontFamily.trim() : "System default"
  const [bgLight, bgDark] = colorPairCells(
    tuning,
    (a) => backgroundColor(tuning, a),
    Boolean(tuning.background),
    "System background"
  )
  const [fgLight, fgDark] = colorPairCells(
    tuning,
    (a) => foregroundColor(tuning, a),
    Boolean(tuning.foreground),
    "System label"
  )
  const secLight = tuning.secondaryForeground
    ? "`" + tuning.secondaryForeground + "`"
    : "System secondary label"
  const secDark = tuning.secondaryForeground
    ? "`" + (tuning.secondaryForegroundDark ?? tuning.secondaryForeground) + "`"
    : "System secondary label"
  const lines: string[] = [
    "# Theme package",
    "",
    `Preset code \`${code}\`. Open it in Create: ${createLink(code)}`,
    "",
    "## Colors",
    "",
    "| Token | Light | Dark |",
    "| --- | --- | --- |",
    `| accent | \`${accentColor(tuning, "light")}\` | \`${accentColor(tuning, "dark")}\` |`,
    `| onAccent | \`${onAccentColor(tuning, "light")}\` | \`${onAccentColor(tuning, "dark")}\` |`,
    `| surface | \`${surfaceRgba("light", tuning.surfaceOpacity)}\` | \`${surfaceRgba("dark", tuning.surfaceOpacity)}\` |`,
    `| border | \`${surfaceRgba("light", tuning.borderOpacity)}\` | \`${surfaceRgba("dark", tuning.borderOpacity)}\` |`,
    `| background | ${bgLight} | ${bgDark} |`,
    `| foreground | ${fgLight} | ${fgDark} |`,
    `| secondaryForeground | ${secLight} | ${secDark} |`,
    "",
    "## Metrics and state",
    "",
    "| Token | Value |",
    "| --- | --- |",
    `| density | ${density ?? "custom"} |`,
    `| disabledOpacity | ${tuning.disabledOpacity} |`,
    `| compactSpacing / standardSpacing / sectionSpacing | ${tuning.compactSpacing} / ${tuning.standardSpacing} / ${tuning.sectionSpacing} |`,
    `| controlHorizontalPadding | ${tuning.controlHorizontalPadding} |`,
    `| borderWidth / emphasizedBorderWidth | ${tuning.borderWidth} / ${tuning.emphasizedBorderWidth} |`,
    `| compactRadius / controlRadius / cardRadius | ${tuning.compactRadius} / ${tuning.controlRadius} / ${tuning.cardRadius} |`,
    "",
    "## Elevation ladder",
    "",
    `Surface opacity ${tuning.surfaceOpacity} stepped by ${tuning.surfaceStep}.`,
    "",
    "| Level | Opacity |",
    "| --- | --- |",
    ...ladder.map((entry) => `| ${entry.label} | ${entry.opacity} |`),
    "",
    "## Chart palette",
    "",
    `${palette}: ${chartSwatches(tuning, "light").join(", ")}`,
    "",
    "## Type scale",
    "",
    `Font design: ${FONT_DESIGN_TITLES[tuning.fontDesign]}. Custom family: ${family}.`,
    "",
    "| Style | Size |",
    "| --- | --- |",
    ...TEXT_STYLES.map((entry) => `| ${entry.label} | ${entry.size} |`),
    "",
  ]
  if (fontFamily && fontFamily.trim()) {
    lines.push(
      `The custom family "${family}" is not carried in the preset code. Register the font file in`,
      'Info.plist and apply it with Font.custom("' +
        family +
        '", size:relativeTo:) so it keeps Dynamic Type.',
      ""
    )
  }
  return lines.join("\n")
}
