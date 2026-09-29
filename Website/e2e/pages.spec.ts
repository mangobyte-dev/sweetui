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
      name: "Native-first SwiftUI you copy and own",
    })
  ).toBeVisible()

  // The count line under the hero: every count comes from the catalog data.
  await expect(
    page.getByText(
      `${registry.counts.component} components · ${registry.counts.block} blocks · ${registry.counts.recipe} recipes · ${registry.presets.length} theme presets`
    )
  ).toBeVisible()
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
