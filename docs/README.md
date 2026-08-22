# Documentation

SwiftUI Semantic Audit builds a deterministic semantic twin of supported
SwiftUI ownership and data flow before a coding agent makes an architectural
judgment. These pages explain the twin, its evidence boundary, and the
operational paths for audit, refactor, and review.

[Project website](https://swiftui-audit.dev/) · [Back to the project README](../README.md)

Release `0.5.0` builds an exact-state twin on demand. The project-watcher guide
is explicitly for the unreleased `0.6.0` candidate; it is not part of the
current Homebrew release.

## Start here

| If you want to… | Read… |
| --- | --- |
| Install the CLI and skills | [Getting started](getting-started/README.md) |
| Configure continuous semantic project state | [Project watcher setup](getting-started/project-watcher.md) |
| Give an agent an installation, audit, refactor, review, or migration task | [Agent prompt library](getting-started/agent-prompts.md) |
| Understand why source or Git diff is not enough | [Why semantic audit](concepts/why-semantic-audit.md) |
| Define “functional SwiftUI” in practical terms | [Functional SwiftUI](concepts/functional-swiftui.md) |
| Compare complete Before/Evidence/Safer shape examples | [Pattern catalog](concepts/pattern-catalog.md) |
| Investigate an application | [Audit workflow](workflows/audit.md) |
| Change ownership or data flow | [Refactor workflow](workflows/refactor.md) |
| Review an existing change | [Change-review workflow](workflows/change-review.md) |
| Look up a command, rule, config field, or output | [Reference](reference/README.md) |
| Build or contribute to this package | [Development](development/README.md) |
| Verify normative product behavior | [Specification registry](specs/README.md) |

## Documentation map

```text
docs/
├── README.md                         # documentation hub
├── getting-started/
│   ├── README.md                     # shortest route to a working audit
│   ├── installation.md               # agent and manual installation
│   ├── agent-prompts.md              # copy-paste tasks for coding agents
│   ├── first-audit.md                # indexed and standalone first passes
│   └── project-watcher.md            # unreleased 0.6.0 continuous state
├── concepts/
│   ├── README.md
│   ├── why-semantic-audit.md
│   ├── functional-swiftui.md
│   ├── pattern-catalog.md
│   └── deterministic-facts-and-agent-judgment.md
├── workflows/
│   ├── README.md
│   ├── audit.md
│   ├── refactor.md
│   └── change-review.md
├── reference/
│   ├── README.md
│   ├── cli.md
│   ├── configuration.md
│   ├── rules.md
│   └── outputs-snapshots-and-diff.md
├── development/
│   └── README.md
├── specs/                             # normative product contracts
└── coordination/                      # internal implementation history
```

## Three layers of documentation

The repository separates material by purpose:

1. **Public guides** explain why and how to use the product. They live in `getting-started`, `concepts`, `workflows`, `reference`, and `development`.
2. **Normative specifications** define the accepted product contract, invariants, schemas, rules, and proof obligations. Start at [`specs/README.md`](specs/README.md).
3. **Coordination records** preserve implementation checkpoints and contract deltas. They are useful to maintainers, but they are not the shortest path for a user.

When a public guide and a specification appear to disagree, the active specification registry controls. Published release claims require the immutable tag, release archive, and Homebrew formula receipt recorded by the release baseline.

## Product boundary

The tool produces the deterministic facts in the semantic twin. It does not
rewrite Swift, call a model API, replace behavior tests, or prove product
intent from syntax alone. The installed agent skill consumes bounded graph
slices, classifies the evidence, and must stop when ownership or behavior
cannot be established.

That split is the central design constraint, not an implementation detail. Read [Deterministic facts and agent judgment](concepts/deterministic-facts-and-agent-judgment.md) before integrating the output into another automated workflow.
