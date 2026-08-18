# Documentation

SwiftUI Semantic Audit gives a coding agent a deterministic view of SwiftUI state and data flow before the agent makes an architectural judgment. These pages explain the product from first installation through audit, refactor, and review.

[Back to the project README](../README.md)

## Start here

| If you want to… | Read… |
| --- | --- |
| Install the CLI and skills | [Getting started](getting-started/README.md) |
| Understand why source or Git diff is not enough | [Why semantic audit](concepts/why-semantic-audit.md) |
| Define “functional SwiftUI” in practical terms | [Functional SwiftUI](concepts/functional-swiftui.md) |
| Investigate an application | [Audit workflow](workflows/audit.md) |
| Change ownership or data flow | [Refactor workflow](workflows/refactor.md) |
| Review an existing change | [Change-review workflow](workflows/change-review.md) |
| Look up a command, rule, config field, or output | [Reference](reference/README.md) |
| Build or contribute to this package | [Development](development/README.md) |
| Verify normative product behavior | [Specification registry](specs/README.md) |

## Documentation map

```text
docs/
├── README.md                         # this public landing page
├── getting-started/
│   ├── README.md                     # shortest route to a working audit
│   ├── installation.md               # agent and manual installation
│   └── first-audit.md                # indexed and standalone first passes
├── concepts/
│   ├── README.md
│   ├── why-semantic-audit.md
│   ├── functional-swiftui.md
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

When a public guide and a specification appear to disagree, the active specification registry controls. The project is currently unreleased, so implementation and documentation claims are tied to the checked-out commit rather than a published tag.

## Product boundary

The tool produces deterministic semantic evidence. It does not rewrite Swift, call a model API, replace behavior tests, or prove product intent from syntax alone. The installed agent skill reads bounded graph slices, classifies the evidence, and must stop when ownership or behavior cannot be established.

That split is the central design constraint, not an implementation detail. Read [Deterministic facts and agent judgment](concepts/deterministic-facts-and-agent-judgment.md) before integrating the output into another automated workflow.
