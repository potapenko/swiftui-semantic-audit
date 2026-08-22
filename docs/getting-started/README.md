# Getting started

## Recommended route

Give this prompt to a local Codex or Claude Code agent:

```text
Install SwiftUI Semantic Audit from this GitHub guide. Install Homebrew first if needed, then the CLI and all four agent skills:
https://github.com/potapenko/swiftui-semantic-audit/blob/master/docs/getting-started/installation.md
```

The GitHub guide pins installation artifacts to the immutable `0.5.0` release.
Homebrew installs only the CLI; the agent installs all four skills separately.

After the agent returns the installation receipt:

1. Open the SwiftUI project you want to inspect and invoke the router:

   - Codex: `$swiftui-semantic`
   - Claude Code: `/swiftui-semantic`

2. Ask for an audit, refactor, or review in ordinary language. The router selects the matching specialist workflow.

On the unreleased 0.6.0 candidate, ask the router to set up continuous semantic analysis first. It previews project writes, creates the project manifest/baseline, starts the watcher, and waits for fresh indexed state. See [Project watcher setup](project-watcher.md).

The [installation guide](installation.md) covers verification, conflicts, manual
setup, updates, removal, and why all four skill directories remain siblings.
The [agent prompt library](agent-prompts.md#install-the-cli-and-agent-skills)
keeps the same copy-paste prompt with the workflow recipes.

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
- [Agent prompt library](agent-prompts.md)
- [First audit](first-audit.md)
- [Project watcher setup](project-watcher.md)
- [Why semantic audit](../concepts/why-semantic-audit.md)
- [CLI reference](../reference/cli.md)
