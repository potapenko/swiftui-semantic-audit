# Acceptance and QA contract

Revision: `spec-5`
Status: active  
Release state: unreleased

## Fixture acceptance

**ACC-FIX-001 — Mandatory cases.** Maintain fixtures for direct Binding, value+setter, bidirectional `onChange`, transactional draft, derived state, three-view callback tunnel, observable model mirror, and intentional transformation.

**ACC-FIX-002 — Exact findings.** Required results are the table in [`rules.md`](rules.md#acceptance-fixture-mapping), including tunnel depth 3 and transaction classification without a Binding finding.

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

**ACC-TEST-007.** The `ARCHITECTURE-001` implementation candidate has 76 passing tests, including all prior suites, four focused architecture/configuration tests, configuration-mismatch comparison, and two new explicit IndexStoreDB tests.

## Determinism and safety

**ACC-DET-001.** Generate the canonical RuleTests snapshot twice from unchanged fixtures and prove all five files are byte-identical.

**ACC-DET-002.** The committed `Tests/Baselines/RuleTests` snapshot must contain exactly five regular files, valid sorted JSON/JSONL, relative paths, matching schema/resolution, and no dangling references.

**ACC-DET-003.** Two fresh snapshots from the same revision must match byte for byte across all five files. Against the committed baseline, require byte-exact `nodes.jsonl`, `edges.jsonl`, `findings.jsonl`, and `summary.json`; deterministically normalize only `manifest.json.repositoryRevision`, require every other manifest field exact, and require the fresh revision to equal checked-out `HEAD`.

**ACC-SAFE-001.** Tests cover source/output overlap, non-snapshot replacement rejection, invalid/missing/extra/symlink files, absolute paths, dangling references, inconsistent counts/schema/resolution, and safe replacement.

**ACC-SAFE-002.** Revision loading must not checkout, switch, or create a worktree; it reconstructs validated Swift blobs in a temporary directory with bounded Git calls.

## CLI dogfood

**ACC-DOG-001.** Run and parse:

- `audit Tests/Fixtures/RuleTests --syntax-only --format json`;
- `snapshot Tests/Fixtures/RuleTests … --syntax-only --format json`;
- `diff <baseline> <regenerated> --format json`;
- `check --baseline Tests/Baselines/RuleTests Tests/Fixtures/RuleTests --fail-on-new high --syntax-only --format json`;
- `slice` on an emitted fixture finding with `--format llm-json`;
- `doctor . --format json`;
- `audit Sources --syntax-only --format json`.

**ACC-DOG-002.** Require valid schema v2 JSON, expected resolution, a passing baseline check, an empty same-input semantic diff, a nonempty bounded slice for a real finding, and no command timeout.

**ACC-DOG-003.** Dogfood does not require zero legacy findings. CI policy is no new high-severity finding relative to the compatible baseline.

## Skills

**ACC-SKILL-001.** Create exactly one user-facing router and three specialist workflows:

- `swiftui-semantic`;
- `swiftui-semantic-audit`;
- `swiftui-dataflow-refactor`;
- `swiftui-change-review`.

**ACC-SKILL-002.** Each skill has frontmatter containing only `name` and trigger-complete `description`, an imperative body under 500 lines, one-level linked references, and generated `agents/openai.yaml` with quoted strings, a 25–64 character short description, and a one-sentence default prompt naming `$skill-name`.

**ACC-SKILL-003.** Run the bundled `quick_validate.py` for all four; parse every YAML file; reject unfinished-marker placeholders and broken relative links.

**ACC-SKILL-004.** Every skill preserves JSON stdout discipline, indexed-resolution consistency, exact failure policy, provider independence, topology-over-wrapper reasoning, and the deterministic/LLM fact boundary.

**ACC-SKILL-005.** `swiftui-semantic` routes investigation or ambiguity to audit, requested state/data-flow implementation to refactor, and pre-existing changes to review. Mixed tasks use the smallest valid sequence, read the selected specialist completely, preserve handoff state, and never replace specialist acceptance gates with a shortened combined workflow.

**ACC-SKILL-006.** Every router, specialist skill, and skill reference requires explicit indexed analysis for agent workflows. Skill Markdown contains no `syntax-only` guidance or examples, does not rely on automatic resolution fallback, validates `resolution: "indexed"`, and stops when a fresh project-covering Index Store or compatible indexed snapshot is unavailable. Change review uses indexed snapshots rather than Git-revision operands that cannot preserve indexed resolution.

## CI

**ACC-CI-001.** Run on official `macos-26`. The official runner catalog identifies it as the macOS 26 arm64 label, and its image inventory lists Xcode 26.6 at `/Applications/Xcode_26.6.app`. Select that toolchain explicitly and fail early unless it reports Swift >= 6.3.

**ACC-CI-002.** Use only official GitHub actions for repository operations and run shell/Swift/Python tools directly. Pin action major versions intentionally.

**ACC-CI-003.** Apply explicit job/step timeouts. Network use is limited to actions and Swift dependency resolution/cache availability.

**ACC-CI-004.** CI must:

1. checkout;
2. verify Swift >= 6.3 and print Xcode version;
3. resolve, build, and test;
4. audit legacy rule fixtures, configured architecture fixtures, negative architecture fixtures, and `Sources` in syntax-only JSON mode;
5. snapshot fixtures twice and compare all five files byte for byte;
6. compare the generated snapshot with the committed baseline using exact semantic-file bytes and the revision-only manifest normalization in `ACC-DET-003`;
7. run `check --fail-on-new high`;
8. slice an emitted real finding;
9. run doctor JSON;
10. validate all skills and their YAML metadata without repository or global-environment mutation, and reject frontend-only resolution guidance anywhere under `skills/`;
11. parse JSON/YAML and check placeholders/links.

## Definition of Done map

**ACC-DOD-001.** Swift CLI, SwiftSyntax frontend, stable graph, deterministic JSON/JSONL, relative source provenance, and twenty-nine rules are present.

**ACC-DOD-002.** Fixtures distinguish direct Binding, manual Binding patterns, mirrors, transactions, derived state, tunnels, observable mirrors, and transformations.

**ACC-DOD-003.** Slice, snapshot, semantic diff, check, and doctor satisfy their contracts.

**ACC-DOD-004.** No rule relies solely on wrapper names; no LLM is required for deterministic scan/audit; an agent can work from JSON/slices without reading the whole codebase.

**ACC-DOD-005.** A refactor can be objectively accepted only when manual synchronization/targeted violations improve, no new high violation appears, ownership does not degrade, and behavior tests pass.

**ACC-DOD-006.** Public documentation, one routing skill, three specialist skills, deterministic dogfood baseline, and CI are complete while the release remains truthfully `unreleased`.

**ACC-DOD-007.** Tool version `0.2.0` baseline shipped ten rules and schema v1.

**ACC-DOD-008.** Tool version `0.3.0` ships schema v2, collision-safe indexed extraction, explicit configuration, twenty-nine rules, dominance, complete negative fixtures, updated skills, deterministic baselines, and hosted CI while remaining unreleased.
