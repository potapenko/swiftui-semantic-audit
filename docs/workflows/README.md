# Workflows

The `swiftui-semantic` router selects one of three specialist workflows. Each workflow uses the same deterministic graph contract but has a different stopping condition.

| Workflow | Starts from | Ends with |
| --- | --- | --- |
| [Audit](audit.md) | A question, symptom, or unknown architecture | Evidence-backed classification and conditional remediation |
| [Refactor](refactor.md) | A user-authorized change and established invariants | Focused edit plus build, tests, semantic diff, and check evidence |
| [Change review](change-review.md) | Pre-existing changes and compatible snapshots | Risk-ranked semantic and implementation findings |

Mixed work should use the smallest valid sequence. An ambiguous change may need audit before refactor. A refactor normally ends with review. A direct review request should not add an unnecessary investigation phase.

All agent workflows require indexed evidence. They may consume a watcher live
snapshot only with its matching fresh indexed status receipt. Otherwise they
wait boundedly for indexed status or use a fresh explicit validated Index Store;
they never downgrade to lower-resolution evidence.

[Back to documentation](../README.md)
