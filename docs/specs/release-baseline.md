# Release and publication baseline

- Node type: hybrid
- Status: Active
- Contract revision: `spec-12`
- Read when: checking the current 0.4.0 release, dependencies, milestones, capabilities, residuals, or acceptance evidence.
- Do not read when: the task concerns intended behavior without realization or release evidence.
- Maximum size: 100 physical lines.

Revision: `spec-12`
Baseline state: `0.4.0 released; website canonical domain released`
Contract epoch: `tz-v8`
Website contract epoch: `tz-v11`

**BASE-REL-001 — Publication state.** Tool `0.4.0` is the first public release. It is distributed from one immutable Git tag and GitHub Release through the tested upstream tap formula; the terminal receipt pins every external artifact.

**BASE-REL-002 — Implementation revision.** P6 began on branch `master` at Git commit `f24751cd25781426ec2c1531243e498534165e60`. Accepted P1–P5 implementation changes, including indexed enrichment, are present in the working tree at that revision. Generated P6 baseline manifests therefore record that Git revision while representing the accepted working tree.

**BASE-REL-003 — Boundary-analysis revision.** The `BOUNDARY-001` product implementation is commit `e81f10d4b06ae1c738b8302d579858854fc69a44`, present on `origin/master`. The regenerated RuleTests manifest records that exact product-source revision; the accompanying tests, baseline, documentation, and skill guidance are its acceptance evidence.

**BASE-REL-004 — Architecture-analysis revision.** The `ARCHITECTURE-001` implementation is product commit `2e9207fe1093995e7abd4880ca17745ee2b0b28b`, collision-scope restore commit `5d16cc3b9ef441be448b16554c9c4e662f573f4a`, bounded large-project index timeout commit `f02927a3ecb38eeee89ab23fd77f58c50c6560b7`, and indexed-enrichment topology optimization commit `91da0c92eb95812a642819634998772f66493a13`. The schema-v2 RuleTests manifest records the latter exact product-source revision; the subsequent baseline, CI, documentation, and skill checkpoint is its acceptance evidence.

**BASE-REL-005 — Realistic-fixtures revision.** `REALISTIC-FIXTURES-001` product/test commit `551158bccb7b1eabf87111fffaada78dddd8becc` is present on `origin/master`. It adds the compilable multi-file regression corpus and restores one-boundary/one-finding semantics plus receiver-specific indexed effect association without changing tool version, schema, rule count, or the canonical RuleTests semantic baseline.

**BASE-REL-006 — Incremental-cache revision.** `INCREMENTAL-CACHE-001` product commit `38146ff9736ef942ed066bab46337cfa880c2626` implements tool `0.4.0` with cache schema v1 while preserving graph schema v2. The canonical RuleTests manifest records that product-source revision. Acceptance checkpoint `84e6fb7859d62cd1a468b3f8c8560544f9d458a8` is present on `origin/master`, and hosted CI run `32239872792` passed.

**BASE-REL-007 — Parallel-execution revision.** The performance implementation chain is observable-tunnel optimization `fe6fd699e8f56ae11a48a71dd4ac540e4936d29b`, frontend concurrency checkpoint `360077ff0d7e1dd62351c09bd5e55d1cfb8d883e`, deterministic job-control/shared-rule-context checkpoint `1a1459a2623f88865694dbd858612f8972734bb1`, and persistent locked IndexStoreDB reuse checkpoint `06ede8eb503709e13d3c2738e7b68eab9a9d1bc1`. All are present on `origin/master`; local acceptance is terminal and hosted CI run `32259485471` passed on the 0.4.0 release candidate.

**BASE-REL-008 — Homebrew release authorization.** User-authorized `HOMEBREW-RELEASE-001` on 2026-08-19 advances the combined contract to `tz-v8`. The release owns version output, immutable tag/archive publication, the external upstream tap formula, direct install verification, and truthful release documentation; it does not change graph schema v2, cache schema v1, twenty-nine rules, command semantics, or agent-skill installation. The post-publication checkpoint records exact tag, archive, tap, and clean-install evidence without changing release semantics.

**BASE-REL-009 — 0.4.0 publication receipt.** Immutable tag `0.4.0` targets commit `189dc44c928f7f61b393f6e4ca7d8f6f5d183a48`; upstream CI run [`32260347511`](https://github.com/potapenko/swiftui-semantic-audit/actions/runs/32260347511) passed on that commit. The public [GitHub Release](https://github.com/potapenko/swiftui-semantic-audit/releases/tag/0.4.0) asset `swiftui-semantic-audit-0.4.0.tar.gz` has SHA-256 `e314379b9cf67f1d5d6ccf3e8b9dce9b10d4a619c6af9eff4d39af0f4a8f08d3`. Tap formula commit `73895365dbd6bea905fc11a6fda2496f3126c620` and bounded-automation head `7979f7f7a1e4c71a2acf92d984926ec63e64c5c5` are public in [`potapenko/homebrew-tap`](https://github.com/potapenko/homebrew-tap). Clean [`macos-26` arm64 run `32261229672`](https://github.com/potapenko/homebrew-tap/actions/runs/32261229672) built from source, passed the functional `brew test`, and verified version `0.4.0`; macOS and Linux tap-syntax jobs also passed. The direct command is `brew install potapenko/tap/swiftui-semantic-audit`. No bottles are claimed for 0.4.0: installation builds the locked package from source and requires Xcode 26.6.

**BASE-WEB-001 — Initial website deployment receipt.** On 2026-08-19,
DigitalOcean app `ed5742fe-8bca-444f-a55b-abb8d005ff55` reached ACTIVE deployment
`df56a626-d87a-4be5-804f-2e93419c975a` from source commit
`a47364f868ac047dfb4eabb1898960bf3eb3a7df`. Its technical ingress is
`https://swiftui-semantic-audit-nuhky.ondigitalocean.app/`; the active spec pins
one `master` static site with `deploy_on_push: true`. Public A/AAAA records,
managed TLS, root marker and English document, canonical/Open Graph metadata,
`robots.txt`, `sitemap.xml`, and the expected 404 response passed. The canonical
At that checkpoint, the `swiftui-audit.dev` cutover remained pending because
authoritative registration and delegation did not yet exist; no domain-ready
claim was accepted.

**BASE-WEB-002 — Canonical domain publication receipt.** On 2026-08-19,
deployment `dfcf358f-551b-453d-808b-aad44ab9281f` reached ACTIVE from source
commit `93f6e1a0c68df37f373b4150e2639075d7e4a699`. App Platform reports both
`swiftui-audit.dev` PRIMARY and `www.swiftui-audit.dev` ALIAS as ACTIVE, with
managed certificates expiring on 2026-11-17. The authoritative OnlyDomains zone
publishes apex A records `162.159.140.98` and `172.66.0.96`, while `www` is a
CNAME to the technical ingress. Fresh public resolvers returned the new zone;
resolvers that had already cached the registrar parking address may retain it
for the original 86400-second TTL during normal propagation. Direct SNI/TLS
acceptance passed for apex content and the `www` certificate: root 200, exact
commit marker, canonical/Open Graph metadata, `robots.txt`, `sitemap.xml`, 404,
and a path-preserving permanent `www`-to-apex redirect.

**BASE-WEB-003 — Author-link publication receipt.** On 2026-08-19, push-triggered
deployment `1e83c8f4-dd3e-4490-9c70-6cf6036d91f2` reached ACTIVE from source
commit `7e391609733fa8df318844020435d49bb6efec80`. The canonical root returned that
exact build marker and the accessible `https://x.com/potapenko` header link;
its local Twitter icon, apex HTTPS, `robots.txt`, `sitemap.xml`, and the
path-preserving permanent `www` redirect passed public verification.

## Choose the baseline child

- [Platform, Dependencies, and Milestones](release-baseline/platform-and-milestones.md) — toolchain/dependency pins and accepted P1–P13 capability evidence.
- [Current Contract Surface and Residuals](release-baseline/contract-surface-and-residuals.md) — current commands, schemas, hashes, capabilities, and accepted limitations.
- [Addendum Acceptance Evidence](release-baseline/router-evidence.md) — terminal evidence for router, indexed skills, boundary, architecture, realistic fixtures, cache, and parallel-execution addenda.
