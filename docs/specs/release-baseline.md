# Unreleased implementation baseline

Revision: `spec-4`
Baseline state: `unreleased`  
Contract epoch: `tz-v4`

**BASE-REL-001 — No public release claim.** This repository has an accepted PoC implementation and release-path workflows, but this document does not claim a tag, package distribution, website, Homebrew formula, plugin, or other public release.

**BASE-REL-002 — Implementation revision.** P6 began on branch `master` at Git commit `f24751cd25781426ec2c1531243e498534165e60`. Accepted P1–P5 implementation changes, including indexed enrichment, are present in the working tree at that revision. Generated P6 baseline manifests therefore record that Git revision while representing the accepted working tree.

**BASE-REL-003 — Boundary-analysis revision.** The `BOUNDARY-001` product implementation is commit `e81f10d4b06ae1c738b8302d579858854fc69a44`, present on `origin/master`. The regenerated RuleTests manifest records that exact product-source revision; the accompanying tests, baseline, documentation, and skill guidance are its acceptance evidence.

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

## Current contract surface

**BASE-CAP-001.** Public commands are `scan`, `audit`, `snapshot`, `slice`, `diff`, `check`, and `doctor`, with syntax/index flags documented in [`cli.md`](cli.md).

**BASE-CAP-002.** Graph/audit/snapshot/diff/check/slice schemas are version 1 and tool version `0.2.0`.

**BASE-CAP-003.** The canonical RuleTests dogfood baseline is syntax-only and contains exactly five files under `Tests/Baselines/RuleTests`.

**BASE-CAP-004.** Repeated fresh generation at one revision is byte-identical across all five files. Cross-commit comparison to the committed baseline is byte-exact for the four semantic files; only manifest `repositoryRevision` is normalized, with every other manifest field exact and the fresh revision required to equal `HEAD`.

**BASE-CAP-005.** Current syntax-only RuleTests baseline contains 353 nodes, 664 edges, and 20 findings. Its metrics are 34 Binding edges, 8 manual-synchronization edges, 40 mutable semantic values, 27 state representations, 5 duplicated sources of truth, 5 ownership violations, 2 derived mutable values, and 1 callback tunnel. Canonical file SHA-256 values are:

| File | SHA-256 |
| --- | --- |
| `nodes.jsonl` | `4a00a8e70eed5c0c6d2d9e72fc2283a1bf67e4b09e791ce3a6078bcc0b6d6570` |
| `edges.jsonl` | `4dc721f7860d4e8d4f621bc2d488d6190dc087290797a4477265cdc7c6fe741d` |
| `findings.jsonl` | `a93a58a986bd0ecd984f641f08eba17a3dc364cc41887b2c6578878c330aaca8` |
| `summary.json` | `8316abe13cc935051b7c5242e420bd27aa52c90238926f3dfa97ae2ae6541ff4` |
| `manifest.json` | `d6686f232cea63123ebe4f6bf2a23cf5dc686d5430fa2a8aefb3033fac0a273c` |

**BASE-CAP-006.** The current P1 extraction fixture contains 42 nodes and 77 edges (SHA-256 `57abbd33524890eb9544b420d47dd06013527ce12b1c2ad7b538dc3a19aa68db`). The one `BOUNDARY-001` addition is an explicit observable-member call edge required by broad-input analysis. Accepted lexical behavior preserves identity for an unshadowed nested `onChange` parameter capture, treats a same-name nested parameter as a shadow barrier, and represents transformed captures only through derivation.

**BASE-CAP-007.** Current syntax-only Sources dogfood produces 3,357 nodes and 6,608 edges (SHA-256 `187ee36e268135d58d9b9e9b4bcaed2cba9023957def77db2b06cfe7b6449b4a`). Its audit has zero findings and SHA-256 `27ef8b8adcde059e2add19a1b48150800b787267bd2d6cabcfba5812fe9ccb33`.

**BASE-CAP-008.** The accepted value-setter evidence repair leaves counts and metrics unchanged while retaining each matching event-trigger edge in its finding. `LabeledSetter` is `finding:871672afc5e64d2` with `edge:df78fa011860918b`; `ValueSetterPair` is `finding:c988942f3dcf8158` with `edge:fec6154e7fee5d1f`. This records current evidence completeness and does not add another rule.

**BASE-CAP-009.** The agent workflow surface contains one concise user-facing router, `swiftui-semantic`, and three specialist skills for audit, refactor, and change review. The router selects or sequences specialists without duplicating their workflow or weakening their gates.

**BASE-CAP-010.** All agent-facing semantic workflows require an explicit validated compiler Index Store and accept only indexed results. They do not recommend frontend-only analysis or automatic fallback. Change review requires compatible indexed snapshots; the CLI's build-free mode remains available outside the agent workflow and continues to support deterministic fixtures, baselines, and dogfood.

## Accepted residuals and limits

**BASE-LIM-001 — PoC extraction.** Syntax-only extraction remains intentionally bounded to the PoC vocabulary. A nested closure passed through an unregistered call can attach to an outer registered call, and receiver identity for same-named member calls is conservative. The frontend is not a full type checker, SIL pipeline, or full interprocedural/alias/control-flow analyzer.

**BASE-LIM-002 — Rebuild.** Full graph rebuild is accepted for the PoC; no incremental cache behavior is guaranteed.

**BASE-LIM-003 — Slice.** Token estimation is byte-based and graph depth is bounded.

**BASE-LIM-004 — Snapshot concurrency.** Snapshot replacement is safe for one writer but has no concurrent-writer lock.

**BASE-LIM-005 — Diff continuity.** Exact-qualified continuity is conservative and represents true renames as removal/addition.

**BASE-LIM-006 — Indexed mode.** Indexed enrichment is macOS-only, skips conservative same-line ambiguities, and auto-discovers only validated local `.build` stores. Explicit selection fails when coverage is absent; automatic mode falls back to syntax-only.

**BASE-LIM-007 — Deferred rules/features.** General typed component-role and ownership-mismatch inference remains adjudication guidance rather than a shipped rule; the new boundary candidates require explicit Binding/Observation topology. Automatic rewriting, embedded LLM APIs, GUI/IDE/Xcode extensions, broad Swift framework analysis, and SIL remain out of scope.

## Router acceptance evidence

**BASE-NEXT-001.** `ROUTER-001` acceptance evidence includes official validation of all four skills, an exact four-skill CI inventory, and fresh-context routing tests that select audit, refactor, review, and the mixed sequence correctly.

**BASE-NEXT-002.** Independent `ROUTER-R1` review accepted the concise routing, intact specialist gates, contract links, exact four-skill CI requirement, and unchanged Swift product and baseline semantics. The only accepted residual is the first hosted GitHub Actions run, pending because commit/push was not authorized.

**BASE-NEXT-003.** `INDEXED-SKILLS-001` acceptance requires zero frontend-only guidance under `skills/`, explicit index-store commands in every live-source specialist workflow, indexed-only handoffs and review snapshots, four-skill validation, YAML/link validation, and the CI regression guard.

**BASE-NEXT-004.** `BOUNDARY-001` is locally accepted with tool version `0.2.0`, schema version 1, ten exact rules, custom Binding construction topology, logical source-count fixtures, syntax-only and fresh explicit indexed evidence, a deterministic regenerated five-file RuleTests baseline, 69 passing tests, updated agent adjudication guidance, and passing audit/snapshot/diff/check/slice/doctor dogfood. The first hosted CI run containing this checkpoint remains a truthful external residual until GitHub Actions reports it.
