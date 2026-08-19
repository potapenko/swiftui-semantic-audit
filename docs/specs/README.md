# Specification registry

- Node type: root
- Status: Active
- Contract revision: `spec-14`
- Authority: epoch `tz-v11` and pinned digest declared below
- Read when: starting any product, behavior, compatibility, QA, release, or specification task in this repository.
- Do not read when: the task is proven behavior-neutral and outside the specification system.
- Maximum size: 100 physical lines.

Status: active  
Contract epoch: `tz-v11`
Local specification revision: `spec-14`
Pinned authority digest: `sha256:68f8a43d924659024b7d29fabb9ad302817c271838a7919b24bd942626927cac`  
Router addendum: user-authorized `ROUTER-001` on 2026-08-18
Indexed-skills addendum: user-authorized `INDEXED-SKILLS-001` on 2026-08-18
Boundary-analysis addendum: user-authorized `BOUNDARY-001` on 2026-08-18
Architecture-analysis addendum: user-authorized `ARCHITECTURE-001` on 2026-08-18
Realistic-fixtures acceptance addendum: user-authorized `REALISTIC-FIXTURES-001` on 2026-08-18; product semantics remain at `tz-v5`
Incremental-cache addendum: user-authorized `INCREMENTAL-CACHE-001` on 2026-08-19; advances the combined contract to `tz-v6`
Parallel-execution addendum: user-authorized `PARALLEL-EXECUTION-001` on 2026-08-19; advances the combined contract to `tz-v7`
Homebrew release addendum: user-authorized `HOMEBREW-RELEASE-001` on 2026-08-19; advances the combined contract to `tz-v8`
Website addendum: user-authorized `WEBSITE-001` on 2026-08-19; advances the combined contract to `tz-v9`
Website publication addendum: user-authorized `WEBSITE-PUBLISH-001` on 2026-08-19; advances the combined contract to `tz-v10`
Website author-link addendum: user-authorized `WEBSITE-AUTHOR-001` on 2026-08-19; advances the combined contract to `tz-v11`
Release baseline: `0.4.0 released`
Website baseline: canonical domain released

This directory is the self-contained active specification package for SwiftUI Semantic Audit. It faithfully restates the user-approved Russian ТЗ without expanding product semantics. Clause IDs are stable references for implementation, review, and QA.

## Precedence

When documents appear to disagree, apply this order:

1. the user-approved ТЗ at epoch `tz-v1`, its pinned digest, the explicit `ROUTER-001`, `INDEXED-SKILLS-001`, `BOUNDARY-001`, `ARCHITECTURE-001`, `INCREMENTAL-CACHE-001`, `PARALLEL-EXECUTION-001`, `HOMEBREW-RELEASE-001`, `WEBSITE-001`, `WEBSITE-PUBLISH-001`, and `WEBSITE-AUTHOR-001` requests that advance the combined contract to `tz-v11`, and the behavior-preserving `REALISTIC-FIXTURES-001` acceptance addendum;
2. [`product-contract.md`](product-contract.md) for product boundaries and invariants;
3. domain contracts (`semantic-ir.md`, `rules.md`, `cli.md`);
4. [`acceptance.md`](acceptance.md) for proof obligations;
5. [`release-baseline.md`](release-baseline.md) for current realization and accepted residuals;
6. README, skills, examples, tests, and source as evidence of realization, not independent intent.

A local spec edit cannot authorize a semantic change. Any semantic delta requires user authority and a new contract epoch or revision. `ROUTER-001` is authorized only by the user's explicit request for one short skill entry point that selects among the three accepted specialist workflows.

## Registry

| Contract | Domain | Authority | Status/stability | Read when | Baseline |
| --- | --- | --- | --- | --- | --- |
| [`product-contract.md`](product-contract.md) | Goal, scope, invariants, LLM boundary, operations, safety, non-goals, workflow routing | Normative restatement of ТЗ plus authorized addenda through `HOMEBREW-RELEASE-001` | active / released `tz-v8` | Any product decision or behavior claim | 0.4.0 |
| [`analysis-config.md`](analysis-config.md) | Explicit role, feature, composition-root, and environment classification | `ARCHITECTURE-001` configuration contract | active / config schema 1 | Role-aware project analysis | unreleased |
| [`semantic-ir.md`](semantic-ir.md) | Graph, evidence, confidence, semantic values, snapshots, diff | Normative restatement of ТЗ plus `BOUNDARY-001` and `ARCHITECTURE-001` | active / schema v2 | Reading/writing graph or snapshot contracts | unreleased schema v2 |
| [`rules.md`](rules.md) | Twenty-nine rules, severities, exclusions, adjudication | Normative restatement of ТЗ plus `BOUNDARY-001` and `ARCHITECTURE-001` | active / evolving rule set | Auditing, classifying, refactoring | twenty-nine-rule target |
| [`cli.md`](cli.md) | Commands, flags, resolution, stdout/status, path/failure policy | Normative restatement plus authorized addenda | active / CLI 0.4.0 released | Running or documenting commands | seven public commands plus global version output |
| [`acceptance.md`](acceptance.md) | Fixtures, determinism, skills, CI, Definition of Done | Normative acceptance map for ТЗ §§44–51 plus authorized addenda through `HOMEBREW-RELEASE-001` | active | Implementing or verifying | 88 tests and hosted CI accepted; Homebrew receipt in release baseline |
| [`evidence-map.md`](evidence-map.md) | Clause ownership and all-54-section plus authorized-addendum coverage | Governance map | active | Tracing authority to evidence | P1–P13 map |
| [`release-baseline.md`](release-baseline.md) | Current realization, dependency pins, residuals | Descriptive evidence; never higher than normative contracts | active / released | Release/readiness/status work | 0.4.0 tool release plus initial website deployment |
| [`website.md`](website.md) | English landing-page experience, claims, examples, build, deployment, and QA | `WEBSITE-001`, `WEBSITE-PUBLISH-001`, and `WEBSITE-AUTHOR-001` product-evolution contract | active / released | Designing, implementing, publishing, or reviewing the website | canonical domain released |

## Domain ownership

- `PC-*`: product and architectural invariants.
- `IR-*`: semantic graph, provenance, persistence, and diff data contracts.
- `RULE-*`: finding and adjudication contracts.
- `CLI-*`: command, resolution, output, failure, and path behavior.
- `ACC-*`: fixtures, quality gates, CI, and completion proof.
- `BASE-*`: current release realization, publication evidence, and accepted limitations.
- `WEB-*`: website narrative, visual structure, accessibility, delivery, and publication behavior.

## Reading routes

- Agent workflow: start with `swiftui-semantic`, then follow its selected specialist → product contract → rules → CLI → semantic IR.
- CLI/API integration: product contract → CLI → semantic IR → acceptance.
- Snapshot/diff work: semantic IR → CLI → acceptance → release baseline.
- Release/CI review: acceptance → release baseline → evidence map.
- Website work: website → product contract → rules → release baseline.
- Contract audit: product contract → every domain contract → evidence map.

## Change control

The pinned base plus authorized addenda through `HOMEBREW-RELEASE-001` authorizes a Swift package and `swiftui-audit` CLI with deterministic syntax extraction, optional indexed enrichment, content-addressed incremental analysis caching, CPU-scaled frontend/rule execution with positive job control, twenty-nine bounded rules, snapshot/slice/diff/check/doctor, explicit project-role configuration, agent skills, documentation, fixtures, dogfood, CI, version output, and an immutable 0.4.0 GitHub/Homebrew release path. Architecture analysis covers collision-safe pre-index identities, type/feature/composition-root classification, component boundaries, lifecycle/focus/selection flow, geometry-driven product behavior, SwiftUI control semantics, narrow representable update analysis, and preview composition pressure. `REALISTIC-FIXTURES-001` strengthens acceptance with a compilable multi-file good/bad corpus, mixed-corpus invariance, and syntax/indexed finding parity without adding a thirtieth rule or extending bounded control-flow semantics. `INCREMENTAL-CACHE-001` changes only how deterministic facts are reused: cached and uncached semantic outputs remain identical, and the agent remains the adjudicator. `PARALLEL-EXECUTION-001` changes execution scheduling only: serial and parallel canonical results remain identical, and IndexStoreDB stays behind its isolated helper boundary. `HOMEBREW-RELEASE-001` changes release state and packaging only: the formula installs the standalone CLI and never owns agent-skill or user configuration paths. The contract does not authorize automatic rewriting, provider-specific LLM calls, SIL/full type checking, name-based application-role classification, generic AppKit/UIKit linting, or general non-SwiftUI analysis outside the bounded adapter/global-command rules.

`WEBSITE-001` adds one English static landing page without changing CLI, graph, rule, skill, release, or installation semantics. It authorizes an original visual system, selected fixture-backed examples, truthful 0.4.0 claims, and HoldType-derived static deployment mechanics. It does not authorize automatic-fix claims, a theme switcher, localization, analytics, a backend, or a new product GUI.

`WEBSITE-PUBLISH-001` authorizes the first DigitalOcean App Platform deployment,
push-triggered publication from `master`, and the staged canonical-domain cutover
to `swiftui-audit.dev` with `www` redirecting to the apex. The technical ingress
must pass before domain attachment, and the domain is not claimed ready until
registry delegation, managed TLS, and public verification pass.

`WEBSITE-AUTHOR-001` adds one HoldType-shaped personal Twitter link to the site
header. It authorizes `https://x.com/potapenko`, an accessible English label,
and the existing local Tabler icon system; it does not open adjacent navigation,
content, analytics, localization, or footer scope.

Advance the epoch before accepting a material semantic change. Editorial clarification may advance only the local specification revision and must preserve every protected behavior and exception.

## Migration state

- [Full-library Markdown migration](migration/README.md) — completed structural reconciliation of the nine-document legacy package.
