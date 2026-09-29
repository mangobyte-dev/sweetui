# Security

## Reporting

Report privately: [advisory](https://github.com/mangobyte-dev/sweetui/security/advisories/new). MUST NOT: public issue. Include repro, files/commands, impact, fix

Acknowledged 7 days; fix or decision 30. Disclosure post-fix

## Versions

`0.5.0`, `main`. Not `0.1.0`, `0.2.0`, `0.3.0`, `0.3.1`, `0.4.0`

## Scope

- Installer (`sweetui install`, `Sources/SweetUIKit/Installer.swift`): path traversal, symlink escapes, receipt tampering, destination escapes
- Validator, search, preset, MCP, generator commands, `Sources/`
- `Registry/sources/`: compromising consumer
- `Website/`, deployment config
- Showcase app, UI tests

## Defenses

- Reviewable source; installer refuses unsafe paths, never edits files
- Commits gitleaks-scanned before push; history clean
- Website deps npm-audited, Dependabot-updated. Static, serverless export, restrictive headers
- Workflows: read-only tokens, pinned commit hash

## Exclusions

- Apple frameworks, Xcode, Python, Node, third-party packages, unexploitable
- Findings needing compromised machine, modified clone
