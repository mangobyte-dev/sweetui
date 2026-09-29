"use client"

import * as React from "react"
import { useSearchParams } from "next/navigation"
import { useTheme } from "next-themes"
import {
  DicesIcon,
  Link2Icon,
  MoonIcon,
  RotateCcwIcon,
  SunIcon,
} from "lucide-react"

import { CopyButton } from "@/components/copy-button"
import { PresetBoard } from "@/components/preset-board"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Slider } from "@/components/ui/slider"
import { Switch } from "@/components/ui/switch"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import {
  ACCENTS,
  ACCENT_TITLES,
  CHART_PALETTES,
  CHART_PALETTE_TITLES,
  DEFAULT_TUNING,
  DENSITIES,
  FONT_DESIGNS,
  FONT_DESIGN_CSS,
  FONT_DESIGN_TITLES,
  IOS_COLORS,
  NUMERIC_FIELDS,
  PRESETS,
  SURFACE_STEPS,
  TEXT_STYLES,
  applyCommand,
  applyDensity,
  backgroundColor,
  chartSwatches,
  decodePreset,
  encodePreset,
  foregroundColor,
  matchingDensity,
  maximum,
  presetCodeIn,
  presetMatching,
  randomTuning,
  surfaceLadder,
  swiftSource,
  themeFileSource,
  themeMarkdown,
  type Accent,
  type DensityName,
  type FontDesign,
  type NumericField,
  type PresetTuning,
} from "@/lib/preset"
import { asset, registry } from "@/lib/registry"
import { HIGHLIGHT_CSS, HIGHLIGHT_STYLE_HREF, highlightSwift } from "@/lib/swift-highlight"
import { cn } from "@/lib/utils"

type Appearance = "light" | "dark"

/** The Point-Free Evolution code box, dark in both color modes. */
const CODE_BOX = "bg-[#1f1f24] text-[#dfdfe0] font-mono text-[13.5px] leading-[1.6]"
/** The copy button that reads on that box. */
const DARK_COPY = "border-white/15 bg-white/5 text-white/70 hover:bg-white/10 hover:text-white"

const SHOWCASE_DEFAULT: PresetTuning = { ...DEFAULT_TUNING, accent: "indigo" }

/** A decoded tuning filled to the full shape: an a code carries no version b keys. */
function normalize(tuning: PresetTuning): PresetTuning {
  return { ...DEFAULT_TUNING, ...tuning }
}

function initialTuning(requested: string | null): PresetTuning {
  if (requested === "random") return randomTuning()
  const decoded = requested ? decodePreset(requested) : null
  return decoded ? normalize(decoded) : SHOWCASE_DEFAULT
}

/** Compose a RegistryTheme from the Showcase's tuning knobs and share it as a preset code. */
export function CreateStudio() {
  const searchParams = useSearchParams()
  const [tuning, setTuning] = React.useState<PresetTuning>(() =>
    initialTuning(searchParams.get("preset"))
  )
  const [fontFamily, setFontFamily] = React.useState("")
  const { resolvedTheme } = useTheme()
  const [chosenAppearance, setChosenAppearance] =
    React.useState<Appearance | null>(null)
  const appearance: Appearance =
    chosenAppearance ?? (resolvedTheme === "dark" ? "dark" : "light")
  const code = encodePreset(tuning)

  // WebKit throws a SecurityError past 100 history.replaceState calls per 10 seconds, and the
  // App Router mirrors each of ours with one of its own, so a dragged slider would cross the
  // limit in seconds and the throw from the router's own call lands on the error screen. The
  // address bar is rewritten once the tuning settles instead.
  React.useEffect(() => {
    const timer = window.setTimeout(() => {
      try {
        window.history.replaceState(null, "", `?preset=${code}`)
      } catch {
        // A sandboxed preview cannot rewrite the address; the code stays visible on the page.
      }
    }, 400)
    return () => window.clearTimeout(timer)
  }, [code])

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_336px]">
      <style href={HIGHLIGHT_STYLE_HREF} precedence="pfe-highlight">
        {HIGHLIGHT_CSS}
      </style>
      <div className="flex min-w-0 flex-col gap-4">
        <PreviewPanel
          tuning={tuning}
          code={code}
          appearance={appearance}
          fontFamily={fontFamily}
          onAppearance={setChosenAppearance}
        />
        <CodeBar code={code} onTuning={setTuning} />
      </div>
      <Customizer
        tuning={tuning}
        appearance={appearance}
        fontFamily={fontFamily}
        onTuning={setTuning}
        onFontFamily={setFontFamily}
      />
    </div>
  )
}

function PreviewPanel({
  tuning,
  code,
  appearance,
  fontFamily,
  onAppearance,
}: {
  tuning: PresetTuning
  code: string
  appearance: Appearance
  fontFamily: string
  onAppearance: (appearance: Appearance) => void
}) {
  const matched = presetMatching(tuning)
  const capture = matched
    ? registry.presets.find((preset) => preset.slug === matched.slug)
        ?.screenshots[appearance]
    : null
  const swift = swiftSource(tuning, fontFamily)
  const themeFile = themeFileSource(tuning, code, fontFamily)
  const themeDoc = themeMarkdown(tuning, code, fontFamily)

  return (
    <Tabs
      defaultValue="preview"
      className="gap-0 overflow-hidden rounded-xl border"
    >
      <div className="flex min-w-0 items-center justify-between gap-2 border-b bg-muted/50 px-2 py-1.5">
        <TabsList>
          <TabsTrigger value="preview">Preview</TabsTrigger>
          <TabsTrigger value="swift">Swift</TabsTrigger>
          <TabsTrigger value="apply">Apply</TabsTrigger>
          <TabsTrigger value="package">Package</TabsTrigger>
        </TabsList>
        <ToggleGroup
          value={[appearance]}
          onValueChange={(value: string[]) =>
            value.length && onAppearance(value[0] as Appearance)
          }
          aria-label="Preview appearance"
          variant="outline"
          size="sm"
        >
          <ToggleGroupItem value="light" aria-label="Light">
            <SunIcon />
          </ToggleGroupItem>
          <ToggleGroupItem value="dark" aria-label="Dark">
            <MoonIcon />
          </ToggleGroupItem>
        </ToggleGroup>
      </div>
      <TabsContent
        value="preview"
        className={cn(
          "flex flex-col items-center gap-4 p-3 sm:p-8",
          appearance === "dark" ? "bg-[#0b0b0d]" : "bg-[#f4f4f6]"
        )}
      >
        <PresetBoard tuning={tuning} appearance={appearance} />
        <SurfacePreview tuning={tuning} appearance={appearance} />
        <p
          className={cn(
            "max-w-[52ch] text-center text-xs",
            appearance === "dark" ? "text-neutral-400" : "text-neutral-500"
          )}
        >
          A token board drawn in CSS from the decoded values, with the system
          colors as they resolve on iOS 27. The Showcase renders the SwiftUI
          itself: open Tune and import the code, or run{" "}
          <code>capture_previews.py --preset {code}</code>.
        </p>
        {capture ? (
          <figure className="flex w-full max-w-[420px] flex-col gap-2">
            {/* The capture is the real Showcase on iPhone 17; next/image is not needed for a static export. */}
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={asset(capture)}
              alt={`${matched?.name} preset captured on iPhone 17, ${appearance}`}
              className="w-full rounded-xl border shadow-lg"
            />
            <figcaption
              className={cn(
                "text-center text-xs",
                appearance === "dark" ? "text-neutral-400" : "text-neutral-500"
              )}
            >
              This code is the {matched?.name} preset. Above is the theme
              preview wall&apos;s first screen under it, captured on iPhone 17.
            </figcaption>
          </figure>
        ) : null}
      </TabsContent>
      <TabsContent value="swift" className="relative">
        <div className="absolute top-2 right-2">
          <CopyButton text={swift} label="Copy Swift" className={DARK_COPY} />
        </div>
        <pre className={cn("max-h-[560px] overflow-auto px-5 py-[18px] pr-14", CODE_BOX)}>
          {highlightSwift(swift)}
        </pre>
      </TabsContent>
      <TabsContent value="apply" className="flex flex-col gap-4 p-4">
        <ApplyStep
          title="With the sweetui tool"
          detail="brew install mangobyte-dev/tap/sweetui. This writes RegistryTheme+App.swift next to your installed items and declares RegistryTheme.app."
        >
          <Command text={applyCommand(code)} />
        </ApplyStep>
        <ApplyStep
          title="Then once at your scene root"
          detail="Every registry item and every tinted native control below inherits it."
        >
          <Command text={"ContentView()\n    .registryTheme(.app)"} />
        </ApplyStep>
        <ApplyStep
          title="On a device"
          detail="In the Showcase, open Tune, choose Import, and paste the code. Or launch the app with the argument below."
        >
          <Command text={`-preset ${code}`} />
        </ApplyStep>
        <ApplyStep
          title="For an agent"
          detail="The MCP server's describe_preset and apply_preset tools, or the CLI, decode the same code."
        >
          <Command text={`sweetui preset decode ${code}`} />
        </ApplyStep>
      </TabsContent>
      <TabsContent value="package" className="flex flex-col gap-4 p-4">
        <p className="text-xs text-muted-foreground">
          A drop-in theme package, the MANGO way: commit both files. Copy each
          one. There is no download.
        </p>
        <PackageFile name="RegistryTheme+App.swift" text={themeFile} />
        <PackageFile name="THEME.md" text={themeDoc} />
      </TabsContent>
    </Tabs>
  )
}

/** Background, foreground, font design, and the elevation ladder, as a small surface preview. */
function SurfacePreview({
  tuning,
  appearance,
}: {
  tuning: PresetTuning
  appearance: Appearance
}) {
  const background = backgroundColor(tuning, appearance)
  const foreground = foregroundColor(tuning, appearance)
  const ink = appearance === "dark" ? "255, 255, 255" : "0, 0, 0"
  const secondary = tuning.secondaryForeground
    ? appearance === "dark"
      ? (tuning.secondaryForegroundDark ?? tuning.secondaryForeground)
      : tuning.secondaryForeground
    : `rgba(${ink}, 0.55)`
  const ladder = surfaceLadder(tuning)

  return (
    <div
      className="flex w-full max-w-[420px] flex-col border"
      style={{
        background,
        color: foreground,
        fontFamily: FONT_DESIGN_CSS[tuning.fontDesign],
        borderRadius: tuning.cardRadius,
        padding: tuning.standardSpacing,
        gap: tuning.compactSpacing,
      }}
    >
      <span style={{ fontSize: 22, fontWeight: 600, lineHeight: 1.1 }}>
        The quick brown fox
      </span>
      <span style={{ fontSize: 15 }}>
        Body text set in the{" "}
        {FONT_DESIGN_TITLES[tuning.fontDesign].toLowerCase()} design.
      </span>
      <span style={{ fontSize: 13, color: secondary }}>
        Secondary label, 1234567890
      </span>
      <div className="mt-1 flex" style={{ gap: tuning.compactSpacing / 2 }}>
        {ladder.map((level) => (
          <div
            key={level.level}
            title={`${level.label} · ${level.opacity}`}
            className="flex h-9 flex-1 items-end justify-center pb-1 text-[10px]"
            style={{
              background: `rgba(${ink}, ${level.opacity})`,
              borderRadius: tuning.compactRadius,
              color: `rgba(${ink}, 0.55)`,
            }}
          >
            {level.label}
          </div>
        ))}
      </div>
    </div>
  )
}

function PackageFile({ name, text }: { name: string; text: string }) {
  const isSwift = name.endsWith(".swift")
  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex items-center justify-between gap-2">
        <code className="font-mono text-xs font-semibold">{name}</code>
        <CopyButton text={text} label={`Copy ${name}`} />
      </div>
      <div className="overflow-hidden rounded-[12px]">
        <pre className={cn("max-h-[360px] overflow-auto px-5 py-[18px]", CODE_BOX)}>
          {isSwift ? highlightSwift(text) : text}
        </pre>
      </div>
    </div>
  )
}

function ApplyStep({
  title,
  detail,
  children,
}: {
  title: string
  detail: string
  children: React.ReactNode
}) {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-col gap-0.5">
        <h3 className="text-sm font-semibold">{title}</h3>
        <p className="text-xs text-muted-foreground">{detail}</p>
      </div>
      {children}
    </div>
  )
}

function Command({ text }: { text: string }) {
  return (
    <div className="relative overflow-hidden rounded-[12px]">
      <div className="absolute top-1.5 right-1.5">
        <CopyButton text={text} className={DARK_COPY} />
      </div>
      <pre className={cn("overflow-x-auto px-5 py-[18px] pr-12", CODE_BOX)}>
        {text}
      </pre>
    </div>
  )
}

function CodeBar({
  code,
  onTuning,
}: {
  code: string
  onTuning: (tuning: PresetTuning) => void
}) {
  const [linkCopied, setLinkCopied] = React.useState(false)

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(
        `${window.location.origin}${window.location.pathname}?preset=${code}`
      )
      setLinkCopied(true)
      window.setTimeout(() => setLinkCopied(false), 1400)
    } catch {
      // The address bar already carries the code.
    }
  }

  return (
    <div className="flex flex-wrap items-center gap-2 rounded-xl border bg-card p-2">
      <code
        className="min-w-0 flex-1 truncate px-2 font-mono text-sm"
        title={`--preset ${code}`}
      >
        --preset {code}
      </code>
      <CopyButton text={`--preset ${code}`} label="Copy preset" />
      <Button variant="outline" size="sm" onClick={copyLink}>
        <Link2Icon data-icon="inline-start" />
        {linkCopied ? "Copied" : "Copy link"}
      </Button>
      <OpenPresetDialog onOpen={onTuning} />
      <Button
        variant="outline"
        size="sm"
        onClick={() => onTuning(randomTuning())}
      >
        <DicesIcon data-icon="inline-start" />
        Random
      </Button>
      <Button
        variant="ghost"
        size="sm"
        onClick={() => onTuning(SHOWCASE_DEFAULT)}
      >
        <RotateCcwIcon data-icon="inline-start" />
        Reset
      </Button>
    </div>
  )
}

function OpenPresetDialog({
  onOpen,
}: {
  onOpen: (tuning: PresetTuning) => void
}) {
  const [open, setOpen] = React.useState(false)
  const [input, setInput] = React.useState("")
  const code = presetCodeIn(input)
  const decoded = code ? decodePreset(code) : null
  const isInvalid = input.trim().length > 0 && decoded === null

  function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!decoded) return
    onOpen(normalize(decoded))
    setOpen(false)
    setInput("")
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger render={<Button variant="outline" size="sm" />}>
        Open
      </DialogTrigger>
      <DialogContent>
        <form onSubmit={submit} className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>Open a preset</DialogTitle>
            <DialogDescription>
              Paste a code from the Showcase, a teammate, or a link, with or
              without its --preset flag.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col gap-2">
            <Label htmlFor="preset-code">Preset code</Label>
            <Input
              id="preset-code"
              value={input}
              onChange={(event) => setInput(event.target.value)}
              placeholder="a13GkaOXWwIF or --preset a13GkaOXWwIF"
              autoCapitalize="none"
              autoCorrect="off"
              spellCheck={false}
              aria-invalid={isInvalid}
            />
            {isInvalid ? (
              <p className="text-xs text-destructive">
                That is not a preset code.
              </p>
            ) : null}
          </div>
          <DialogFooter>
            <DialogClose render={<Button variant="outline" type="button" />}>
              Cancel
            </DialogClose>
            <Button type="submit" disabled={!decoded}>
              Open
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function Customizer({
  tuning,
  appearance,
  fontFamily,
  onTuning,
  onFontFamily,
}: {
  tuning: PresetTuning
  appearance: Appearance
  fontFamily: string
  onTuning: (tuning: PresetTuning) => void
  onFontFamily: (family: string) => void
}) {
  const update = (changes: Partial<PresetTuning>) =>
    onTuning({ ...tuning, ...changes })
  const matched = presetMatching(tuning)
  const groups: { title: string; keys: NumericField["key"][] }[] = [
    {
      title: "Surface",
      keys: [
        "surfaceOpacity",
        "borderOpacity",
        "borderWidth",
        "emphasizedBorderWidth",
      ],
    },
    { title: "Radius", keys: ["compactRadius", "controlRadius", "cardRadius"] },
    {
      title: "Spacing",
      keys: [
        "compactSpacing",
        "standardSpacing",
        "sectionSpacing",
        "controlHorizontalPadding",
      ],
    },
    { title: "State", keys: ["disabledOpacity"] },
  ]

  return (
    <Card className="h-fit lg:sticky lg:top-20">
      <CardHeader>
        <CardTitle>Customize</CardTitle>
      </CardHeader>
      <CardContent className="flex flex-col gap-6">
        <Fieldset title="Presets">
          <div className="flex flex-wrap gap-1.5">
            {PRESETS.map((preset) => (
              <Button
                key={preset.slug}
                size="sm"
                variant={matched?.slug === preset.slug ? "default" : "outline"}
                aria-pressed={matched?.slug === preset.slug}
                onClick={() => onTuning({ ...preset.tuning })}
              >
                {preset.name}
              </Button>
            ))}
          </div>
        </Fieldset>

        <Fieldset title="Accent">
          <div
            className="grid grid-cols-7 gap-2"
            role="radiogroup"
            aria-label="Accent"
          >
            {ACCENTS.filter(
              (accent): accent is Exclude<Accent, "custom"> =>
                accent !== "custom"
            ).map((accent) => (
              <button
                key={accent}
                type="button"
                role="radio"
                aria-checked={tuning.accent === accent}
                aria-label={ACCENT_TITLES[accent]}
                title={ACCENT_TITLES[accent]}
                onClick={() => update({ accent })}
                className={cn(
                  "flex size-8 items-center justify-center rounded-full border-2 border-transparent transition-transform outline-none focus-visible:ring-3 focus-visible:ring-ring/50",
                  tuning.accent === accent && "scale-110 border-foreground"
                )}
                style={{ background: IOS_COLORS[accent][appearance] }}
              >
                {accent === "system" ? (
                  <span className="text-[10px] font-bold text-white">iOS</span>
                ) : null}
              </button>
            ))}
          </div>
          <ColorRow
            id="custom-accent"
            label="Custom accent"
            value={tuning.customAccent ?? "#5957D6"}
            selected={tuning.accent === "custom"}
            onChange={(value) =>
              update({
                accent: "custom",
                customAccent: value,
                customAccentDark: tuning.customAccentDark ?? null,
              })
            }
          />
          <SwitchRow
            id="separate-dark"
            label="Separate dark accent"
            checked={
              tuning.accent === "custom" && Boolean(tuning.customAccentDark)
            }
            onChange={(checked) =>
              update({
                accent: "custom",
                customAccent: tuning.customAccent ?? "#5957D6",
                customAccentDark: checked
                  ? (tuning.customAccentDark ??
                    tuning.customAccent ??
                    "#5957D6")
                  : null,
              })
            }
          />
          {tuning.accent === "custom" && tuning.customAccentDark ? (
            <ColorRow
              id="custom-accent-dark"
              label="Custom accent in dark"
              value={tuning.customAccentDark}
              selected
              onChange={(value) => update({ customAccentDark: value })}
            />
          ) : null}
          <SwitchRow
            id="dark-label"
            label="Dark label on accent"
            checked={tuning.darkLabelOnAccent}
            disabled={tuning.accent === "ink"}
            onChange={(checked) => update({ darkLabelOnAccent: checked })}
          />
        </Fieldset>

        <Fieldset title="Typography">
          <SegmentedRow
            label="Font design"
            options={FONT_DESIGNS.map((design) => ({
              value: design,
              label: FONT_DESIGN_TITLES[design],
            }))}
            value={tuning.fontDesign}
            onChange={(value) => update({ fontDesign: value as FontDesign })}
          />
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="font-family">Custom font family</Label>
            <Input
              id="font-family"
              value={fontFamily}
              onChange={(event) => onFontFamily(event.target.value)}
              placeholder="Avenir Next (export only)"
              autoCapitalize="words"
              autoCorrect="off"
              spellCheck={false}
            />
            <p className="text-xs text-muted-foreground">
              It never enters the code. It appears only in the Swift export and
              the theme package, with the Dynamic Type note.
            </p>
          </div>
          <TypeScale design={tuning.fontDesign} />
        </Fieldset>

        <Fieldset title="Density">
          <div className="flex flex-wrap gap-1.5">
            {DENSITIES.map((density) => (
              <Button
                key={density.name}
                size="sm"
                variant={
                  matchingDensity(tuning) === density.name
                    ? "default"
                    : "outline"
                }
                aria-pressed={matchingDensity(tuning) === density.name}
                onClick={() =>
                  onTuning(applyDensity(tuning, density.name as DensityName))
                }
              >
                {density.label}
              </Button>
            ))}
            {matchingDensity(tuning) === null ? (
              <span className="inline-flex items-center rounded-md border border-dashed px-2 text-xs text-muted-foreground">
                Custom
              </span>
            ) : null}
          </div>
          <p className="text-xs text-muted-foreground">
            A bundle of the spacing and radius knobs below. When you edit them,
            the density lands on Custom.
          </p>
        </Fieldset>

        <Fieldset title="Elevation">
          <div className="flex flex-col gap-1.5">
            <div className="flex items-center justify-between text-sm">
              <Label htmlFor="surface-step">Surface step</Label>
              <span className="font-mono text-xs text-muted-foreground tabular-nums">
                {tuning.surfaceStep.toFixed(2)}
              </span>
            </div>
            <Slider
              id="surface-step"
              aria-label="Surface step"
              min={0}
              max={SURFACE_STEPS[SURFACE_STEPS.length - 1]}
              step={0.01}
              value={[tuning.surfaceStep]}
              onValueChange={(next) =>
                update({ surfaceStep: Array.isArray(next) ? next[0] : next })
              }
            />
          </div>
          <div className="flex gap-1.5" aria-hidden>
            {surfaceLadder(tuning).map((level) => {
              const ink = appearance === "dark" ? "255, 255, 255" : "0, 0, 0"
              return (
                <div
                  key={level.level}
                  title={`${level.label} · ${level.opacity}`}
                  className="flex h-10 flex-1 items-end justify-center rounded-md border pb-1 text-[10px] text-muted-foreground"
                  style={{ background: `rgba(${ink}, ${level.opacity})` }}
                >
                  {level.label}
                </div>
              )
            })}
          </div>
        </Fieldset>

        <Fieldset title="Chart palette">
          <div className="flex flex-col gap-1.5">
            {CHART_PALETTES.map((palette) => (
              <button
                key={palette}
                type="button"
                aria-pressed={tuning.chartPalette === palette}
                onClick={() => update({ chartPalette: palette })}
                className={cn(
                  "flex items-center justify-between gap-3 rounded-lg border-2 px-3 py-2 text-left transition-colors outline-none focus-visible:ring-3 focus-visible:ring-ring/50",
                  tuning.chartPalette === palette
                    ? "border-foreground"
                    : "border-transparent bg-muted/50 hover:bg-muted"
                )}
              >
                <span className="text-sm font-medium">
                  {CHART_PALETTE_TITLES[palette]}
                </span>
                <span className="flex gap-1">
                  {chartSwatches(
                    { ...tuning, chartPalette: palette },
                    appearance
                  ).map((color, index) => (
                    <span
                      key={index}
                      className="size-4 rounded-full"
                      style={{ background: color }}
                    />
                  ))}
                </span>
              </button>
            ))}
          </div>
        </Fieldset>

        <Fieldset title="Colors">
          <ColorPair
            label="Background"
            light={tuning.background}
            dark={tuning.backgroundDark}
            fallback="#F7F2EA"
            onChange={(background, backgroundDark) =>
              update({ background, backgroundDark })
            }
          />
          <ColorPair
            label="Foreground"
            light={tuning.foreground}
            dark={tuning.foregroundDark}
            fallback="#1B1B1F"
            onChange={(foreground, foregroundDark) =>
              update({ foreground, foregroundDark })
            }
          />
          <ColorPair
            label="Secondary foreground"
            light={tuning.secondaryForeground}
            dark={tuning.secondaryForegroundDark}
            fallback="#5C5C66"
            onChange={(secondaryForeground, secondaryForegroundDark) =>
              update({ secondaryForeground, secondaryForegroundDark })
            }
          />
        </Fieldset>

        {groups.map((group) => (
          <Fieldset key={group.title} title={group.title}>
            {NUMERIC_FIELDS.filter((field) =>
              group.keys.includes(field.key)
            ).map((field) => (
              <SliderRow
                key={field.key}
                field={field}
                value={tuning[field.key]}
                onChange={(value) => update({ [field.key]: value })}
              />
            ))}
          </Fieldset>
        ))}
      </CardContent>
    </Card>
  )
}

function Fieldset({
  title,
  children,
}: {
  title: string
  children: React.ReactNode
}) {
  return (
    <fieldset className="flex flex-col gap-3">
      <legend className="mb-2 text-xs font-semibold tracking-widest text-muted-foreground uppercase">
        {title}
      </legend>
      {children}
    </fieldset>
  )
}

function SegmentedRow({
  label,
  options,
  value,
  onChange,
}: {
  label: string
  options: { value: string; label: string }[]
  value: string
  onChange: (value: string) => void
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <Label>{label}</Label>
      <ToggleGroup
        className="w-full"
        value={[value]}
        onValueChange={(next: string[]) => next.length && onChange(next[0])}
        aria-label={label}
        variant="outline"
        size="sm"
      >
        {options.map((option) => (
          <ToggleGroupItem
            key={option.value}
            value={option.value}
            className="flex-1 text-xs"
          >
            {option.label}
          </ToggleGroupItem>
        ))}
      </ToggleGroup>
    </div>
  )
}

function TypeScale({ design }: { design: FontDesign }) {
  return (
    <div
      className="flex max-h-52 flex-col gap-1 overflow-auto rounded-lg border bg-muted/30 p-3"
      style={{ fontFamily: FONT_DESIGN_CSS[design] }}
    >
      {TEXT_STYLES.map((style) => (
        <div
          key={style.style}
          className="flex items-baseline justify-between gap-3"
        >
          <span
            className="truncate"
            style={{
              fontSize: Math.min(style.size, 22),
              fontWeight: style.weight,
            }}
          >
            {style.label}
          </span>
          <span className="shrink-0 font-mono text-[10px] text-muted-foreground tabular-nums">
            {style.size}
          </span>
        </div>
      ))}
    </div>
  )
}

function SliderRow({
  field,
  value,
  onChange,
}: {
  field: NumericField
  value: number
  onChange: (value: number) => void
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex items-center justify-between text-sm">
        <Label htmlFor={field.key}>{field.label}</Label>
        <span className="font-mono text-xs text-muted-foreground tabular-nums">
          {value.toFixed(field.decimals)}
        </span>
      </div>
      <Slider
        id={field.key}
        aria-label={field.label}
        min={field.minimum}
        max={maximum(field)}
        step={field.step}
        value={[value]}
        onValueChange={(next) => onChange(Array.isArray(next) ? next[0] : next)}
      />
    </div>
  )
}

function SwitchRow({
  id,
  label,
  checked,
  disabled,
  onChange,
}: {
  id: string
  label: string
  checked: boolean
  disabled?: boolean
  onChange: (checked: boolean) => void
}) {
  return (
    <div className="flex items-center justify-between gap-3">
      <Label htmlFor={id} className={cn(disabled && "opacity-50")}>
        {label}
      </Label>
      <Switch
        id={id}
        aria-label={label}
        checked={checked}
        disabled={disabled}
        onCheckedChange={(next) => onChange(next)}
      />
    </div>
  )
}

function ColorRow({
  id,
  label,
  value,
  selected,
  onChange,
}: {
  id: string
  label: string
  value: string
  selected: boolean
  onChange: (value: string) => void
}) {
  return (
    <div className="flex items-center justify-between gap-3">
      <Label htmlFor={id}>{label}</Label>
      <span className="flex items-center gap-2">
        <code className="font-mono text-xs text-muted-foreground">
          {selected ? value.toUpperCase() : ""}
        </code>
        <input
          id={id}
          type="color"
          value={value}
          onChange={(event) => onChange(event.target.value.toUpperCase())}
          className={cn(
            "size-8 cursor-pointer rounded-full border-2 border-transparent bg-transparent p-0",
            selected && "border-foreground"
          )}
        />
      </span>
    </div>
  )
}

/** An optional custom color with an on switch, a light color, and an optional dark color. */
function ColorPair({
  label,
  light,
  dark,
  fallback,
  onChange,
}: {
  label: string
  light: string | null
  dark: string | null
  fallback: string
  onChange: (light: string | null, dark: string | null) => void
}) {
  const id = label.toLowerCase().replace(/\s+/g, "-")
  const on = Boolean(light)
  return (
    <div className="flex flex-col gap-3">
      <SwitchRow
        id={`${id}-on`}
        label={label}
        checked={on}
        onChange={(checked) =>
          onChange(checked ? (light ?? fallback) : null, checked ? dark : null)
        }
      />
      {on ? (
        <>
          <ColorRow
            id={`${id}-light`}
            label={`${label} light`}
            value={light ?? fallback}
            selected
            onChange={(value) => onChange(value, dark)}
          />
          <SwitchRow
            id={`${id}-dark-on`}
            label="Separate dark"
            checked={Boolean(dark)}
            onChange={(checked) =>
              onChange(
                light ?? fallback,
                checked ? (dark ?? light ?? fallback) : null
              )
            }
          />
          {dark ? (
            <ColorRow
              id={`${id}-dark`}
              label={`${label} dark`}
              value={dark}
              selected
              onChange={(value) => onChange(light ?? fallback, value)}
            />
          ) : null}
        </>
      ) : null}
    </div>
  )
}
