# Definition of Done

- Node type: leaf
- Status: Active
- Contract revision: `spec-9`
- Authority: [Acceptance and QA contract](../acceptance.md)
- Read when: selecting fixture, build, determinism, safety, dogfood, skill, CI, or completion obligations.
- Do not read when: the task does not implement or verify accepted behavior.
- Maximum size: 100 physical lines.


## Definition of Done map

**ACC-DOD-001.** Swift CLI, SwiftSyntax frontend, stable graph, deterministic JSON/JSONL, relative source provenance, and twenty-nine rules are present.

**ACC-DOD-002.** Fixtures distinguish direct Binding, manual Binding patterns, mirrors, transactions, derived state, tunnels, observable mirrors, and transformations.

**ACC-DOD-003.** Slice, snapshot, semantic diff, check, and doctor satisfy their contracts.

**ACC-DOD-004.** No rule relies solely on wrapper names; no LLM is required for deterministic scan/audit; an agent can work from JSON/slices without reading the whole codebase.

**ACC-DOD-005.** A refactor can be objectively accepted only when manual synchronization/targeted violations improve, no new high violation appears, ownership does not degrade, and behavior tests pass.

**ACC-DOD-006.** Public documentation, one routing skill, three specialist skills, deterministic dogfood baseline, and CI are complete while the release remains truthfully `unreleased`.

**ACC-DOD-007.** Tool version `0.2.0` baseline shipped ten rules and schema v1.

**ACC-DOD-008.** Tool version `0.3.0` ships schema v2, collision-safe indexed extraction, explicit configuration, twenty-nine rules, dominance, complete negative fixtures, updated skills, deterministic baselines, and hosted CI while remaining unreleased.

**ACC-DOD-009.** A compilable multi-file realistic corpus proves 34 exact findings across 24 rules, clean paired alternatives, forty-file distractor invariance, and syntax/indexed matrix parity without changing the twenty-nine-rule product contract.

**ACC-DOD-010.** Tool version `0.4.0` ships cache schema v1. All live-source commands reuse unchanged deterministic facts, conservatively invalidate dependencies, and remain byte-equivalent to an uncached rebuild without changing graph schema v2 or the agent-adjudication boundary.

**ACC-DOD-011.** `PARALLEL-EXECUTION-001` supplies positive `--jobs` control to every live-source command, uses one immutable audit context, preserves serial/parallel graph and report bytes, keeps order-dependent relationship resolution serial, and reuses one locked persistent IndexStoreDB database per cache/store/library identity without sharing a Swift database object concurrently.

**ACC-DOD-012.** `HOMEBREW-RELEASE-001` publishes stable tool `0.4.0` from one immutable Git tag and release archive, exposes `swiftui-audit --version`, and supplies a tested upstream Homebrew formula whose direct install preserves the standalone CLI contract without installing agent skills or mutating user configuration.
