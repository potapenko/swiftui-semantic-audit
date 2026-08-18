# Unreleased implementation baseline

Revision: `spec-4`
Baseline state: `unreleased`  
Contract epoch: `tz-v4`

**BASE-REL-001 — No public release claim.** This repository has an accepted PoC implementation and release-path workflows, but this document does not claim a tag, package distribution, website, Homebrew formula, plugin, or other public release.

**BASE-REL-002 — Implementation revision.** P6 began on branch `master` at Git commit `f24751cd25781426ec2c1531243e498534165e60`. Accepted P1–P5 implementation changes, including indexed enrichment, are present in the working tree at that revision. Generated P6 baseline manifests therefore record that Git revision while representing the accepted working tree.

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

## Current contract surface

**BASE-CAP-001.** Public commands are `scan`, `audit`, `snapshot`, `slice`, `diff`, `check`, and `doctor`, with syntax/index flags documented in [`cli.md`](cli.md).

**BASE-CAP-002.** Graph/audit/snapshot/diff/check/slice schemas are version 1 and tool version `0.1.0`.

**BASE-CAP-003.** The canonical RuleTests dogfood baseline is syntax-only and contains exactly five files under `Tests/Baselines/RuleTests`.

**BASE-CAP-004.** Repeated fresh generation at one revision is byte-identical across all five files. Cross-commit comparison to the committed baseline is byte-exact for the four semantic files; only manifest `repositoryRevision` is normalized, with every other manifest field exact and the fresh revision required to equal `HEAD`.

**BASE-CAP-005.** Current syntax-only RuleTests metrics are 24 Binding edges, 8 manual-synchronization edges, 27 mutable semantic values, 24 state representations, 5 duplicated sources of truth, 5 ownership violations, 2 derived mutable values, and 1 callback tunnel. Canonical file SHA-256 values are:

| File | SHA-256 |
| --- | --- |
| `nodes.jsonl` | `674c06120f63e80670e08e52ea773fb1beffbaed2a9bc5bc2c75f9c625ccacb4` |
| `edges.jsonl` | `7faa95f50820dcc027ca901adf5c845601993ce4070190f632652c16a50956ca` |
| `findings.jsonl` | `165a0fbd39039507f32f4fce62467abbaa10ff93caaad82df2bb54b6ef4cc4f3` |
| `summary.json` | `9166050912784d9fadbd591807356477ec97f68c083d56d0148f57b5488ab137` |
| `manifest.json` | `cbfb133ed92333249d5dbd70b018249e4f59ab606ab9859de7e7ee051417efcc` |

**BASE-CAP-006.** The current P1 extraction fixture contains 42 nodes and 76 edges (SHA-256 `92935530c0ad54cbd9a17b955b852c97fbfcb9edbc9004a3d7b56f96e7b9c1ca`) after authorized additive closure-parameter facts. Accepted lexical behavior preserves identity for an unshadowed nested `onChange` parameter capture, treats a same-name nested parameter as a shadow barrier, and represents transformed captures only through derivation.

**BASE-CAP-007.** Current syntax-only Sources dogfood produces 3,134 nodes and 6,150 edges (SHA-256 `ff269945a8ca7b31b4c1be6dc19c8ab9a1b8aea305ddc3a0cdef8d15d3e4b907`). Its audit has zero findings and SHA-256 `e03c13cc1f464e7cdf9836ebd08e96ce197975e4480852248fc9d7d8b4ac9704`.

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

**BASE-LIM-007 — Deferred rules/features.** Suspicious Binding setter and general ownership-mismatch concepts remain adjudication guidance rather than additional shipped PoC rules. Automatic rewriting, embedded LLM APIs, GUI/IDE/Xcode extensions, broad Swift framework analysis, and SIL remain out of scope.

## Router acceptance evidence

**BASE-NEXT-001.** `ROUTER-001` acceptance evidence includes official validation of all four skills, an exact four-skill CI inventory, and fresh-context routing tests that select audit, refactor, review, and the mixed sequence correctly.

**BASE-NEXT-002.** Independent `ROUTER-R1` review accepted the concise routing, intact specialist gates, contract links, exact four-skill CI requirement, and unchanged Swift product and baseline semantics. The only accepted residual is the first hosted GitHub Actions run, pending because commit/push was not authorized.

**BASE-NEXT-003.** `INDEXED-SKILLS-001` acceptance requires zero frontend-only guidance under `skills/`, explicit index-store commands in every live-source specialist workflow, indexed-only handoffs and review snapshots, four-skill validation, YAML/link validation, and the CI regression guard.

**BASE-NEXT-004.** `BOUNDARY-001` acceptance requires tool version `0.2.0`, schema version 1, ten exact rules, custom Binding construction topology, logical source-count fixtures, syntax-only and fresh explicit indexed evidence, a regenerated five-file RuleTests baseline, and updated agent adjudication guidance. Final counts and hashes replace this planning clause only after verification.
