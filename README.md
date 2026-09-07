# SwiftUI Semantic Audit

**Trace SwiftUI state and write paths before a coding agent changes them.**

SwiftUI Semantic Audit gives Codex, Claude Code, and other agents a source-linked
map of ownership, Bindings, copies, calls, and component boundaries. This
**semantic twin** lets an agent inspect a specific flow, decide what the code
means, and compare that flow after a change.

macOS 13 or later · MIT · [Website](https://swiftui-audit.dev/) ·
[Install](#quick-start) · [Documentation](docs/README.md)

## One value, two mutable representations

This editor copies an external value into local state, then writes every edit
back. The local copy has no separate Apply/Cancel boundary:

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

The analyzer reports `mirrored-state` and `manual-two-way-sync`, with the two
representations, both copy paths, and source locations. The Binding provides
write access to external state; the external owner's declaration is not shown.

If edits are meant to reach that owner immediately, the agent can keep the same
editor and remove the local synchronization:

```swift
struct NameEditor: View {
    @Binding var name: String

    var body: some View {
        TextField("Name", text: $name)
    }
}
```

If the product instead requires Save and Cancel, local draft state is necessary.
The right change is to protect its commit boundary. A finding supplies evidence;
it does not choose the intended behavior.

[Inspect the annotated example](https://swiftui-audit.dev/#xray) ·
[Understand ownership and lifetime](docs/concepts/functional-swiftui.md)

## Quick start

Give a local Codex or Claude Code agent this installation request:

```text
Install SwiftUI Semantic Audit from this GitHub guide. Install Homebrew first if needed, then the CLI and all four agent skills:
https://github.com/potapenko/swiftui-semantic-audit/blob/0.6.0/docs/getting-started/installation.md
```

For an existing installation:

```text
Update SwiftUI Semantic Audit to the latest stable release using the guide linked from https://swiftui-audit.dev/#install. Update the Homebrew CLI and all four agent skills separately, then verify that they use the same release.
```

Homebrew installs the `swiftui-audit` executable. The guide installs the four
skills separately from the same release. CLI-only installation:

```bash
brew install potapenko/tap/swiftui-semantic-audit
swiftui-audit --version
swiftui-audit doctor . --format json
```

Then request one outcome:

```text
Use $swiftui-semantic to audit this project's SwiftUI ownership and data flow
without editing code. Show one finding, the write paths that support it,
and any missing evidence needed to decide what should change.
```

Use `/swiftui-semantic` in Claude Code. The router selects audit, refactor, or
change review. A strict workflow needs a fresh project-covering compiler index,
or a watcher snapshot with its matching fresh indexed status receipt.
[`doctor`](docs/reference/cli.md) checks environment readiness; it does not prove
snapshot freshness. [Run the first audit](docs/getting-started/first-audit.md).

## How the semantic twin is built

```text
Swift source + compiler index → graph and rule assessments
                             → finding/symbol slice → agent judgment
                             → snapshots → semantic diff and check
```

The CLI extracts identities and relationships, evaluates 30 bounded rules,
and attaches source evidence. It does not call a model API or rewrite Swift.
The agent supplies product intent, checks ownership and lifetime, and proposes
a focused change. Builds and behavior tests establish whether that change works.

A slice selects a relevant part of the graph. It is not guaranteed to be smaller
than the source or even the full graph: required evidence has a cost. Use an
explicit token budget and follow evidence back to source when necessary.
[Output formats and budgets](docs/reference/outputs-snapshots-and-diff.md).

## What a result establishes

- A graph records supported source/compiler facts. Repetition makes output
  reproducible; it does not turn a rule's architectural assessment into proof.
- `candidate` means review is required. `strong-inference` means explicit
  topology supports the assessment. Neither establishes all product intent.
- `check` fails for new findings at the selected severity threshold; its default
  is `high`. It is a policy gate, not a complete correctness test.
- A clean report can miss runtime behavior. In the [eight-task pilot](evaluation/ownership-pilot/results.md),
  the analyzer found the three supported problem patterns and missed the
  runtime control involving a retained `State` initializer. This small authored
  set does not establish accuracy or productivity on other projects.

[Facts and judgment](docs/concepts/deterministic-facts-and-agent-judgment.md) ·
[Rule catalog](docs/reference/rules.md) · [Pattern catalog](docs/concepts/pattern-catalog.md)

## Release and current source

| Surface | State |
| --- | --- |
| Public CLI and tagged skills | Immutable [0.6.0](https://github.com/potapenko/swiftui-semantic-audit/releases/tag/0.6.0); invoke the semantic workflow explicitly |
| Current source | Unpublished 0.6.1 candidate: watcher repairs, cache hygiene, index coverage/freshness checks, slice provenance, and a revised native-update review signal |
| Current-source skills | The router may offer bounded assistance when fresh indexed evidence is already ready; all three specialists require explicit invocation |

Installing public 0.6.0 does not install current-source changes. Native update
boundaries remain `high / strong-inference` in 0.6.0; current source uses
`medium / candidate`. Current source does not imply an updated local installation.
[Installation and version-specific behavior](docs/getting-started/installation.md).

## Ongoing analysis and review

The optional [project watcher](docs/getting-started/project-watcher.md) keeps live
state outside the repository and invalidates stale results. A saved snapshot
contains exactly five files; a baseline is a deliberately selected snapshot.
The analysis cache is an implementation detail and is never evidence by itself.

Use `scan`, `audit`, `snapshot`, `slice`, `diff`, `check`, and `doctor` for one-shot
work. The `project` namespace handles setup, watching, status and baseline
promotion. [CLI reference](docs/reference/cli.md) · [Review workflow](docs/workflows/change-review.md).

Role-aware analysis requires exact project configuration. The tool does not
cover every concurrency, persistence, navigation, security, or performance
problem. Rename matching is conservative, and no clean diff replaces source
review or tests of product behavior.

## Development

```bash
swift build --disable-automatic-resolution
swift test --disable-automatic-resolution
```

A Swift 6.3-compatible toolchain is required. See the
[development guide](docs/development/README.md), [specification registry](docs/specs/README.md),
and [pilot protocol](evaluation/ownership-pilot/README.md).

## License

[MIT](LICENSE).
