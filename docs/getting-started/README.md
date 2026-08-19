# Getting started

The normal setup has two parts:

- `swiftui-audit`, the deterministic CLI;
- `swiftui-semantic`, the user-facing router skill, plus its three specialist skills.

Release 0.4.0 separates Homebrew CLI installation from optional agent-skill installation. Both remain pinned to the same immutable tag.

## Recommended route

1. Install the CLI with `brew install potapenko/tap/swiftui-semantic-audit`.
2. Copy the skill-installation prompt from the [root README](../../README.md#install-agent-skills) into a local Codex or Claude Code session.
3. Confirm the installation receipt: release tag, exact commit, CLI version, four skill paths, and successful `doctor` output.
4. Open the SwiftUI project you want to inspect and invoke the router:

   - Codex: `$swiftui-semantic`
   - Claude Code: `/swiftui-semantic`

5. Ask for an audit, refactor, or review in ordinary language. The router selects the matching specialist workflow.

The [installation guide](installation.md) also covers manual setup and the reason all four skill directories must be installed together.

## Before the first agent audit

An agent workflow requires compiler-backed indexed evidence:

1. build the target source state;
2. retain the fresh project-covering Index Store produced by that build;
3. pass its path explicitly to `swiftui-audit`;
4. require `resolution: "indexed"` in the result.

If role-aware architecture rules are relevant, add a validated `.swiftui-audit.json`. Missing role configuration does not make the tool guess; affected rules stay silent.

Continue with [Run a first audit](first-audit.md).

## Next pages

- [Installation](installation.md)
- [First audit](first-audit.md)
- [Why semantic audit](../concepts/why-semantic-audit.md)
- [CLI reference](../reference/cli.md)
