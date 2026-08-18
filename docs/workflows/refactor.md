# Refactor workflow

Use this workflow when the user has asked to change SwiftUI state ownership or data flow. It limits the edit to one semantic-value cluster and proves the result with behavior and semantic evidence.

## Entry point

- Codex: `$swiftui-semantic Remove the manual synchronization in the profile editor without changing its save/cancel behavior.`
- Claude Code: `/swiftui-semantic Remove the manual synchronization in the profile editor without changing its save/cancel behavior.`

For a direct change request, the router selects `swiftui-dataflow-refactor`. That specialist already includes audit, slice, baseline, diff, and check gates.

## 1. Pin the baseline

Build the exact pre-edit source and validate its project-covering Index Store. If role-aware analysis is needed, validate the exact `.swiftui-audit.json`.

Create an indexed snapshot before editing:

```bash
swiftui-audit snapshot Sources \
  --output .semantic/baseline \
  --index-store /absolute/path/to/baseline/index/store \
  --config .swiftui-audit.json \
  --format json
```

Store the snapshot outside the source path when needed to avoid source/output overlap. Record its resolution, configuration digest, tool/schema versions, and repository revision.

## 2. Select one cluster

Run an indexed audit and slice the target finding:

```bash
swiftui-audit audit Sources \
  --index-store /absolute/path/to/baseline/index/store \
  --config .swiftui-audit.json \
  --format json > audit-before.json

swiftui-audit slice Sources \
  --finding finding:0123456789abcdef \
  --index-store /absolute/path/to/baseline/index/store \
  --config .swiftui-audit.json \
  --format llm-json \
  --token-budget 10000 > slice-before.json
```

Inspect only the evidence locations and declarations required by that cluster.

## 3. State the behavior to preserve

Before editing, name:

- intended owner and canonical representation;
- component lifetime and write authority;
- product behavior and ordering;
- transformations;
- commit, cancel, or rollback semantics;
- side effects and their timing;
- public or sibling interfaces that must remain stable.

If these cannot be established, stop. A plausible property-wrapper change is not a substitute for product intent.

## 4. Choose the representation

Possible outcomes include:

- owner-local `State`;
- an external focused `Binding`;
- observable projection through `Bindable`;
- an injected environment dependency;
- focused value and action inputs;
- a computed/derived value;
- a transactional draft.

Choose from the ownership and lifetime evidence. Do not optimize for Binding everywhere or for the fewest `@State` properties.

## 5. Edit the smallest complete path

Change the selected cluster and directly required call sites. Preserve behavior, transformations, effects, identity, lifetime, and transaction boundaries.

When narrowing a model input or command-shaped Binding, do not hide the same command behind another callback. The new interface should make value flow and effects more explicit.

## 6. Verify behavior and refresh indexed evidence

Build the edited source and run the relevant behavior tests. The edit changes compiler facts, so create a fresh Index Store for the current state.

Audit again and create a compatible current snapshot:

```bash
swiftui-audit audit Sources \
  --index-store /absolute/path/to/current/index/store \
  --config .swiftui-audit.json \
  --format json > audit-after.json

swiftui-audit snapshot Sources \
  --output .semantic/current \
  --index-store /absolute/path/to/current/index/store \
  --config .swiftui-audit.json \
  --format json
```

Both snapshots must be indexed and carry the same configuration digest.

## 7. Diff and enforce policy

```bash
swiftui-audit diff .semantic/baseline .semantic/current --format json > semantic-diff.json

swiftui-audit check \
  --baseline .semantic/baseline \
  Sources \
  --fail-on-new high \
  --index-store /absolute/path/to/current/index/store \
  --config .swiftui-audit.json \
  --format json > semantic-check.json
```

`check` exits `2` when policy fails. Treat status separately from JSON output.

## Acceptance

Accept the refactor only when:

- required behavior tests pass;
- the target synchronization or ownership problem improves;
- no new high-severity finding appears;
- no unexplained mutable, write, call, or dependency path is added;
- ownership and lifetime are at least as clear as before;
- transformations, effects, and commit/cancel semantics remain intact;
- semantic diff matches the intended architecture change.

A lower aggregate finding count is not sufficient. Reject the change when build or behavior tests fail even if the graph looks cleaner.

Finish with the [change-review workflow](change-review.md) when the change needs independent evaluation.
