# SweetUI website

Next.js static export, shadcn/ui, from `content/registry.json` + `public/images/` (`swift run sweetui generate site-data`). MUST NOT hand-edit.

```sh
swift run sweetui generate site-data   # from the repository root
cd Website
npm ci
npm run dev          # http://localhost:3000
npm run typecheck
npm run build        # static export under out/
```

Production: Cloudflare Workers static assets (`wrangler.jsonc`, worker `swiftui-registry`, custom domain `sweetui.dev`). `npm run deploy` builds, uploads `out/` to `https://sweetui.dev` after `npx wrangler login`. Workers Builds deploys every push to `main` from root `/Website` with `npm run build:workers`: its Linux image has no Swift, so the script copies `docs/images` the way `sweetui generate site-data` does. Alternative: `.github/workflows/pages.yml` → GitHub Pages, `NEXT_PUBLIC_BASE_PATH` = repo.

Pages: `/` (hero, setup, cards); `/items/<name>/` (preview, light/dark, install, usage, source, accessibility, details); `/themes/` (presets, tuning export, tokens). shadcn/ui: `components/ui`; site: `components/`.
