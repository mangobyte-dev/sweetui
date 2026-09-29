import data from "@/content/registry.json"

export type ItemKind = "component" | "block" | "recipe"

export type RegistryItem = {
  name: string
  kind: ItemKind
  version: string
  description: string
  usage: string
  docs: string | null
  tags: string[]
  aliases: string[]
  platforms: string[]
  dependencies: string[]
  installOrder: { name: string; version: string }[]
  accessibility: string[]
  sourcePath: string | null
  sourceURL: string | null
  source: string | null
  previewName: string | null
  screenshots: { light: string | null; dark: string | null }
  wideScreenshots: { light: string | null; dark: string | null }
  requirements: { instruction: string; manifest: string; xcode: string }[]
}

export type ThemePreset = {
  name: string
  slug: string
  blurb: string
  code: string
  screenshots: { light: string | null; dark: string | null }
  demoScreenshots: { light: string | null; dark: string | null }
}

export type Registry = {
  name: string
  repositoryURL: string
  counts: Record<ItemKind, number>
  items: RegistryItem[]
  presets: ThemePreset[]
}

export const registry = data as Registry

export const KINDS: { kind: ItemKind; title: string; summary: string }[] = [
  { kind: "component", title: "Components", summary: "Each is one installable style, modifier, or view." },
  { kind: "block", title: "Blocks", summary: "Compositions of components. When you install one, you install its whole closure." },
  { kind: "recipe", title: "Recipes", summary: "Native guidance. Nothing installs. Copy the snippet." },
]

export function itemsOfKind(kind: ItemKind): RegistryItem[] {
  return registry.items.filter((item) => item.kind === kind)
}

export function findItem(name: string): RegistryItem | undefined {
  return registry.items.find((item) => item.name === name)
}

/** Prefixes a `public/` path with the Pages base path at build time. */
export function asset(path: string): string {
  return `${process.env.NEXT_PUBLIC_BASE_PATH ?? ""}${path}`
}

export function installCommand(name: string): string {
  return `sweetui install ${name} --destination Sources/YourFeature/Components`
}
