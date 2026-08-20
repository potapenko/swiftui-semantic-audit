# Semantic review contract

Read this reference when interpreting semantic diff JSON or separating semantic and implementation-only review.

## Diff envelope

The report contains `baseIdentity`, `currentIdentity`, before/after metrics, `changes`, `newFindings`, `resolvedFindings`, and `affectedSemanticValues`.

Change kinds are:

- `NODE_ADDED`, `NODE_REMOVED`;
- `OWNERSHIP_CHANGED`;
- `READ_PATH_ADDED`, `READ_PATH_REMOVED`;
- `WRITE_PATH_ADDED`, `WRITE_PATH_REMOVED`;
- `BINDING_ADDED`, `BINDING_REMOVED`;
- `MANUAL_SYNC_ADDED`, `MANUAL_SYNC_REMOVED`;
- `DERIVATION_CHANGED`;
- `SOURCE_OF_TRUTH_COUNT_CHANGED`.

Affected semantic values include before/after representations and optional representation/source counts. Exact-qualified continuity is conservative: a true rename can appear as removal plus addition.

## Review priorities

1. New high-severity findings and ownership changes.
2. Added write paths, mutable representations, or sources of truth.
3. Removed read/write paths that may encode invariants or effects.
4. Binding and manual synchronization changes.
5. Command-shaped setter calls, Binding factories, observable-model tunnels, and broad component inputs.
6. Configured owner/feature/View-role changes, reusable-owner candidates, instance/lifetime changes, lifecycle effects, focus/selection loops, geometry escape/effects, and platform commands.
7. Logical source-count, derivation, configuration-digest, and lifetime changes.
8. Resolved findings whose removal may be accidental suppression.

## Semantic versus implementation-only

Semantic findings concern ownership, representations, reads/writes, synchronization, bindings, derivation, lifetime, or transaction behavior. Implementation-only findings concern source mechanics not expressed in the graph, such as API misuse, control flow, error handling, performance, styling, or tests. Inspect raw Git diff for the latter only after semantic triage.

Do not claim a behavior change solely from an aggregate metric. Tie it to a change, slice, evidence location, and affected invariant. Do not claim implementation safety solely from a semantic-clean diff.

A reusable-owner finding is candidate evidence, not an automatic defect. Check whether the dependency is a shared app/feature owner or an explicit per-instance component model before recommending values, focused bindings, actions, or ownership changes.
