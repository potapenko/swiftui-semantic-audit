# Current Contract Surface and Residuals

- Node type: leaf
- Status: Active
- Contract revision: `spec-10`
- Authority: [Unreleased implementation baseline](../release-baseline.md)
- Read when: checking realized behavior, canonical evidence hashes, or accepted product limits.
- Do not read when: only dependency history, milestones, or addendum acceptance evidence is needed.
- Maximum size: 100 physical lines.

## Current contract surface

**BASE-CAP-001.** Public commands are `scan`, `audit`, `snapshot`, `slice`, `diff`, `check`, and `doctor`, with syntax/index flags documented in [`cli.md`](../cli.md).

**BASE-CAP-002.** Graph/audit/snapshot/diff/check/slice schemas are version 2, the development tool version is `0.5.0`, and the non-authoritative analysis-cache schema is version 1. Public release 0.4.0 remains immutable. Reports and snapshot manifests carry the canonical analysis-configuration digest or `none`.

**BASE-CAP-003.** The canonical RuleTests dogfood baseline is syntax-only and contains exactly five files under `Tests/Baselines/RuleTests`.

**BASE-CAP-004.** Repeated fresh generation at one revision is byte-identical across all five files. Cross-commit comparison to the committed baseline is byte-exact for the four semantic files; only manifest `repositoryRevision` is normalized, with every other manifest field exact and the fresh revision required to equal `HEAD`.

**BASE-CAP-005.** Current syntax-only RuleTests baseline contains 353 nodes, 713 edges, and 20 findings. Its metrics are 34 Binding edges, 8 manual-synchronization edges, 40 mutable semantic values, 27 state representations, 5 duplicated sources of truth, 5 ownership violations, 2 derived mutable values, and 1 callback tunnel. Canonical file SHA-256 values are:

| File | SHA-256 |
| --- | --- |
| `nodes.jsonl` | `bbe26842938f90384520929f9c56f64f12bf816b8eae9fb6035bac7b1fddd4c3` |
| `edges.jsonl` | `e1ba91905742c9a088790b35e18a46ae5a566254af7728484738ed8ad13a6bf2` |
| `findings.jsonl` | `9d9305389503bffcaa70651fa233ebb372ef0d4f7edd2bf1901c353a0391c7b3` |
| `summary.json` | `b37146210fbf1a690985d89c2f617ef892727d8f4597087abaed1739dbc15177` |
| `manifest.json` | `6a86aa95fc236f9290757a087878dbb5e45a3c8a0658d255a2ac8cc46f76bb3b` |

**BASE-CAP-006.** The current P1 extraction fixture contains 42 nodes and 83 edges (SHA-256 `ae2f86326085816ee62f9d3fcf8a1531f007df80d2f60a895d2a9f1ea7241ceb`). Schema v2 adds bounded typed/value-flow facts while preserving accepted lexical behavior: identity for an unshadowed nested `onChange` parameter capture, a same-name nested parameter as a shadow barrier, and derivation for transformed captures.

**BASE-CAP-007.** Current syntax-only Sources dogfood produces 4,470 nodes and 11,674 edges (SHA-256 `4f6ebc0ec9e18a5f102bde459bf02a7b5cf7691f45c12b8811f485ccda22c03e`). Its audit has zero findings and SHA-256 `2a43115910dfa518a16d8f28eedd0d098c416fdc4669eaca50fe499ccce36300`.

**BASE-CAP-008.** The accepted value-setter evidence repair leaves counts and metrics unchanged while retaining each matching event-trigger edge in its finding. `LabeledSetter` is `finding:871672afc5e64d2` with `edge:df78fa011860918b`; `ValueSetterPair` is `finding:c988942f3dcf8158` with `edge:fec6154e7fee5d1f`. This records current evidence completeness and does not add another rule.

**BASE-CAP-009.** The agent workflow surface contains one concise user-facing router, `swiftui-semantic`, and three specialist skills for audit, refactor, and change review. The router selects or sequences specialists without duplicating their workflow or weakening their gates.

**BASE-CAP-010.** All agent-facing semantic workflows require an explicit validated compiler Index Store and accept only indexed results. They do not recommend frontend-only analysis or automatic fallback. Change review requires compatible indexed snapshots; the CLI's build-free mode remains available outside the agent workflow and continues to support deterministic fixtures, baselines, and dogfood.

**BASE-CAP-011.** The configured architecture fixture emits all nineteen new rule identifiers across 25 findings with digest `99b15b05460746f3931ce87b3f44a6da374ae6f8b4b332562432070e69ada3b9`; the configured negative fixture emits none of those identifiers. Finding dominance removes overlapping generic paths.

**BASE-CAP-012.** `Tests/Fixtures/RealProjectPatterns` is a compilable configured SwiftUI corpus with bad/good pairs in twelve source files. Syntax-only and explicit indexed audits each emit the same 34-entry per-rule/per-file matrix spanning 24 rules, and no finding evidence points into `Good/`. The accepted repeated indexed audit SHA-256 is `bb03a5d3418a244fe66d8d7a3304a9e82b95dbd71daaf44e8c119466c123a96a`.

**BASE-CAP-013.** Live-source commands persist integrity-checked frontend state and content-addressed indexed facts outside semantic snapshots. An exact warm frontend pass reparses zero files; add/delete/rename and declaration-bearing edits conservatively invalidate affected lexical dependents. Indexed facts include relative source path, source content, graph/tool/cache versions, compiler-unit digests, and the selected index-library identity. Every invocation still normalizes the complete current graph and evaluates all thirty rules.

**BASE-CAP-014.** Live-source commands accept positive `--jobs`; omission uses active processors and `1` is serial. Eligible declaration phases and all contextual rules use bounded workers over immutable inputs; all built-in rules share one graph index. On the accepted host, uncached Release Sources audit improved from 1.43s before this audit to 0.57s, with serial/12-job graph and report bytes exact. Indexed whole-result miss with an existing database improved from a 4.24s cold initialization to 2.22s; the following whole-result hit was 0.77s. Reused-database and uncached indexed reports matched at SHA-256 `1380ea9cca5deb609dd520056d5347834c4166e532941b2966223c2d976c9594`.

**BASE-CAP-015.** Release 0.4.0 exposes `swiftui-audit --version` from the same `ToolMetadata.version` used by reports and snapshots. The Homebrew package name is `swiftui-semantic-audit`; it installs the unchanged executable name `swiftui-audit` and leaves all agent-skill locations operator-owned.

**BASE-CAP-016.** Config schema 2 adds exact View roles and `component-model`; schema 1 remains accepted. The thirtieth reusable-owner candidate is configuration-only, uses existing graph roles, and preserves the realistic corpus total through finding dominance.

## Accepted residuals and limits

**BASE-LIM-001 — PoC extraction.** Syntax-only extraction remains intentionally bounded to the PoC vocabulary. A nested closure passed through an unregistered call can attach to an outer registered call, and receiver identity for same-named member calls is conservative. The frontend is not a full type checker, SIL pipeline, or full interprocedural/alias/control-flow analyzer.

**BASE-LIM-002 — Conservative invalidation.** Live analysis still reads source bytes to establish content identity, and declaration-bearing edits may conservatively reparse unchanged lexical dependents. Normalization and all rules intentionally rerun over the complete current graph. The cache has no automatic garbage-collection policy in this PoC.

**BASE-LIM-003 — Slice.** Token estimation is byte-based and graph depth is bounded.

**BASE-LIM-004 — Snapshot concurrency.** Snapshot replacement is safe for one writer but has no concurrent-writer lock.

**BASE-LIM-005 — Diff continuity.** Exact-qualified continuity is conservative and represents true renames as removal/addition.

**BASE-LIM-006 — Indexed mode.** Indexed enrichment is macOS-only, skips conservative same-line ambiguities, and auto-discovers only validated local `.build` stores. Explicit selection fails when coverage is absent; automatic mode falls back to syntax-only.

**BASE-LIM-007 — Bounded architecture analysis.** Role- and feature-aware conclusions require exact validated configuration and remain silent without it. Syntax extraction is not a full type checker or general control-flow/effect engine; architecture rules cover only their documented SwiftUI, lifecycle, geometry, representable, and platform-command topology. Automatic rewriting, embedded LLM APIs, GUI/IDE/Xcode extensions, broad Swift framework analysis, and SIL remain out of scope.

**BASE-LIM-008 — Behavioral value freshness.** Collection-window exhaustion, stale captured values in already mounted Views, pagination progression, and similar runtime/control-flow defects are not inferred by the current thirty rules. They require behavior tests or a separately authorized rule/IR evolution and must not be reported as architecture findings without deterministic topology.

**BASE-LIM-010 — Component multiplicity.** Exact roles establish a candidate boundary, not runtime aliasing or instance multiplicity. Full interprocedural `ForEach` lifetime and alias analysis remains out of scope; the agent adjudicates instance count and lifetime from the bounded slice and source evidence.

**BASE-LIM-009 — Parallelism ceiling.** Relationship extraction remains serial because it observes generated nodes in sorted file order; a lock-only parallel pass changed graph bytes and was rejected. Full scaling requires a two-phase immutable fact/merge frontend. IndexStoreDB's Swift object is not shared concurrently, and upstream unit import remains library-serialized; the tool instead reuses one persistent database behind a bounded interprocess lock. Therefore `--jobs` improves eligible work but does not promise linear all-core utilization for every project or stage.
