# Acceptance and QA contract

Revision: `spec-1`  
Status: active  
Release state: unreleased

## Fixture acceptance

**ACC-FIX-001 — Mandatory cases.** Maintain fixtures for direct Binding, value+setter, bidirectional `onChange`, transactional draft, derived state, three-view callback tunnel, observable model mirror, and intentional transformation.

**ACC-FIX-002 — Exact findings.** Required results are the table in [`rules.md`](rules.md#acceptance-fixture-mapping), including tunnel depth 3 and transaction classification without a Binding finding.

**ACC-FIX-003 — Perturbations.** Prove that rule behavior depends on topology rather than names with renamed actions, missing/fake discard, labeled setters, unary derived values, identity-transform exclusion, callback-value mismatch, and depth-two tunnel rejection.

**ACC-FIX-004 — Evidence integrity.** Every finding references existing nodes/edges and nonempty relative one-based evidence.

**ACC-FIX-005 — Binding mirror boundary.** Prove that a Binding copied into identity-synchronized local `State` emits both high-severity mirror findings, while a Binding-backed transactional draft, an independent local UI state, and a Binding self-copy remain clean. Reciprocal synchronization requires two distinct declaration-backed representations.

**ACC-FIX-006 — Closure-parameter scope.** Prove that an unshadowed nested closure may capture an outer `onChange` parameter with identity preserved, a same-name nested parameter is a lexical shadow barrier, and transformed captures produce derivation rather than identity-copy topology.

## Build and tests

**ACC-TEST-001.** Resolve only intentionally, then run locked verification:

```bash
swift build --disable-automatic-resolution
swift test --disable-automatic-resolution
```

**ACC-TEST-002.** The accepted pre-P6 baseline is 53 passing tests across extraction, rules, snapshot, context slice, diff, check, doctor, and symbol resolution.

**ACC-TEST-003.** The current integration candidate has 64 passing tests after the separately owned stable-identity, Binding-mirror/distinct-endpoint, lexical closure-parameter, and value-setter evidence repairs.

**ACC-TEST-004.** P6 itself must not modify accepted Swift product source, dependencies, existing tests, or fixtures.

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

**ACC-DOG-002.** Require valid schema v1 JSON, expected resolution, a passing baseline check, an empty same-input semantic diff, a nonempty bounded slice for a real finding, and no command timeout.

**ACC-DOG-003.** Dogfood does not require zero legacy findings. CI policy is no new high-severity finding relative to the compatible baseline.

## Skills

**ACC-SKILL-001.** Create exactly:

- `swiftui-semantic-audit`;
- `swiftui-dataflow-refactor`;
- `swiftui-change-review`.

**ACC-SKILL-002.** Each skill has frontmatter containing only `name` and trigger-complete `description`, an imperative body under 500 lines, one-level linked references, and generated `agents/openai.yaml` with quoted strings, a 25–64 character short description, and a one-sentence default prompt naming `$skill-name`.

**ACC-SKILL-003.** Run the bundled `quick_validate.py` for all three; parse every YAML file; reject unfinished-marker placeholders and broken relative links.

**ACC-SKILL-004.** Every skill preserves JSON stdout discipline, resolution consistency, exact failure policy, provider independence, topology-over-wrapper reasoning, and the deterministic/LLM fact boundary.

## CI

**ACC-CI-001.** Run on official `macos-26`. The official runner catalog identifies it as the macOS 26 arm64 label, and its image inventory lists Xcode 26.6 at `/Applications/Xcode_26.6.app`. Select that toolchain explicitly and fail early unless it reports Swift >= 6.3.

**ACC-CI-002.** Use only official GitHub actions for repository operations and run shell/Swift/Python tools directly. Pin action major versions intentionally.

**ACC-CI-003.** Apply explicit job/step timeouts. Network use is limited to actions and Swift dependency resolution/cache availability.

**ACC-CI-004.** CI must:

1. checkout;
2. verify Swift >= 6.3 and print Xcode version;
3. resolve, build, and test;
4. audit fixtures and `Sources` in syntax-only JSON mode;
5. snapshot fixtures twice and compare all five files byte for byte;
6. compare the generated snapshot with the committed baseline using exact semantic-file bytes and the revision-only manifest normalization in `ACC-DET-003`;
7. run `check --fail-on-new high`;
8. slice an emitted real finding;
9. run doctor JSON;
10. validate all skills and their YAML metadata without repository or global-environment mutation;
11. parse JSON/YAML and check placeholders/links.

## Definition of Done map

**ACC-DOD-001.** Swift CLI, SwiftSyntax frontend, stable graph, deterministic JSON/JSONL, relative source provenance, and six rules are present.

**ACC-DOD-002.** Fixtures distinguish direct Binding, manual Binding patterns, mirrors, transactions, derived state, tunnels, observable mirrors, and transformations.

**ACC-DOD-003.** Slice, snapshot, semantic diff, check, and doctor satisfy their contracts.

**ACC-DOD-004.** No rule relies solely on wrapper names; no LLM is required for deterministic scan/audit; an agent can work from JSON/slices without reading the whole codebase.

**ACC-DOD-005.** A refactor can be objectively accepted only when manual synchronization/targeted violations improve, no new high violation appears, ownership does not degrade, and behavior tests pass.

**ACC-DOD-006.** Public documentation, three skills, deterministic dogfood baseline, and CI are complete while the release remains truthfully `unreleased`.
