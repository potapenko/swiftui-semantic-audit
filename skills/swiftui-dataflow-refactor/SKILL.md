---
name: swiftui-dataflow-refactor
description: Refactor SwiftUI state ownership and data flow with snapshot, audit, slice, semantic diff, and check gates. Use when Codex needs to remove manual synchronization, collapse duplicated sources of truth, replace callback plumbing, correct derived state, or improve Binding, Bindable, Environment, or State architecture while preserving behavior.
---

# SwiftUI Dataflow Refactor

## Fix one semantic-value cluster

1. Use an installed `swiftui-audit`, or use `swift run --disable-automatic-resolution swiftui-audit` in this repository.
2. Build the project to produce a fresh compiler Index Store, validate that it covers the requested source, and record its exact path. Pass `--index-store <path>` explicitly to every live-source command; never rely on automatic discovery. Require `resolution: "indexed"` throughout baseline, current snapshot, audit, slice, diff, and check.
3. Capture a canonical baseline before editing:

   ```bash
   swiftui-audit snapshot <source-path> --output <baseline-dir> --index-store <path> --format json
   ```

4. Run audit JSON and select exactly one semantic value or overlapping finding cluster:

   ```bash
   swiftui-audit audit <source-path> --index-store <path> --format json
   swiftui-audit slice <source-path> --finding <finding-id> --index-store <path> --format llm-json --token-budget 10000
   ```

5. Inspect source only at slice evidence locations and directly required declarations.
6. Establish intended owner, canonical representation, lifetime, write authority, transaction boundary, and behavior invariants before editing.
7. Choose among owned `State`, external focused `Binding`, model projection through `Bindable`, injected `Environment` dependency, focused value/action inputs, computed/derived value, or transactional draft. Never “Use Binding everywhere” or “Minimize `@State`.”
8. Edit only the selected cluster and required call sites. When resolving a command-shaped setter or broad observable input, keep value mutation and actions explicit and narrow only the proven component boundary. Preserve transformations, side effects and their timing, commit/cancel semantics, identity, lifetime, legitimate screen/container ownership, and unrelated APIs.
9. Build and run behavior tests, refreshing the compiler Index Store after the edit.
10. Re-run audit and create a current snapshot with the refreshed validated Index Store. Require indexed resolution again.
11. Compare semantic snapshots, then enforce policy:

    ```bash
    swiftui-audit diff <baseline-dir> <current-dir> --format json
    swiftui-audit check --baseline <baseline-dir> <source-path> --fail-on-new high --index-store <path> --format json
    ```

12. Read [references/refactor-gates.md](references/refactor-gates.md) when choosing a representation or evaluating acceptance.

Treat JSON stdout as the machine contract. Keep stderr and exit status separate. Do not add or assume a provider API; the agent adjudicates ambiguous candidates outside the deterministic CLI.

## Reject or stop

Reject the refactor when it introduces a high-severity finding, increases manual synchronization, adds an unexplained mutable/write/call path, makes ownership ambiguous, broadens a component dependency without evidence, hides a Binding setter effect, weakens an invariant, or changes transaction/lifetime semantics. Treat a failed build or behavior test as a rejection, even when semantic metrics improve.

Stop without editing further when a command fails, JSON is invalid, a slice is missing/ambiguous or cannot fit, a fresh explicit index cannot cover the project, any result is not indexed, resolutions differ, snapshot paths are unsafe, or intended ownership remains unknown. Report the exact failure and smallest missing evidence. Never fill deterministic AST/symbol/read/write/source facts with model guesses.

## Report the cluster outcome

Separate:

- behavior preserved by tests;
- semantic changes proven by diff;
- findings resolved, retained, or added;
- ownership and lifetime decision;
- remaining ambiguous agent judgment.
