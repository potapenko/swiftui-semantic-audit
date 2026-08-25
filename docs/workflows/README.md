# Workflows

The explicit-only `$swiftui-semantic` router selects one of three specialist workflows after the user invokes it. Ordinary SwiftUI implementation, debugging, refactor, and review work does not activate this bundle. Each invoked workflow uses the same deterministic graph contract but has a different stopping condition.

| Workflow | Starts from | Ends with |
| --- | --- | --- |
| [Audit](audit.md) | A question, symptom, or unknown architecture | Evidence-backed classification and conditional remediation |
| [Refactor](refactor.md) | A user-authorized change and established invariants | Focused edit plus build, tests, semantic diff, and check evidence |
| [Change review](change-review.md) | Pre-existing changes and compatible snapshots | Risk-ranked semantic and implementation findings |

Mixed work should use the smallest valid sequence. An ambiguous change may need audit before refactor. A refactor normally ends with review. A direct review request should not add an unnecessary investigation phase.

Once explicitly invoked, all semantic agent workflows require indexed evidence. They may consume a watcher live
snapshot only with its matching fresh indexed status receipt. Otherwise they
wait boundedly for indexed status or use a fresh explicit validated Index Store;
they never downgrade to lower-resolution evidence. Missing indexed evidence
blocks that semantic result, not unrelated agent work.

[Back to documentation](../README.md)
