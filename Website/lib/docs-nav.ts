/**
 * The Docs section, in reading order. A page's body is markdown: either a
 * repository document the site-data generator copies into `content/docs/`
 * (never edited here) or a hand-written page under `docs/`.
 */
export type DocGroup = "Get started" | "Guides" | "Reference"

export type DocPage = {
  slug: string
  title: string
  description: string
  group: DocGroup
  /** Path relative to the `Website/` directory. */
  file: string
}

export const DOCS: DocPage[] = [
  {
    slug: "introduction",
    title: "Introduction",
    description: "What it is, its principles, what it leaves to Apple.",
    group: "Get started",
    file: "content/docs/philosophy.md",
  },
  {
    slug: "installation",
    title: "Installation",
    description: "Package, theme once, install, use, tune on device: five minutes.",
    group: "Get started",
    file: "docs/installation.md",
  },
  {
    slug: "design-surface",
    title: "Design surface",
    description: "On-device tuner: floating panel, selects items, live tokens, exports result.",
    group: "Guides",
    file: "docs/design-surface.md",
  },
  {
    slug: "cli",
    title: "CLI",
    description: "sweetui commands: search, describe, plan, install, diff, update, info, presets, validate, generators.",
    group: "Guides",
    file: "docs/cli.md",
  },
  {
    slug: "mcp",
    title: "MCP server",
    description: "Same tools over stdio: search, describe, plan, diff, install, preset.",
    group: "Guides",
    file: "docs/mcp.md",
  },
  {
    slug: "mango",
    title: "MANGO design system",
    description: "Sample design system built on registry; template to build your own.",
    group: "Guides",
    file: "content/docs/mango.md",
  },
  {
    slug: "case-studies",
    title: "Case studies",
    description: "Four small apps an agent built from the registry, with screenshots and what got in its way.",
    group: "Guides",
    file: "content/docs/case-studies.md",
  },
  {
    slug: "architecture",
    title: "Architecture",
    description: "Hybrid: small foundations package you depend on, plus item source you copy and own.",
    group: "Reference",
    file: "content/docs/architecture.md",
  },
  {
    slug: "registry-spec",
    title: "Registry specification",
    description: "Item document, validator, resolution, receipts, generators, preset code format.",
    group: "Reference",
    file: "content/docs/registry-spec.md",
  },
  {
    slug: "visual-testing",
    title: "Visual testing",
    description: "How Showcase's pinned visual references and captures are made, compared, replaced.",
    group: "Reference",
    file: "content/docs/visual-testing.md",
  },
  {
    slug: "changelog",
    title: "Changelog",
    description: "Releases and known limitations.",
    group: "Reference",
    file: "content/docs/changelog.md",
  },
]

export const DOC_GROUPS: DocGroup[] = ["Get started", "Guides", "Reference"]

export function findDoc(slug: string): DocPage | undefined {
  return DOCS.find((doc) => doc.slug === slug)
}

export function docHref(slug: string): string {
  return `/docs/${slug}/`
}
