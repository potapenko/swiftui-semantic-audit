# Unreleased implementation baseline

Revision: `spec-6`
Baseline state: `unreleased`  
Contract epoch: `tz-v5`

**BASE-REL-001 — No public release claim.** This repository has an accepted PoC implementation and release-path workflows, but this document does not claim a tag, package distribution, website, Homebrew formula, plugin, or other public release.

**BASE-REL-002 — Implementation revision.** P6 began on branch `master` at Git commit `f24751cd25781426ec2c1531243e498534165e60`. Accepted P1–P5 implementation changes, including indexed enrichment, are present in the working tree at that revision. Generated P6 baseline manifests therefore record that Git revision while representing the accepted working tree.

**BASE-REL-003 — Boundary-analysis revision.** The `BOUNDARY-001` product implementation is commit `e81f10d4b06ae1c738b8302d579858854fc69a44`, present on `origin/master`. The regenerated RuleTests manifest records that exact product-source revision; the accompanying tests, baseline, documentation, and skill guidance are its acceptance evidence.

**BASE-REL-004 — Architecture-analysis revision.** The `ARCHITECTURE-001` implementation is product commit `2e9207fe1093995e7abd4880ca17745ee2b0b28b`, collision-scope restore commit `5d16cc3b9ef441be448b16554c9c4e662f573f4a`, bounded large-project index timeout commit `f02927a3ecb38eeee89ab23fd77f58c50c6560b7`, and indexed-enrichment topology optimization commit `91da0c92eb95812a642819634998772f66493a13`. The schema-v2 RuleTests manifest records the latter exact product-source revision; the subsequent baseline, CI, documentation, and skill checkpoint is its acceptance evidence.

**BASE-REL-005 — Realistic-fixtures revision.** `REALISTIC-FIXTURES-001` product/test commit `551158bccb7b1eabf87111fffaada78dddd8becc` is present on `origin/master`. It adds the compilable multi-file regression corpus and restores one-boundary/one-finding semantics plus receiver-specific indexed effect association without changing tool version, schema, rule count, or the canonical RuleTests semantic baseline.

## Dependency and platform baseline

**BASE-DEP-001.** Swift tools declaration: `6.2`; accepted build/test toolchain: Apple Swift `6.3.3`; package platform: macOS 13+.

**BASE-DEP-002.** Exact or locked dependencies:

| Dependency | Version/revision |
| --- | --- |
| SwiftSyntax | `603.0.2` / `79e4b74a295b6eb74a8b585e3a39d29e70c1dbd1` |
| swift-argument-parser | `1.8.2` / `6a52f3251125d74daf04fcbd5e6f08a75d074382` |
| IndexStoreDB | `003ac41513ba291f10ff1a0147ae68588914668d` |
| swift-lmdb (transitive) | branch `release/6.3`, revision `1ad9a2d80b6fcde498c2242f509bd1be7d667ff8` |

**BASE-DEP-003.** Indexed mode is macOS-only and requires the selected Swift/Xcode toolchain's `libIndexStore.dylib`. Syntax-only remains the portable product fallback within the package's macOS platform boundary.

## Accepted milestone evidence

**BASE-MILESTONE-001.** Accepted realization:

| Milestone | Capability | Accepted evidence before P6 |
| --- | --- | --- |
| P1 | SwiftSyntax graph and `scan` | 6 tests; deterministic 41-node/67-edge fixture graph |
| P2 | normalization, six rules, `audit` | 18 tests; mandatory A–H and perturbations |
| P3 | five-file snapshot and bounded slice | 29 tests; deterministic store, safe replacement, fixed-point budgets |
| P4 | semantic diff, check policy, doctor | 47 tests; per-cluster counts, resolution-safe loading, structured doctor |
| P5 | real IndexStoreDB enrichment | 53 tests; compiler USRs/read/write/call relations, mixed-mode guard, canonical use-site merge |
| P6 | specialist skills, self-contained specs, baseline, dogfood, CI | accepted: three specialist skills; 64 tests; source scan 3,134 nodes/6,150 edges and audit 0 findings; RuleTests baseline 268 nodes/521 edges/14 findings |
| P7 | requirement-by-requirement completion | accepted with compatible PoC residuals across all 54 source sections |
| P8 | single skill entry point | accepted: `swiftui-semantic` routes to three accepted specialist workflows; four-skill validation, four fresh-context routing scenarios, and independent review pass |
| P9 | boundary analysis and logical roots | accepted: tool 0.2.0/schema v1; ten rules; explicit custom Binding topology; 69 tests including fresh indexed enrichment; deterministic 353/664/20 RuleTests baseline; full CLI dogfood pass |
| P10 | architecture analysis | accepted: tool 0.3.0/schema v2; collision-safe identities; exact configuration; 29 rules; 77 tests; deterministic 353/713/20 RuleTests baseline; configured positive/negative and indexed evidence; full local CLI dogfood; hosted CI pass |
| P11 | realistic architecture regression corpus | accepted: 81 tests; 34 exact findings across 24 rules; paired clean alternatives; forty-file distractor invariance; two fresh byte-identical indexed enrichments; syntax/indexed rule-file parity; CLI/CI coverage |

## Current contract surface

**BASE-CAP-001.** Public commands are `scan`, `audit`, `snapshot`, `slice`, `diff`, `check`, and `doctor`, with syntax/index flags documented in [`cli.md`](cli.md).

**BASE-CAP-002.** Graph/audit/snapshot/diff/check/slice schemas are version 2 and tool version `0.3.0`. Reports and snapshot manifests carry the canonical analysis-configuration digest or `none`.

**BASE-CAP-003.** The canonical RuleTests dogfood baseline is syntax-only and contains exactly five files under `Tests/Baselines/RuleTests`.

**BASE-CAP-004.** Repeated fresh generation at one revision is byte-identical across all five files. Cross-commit comparison to the committed baseline is byte-exact for the four semantic files; only manifest `repositoryRevision` is normalized, with every other manifest field exact and the fresh revision required to equal `HEAD`.

**BASE-CAP-005.** Current syntax-only RuleTests baseline contains 353 nodes, 713 edges, and 20 findings. Its metrics are 34 Binding edges, 8 manual-synchronization edges, 40 mutable semantic values, 27 state representations, 5 duplicated sources of truth, 5 ownership violations, 2 derived mutable values, and 1 callback tunnel. Canonical file SHA-256 values are:

| File | SHA-256 |
| --- | --- |
| `nodes.jsonl` | `bbe26842938f90384520929f9c56f64f12bf816b8eae9fb6035bac7b1fddd4c3` |
| `edges.jsonl` | `e1ba91905742c9a088790b35e18a46ae5a566254af7728484738ed8ad13a6bf2` |
| `findings.jsonl` | `9d9305389503bffcaa70651fa233ebb372ef0d4f7edd2bf1901c353a0391c7b3` |
| `summary.json` | `b37146210fbf1a690985d89c2f617ef892727d8f4597087abaed1739dbc15177` |
| `manifest.json` | `3a9a21e28c10f0681a9d9e72b673022919d2c7ceab51f2200f8192327d51b27f` |

**BASE-CAP-006.** The current P1 extraction fixture contains 42 nodes and 83 edges (SHA-256 `ae2f86326085816ee62f9d3fcf8a1531f007df80d2f60a895d2a9f1ea7241ceb`). Schema v2 adds bounded typed/value-flow facts while preserving accepted lexical behavior: identity for an unshadowed nested `onChange` parameter capture, a same-name nested parameter as a shadow barrier, and derivation for transformed captures.

**BASE-CAP-007.** Current syntax-only Sources dogfood produces 4,010 nodes and 10,320 edges (SHA-256 `993d138b78d2cfa73d9bc75b4d4cabea1789e895ebe58cd3dc3d937d7f6c86fe`). Its audit has zero findings and SHA-256 `5cd4100a19a799e7210ae5d28bfada1a9f5f87fc577212fde85a069379e25940`.

**BASE-CAP-008.** The accepted value-setter evidence repair leaves counts and metrics unchanged while retaining each matching event-trigger edge in its finding. `LabeledSetter` is `finding:871672afc5e64d2` with `edge:df78fa011860918b`; `ValueSetterPair` is `finding:c988942f3dcf8158` with `edge:fec6154e7fee5d1f`. This records current evidence completeness and does not add another rule.

**BASE-CAP-009.** The agent workflow surface contains one concise user-facing router, `swiftui-semantic`, and three specialist skills for audit, refactor, and change review. The router selects or sequences specialists without duplicating their workflow or weakening their gates.

**BASE-CAP-010.** All agent-facing semantic workflows require an explicit validated compiler Index Store and accept only indexed results. They do not recommend frontend-only analysis or automatic fallback. Change review requires compatible indexed snapshots; the CLI's build-free mode remains available outside the agent workflow and continues to support deterministic fixtures, baselines, and dogfood.

**BASE-CAP-011.** The configured architecture fixture emits all nineteen new rule identifiers across 25 findings with digest `99b15b05460746f3931ce87b3f44a6da374ae6f8b4b332562432070e69ada3b9`; the configured negative fixture emits none of those identifiers. Finding dominance removes overlapping generic paths.

**BASE-CAP-012.** `Tests/Fixtures/RealProjectPatterns` is a compilable configured SwiftUI corpus with bad/good pairs in twelve source files. Syntax-only and explicit indexed audits each emit the same 34-entry per-rule/per-file matrix spanning 24 rules, and no finding evidence points into `Good/`. The accepted repeated indexed audit SHA-256 is `bb03a5d3418a244fe66d8d7a3304a9e82b95dbd71daaf44e8c119466c123a96a`.

## Accepted residuals and limits

**BASE-LIM-001 — PoC extraction.** Syntax-only extraction remains intentionally bounded to the PoC vocabulary. A nested closure passed through an unregistered call can attach to an outer registered call, and receiver identity for same-named member calls is conservative. The frontend is not a full type checker, SIL pipeline, or full interprocedural/alias/control-flow analyzer.

**BASE-LIM-002 — Rebuild.** Full graph rebuild is accepted for the PoC; no incremental cache behavior is guaranteed.

**BASE-LIM-003 — Slice.** Token estimation is byte-based and graph depth is bounded.

**BASE-LIM-004 — Snapshot concurrency.** Snapshot replacement is safe for one writer but has no concurrent-writer lock.

**BASE-LIM-005 — Diff continuity.** Exact-qualified continuity is conservative and represents true renames as removal/addition.

**BASE-LIM-006 — Indexed mode.** Indexed enrichment is macOS-only, skips conservative same-line ambiguities, and auto-discovers only validated local `.build` stores. Explicit selection fails when coverage is absent; automatic mode falls back to syntax-only.

**BASE-LIM-007 — Bounded architecture analysis.** Role- and feature-aware conclusions require exact validated configuration and remain silent without it. Syntax extraction is not a full type checker or general control-flow/effect engine; architecture rules cover only their documented SwiftUI, lifecycle, geometry, representable, and platform-command topology. Automatic rewriting, embedded LLM APIs, GUI/IDE/Xcode extensions, broad Swift framework analysis, and SIL remain out of scope.

**BASE-LIM-008 — Behavioral value freshness.** Collection-window exhaustion, stale captured values in already mounted Views, pagination progression, and similar runtime/control-flow defects are not inferred by the current twenty-nine rules. They require behavior tests or a separately authorized rule/IR evolution and must not be reported as architecture findings without deterministic topology.

## Router acceptance evidence

**BASE-NEXT-001.** `ROUTER-001` acceptance evidence includes official validation of all four skills, an exact four-skill CI inventory, and fresh-context routing tests that select audit, refactor, review, and the mixed sequence correctly.

**BASE-NEXT-002.** Independent `ROUTER-R1` review accepted the concise routing, intact specialist gates, contract links, exact four-skill CI requirement, and unchanged Swift product and baseline semantics. The only accepted residual is the first hosted GitHub Actions run, pending because commit/push was not authorized.

**BASE-NEXT-003.** `INDEXED-SKILLS-001` acceptance requires zero frontend-only guidance under `skills/`, explicit index-store commands in every live-source specialist workflow, indexed-only handoffs and review snapshots, four-skill validation, YAML/link validation, and the CI regression guard.

**BASE-NEXT-004.** `BOUNDARY-001` is locally accepted with tool version `0.2.0`, schema version 1, ten exact rules, custom Binding construction topology, logical source-count fixtures, syntax-only and fresh explicit indexed evidence, a deterministic regenerated five-file RuleTests baseline, 69 passing tests, updated agent adjudication guidance, and passing audit/snapshot/diff/check/slice/doctor dogfood. Hosted CI on the integrated P9 checkpoint is required external release evidence and its terminal result is reported in the checkpoint handoff.

**BASE-NEXT-005.** `ARCHITECTURE-001` acceptance evidence includes 77 passing tests, locked build, fresh explicit IndexStoreDB identity/configuration coverage, byte-identical schema-v2 snapshots, empty same-input diff, passing high-severity check, bounded slice, healthy doctor, zero Sources findings, all nineteen configured positive rules, zero configured negative rules, and four validated skills. Integration checkpoint `1821b72de6d75a48a2a2b672a191e408c324bd02` is present on `origin/master`; hosted GitHub Actions run `32130756118` passed every CI step in 4m06s.

**BASE-NEXT-006.** `REALISTIC-FIXTURES-001` acceptance evidence includes locked build, 81 passing tests, a 34-finding syntax audit, two byte-identical 34-finding indexed audits, exact syntax/indexed rule-file parity, forty clean distractors with unchanged findings, 25/0 legacy architecture positive/negative findings, zero Sources findings, exact canonical RuleTests semantic files, revision-only manifest normalization, valid CI YAML, and clean diff checks. Acceptance commit `ec369e8e93989d0c8fb71370c592e9b1e07c6035` is present on `origin/master`; hosted GitHub Actions run `32138078906` passed every CI step in 6m36s.
