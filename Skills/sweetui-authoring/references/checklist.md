<!-- Checklist for `sweetui-authoring`; from `AGENTS.md` Verification, do not edit. -->

# Authoring verification checklist

Repo root, cheapest first; scope to change (Scoping).

## Commands

- [ ] `swift build`
- [ ] `swift run sweetui validate`
- [ ] `swift run sweetui generate catalog`
- [ ] `swift run sweetui generate showcase-manifest`
- [ ] `swift run sweetui generate site-data`
- [ ] `swift run sweetui generate item-tokens`
- [ ] `git diff --exit-code -- docs/catalog Examples/Showcase Website/content Sources/SweetUIDesignSurface/RegistryItemTokens.swift`
- [ ] `swift test`
- [ ] `make format-check`
- [ ] `swift run sweetui search nutrition dashboard --kind block --platform iOS --target-version 26.0`
- [ ] `swift run sweetui install finance-overview --destination Examples/Showcase/SweetUIShowcasePackage/Sources/SweetUIShowcaseFeature/Installed --force`
- [ ] `swift run sweetui install nutrition-overview --destination Examples/Showcase/SweetUIShowcasePackage/Sources/SweetUIShowcaseFeature/Installed`
- [ ] `xcodebuildmcp simulator build --workspace-path Examples/Showcase/SweetUIShowcase.xcworkspace --scheme SweetUIShowcase --simulator-name 'iPhone 17'`
- [ ] `xcodebuildmcp simulator test --workspace-path Examples/Showcase/SweetUIShowcase.xcworkspace --scheme SweetUIShowcase --simulator-id 1807166B-C557-4F6B-B177-D5F3F701CBD7`
- [ ] `(cd Website && npm ci && npm run typecheck && npm run build)`

## Captures

- [ ] visible item change: `python3 Scripts/capture_previews.py <item>` on pinned simulator, rerun the four generators above

## Scoping

- metadata-only: stop after `make format-check`
- registry source: + install, compile
- visible UI: + simulator test
- `Website/`: + typecheck, build
- `swift test` needs `git`, `node` 22 on PATH: `git merge-file`; `Website/lib/preset.ts` under `node --experimental-strip-types`

Incomplete if generated differs from registry, or any command fails; name skipped steps.
