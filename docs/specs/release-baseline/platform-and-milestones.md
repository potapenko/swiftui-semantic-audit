# Platform, Dependencies, and Milestones

- Node type: leaf
- Status: Active
- Contract revision: `spec-8`
- Authority: [Unreleased implementation baseline](../release-baseline.md)
- Read when: checking platform/dependency compatibility or accepted milestone history.
- Do not read when: only current capabilities, residuals, or addendum acceptance evidence is needed.
- Maximum size: 100 physical lines.

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
| P12 | incremental deterministic fact cache | locally accepted: tool 0.4.0/cache schema v1; 86 tests; exact frontend and indexed hit/invalidation coverage; cached/uncached byte equality; complete CLI dogfood; canonical RuleTests semantic files unchanged |
| P13 | deterministic parallel execution and indexed DB reuse | accepted: 88 tests; positive `--jobs`; serial/parallel byte equality; focused frontend/rule TSan; locked persistent IndexStoreDB reuse; Release syntax audit 1.43s → 0.57s from the pre-audit baseline; hosted CI run `32259485471` passed |
