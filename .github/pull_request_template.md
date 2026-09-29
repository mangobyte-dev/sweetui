**What changed**

**Verification run** (from AGENTS.md, cheapest first; name anything skipped)

- [ ] `swift run sweetui validate`
- [ ] Generators rerun: catalog, Showcase manifest, site data, item tokens
- [ ] `swift test` and `make format-check`
- [ ] Showcase builds; UI suite run if the change is visible
- [ ] Item recaptured with `Scripts/capture_previews.py` if its look changed

**Visual references**

A `GOLDEN-CHANGE` note in `docs/visual-testing.md` if a reference changed
