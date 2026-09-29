import type { Metadata } from "next"
import Link from "next/link"

import { CodeBlock } from "@/components/code-block"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { asset, registry } from "@/lib/registry"

export const metadata: Metadata = {
  title: "Themes",
  description: "One RegistryTheme at the scene root. Presets and the live tuning panel.",
}

const TUNE_EXPORT = `let theme = RegistryTheme(
    accent: .primary,
    onAccent: Color(uiColor: .systemBackground),
    surface: .primary.opacity(0.050),
    border: .primary.opacity(0.100),
    disabledOpacity: 0.500,
    metrics: RegistryMetrics(
        compactSpacing: 8,
        standardSpacing: 16,
        sectionSpacing: 24,
        controlHorizontalPadding: 12,
        borderWidth: 1,
        emphasizedBorderWidth: 2,
        compactRadius: 6,
        controlRadius: 10,
        cardRadius: 18
    )
)

// Apply once at the root of your scene; every registry item below inherits it.
ContentView()
    .registryTheme(theme)`

const TOKENS: [string, string, string][] = [
  ["accent", "nil (app tint)", "tinted items, via subtree tint"],
  ["onAccent", ".white", "button, auth-form"],
  [
    "surface",
    ".primary.opacity(0.055)",
    "card, input, badge, select, textarea, avatar, alert, empty, blocks",
  ],
  [
    "border",
    ".primary.opacity(0.08)",
    "card, input, badge, separator, select, textarea, checkbox, accordion",
  ],
  ["positive", ".green", "badge, progress, transaction-row, alert"],
  [
    "negative",
    ".red",
    "badge, button, input, textarea, transaction-row, alert, auth-form",
  ],
  ["disabledOpacity", "0.5", "button, checkbox, input, select, textarea"],
  ["metrics.compactSpacing", "8", "badge, label, rows"],
  ["metrics.standardSpacing", "16", "card, metric-card, blocks"],
  ["metrics.sectionSpacing", "24", "blocks"],
  ["metrics.controlHorizontalPadding", "12", "input, select"],
  [
    "metrics.borderWidth / emphasizedBorderWidth",
    "1 / 2",
    "inputs at rest, focused, or invalid",
  ],
  [
    "metrics.compactRadius / controlRadius / cardRadius",
    "6 / 8 / 16",
    "badge/checkbox, controls/alerts, cards",
  ],
  [
    "fontDesign",
    "nil (system)",
    "every text, via registryTheme's .fontDesign when set",
  ],
  [
    "surfaceStep",
    "0.02",
    "elevation ladder, registrySurface(level:), RegistrySurfaceLevel",
  ],
  ["chartPalette", ".accent", "chart, via chartForegroundStyleScale"],
  ["background", "nil (system background)", "scene root, when set"],
  [
    "foreground",
    "nil (system label)",
    "scene root; secondary hierarchy derives from it",
  ],
  [
    "secondaryForeground",
    "nil (system secondary label)",
    "scene root, paired with foreground when set",
  ],
]

export default function ThemesPage() {
  const mango = registry.presets.find((preset) => preset.slug === "mango")
  return (
    <div className="flex flex-col gap-12">
      <header className="flex flex-col gap-3">
        <p className="text-xs font-semibold tracking-widest text-muted-foreground uppercase">
          Themes
        </p>
        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">
          One modifier, every screen
        </h1>
        <p className="max-w-[62ch] text-lg text-muted-foreground">
          <code>RegistryTheme</code>: optional accent, label color, surface, hairline border,
          positive/negative, disabled opacity, metrics. Apply once via{" "}
          <code>.registryTheme(_:)</code> at root; items read tokens from the environment, controls follow tint.
        </p>
      </header>

      <section className="flex flex-col gap-4">
        <div className="flex flex-col gap-1">
          <h2 className="text-2xl font-semibold tracking-tight">Presets</h2>
          <p className="text-muted-foreground">
            Starting points, each a plain <code>static let</code> to copy/edit. Cards: first
            screen of the{" "}
            <Link href="/items/preview/">preview wall</Link> ({" "}
            <code>preview</code> block, 33 cards), iPhone 17.
          </p>
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          {registry.presets.map((preset) => (
            <Card key={preset.slug} className="gap-0 overflow-hidden py-0">
              <div className="border-b bg-muted">
                {preset.screenshots.light ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={asset(preset.screenshots.light)}
                    alt={`${preset.name}, light`}
                    loading="lazy"
                    className="w-full dark:hidden"
                  />
                ) : null}
                {preset.screenshots.dark ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={asset(preset.screenshots.dark)}
                    alt={`${preset.name}, dark`}
                    loading="lazy"
                    className="hidden w-full dark:block"
                  />
                ) : null}
              </div>
              <CardHeader className="pt-4">
                <CardTitle>{preset.name}</CardTitle>
                <CardDescription>{preset.blurb}</CardDescription>
              </CardHeader>
              <CardContent className="pb-4">
                <CodeBlock
                  code={`ContentView()\n    .registryTheme(.${preset.slug})`}
                />
              </CardContent>
            </Card>
          ))}
        </div>
      </section>

      {mango ? (
        <section className="flex flex-col gap-4">
          <div className="flex flex-col gap-1">
            <h2 className="text-2xl font-semibold tracking-tight">
              MANGO, a design system built on the registry
            </h2>
            <p className="text-muted-foreground">
              A worked brand example, a template to build your own.
            </p>
          </div>
          <div className="grid gap-6 md:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)]">
            <div className="flex flex-col gap-4">
              <p className="max-w-[62ch] text-sm leading-relaxed">
                MANGO: rounded type via <code>.fontDesign(.rounded)</code>, strokeless
                surfaces (zero border opacity, depth from surface step), one accent, two
                owned/edited items, critically-damped button press, tabular metric-card
                digits, preset <code>.mango</code>. Code opens it in Create as a template.
              </p>
              <CodeBlock
                code={`ContentView()\n    .registryTheme(.mango)\n    .fontDesign(.rounded)`}
              />
              <CodeBlock
                code={`sweetui preset apply ${mango.code} --destination Sources/YourFeature/Components`}
              />
              <p className="text-sm text-muted-foreground">
                <Link href={`/create/?preset=${mango.code}`}>
                  Open MANGO in Create
                </Link>
                {" · "}
                <a
                  href={`${registry.repositoryURL}/blob/main/docs/mango.md`}
                  target="_blank"
                  rel="noreferrer"
                >
                  docs/mango.md
                </a>
              </p>
            </div>
            {mango.demoScreenshots.light ? (
              <div className="overflow-hidden rounded-xl border bg-muted">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={asset(mango.demoScreenshots.light)}
                  alt="MANGO demo, Showcase, light"
                  loading="lazy"
                  className="w-full dark:hidden"
                />
                {mango.demoScreenshots.dark ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={asset(mango.demoScreenshots.dark)}
                    alt="MANGO demo, Showcase, dark"
                    loading="lazy"
                    className="hidden w-full dark:block"
                  />
                ) : null}
              </div>
            ) : null}
          </div>
        </section>
      ) : null}

      <section className="flex flex-col gap-4">
        <div className="flex flex-col gap-1">
          <h2 className="text-2xl font-semibold tracking-tight">
            Tune it live
          </h2>
          <p className="text-muted-foreground">
            The Showcase&apos;s tuning panel is the theme creator, beside the catalog.
          </p>
        </div>
        <p className="max-w-[70ch] text-sm leading-relaxed">
          Every token: a slider or swatch beside live preview: accent, label color,
          surface/border opacity, border widths, 3 radii, 4 spacings, disabled opacity.
          Appearance, text size, RTL check result. <strong>Copy Swift</strong> puts the exact initializer on
          pasteboard; <strong>Copy Code</strong> puts the preset code instead:
        </p>
        <CodeBlock code={TUNE_EXPORT} />
        <p className="text-sm text-muted-foreground">
          Open{" "}
          <code>Examples/Showcase/SweetUIShowcase.xcworkspace</code>, run
          Showcase, tap Tune above the tab bar. Panel: inspector on iPad, sheet on iPhone
          (catalog interactive beneath). Demos update live. Copy Code puts a preset code
          on pasteboard; <Link href="/create/">Create page</Link> and{" "}
          <code>sweetui preset</code> read it. Captures: preview wall&apos;s first
          screen ({" "}
          <code>preview</code> block, 33 cards), iPhone 17.
        </p>
      </section>

      <section className="flex flex-col gap-4">
        <h2 className="text-2xl font-semibold tracking-tight">
          Every token
        </h2>
        <div className="overflow-x-auto rounded-xl border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Token</TableHead>
                <TableHead>Default</TableHead>
                <TableHead>Read by</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {TOKENS.map(([token, value, readers]) => (
                <TableRow key={token}>
                  <TableCell>
                    <code>{token}</code>
                  </TableCell>
                  <TableCell>
                    <code>{value}</code>
                  </TableCell>
                  <TableCell className="whitespace-normal text-muted-foreground">
                    {readers}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </section>
    </div>
  )
}
