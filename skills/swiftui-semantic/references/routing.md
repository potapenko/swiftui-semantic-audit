# Workflow routing and handoffs

Read this reference when a request spans more than one specialist workflow or its starting state is unclear.

## Decision matrix

| Request state and outcome | Select first | Continue when needed |
| --- | --- | --- |
| No trusted semantic evidence; investigate or explain | `swiftui-semantic-audit` | Stop after the report unless the user requested a change |
| User requests a state/data-flow change | `swiftui-dataflow-refactor` | Finish with `swiftui-change-review` when review is in scope |
| A diff, commit, or changed worktree already exists | `swiftui-change-review` | Use refactor only when the user also requested remediation |
| Analyze, fix, and verify | `swiftui-dataflow-refactor` | Its baseline/audit gates cover discovery; then run change review |
| Ambiguous ownership or transaction intent | `swiftui-semantic-audit` | Route to refactor only after intent and invariants are established |

Do not select a semantic workflow for unrelated SwiftUI layout, styling, performance, concurrency, security, or general framework work.

## Transition gates

### Audit to refactor

Proceed only when the user requested implementation and the audit established the target cluster, owner, canonical representation, lifetime, write authority, transaction boundary, transformations, side effects, and required behavior tests.

### Refactor to review

Carry forward the unchanged baseline, current snapshot, resolution, intended semantic delta, build/test evidence, and `check` result. Review semantic changes before the raw source diff.

### Review to refactor

Proceed only when remediation is authorized. Preserve the review's failing finding/change IDs, evidence locations, risk, and protected behavior. Capture a suitable baseline before editing when one does not already exist.

## Stop conditions

Stop the sequence when resolution differs, JSON is invalid, an explicit index is unavailable, a selector is ambiguous, ownership or lifetime remains unknown, behavior tests fail, or a new high-severity finding appears. Report the exact failed phase instead of silently choosing another workflow.
