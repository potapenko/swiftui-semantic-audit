# Getting started

The normal setup has two parts:

- `swiftui-audit`, the deterministic CLI;
- `swiftui-semantic`, the user-facing router skill, plus its three specialist skills.

The project is unreleased. Installation therefore builds a pinned repository commit instead of downloading a tagged artifact.

## Recommended route

1. Copy the installation prompt from the [root README](../../README.md#install-with-your-coding-agent) into a local Codex or Claude Code session.
2. Confirm the installation receipt: exact commit, binary path, four skill paths, and successful `doctor` output.
3. Open the SwiftUI project you want to inspect and invoke the router:

   - Codex: `$swiftui-semantic`
   - Claude Code: `/swiftui-semantic`

4. Ask for an audit, refactor, or review in ordinary language. The router selects the matching specialist workflow.

The [installation guide](installation.md) also covers manual setup and the reason all four skill directories must be installed together.

## Before the first agent audit

An agent workflow requires compiler-backed indexed evidence:

1. build the target source state;
2. retain the fresh project-covering Index Store produced by that build;
3. pass its path explicitly to `swiftui-audit`;
4. require `resolution: "indexed"` in the result.

If role-aware architecture rules are relevant, add a validated `.swiftui-audit.json`. Missing role configuration does not make the tool guess; affected rules stay silent.

Continue with [Run a first audit](first-audit.md).

## Standalone CLI use

The CLI can also extract useful syntax-only facts without building the target:

```bash
swiftui-audit audit Sources --syntax-only --format json
```

That mode is suitable for deterministic exploration, fixture work, and CI. It is deliberately not accepted as enough evidence by the bundled agent workflows.

## Next pages

- [Installation](installation.md)
- [First audit](first-audit.md)
- [Why semantic audit](../concepts/why-semantic-audit.md)
- [CLI reference](../reference/cli.md)
