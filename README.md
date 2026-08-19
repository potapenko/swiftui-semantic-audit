# SwiftUI Semantic Audit

**Give coding agents a map of SwiftUI state before they edit it.**

SwiftUI Semantic Audit is an architecture guardrail for coding agents. It turns state ownership, writes, bindings, effects, synchronization, and component boundaries into deterministic evidence before an agent changes code. Afterward, a semantic diff between compatible snapshots shows what the refactor actually changed.

The tool is built for SwiftUI work that crosses file boundaries: auditing an unfamiliar project, removing manual synchronization, narrowing component inputs, or reviewing an agent-authored change. It does not rewrite source by itself or ask a model to invent compiler facts.

> **Current release:** 0.4.0 for macOS 13 or later.

[Install](#install-the-cli-and-agent-skills) · [Copy a task prompt](#copy-a-task-prompt) · [Run the first audit](docs/getting-started/first-audit.md) · [Read the docs](docs/README.md)

## Give the agent architecture evidence

SwiftUI code can compile while hiding an imperative data-flow system underneath `body`:

- local state mirrors a value that already has an owner;
- reciprocal `onChange` handlers keep two mutable representations synchronized;
- a custom `Binding` setter performs commands unrelated to value mutation;
- leaf views receive whole models or services for one value or action;
- lifecycle, focus, geometry, or platform bridges quietly drive product behavior.

Compiler diagnostics and style linters catch different problems; a general prompt can still ask an agent to follow good SwiftUI practices. None gives the agent stable cross-file identities, evidence-backed read and write paths within the supported topology, a compatible semantic baseline, and repeatable evidence for a later review.

SwiftUI Semantic Audit extracts that bounded evidence first. The agent then decides whether a candidate is an accidental mirror, a real transactional draft, legitimate local UI state, an intentional transformation, or something that still lacks evidence.

## See one value with two owners

This editor keeps one logical value in both an external `Binding` and local `State`, then synchronizes the copies in both directions:

```swift
struct NameEditor: View {
    @Binding var name: String
    @State private var draft = ""

    var body: some View {
        TextField("Name", text: $draft)
            .onAppear { draft = name }
            .onChange(of: name) { _, value in draft = value }
            .onChange(of: draft) { _, value in name = value }
    }
}
```

The audit reports the topology, not a wrapper preference:

```text
mirrored-state          high
manual-two-way-sync     high
logical sources         2
```

When both representations mean the same thing and share one lifetime, the focused result can be direct:

```swift
struct NameEditor: View {
    @Binding var name: String

    var body: some View {
        TextField("Name", text: $name)
    }
}
```

A screen with real **Apply** and **Discard** behavior is different. Its local draft should remain local. The tool distinguishes transaction topology from an accidental mirror instead of prescribing “Binding everywhere.”

## Install the CLI and agent skills

Install the released CLI from the upstream Homebrew tap:

```bash
brew install potapenko/tap/swiftui-semantic-audit
swiftui-audit --version
```

Homebrew installs `swiftui-audit`; it does not modify an agent host. The normal workflow also installs one router and three specialist skills from the same immutable release tag.

Give a local Codex or Claude Code session this prompt:

```text
Install exactly the four SwiftUI Semantic Audit agent skills for release 0.4.0.
The CLI is already managed by Homebrew; verify `swiftui-audit --version` first.
Read and follow the tagged installation guide:
https://github.com/potapenko/swiftui-semantic-audit/blob/0.4.0/docs/getting-started/installation.md
Clone only tag 0.4.0 from
https://github.com/potapenko/swiftui-semantic-audit.git into a stable user-owned
path. Before linking anything, verify the origin, tag, and exact commit
189dc44c928f7f61b393f6e4ca7d8f6f5d183a48. Detect this agent host and link all
four sibling skill directories into its documented personal skill directory.
Do not overwrite, delete, move, or repoint an existing path. Finish with the
tag, commit, CLI version, installed paths, host, and verification receipt.
```

See [Installation](docs/getting-started/installation.md) for the complete safe procedure and source-build fallback.

## Copy a task prompt

The prompts below use Codex syntax: `$swiftui-semantic`. In Claude Code, replace it with `/swiftui-semantic`. The staged migration prompt also starts with Codex `/goal`; in Claude Code, remove that prefix and submit the rest as a project task.

### Audit a project without editing it

```text
Use $swiftui-semantic to audit this repository's SwiftUI state and data-flow
architecture. Do not edit product code or configuration. Build the exact
current source, validate a fresh project-covering compiler Index Store, and
accept only indexed evidence. Audit before reading broad source, group
overlapping findings by semantic value, and slice the highest-risk clusters.
Return canonical owners, duplicated representations, synchronization and
effect paths, legitimate exceptions, prioritized candidate refactors, and
the exact missing evidence behind every unknown.
```

### Add the guardrail to a project

```text
Preserve the repository's existing agent instructions and add one bounded
project rule: route SwiftUI tasks that change state ownership, data flow,
Bindings, effects, lifetime, or component boundaries through
$swiftui-semantic. Require its semantic review for existing changes in those
areas. Do not apply the rule to unrelated styling, layout-only, performance,
concurrency, or security work. Show the exact instruction diff before making
any other project change.
```

### Run a staged migration

```text
/goal Migrate this project's SwiftUI state and data-flow architecture with
$swiftui-semantic while preserving product behavior. Start with a read-only
indexed audit and create a restart-safe registry with one row per overlapping
finding cluster, including evidence IDs, owner, invariants, tests, risk, and
status. Process one approved cluster per checkpoint through baseline, slice,
focused edit, build, behavior tests, refreshed indexed snapshot, semantic
diff, check, and independent review. Never hide a finding by weakening scope,
configuration, thresholds, or by moving the same mechanism into another
wrapper. Finish only when every in-scope row has an evidence-backed terminal
disposition and the final configured audit matches the approved scope.
```

This prompt coordinates the existing audit, refactor, and review workflows. It is not a new CLI mode or a one-pass rewrite command.

The [prompt library](docs/getting-started/agent-prompts.md) also includes focused-refactor and existing-change review recipes with their stop conditions.

## Follow one evidence boundary

```text
Swift source + fresh compiler index
    → deterministic ownership and data-flow facts
    → evidence-backed findings and bounded slices
    → agent judgment
    → focused edit + behavior tests + semantic diff
```

The CLI owns syntax, symbols, topology, confidence, and source locations. The agent may classify intent, explain risk, and choose a conditional remediation. It must return `unknown` when ownership, lifetime, transformation, or transaction evidence is missing.

One router selects the smallest workflow:

| Requested result | Workflow |
| --- | --- |
| Explain ownership, synchronization, effects, or component boundaries | [Semantic audit](docs/workflows/audit.md) |
| Change one established state/data-flow cluster | [Data-flow refactor](docs/workflows/refactor.md) |
| Evaluate pre-existing SwiftUI changes | [Change review](docs/workflows/change-review.md) |

## Know the boundary

- Agent workflows require a fresh project-covering compiler Index Store and stop when indexed evidence is unavailable.
- Role-aware findings require exact project configuration; type names do not establish application roles.
- The 29 rules cover bounded SwiftUI topology, not every runtime, concurrency, security, or performance defect.
- A clean semantic diff does not prove behavior. Relevant builds and behavior tests remain required.
- The CLI does not call a model-provider API, rewrite source automatically, or install an IDE/Xcode extension.

## Go deeper

- [Getting started](docs/getting-started/README.md)
- [Why semantic audit](docs/concepts/why-semantic-audit.md)
- [Functional SwiftUI](docs/concepts/functional-swiftui.md)
- [Rules](docs/reference/rules.md)
- [CLI](docs/reference/cli.md)
- [Snapshots and semantic diff](docs/reference/outputs-snapshots-and-diff.md)
- [Development](docs/development/README.md)
- [Product specifications](docs/specs/README.md)

## License

Licensed under the repository [LICENSE](LICENSE).
