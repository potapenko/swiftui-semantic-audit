# Unreleased implementation baseline

- Node type: hybrid
- Status: Active
- Contract revision: `spec-8`
- Read when: checking current unreleased realization, dependencies, milestones, capabilities, residuals, or acceptance evidence.
- Do not read when: the task concerns intended behavior without realization or release evidence.
- Maximum size: 100 physical lines.

Revision: `spec-8`
Baseline state: `unreleased`  
Contract epoch: `tz-v7`

**BASE-REL-001 — No public release claim.** This repository has an accepted PoC implementation and release-path workflows, but this document does not claim a tag, package distribution, website, Homebrew formula, plugin, or other public release.

**BASE-REL-002 — Implementation revision.** P6 began on branch `master` at Git commit `f24751cd25781426ec2c1531243e498534165e60`. Accepted P1–P5 implementation changes, including indexed enrichment, are present in the working tree at that revision. Generated P6 baseline manifests therefore record that Git revision while representing the accepted working tree.

**BASE-REL-003 — Boundary-analysis revision.** The `BOUNDARY-001` product implementation is commit `e81f10d4b06ae1c738b8302d579858854fc69a44`, present on `origin/master`. The regenerated RuleTests manifest records that exact product-source revision; the accompanying tests, baseline, documentation, and skill guidance are its acceptance evidence.

**BASE-REL-004 — Architecture-analysis revision.** The `ARCHITECTURE-001` implementation is product commit `2e9207fe1093995e7abd4880ca17745ee2b0b28b`, collision-scope restore commit `5d16cc3b9ef441be448b16554c9c4e662f573f4a`, bounded large-project index timeout commit `f02927a3ecb38eeee89ab23fd77f58c50c6560b7`, and indexed-enrichment topology optimization commit `91da0c92eb95812a642819634998772f66493a13`. The schema-v2 RuleTests manifest records the latter exact product-source revision; the subsequent baseline, CI, documentation, and skill checkpoint is its acceptance evidence.

**BASE-REL-005 — Realistic-fixtures revision.** `REALISTIC-FIXTURES-001` product/test commit `551158bccb7b1eabf87111fffaada78dddd8becc` is present on `origin/master`. It adds the compilable multi-file regression corpus and restores one-boundary/one-finding semantics plus receiver-specific indexed effect association without changing tool version, schema, rule count, or the canonical RuleTests semantic baseline.

**BASE-REL-006 — Incremental-cache revision.** `INCREMENTAL-CACHE-001` product commit `38146ff9736ef942ed066bab46337cfa880c2626` implements tool `0.4.0` with cache schema v1 while preserving graph schema v2. The canonical RuleTests manifest records that product-source revision. Acceptance checkpoint `84e6fb7859d62cd1a468b3f8c8560544f9d458a8` is present on `origin/master`, and hosted CI run `32239872792` passed.

**BASE-REL-007 — Parallel-execution revision.** The performance implementation chain is observable-tunnel optimization `fe6fd699e8f56ae11a48a71dd4ac540e4936d29b`, frontend concurrency checkpoint `360077ff0d7e1dd62351c09bd5e55d1cfb8d883e`, deterministic job-control/shared-rule-context checkpoint `1a1459a2623f88865694dbd858612f8972734bb1`, and persistent locked IndexStoreDB reuse checkpoint `06ede8eb503709e13d3c2738e7b68eab9a9d1bc1`. All are present on `origin/master`; local acceptance is terminal and hosted CI for this addendum remains pending.

## Choose the baseline child

- [Platform, Dependencies, and Milestones](release-baseline/platform-and-milestones.md) — toolchain/dependency pins and accepted P1–P13 capability evidence.
- [Current Contract Surface and Residuals](release-baseline/contract-surface-and-residuals.md) — current commands, schemas, hashes, capabilities, and accepted limitations.
- [Addendum Acceptance Evidence](release-baseline/router-evidence.md) — terminal evidence for router, indexed skills, boundary, architecture, realistic fixtures, cache, and parallel-execution addenda.
