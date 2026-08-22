# Specification registry

- Node type: root
- Status: Active
- Contract revision: `spec-18`
- Authority: epoch `tz-v15` and pinned digest declared below
- Read when: starting any product, behavior, compatibility, QA, release, or specification task in this repository.
- Do not read when: the task is proven behavior-neutral and outside the specification system.
- Maximum size: 100 physical lines.

Status: active  
Contract epoch: `tz-v15`
Local specification revision: `spec-18`
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
Website skill-story addendum: user-authorized `WEBSITE-SKILL-STORY-001` on 2026-08-19; advances the combined contract to `tz-v12`
Component-surface addendum: user-authorized `COMPONENT-SURFACE-001` on 2026-08-20; advances the combined contract to `tz-v13`; release addendum: user-authorized `RELEASE-0.5.0-001` on 2026-08-20; advances it to `tz-v14`
Installation UX addendum: user-authorized `INSTALL-UX-001` on 2026-08-22; advances the combined contract to `tz-v15`
Release baseline: `0.5.0 released`; immutable historical baseline: `0.4.0`; website baseline: canonical domain released

This directory is the self-contained active specification package for SwiftUI Semantic Audit. It faithfully restates the user-approved Russian ТЗ without expanding product semantics. Clause IDs are stable references for implementation, review, and QA.

## Precedence

When documents appear to disagree, apply this order:

1. the user-approved ТЗ at epoch `tz-v1`, its pinned digest, the explicit addenda through `RELEASE-0.5.0-001` and `INSTALL-UX-001` that advance the combined contract to `tz-v15`, and the behavior-preserving `REALISTIC-FIXTURES-001` acceptance addendum;
2. [`product-contract.md`](product-contract.md) for product boundaries and invariants;
3. domain contracts (`semantic-ir.md`, `rules.md`, `cli.md`);
4. [`acceptance.md`](acceptance.md) for proof obligations;
5. [`release-baseline.md`](release-baseline.md) for current realization and accepted residuals;
6. README, skills, examples, tests, and source as evidence of realization, not independent intent.

A local spec edit cannot authorize a semantic change. Any semantic delta requires user authority and a new contract epoch or revision. `ROUTER-001` is authorized only by the user's explicit request for one short skill entry point that selects among the three accepted specialist workflows.

## Registry

| Contract | Domain | Authority | Status/stability | Read when | Baseline |
| --- | --- | --- | --- | --- | --- |
| [`product-contract.md`](product-contract.md) | Goal, scope, invariants, LLM boundary, operations, safety, non-goals, workflow routing | Normative restatement of ТЗ plus authorized addenda through `RELEASE-0.5.0-001` | active / released `tz-v14` | Any product decision or behavior claim | 0.5.0 |
| [`analysis-config.md`](analysis-config.md) | Explicit owner, View-role, feature, root, and environment classification | `ARCHITECTURE-001` plus `COMPONENT-SURFACE-001` | active / config schema 2, schema 1 accepted | Role-aware project analysis | 0.5.0 |
| [`semantic-ir.md`](semantic-ir.md) | Graph, evidence, confidence, semantic values, snapshots, diff | Normative restatement of ТЗ plus `BOUNDARY-001` and `ARCHITECTURE-001` | active / released schema v2 | Reading/writing graph or snapshot contracts | 0.5.0 |
| [`rules.md`](rules.md) | Thirty rules, severities, exclusions, adjudication | Normative restatement plus boundary, architecture, and component addenda | active / released rule set | Auditing, classifying, refactoring | 0.5.0 |
| [`cli.md`](cli.md) | Commands, flags, resolution, stdout/status, path/failure policy | Normative restatement plus authorized addenda | active / CLI 0.5.0 released | Running or documenting commands | seven public commands plus global version output |
| [`acceptance.md`](acceptance.md) | Fixtures, determinism, skills, CI, Definition of Done | Normative acceptance map for ТЗ §§44–51 plus authorized addenda through `RELEASE-0.5.0-001` | active | Implementing or verifying | 92 tests and hosted CI accepted; Homebrew receipt in release baseline |
| [`evidence-map.md`](evidence-map.md) | Clause ownership and all-54-section plus authorized-addendum coverage | Governance map | active | Tracing authority to evidence | P1–P13 map |
| [`release-baseline.md`](release-baseline.md) | Current realization, dependency pins, residuals | Descriptive evidence; never higher than normative contracts | active / released | Release/readiness/status work | 0.5.0 tool release plus canonical website |
| [`website.md`](website.md) | English landing-page experience, claims, examples, build, deployment, and QA | Website addenda through `INSTALL-UX-001` | active / released baseline; install UX evolving | Designing, implementing, publishing, or reviewing the website | canonical domain at pre-change baseline |

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

The pinned base plus authorized addenda authorizes a Swift package and `swiftui-audit` CLI with deterministic syntax extraction, optional indexed enrichment, incremental caching, bounded parallel execution, thirty rules, snapshot/slice/diff/check/doctor, exact project classification, agent skills, fixtures, CI, and immutable 0.4.0 and 0.5.0 releases. `COMPONENT-SURFACE-001` adds config schema 2 View roles, `component-model`, and one exact-config candidate for reusable components while preserving schema 1, graph schema 2, the prior twenty-nine rules, the 34-finding realistic total, and agent adjudication. `RELEASE-0.5.0-001` publishes that accepted candidate without changing analysis semantics. The contract still forbids automatic rewriting, provider-specific LLM calls, SIL/full type checking, name-based role inference, generic AppKit/UIKit linting, and broad non-SwiftUI analysis.

`WEBSITE-001` adds one English static landing page without changing CLI, graph, rule, skill, release, or installation semantics. It authorizes an original visual system, selected fixture-backed examples, initially truthful 0.4.0 claims later advanced to 0.5.0 by `RELEASE-0.5.0-001`, and HoldType-derived static deployment mechanics. It does not authorize automatic-fix claims, a theme switcher, localization, analytics, a backend, or a new product GUI.

`WEBSITE-PUBLISH-001` authorizes the first DigitalOcean App Platform deployment, push-triggered publication from `master`, and the staged canonical-domain cutover
to `swiftui-audit.dev` with `www` redirecting to the apex. Technical ingress must pass before domain attachment; readiness also requires registry delegation, managed TLS, and public verification.

`WEBSITE-AUTHOR-001` adds one HoldType-shaped personal Twitter link to the site
header. It authorizes `https://x.com/potapenko`, an accessible English label,
and the existing local Tabler icon system; it does not open adjacent navigation,
content, analytics, localization, or footer scope.

`INSTALL-UX-001` replaces the prior public setup presentation with one short agent prompt linked to the GitHub installation guide. The guide pins artifacts to release 0.5.0. The agent installs Homebrew first when absent, the CLI through Homebrew, and then all four skills as a separately owned phase. Homebrew remains CLI-only and must never modify agent-host directories.

Advance the epoch before accepting a material semantic change. Editorial clarification may advance only the local specification revision and must preserve every protected behavior and exception.

## Migration state

- [Full-library Markdown migration](migration/README.md) — completed structural reconciliation of the nine-document legacy package.
