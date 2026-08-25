# Definition of Done

- Node type: leaf
- Status: Active
- Contract revision: `spec-17`
- Authority: [Acceptance and QA contract](../acceptance.md)
- Read when: selecting fixture, build, determinism, safety, dogfood, skill, CI, or completion obligations.
- Do not read when: the task does not implement or verify accepted behavior.
- Maximum size: 100 physical lines.


## Definition of Done map

**ACC-DOD-001.** Swift CLI, SwiftSyntax frontend, stable graph, deterministic JSON/JSONL, relative source provenance, and thirty rules are present.

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

**ACC-DOD-013.** Released tool `0.5.0` accepts config schemas 1 and 2, ships thirty bounded rules, uses exact reusable/screen/container and component-model roles without name inference, emits the reusable-owner candidate with documented dominance/slices, preserves the 34-finding realistic total, and leaves release 0.4.0 immutable.

**ACC-DOD-014.** `RELEASE-0.5.0-001` publishes one immutable tag/archive, a tested upstream formula, the same four validated skills, and truthful 0.5.0 public/website facts without adding bottles, automatic skill installation, or new analysis behavior.

**ACC-DOD-015.** `ARTIFACT-HYGIENE-001` makes auxiliary agent evidence temporary by default, keeps required durable evidence outside repositories and installed packages with explicit retention, preserves canonical snapshot behavior, and prevents Codex configuration commits from collecting run output.

**ACC-DOD-016.** `PROJECT-WATCHER-001` supplies safe project setup, project manifest schema 1, one-writer foreground/background lifecycle, freshness-qualified indexed live snapshots, deliberate baseline promotion, router integration, runtime-state isolation, and compatibility with the seven existing analysis commands in released 0.6.0.

**ACC-DOD-017.** `RELEASE-0.6.0-001` is complete through `BASE-REL-015`: one immutable tag/archive, tag CI, a checksum-pinned source-built upstream formula, the same four validated separately installed tagged skills, local installation, and truthful public/website release facts have terminal receipts. It adds no bottles or automatic skill installation and preserves graph/config/cache/snapshot schemas, thirty rules and severities, semantics of the seven existing analysis commands, project manifest schema 1, and immutable 0.4.0/0.5.0 artifacts.

**ACC-DOD-018.** `RELEASE-0.6.1-001` is a complete local candidate only when the integrated watcher repair, exact 0.6.1 version/CI gates, compatible canonical baselines, router guidance, focused/full tests, Release build, executable help, indexed watcher dogfood, skill/docs validation, and protected website regressions are locally terminal. Hosted CI, tag/archive, upstream tap, website facts, and publication receipt remain explicitly nonterminal; installation and skill activation require separate authority.

**ACC-DOD-019.** `LOCAL-0.6.1-ACTIVATION-001` is complete only when a checksum-pinned archive of the accepted checkpoint builds and functionally tests as Homebrew keg 0.6.1, the active executable reports 0.6.1 and exposes candidate help, all four validated skills resolve to one clean commit-pinned candidate checkout, released 0.6.0 rollback assets remain, no external release or consumer state changes, and a local receipt is checkpointed.

**ACC-DOD-020.** `SKILL-NON-INTERFERENCE-001` is complete only when all four semantic skills are explicit-only in source and the active local bundle, descriptions and bodies exclude ordinary SwiftUI work from automatic routing, explicit invocations preserve every indexed/fact/artifact gate, repository validation passes, released bundles remain immutable, and the local activation receipt is checkpointed.
