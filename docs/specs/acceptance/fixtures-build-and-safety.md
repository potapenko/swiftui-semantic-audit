# Fixture, Build, and Safety Acceptance

- Node type: leaf
- Status: Active
- Contract revision: `spec-9`
- Authority: [Acceptance and QA contract](../acceptance.md)
- Read when: selecting fixture, build, determinism, safety, dogfood, skill, CI, or completion obligations.
- Do not read when: the task does not implement or verify accepted behavior.
- Maximum size: 100 physical lines.


## Fixture acceptance

**ACC-FIX-001 — Mandatory cases.** Maintain fixtures for direct Binding, value+setter, bidirectional `onChange`, transactional draft, derived state, three-view callback tunnel, observable model mirror, and intentional transformation.

**ACC-FIX-002 — Exact findings.** Required results are the table in [`rules.md`](../rules/adjudication-and-remediation.md#acceptance-fixture-mapping), including tunnel depth 3 and transaction classification without a Binding finding.

**ACC-FIX-003 — Perturbations.** Prove that rule behavior depends on topology rather than names with renamed actions, missing/fake discard, labeled setters, unary derived values, identity-transform exclusion, callback-value mismatch, and depth-two tunnel rejection.

**ACC-FIX-004 — Evidence integrity.** Every finding references existing nodes/edges and nonempty relative one-based evidence.

**ACC-FIX-005 — Binding mirror boundary.** Prove that a Binding copied into identity-synchronized local `State` emits both high-severity mirror findings, while a Binding-backed transactional draft, an independent local UI state, and a Binding self-copy remain clean. Reciprocal synchronization requires two distinct declaration-backed representations.

**ACC-FIX-006 — Closure-parameter scope.** Prove that an unshadowed nested closure may capture an outer `onChange` parameter with identity preserved, a same-name nested parameter is a lexical shadow barrier, and transformed captures produce derivation rather than identity-copy topology.

**ACC-FIX-007 — Binding construction.** Prove that explicit custom Binding construction records one binding node, distinct getter/setter closures, a setter-role edge, enclosing control binding, and stable relative evidence in syntax-only and indexed graphs.

**ACC-FIX-008 — Boundary findings.** Prove exact findings for command-only and write-plus-effect setters, non-View Binding factories, two-boundary observable tunnels, and broad observed leaf inputs.

**ACC-FIX-009 — Boundary exclusions.** Prove no new finding for a direct custom Binding, transformation-only setter, focused Binding chain, View-owned local model, focused value/action input, transactional draft, or intentional transformation.

**ACC-FIX-010 — Logical source count.** Prove focused Binding and observable projection chains have one logical source, while an external borrowed root mirrored into a distinct local State still has two and reports one duplication.

**ACC-FIX-011 — Identity and configuration.** Prove same-named legal file-local declarations in different files do not collide, remain file-scoped in syntax mode, and remap to distinct compiler USRs in indexed mode. Validate configuration schema, exact roles/features/roots, discovery, canonical digest, and fail-closed invalid inputs.

**ACC-FIX-012 — Component architecture.** Positive fixtures cover configured model descendants, multiple owners, cross-feature dependencies, service/repository/effect inputs, and environment command routers. Negative fixtures cover composition roots, focused value/action APIs, passive environment, and unconfigured role-like names.

**ACC-FIX-013 — Binding/lifecycle/focus.** Cover multi-source Bindings, one-way lifecycle owner synchronization, hidden lifecycle commands, leaf external effects, imperative FocusState, and selection correction. Preserve direct projections, reversible transforms, transactions, local animation state, and direct user focus actions.

**ACC-FIX-014 — Layout/platform.** Cover all four geometry findings, gesture button emulation, nonempty representable updates, direct global commands, and preview composition. Preserve Canvas, Shape-local coordinates, local animation transforms, Button, empty representable updates, and focused previews.

**ACC-FIX-015 — Dominance.** Prove one generic/specific path does not produce redundant findings under `RULE-DOM-001`.

**ACC-FIX-016 — Realistic multi-file patterns.** Maintain one compilable, configured SwiftUI corpus with paired bad and good implementations across state flow, owner/component boundaries, lifecycle/focus/selection, geometry, platform adapters, and previews. Require an exact per-file rule/count matrix, exact severity/confidence, valid relative evidence, and no finding whose evidence points into a good counterpart.

**ACC-FIX-017 — Scale and resolution invariance.** Adding at least forty clean SwiftUI source files to the realistic corpus must preserve every existing finding exactly. Two fresh explicit IndexStoreDB enrichments must be byte-identical, retain `resolution: "indexed"`, and preserve the syntax-mode per-rule/per-file finding matrix without duplication or loss.

**ACC-FIX-018 — Reusable component surface.** The positive, exception, compatibility, dominance, slice, and realistic-corpus obligations are pinned in [`component-surface.md`](component-surface.md).

## Build and tests

**ACC-TEST-001.** Resolve only intentionally, then run locked verification:

```bash
swift build --disable-automatic-resolution
swift test --disable-automatic-resolution
```

**ACC-TEST-002.** The accepted pre-P6 baseline is 53 passing tests across extraction, rules, snapshot, context slice, diff, check, doctor, and symbol resolution.

**ACC-TEST-003.** The `BOUNDARY-001` integration candidate has 69 passing tests: the accepted 64-test suite plus focused custom-Binding extraction, exact boundary-rule/metric, semantic-diff source-count, and fresh explicit indexed-enrichment coverage.

**ACC-TEST-004.** P6 itself must not modify accepted Swift product source, dependencies, existing tests, or fixtures.

**ACC-TEST-005.** `BOUNDARY-001` must exercise every new rule in deterministic frontend tests and at least one fresh explicit indexed integration path. Indexed enrichment must preserve new generated binding topology and finding identity.

**ACC-TEST-006.** `ARCHITECTURE-001` advances tool version to `0.3.0` and schema to v2. Every new rule has positive and negative deterministic fixtures; identity/config/type topology has fresh explicit indexed coverage; snapshot/diff/check enforce configuration digest equality.

**ACC-TEST-007.** The `ARCHITECTURE-001` implementation candidate has 77 passing tests, including all prior suites, four focused architecture/configuration tests, accessor/switch-case identity coverage, configuration-mismatch comparison, and two new explicit IndexStoreDB tests.

**ACC-TEST-008.** `REALISTIC-FIXTURES-001` advances the accepted suite to 81 passing tests: three deterministic realistic-corpus rule tests and one fresh explicit indexed parity test. The restore sub-slice deduplicates multiple frontend/compiler ownership edges for one typed View boundary and associates a compiler-shared method call only with receiver evidence from the same source range.

**ACC-TEST-009.** `INCREMENTAL-CACHE-001` advances the local suite to 86 passing tests. Four frontend tests prove warm reuse, one-file reparsing, lexical dependency invalidation, add/delete/rename equivalence, integrity failure, persistent round-trip, and concurrent writers. One indexed test proves exact per-file hit/miss counts, whole-result reuse without a repeated helper, and cached/uncached byte equivalence.

**ACC-TEST-010.** `PARALLEL-EXECUTION-001` advances the local suite to 88 passing tests. Frontend and rule-engine tests compare one worker with four workers byte for byte; CLI integration covers one/two jobs and rejects zero; focused Thread Sanitizer runs cover both parallel boundaries.

**ACC-TEST-011.** `COMPONENT-SURFACE-001` advances the target suite to 92 passing tests with four focused configuration/rule/exception/slice cases while reusing the realistic syntax/indexed parity gate.

## Determinism and safety

**ACC-CACHE-001.** A cold cached run, a warm cached run, and `--no-cache` produce byte-identical graphs and reports. A warm run performs zero frontend parses for unchanged files; a one-file body edit reparses that file only.

**ACC-CACHE-002.** Add, delete, rename, declaration-surface change, dependency change, configuration change, tool/schema mismatch, compiler/index-unit change, corrupt entry, and concurrent writers cannot produce stale or malformed facts. Indexed warm runs retain `resolution: "indexed"` and remain byte-identical to uncached indexed enrichment.

**ACC-CACHE-003.** CI proves operation-count hits/misses rather than a wall-clock ratio, preserves the exact five-file snapshot boundary, and runs the existing realistic syntax/indexed parity and full dogfood gates with cache enabled and disabled.

**ACC-PERF-001.** Frontend extraction and audit rule evaluation produce byte-identical graph/report output with one worker and multiple workers. Repeated multi-worker runs are deterministic, and focused Thread Sanitizer verification reports no race in either parallel boundary.

**ACC-DET-001.** Generate the canonical RuleTests snapshot twice from unchanged fixtures and prove all five files are byte-identical.

**ACC-DET-002.** The committed `Tests/Baselines/RuleTests` snapshot must contain exactly five regular files, valid sorted JSON/JSONL, relative paths, matching schema/resolution, and no dangling references.

**ACC-DET-003.** Two fresh snapshots from the same revision must match byte for byte across all five files. Against the committed baseline, require byte-exact `nodes.jsonl`, `edges.jsonl`, `findings.jsonl`, and `summary.json`; deterministically normalize only `manifest.json.repositoryRevision`, require every other manifest field exact, and require the fresh revision to equal checked-out `HEAD`.

**ACC-SAFE-001.** Tests cover source/output overlap, non-snapshot replacement rejection, invalid/missing/extra/symlink files, absolute paths, dangling references, inconsistent counts/schema/resolution, and safe replacement.

**ACC-SAFE-002.** Revision loading must not checkout, switch, or create a worktree; it reconstructs validated Swift blobs in a temporary directory with bounded Git calls.
