import type { Metadata } from "next"
import Link from "next/link"
import { notFound } from "next/navigation"

import { CodeBlock } from "@/components/code-block"
import { ItemPreview } from "@/components/item-preview"
import { PrevNext } from "@/components/prev-next"
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableRow } from "@/components/ui/table"
import {
  asset,
  findItem,
  installCommand,
  itemsOfKind,
  registry,
} from "@/lib/registry"
import {
  HIGHLIGHT_CSS,
  HIGHLIGHT_STYLE_HREF,
  highlightSwift,
} from "@/lib/swift-highlight"

type Params = { name: string }

export function generateStaticParams(): Params[] {
  return registry.items.map((item) => ({ name: item.name }))
}

export async function generateMetadata({
  params,
}: {
  params: Promise<Params>
}): Promise<Metadata> {
  const { name } = await params
  const item = findItem(name)
  return { title: item?.name ?? name, description: item?.description }
}

export default async function ItemPage({
  params,
}: {
  params: Promise<Params>
}) {
  const { name } = await params
  const item = findItem(name)
  if (!item) notFound()

  const isRecipe = item.kind === "recipe"
  const hasWide = Boolean(
    item.wideScreenshots.light && item.wideScreenshots.dark
  )

  // Prev/next walk the items of the same kind, in alphabetical order.
  const siblings = [...itemsOfKind(item.kind)].sort((a, b) =>
    a.name.localeCompare(b.name)
  )
  const position = siblings.findIndex(
    (candidate) => candidate.name === item.name
  )
  const previous = position > 0 ? siblings[position - 1] : null
  const next = position < siblings.length - 1 ? siblings[position + 1] : null

  // "On this page", matching the sections that actually render below.
  const toc: { id: string; label: string }[] = [
    ...(hasWide ? [{ id: "on-ipad", label: "On iPad" }] : []),
    { id: "install", label: "Install" },
    { id: "usage", label: "Usage" },
    ...(isRecipe && item.docs
      ? [{ id: "why-native", label: "Why native is enough" }]
      : []),
    { id: "accessibility", label: "Accessibility contract" },
    { id: "details", label: "Details" },
  ]

  return (
    <div className="grid grid-cols-1 gap-x-10 min-[1080px]:grid-cols-[minmax(0,1fr)_244px]">
      <article className="flex min-w-0 flex-col gap-10">
        <style href={HIGHLIGHT_STYLE_HREF} precedence="pfe-highlight">
          {HIGHLIGHT_CSS}
        </style>
        <header className="flex flex-col gap-3">
          <p className="text-[12.5px] font-semibold tracking-[0.03em] text-primary uppercase">
            {item.kind}
          </p>
          <h1 className="border-b pb-4 text-[32px] leading-[1.1] font-semibold tracking-[-0.015em] break-words sm:text-[40px] sm:leading-[1.08]">
            {item.name}
          </h1>
          <p className="max-w-[62ch] text-base text-muted-foreground sm:text-lg">
            {item.description}
          </p>
          <div className="flex flex-wrap gap-1.5">
            {item.tags.map((tag) => (
              <Badge key={tag} variant="secondary">
                {tag}
              </Badge>
            ))}
          </div>
        </header>

        <ItemPreview
          name={item.name}
          screenshots={item.screenshots}
          codeLabel={isRecipe ? "Snippet" : "Source"}
          code={
            <CodeBlock code={isRecipe ? item.usage : (item.source ?? "")} />
          }
        />

        {hasWide ? (
          <section id="on-ipad" className="flex scroll-mt-20 flex-col gap-3">
            <h2 className="section-heading">On iPad</h2>
            <p className="text-sm text-muted-foreground">
              The same installed source at a regular width. It adapts its layout
              without a separate design.
            </p>
            <div className="overflow-hidden rounded-xl border bg-muted">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={asset(item.wideScreenshots.light!)}
                alt={`${item.name} on iPad, light`}
                loading="lazy"
                className="w-full dark:hidden"
              />
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={asset(item.wideScreenshots.dark!)}
                alt={`${item.name} on iPad, dark`}
                loading="lazy"
                className="hidden w-full dark:block"
              />
            </div>
          </section>
        ) : null}

        <section id="install" className="flex scroll-mt-20 flex-col gap-3">
          <h2 className="section-heading">Install</h2>
          {isRecipe ? (
            <Alert>
              <AlertTitle>Nothing to install</AlertTitle>
              <AlertDescription>
                Copy the snippet below. The native API is the whole treatment.
              </AlertDescription>
            </Alert>
          ) : (
            <>
              <p className="text-sm text-muted-foreground">
                With the sweetui tool (
                <code className="ic">
                  {highlightSwift(
                    "brew install mangobyte-dev/tap/sweetui"
                  )}
                </code>
                ):
              </p>
              <CodeBlock language="bash" code={installCommand(item.name)} />
              <p className="text-sm text-muted-foreground">
                Installs in order:{" "}
                {item.installOrder.map((member, memberPosition) => (
                  <span key={member.name}>
                    {memberPosition > 0 ? ", " : ""}
                    <Link
                      href={`/items/${member.name}/`}
                      className="font-medium text-foreground underline-offset-4 hover:underline"
                    >
                      {member.name}
                    </Link>{" "}
                    {member.version}
                  </span>
                ))}
                . Point{" "}
                <code className="ic">{highlightSwift("--destination")}</code> at
                a folder inside the consuming target&apos;s sources.
              </p>
              <Accordion>
                <AccordionItem value="requirement">
                  <AccordionTrigger>Package requirement</AccordionTrigger>
                  <AccordionContent className="flex flex-col gap-3">
                    {item.requirements.map((requirement) => (
                      <div
                        key={requirement.instruction}
                        className="flex flex-col gap-3"
                      >
                        <p className="text-sm">
                          Then {requirement.instruction}.
                        </p>
                        <CodeBlock code={requirement.manifest} />
                        <p className="text-sm text-muted-foreground">
                          {requirement.xcode}.
                        </p>
                      </div>
                    ))}
                  </AccordionContent>
                </AccordionItem>
              </Accordion>
            </>
          )}
        </section>

        <section id="usage" className="flex scroll-mt-20 flex-col gap-3">
          <h2 className="section-heading">Usage</h2>
          <CodeBlock code={item.usage} />
        </section>

        {isRecipe && item.docs ? (
          <section id="why-native" className="flex scroll-mt-20 flex-col gap-3">
            <h2 className="section-heading">Why native is enough</h2>
            <Prose text={item.docs} />
          </section>
        ) : null}

        <section
          id="accessibility"
          className="flex scroll-mt-20 flex-col gap-3"
        >
          <h2 className="section-heading">Accessibility contract</h2>
          <ul className="flex list-disc flex-col gap-1.5 pl-5 text-sm">
            {item.accessibility.map((note) => (
              <li key={note}>{note}</li>
            ))}
          </ul>
        </section>

        <section id="details" className="flex scroll-mt-20 flex-col gap-3">
          <h2 className="section-heading">Details</h2>
          <div className="overflow-x-auto rounded-xl border">
            <Table>
              <TableBody>
                <TableRow>
                  <TableCell className="w-32 text-muted-foreground sm:w-40">
                    Kind
                  </TableCell>
                  <TableCell>{item.kind}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell className="text-muted-foreground">
                    Version
                  </TableCell>
                  <TableCell>{item.version}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell className="text-muted-foreground">
                    Platforms
                  </TableCell>
                  <TableCell>{item.platforms.join(", ")}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell className="text-muted-foreground">
                    Dependencies
                  </TableCell>
                  <TableCell>
                    {item.dependencies.length
                      ? item.dependencies.map(
                          (dependency, dependencyPosition) => (
                            <span key={dependency}>
                              {dependencyPosition > 0 ? ", " : ""}
                              <Link
                                href={`/items/${dependency}/`}
                                className="underline-offset-4 hover:underline"
                              >
                                {dependency}
                              </Link>
                            </span>
                          )
                        )
                      : "none"}
                  </TableCell>
                </TableRow>
                <TableRow>
                  <TableCell className="text-muted-foreground">
                    Source
                  </TableCell>
                  <TableCell>
                    {item.sourceURL ? (
                      <a
                        href={item.sourceURL}
                        className="break-all underline-offset-4 hover:underline"
                      >
                        {item.sourcePath}
                      </a>
                    ) : (
                      "none (native guidance)"
                    )}
                  </TableCell>
                </TableRow>
                {item.previewName ? (
                  <TableRow>
                    <TableCell className="text-muted-foreground">
                      Xcode preview
                    </TableCell>
                    <TableCell>
                      <code className="ic">
                        {highlightSwift(item.previewName)}
                      </code>
                    </TableCell>
                  </TableRow>
                ) : null}
              </TableBody>
            </Table>
          </div>
        </section>

        <PrevNext
          previous={
            previous
              ? { href: `/items/${previous.name}/`, title: previous.name }
              : null
          }
          next={
            next ? { href: `/items/${next.name}/`, title: next.name } : null
          }
        />
      </article>

      <aside className="max-[1079px]:hidden">
        <div className="sticky top-[76px] flex max-h-[calc(100vh-76px)] flex-col gap-6 overflow-auto py-1 text-[13px]">
          <div className="flex flex-col gap-3">
            <Badge variant="outline" className="w-fit uppercase">
              {item.kind}
            </Badge>
            <dl className="flex flex-col gap-1.5 text-muted-foreground">
              <div className="flex gap-2">
                <dt className="text-foreground">Version</dt>
                <dd>{item.version}</dd>
              </div>
              <div className="flex gap-2">
                <dt className="text-foreground">Platforms</dt>
                <dd>{item.platforms.join(", ")}</dd>
              </div>
            </dl>
            {item.installOrder.length ? (
              <div className="flex flex-col gap-1.5">
                <div className="text-[11px] font-semibold tracking-[0.05em] text-muted-foreground uppercase">
                  Install order
                </div>
                <ul className="flex flex-col gap-1">
                  {item.installOrder.map((member) => (
                    <li key={member.name}>
                      <Link
                        href={`/items/${member.name}/`}
                        className="text-primary underline-offset-4 hover:underline"
                      >
                        {member.name}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
            {item.tags.length ? (
              <div className="flex flex-wrap gap-1.5">
                {item.tags.map((tag) => (
                  <span
                    key={tag}
                    className="rounded-full bg-accent px-2.5 py-0.5 text-[12.5px] text-muted-foreground"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            ) : null}
          </div>
          {toc.length ? (
            <nav aria-label="On this page">
              <div className="mb-2.5 text-[11px] font-semibold tracking-[0.05em] text-muted-foreground uppercase">
                On this page
              </div>
              <ul className="flex flex-col gap-1.5">
                {toc.map((entry) => (
                  <li key={entry.id}>
                    <a
                      href={`#${entry.id}`}
                      className="text-muted-foreground hover:text-primary"
                    >
                      {entry.label}
                    </a>
                  </li>
                ))}
              </ul>
            </nav>
          ) : null}
        </div>
      </aside>
    </div>
  )
}

/** Prose with `backtick` spans rendered as code. */
function Prose({ text }: { text: string }) {
  const parts = text.split("`")
  return (
    <p className="text-sm leading-relaxed">
      {parts.map((part, position) =>
        position % 2 ? (
          <code key={position} className="ic">
            {highlightSwift(part)}
          </code>
        ) : (
          <span key={position}>{part}</span>
        )
      )}
    </p>
  )
}
