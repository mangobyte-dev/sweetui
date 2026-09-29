<!-- Reference for the sweetui-authoring skill. Field names, types, and constraints quoted from Registry/schema.json (the canonical schema). Prose descriptions of each field are in docs/registry-spec.md, "Item fields". Do not hand-edit; the schema governs. -->

# Item schema (version 1)

The canonical schema is `Registry/schema.json`. Every item document validates against it through `Sources/SweetUIKit/Validation.swift`. Field prose is in `docs/registry-spec.md`, "Item fields".

## Required keys

`schemaVersion`, `version`, `name`, `kind`, `description`, `files`, `registryDependencies`, `packageDependencies`, `platforms`, `tags`, `accessibility`.

## Conditional rule (from the schema's `allOf`)

- When `kind` is `recipe`: `docs` is required and `files` must have `maxItems: 0` (empty).
- Otherwise (`component`, `block`, `flow`): `preview` is required and `files` must have `minItems: 1`.

## Field types and constraints

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "SweetUI item",
  "type": "object",
  "required": [
    "schemaVersion",
    "version",
    "name",
    "kind",
    "description",
    "files",
    "registryDependencies",
    "packageDependencies",
    "platforms",
    "tags",
    "accessibility"
  ],
  "allOf": [
    {
      "if": { "required": ["kind"], "properties": { "kind": { "const": "recipe" } } },
      "then": {
        "required": ["docs"],
        "properties": { "files": { "maxItems": 0 } }
      },
      "else": {
        "required": ["preview"],
        "properties": { "files": { "minItems": 1 } }
      }
    }
  ],
  "properties": {
    "$schema": { "type": "string" },
    "schemaVersion": { "const": 1 },
    "version": { "type": "string", "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$" },
    "name": { "type": "string", "pattern": "^[a-z0-9]+(?:-[a-z0-9]+)*$" },
    "kind": { "enum": ["component", "block", "flow", "recipe"] },
    "description": { "type": "string", "minLength": 1 },
    "usage": { "type": "string", "minLength": 1 },
    "docs": { "type": "string", "minLength": 1 },
    "files": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["source", "target"],
        "properties": {
          "source": { "type": "string" },
          "target": { "type": "string" }
        },
        "additionalProperties": false
      }
    },
    "registryDependencies": {
      "type": "array",
      "items": { "type": "string" },
      "uniqueItems": true
    },
    "packageDependencies": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["package", "product", "requirement"],
        "properties": {
          "package": { "type": "string" },
          "product": { "type": "string" },
          "requirement": { "type": "string" },
          "sourceURL": { "type": "string" },
          "swiftPM": {
            "type": "object",
            "required": ["kind", "minimumVersion"],
            "properties": {
              "kind": { "enum": ["upToNextMinor", "upToNextMajor", "exactVersion", "range"] },
              "minimumVersion": { "type": "string", "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$" },
              "maximumVersionExclusive": { "type": "string", "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$" }
            },
            "additionalProperties": false
          }
        },
        "additionalProperties": false
      }
    },
    "platforms": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["name", "minimumVersion"],
        "properties": {
          "name": { "enum": ["iOS"] },
          "minimumVersion": { "type": "string" }
        },
        "additionalProperties": false
      }
    },
    "tags": { "type": "array", "items": { "type": "string" }, "uniqueItems": true },
    "aliases": { "type": "array", "items": { "type": "string" }, "uniqueItems": true },
    "accessibility": { "type": "array", "items": { "type": "string" } },
    "preview": {
      "type": "object",
      "required": [],
      "properties": {
        "source": { "type": "string" },
        "name": { "type": "string" },
        "screenshots": {
          "type": "array",
          "items": { "type": "string" },
          "uniqueItems": true
        }
      },
      "additionalProperties": false
    }
  },
  "additionalProperties": false
}
```
