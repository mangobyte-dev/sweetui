import { readFileSync } from "node:fs"

import { test, expect } from "./fixtures"

const registry = JSON.parse(
  readFileSync(new URL("../content/registry.json", import.meta.url), "utf8")
) as {
  counts: { component: number; block: number; recipe: number }
  presets: unknown[]
}

test("home shows the hero and the catalog counts", async ({ page }) => {
  await page.goto("/", { waitUntil: "commit" })
  await expect(
    page.getByRole("heading", {
      name: "Native-first SwiftUI you copy and own.",
    })
  ).toBeVisible()

  // The count strip: each label's preceding <dt> is that kind's count.
  const stats = page.locator("main dl").first()
  const dtFor = (label: string) =>
    stats
      .locator("dd", { hasText: label })
      .locator("xpath=preceding-sibling::dt")
  await expect(dtFor("components")).toHaveText(
    String(registry.counts.component)
  )
  await expect(dtFor("blocks")).toHaveText(String(registry.counts.block))
  await expect(dtFor("recipes")).toHaveText(String(registry.counts.recipe))
  await expect(dtFor("theme presets")).toHaveText(
    String(registry.presets.length)
  )
})

test("themes shows the MANGO section", async ({ page }) => {
  await page.goto("/themes/", { waitUntil: "commit" })
  await expect(
    page.getByRole("heading", {
      name: "MANGO, a design system built on the registry",
    })
  ).toBeVisible()
  await expect(
    page.getByRole("link", { name: "Open MANGO in Create" })
  ).toBeVisible()
})

test("an item page shows the install command, the usage, and the iPad captures", async ({
  page,
}) => {
  await page.goto("/items/button/", { waitUntil: "commit" })
  await expect(
    page.getByRole("heading", { name: "button", exact: true })
  ).toBeVisible()

  // Install command.
  await expect(page.getByRole("heading", { name: "Install" })).toBeVisible()
  await expect(page.getByText("sweetui install button")).toBeVisible()

  // Usage snippet.
  await expect(page.getByRole("heading", { name: "Usage" })).toBeVisible()

  // The On iPad captures.
  await expect(page.getByRole("heading", { name: "On iPad" })).toBeVisible()
  await expect(
    page.getByRole("img", { name: "button on iPad, light" })
  ).toBeAttached()
})
