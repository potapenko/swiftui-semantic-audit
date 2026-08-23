# Specification registry

- Node type: root
- Status: Active
- Contract revision: `spec-31`
- Authority: epoch `tz-v25` and pinned digest declared below
- Read when: starting any product, behavior, compatibility, QA, release, or specification task in this repository.
- Do not read when: the task is proven behavior-neutral and outside the specification system.
- Maximum size: 100 physical lines.

Status: active  
Contract epoch: `tz-v25`
Local specification revision: `spec-31`
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
Artifact-hygiene addendum: user-authorized [`ARTIFACT-HYGIENE-001`](../coordination/artifact-hygiene-001.md) on 2026-08-22; advances the combined contract to `tz-v16`
Project-watcher addendum: user-authorized [`PROJECT-WATCHER-001`](../coordination/project-watcher-001.md) on 2026-08-22; advances the combined contract to `tz-v17`
Semantic-twin story addenda: user-authorized [`SEMANTIC-TWIN-STORY-001`](../coordination/semantic-twin-story-001.md) and capability-preservation correction [`SEMANTIC-TWIN-CAPABILITIES-001`](../coordination/semantic-twin-capabilities-001.md) on 2026-08-22; advance the combined contract to `tz-v19`
Release addendum: user-authorized [`RELEASE-0.6.0-001`](../coordination/release-0.6.0.md) on 2026-08-23; advances the combined contract to `tz-v20`; copy-control addenda: user-authorized `COPY-CONTROLS-001` and placement correction `COPY-CONTROLS-RIGHT-001` on 2026-08-23; advance the website contract through `tz-v22`; compatible source repair: user-authorized [`PROJECT-WATCHER-INTEGRATION-001`](../coordination/project-watcher-integration-001.md) on 2026-08-23; advances the combined contract to `tz-v23`; patch-candidate addendum: user-authorized [`RELEASE-0.6.1-001`](../coordination/release-0.6.1.md) on 2026-08-23; advances the combined contract to `tz-v24` without publishing or changing website behavior; local activation addendum: user-authorized [`LOCAL-0.6.1-ACTIVATION-001`](../coordination/local-0.6.1-activation-001.md) on 2026-08-23; advances the combined contract to `tz-v25` for this machine only
Release baseline: `0.6.0 current public`; immutable release artifacts: `0.4.0`, `0.5.0`, and `0.6.0`; current source and this machine's active CLI/four-skill bundle: unpublished 0.6.1 candidate pinned through `BASE-REL-017`; website baseline: canonical domain carries verified 0.6.0 release facts; project-watcher 0.6.0 is Released through `BASE-REL-015`; semantic-twin story candidate remains separately evolving

This directory is the self-contained active specification package for SwiftUI Semantic Audit. It faithfully restates the user-approved Russian ТЗ without expanding product semantics. Clause IDs are stable references for implementation, review, and QA.

## Precedence

When documents appear to disagree, apply this order:

1. the user-approved ТЗ at epoch `tz-v1`, its pinned digest, the explicit addenda through `LOCAL-0.6.1-ACTIVATION-001` that advance the combined contract to `tz-v25`, and the behavior-preserving `REALISTIC-FIXTURES-001` acceptance addendum;
2. [`product-contract.md`](product-contract.md) for product boundaries and invariants;
3. domain contracts (`semantic-ir.md`, `rules.md`, `cli.md`);
4. [`acceptance.md`](acceptance.md) for proof obligations;
5. [`release-baseline.md`](release-baseline.md) for current realization and accepted residuals;
6. README, skills, examples, tests, and source as evidence of realization, not independent intent.

A local spec edit cannot authorize a semantic change. Any semantic delta requires user authority and a new contract epoch or revision. `ROUTER-001` is authorized only by the user's explicit request for one short skill entry point that selects among the three accepted specialist workflows.

## Registry

| Contract | Domain | Authority | Status/stability | Read when | Baseline |
| --- | --- | --- | --- | --- | --- |
| [`product-contract.md`](product-contract.md) | Goal, semantic-twin identity, scope, invariants, LLM boundary, operations, safety, non-goals, workflow routing | Normative restatement of ТЗ plus authorized addenda through `LOCAL-0.6.1-ACTIVATION-001` | active / 0.6.0 public plus locally activated unpublished 0.6.1 candidate and evolving story | Any product decision or behavior claim | 0.6.0 released through `BASE-REL-015`; local activation `BASE-REL-017` |
| [`analysis-config.md`](analysis-config.md) | Explicit owner, View-role, feature, root, and environment classification | `ARCHITECTURE-001` plus `COMPONENT-SURFACE-001` | active / config schema 2, schema 1 accepted | Role-aware project analysis | 0.5.0 |
| [`semantic-ir.md`](semantic-ir.md) | Graph, evidence, confidence, semantic values, snapshots, diff | Normative restatement of ТЗ plus `BOUNDARY-001` and `ARCHITECTURE-001` | active / released schema v2 | Reading/writing graph or snapshot contracts | 0.5.0 |
| [`project-runtime.md`](project-runtime.md) | Project bootstrap, watcher freshness, lifecycle, runtime state, and baseline promotion | `PROJECT-WATCHER-001` plus `PROJECT-WATCHER-INTEGRATION-001` | active / Released schema 1 plus 0.6.1 repair candidate | Continuous project analysis | 0.6.0 public / 0.6.1 candidate |
| [`rules.md`](rules.md) | Thirty rules, severities, exclusions, adjudication | Normative restatement plus boundary, architecture, and component addenda | active / released rule set | Auditing, classifying, refactoring | 0.5.0 |
| [`cli.md`](cli.md) | Commands, flags, resolution, stdout/status, path/failure policy | Normative restatement plus authorized addenda | active / CLI 0.6.0 public plus 0.6.1 source candidate | Running or documenting commands | seven analysis commands plus project namespace |
| [`acceptance.md`](acceptance.md) | Fixtures, determinism, skills, CI, Definition of Done | Normative acceptance map for ТЗ §§44–51 plus authorized addenda through `LOCAL-0.6.1-ACTIVATION-001` | active | Implementing or verifying | candidate tests and local activation terminal; public receipts remain `BASE-REL-015` |
| [`evidence-map.md`](evidence-map.md) | Clause ownership and all-54-section plus authorized-addendum coverage | Governance map | active | Tracing authority to evidence | P1–P18 map |
| [`release-baseline.md`](release-baseline.md) | Current realization, dependency pins, residuals | Descriptive evidence; never higher than normative contracts | active / 0.6.0 released plus locally activated 0.6.1 candidate | Release/readiness/status work | local activation `BASE-REL-017`; hosted and publication evidence pending |
| [`website.md`](website.md) | English landing-page experience, claims, semantic-twin story, build, deployment, and QA | Website addenda through `RELEASE-0.6.0-001` | active / verified 0.6.0 release facts; corrected semantic-twin story evolving | Designing, implementing, publishing, or reviewing the website | canonical domain at `BASE-REL-015` |

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

The pinned base plus authorized addenda authorizes a Swift package and `swiftui-audit` CLI with deterministic syntax extraction, optional indexed enrichment, incremental caching, bounded parallel execution, thirty rules, snapshot/slice/diff/check/doctor, exact project classification, agent skills, fixtures, CI, immutable 0.4.0/0.5.0/0.6.0 artifacts, and the Released 0.6.0 project watcher recorded by `BASE-REL-015`. `COMPONENT-SURFACE-001` adds config schema 2 View roles, `component-model`, and one exact-config candidate for reusable components while preserving schema 1, graph schema 2, the prior twenty-nine rules, the 34-finding realistic total, and agent adjudication. `RELEASE-0.5.0-001` publishes that accepted candidate without changing analysis semantics. `ARTIFACT-HYGIENE-001` makes auxiliary agent evidence temporary by default, keeps durable evidence outside source/config/skill repositories with explicit retention, and preserves explicitly requested canonical snapshots. `PROJECT-WATCHER-001` adds opt-in safe setup and freshness-qualified continuous indexed state without changing analysis facts. `RELEASE-0.6.0-001` publishes its immutable tag/archive, source-built formula, separately installed tagged skills, and factual public release updates without changing analysis semantics. `PROJECT-WATCHER-INTEGRATION-001` adds a schema-1-compatible managed timeout and deterministic root/source configuration precedence. `RELEASE-0.6.1-001` assigns that current-source repair an unpublished 0.6.1 candidate identity without authorizing distribution; `LOCAL-0.6.1-ACTIVATION-001` separately permits its pinned local CLI/skill activation while preserving every public 0.6.0 surface. The contract still forbids automatic rewriting, provider-specific LLM calls, SIL/full type checking, name-based role inference, generic AppKit/UIKit linting, and broad non-SwiftUI analysis.

`WEBSITE-001` adds one English static landing page without changing CLI, graph, rule, skill, release, or installation semantics. It authorizes an original visual system, selected fixture-backed examples, initially truthful 0.4.0 claims later advanced to 0.5.0 by `RELEASE-0.5.0-001`, and HoldType-derived static deployment mechanics. It does not authorize automatic-fix claims, a theme switcher, localization, analytics, a backend, or a new product GUI.

`WEBSITE-PUBLISH-001` authorizes the first DigitalOcean App Platform deployment, push-triggered publication from `master`, and the staged canonical-domain cutover to `swiftui-audit.dev` with `www` redirecting to the apex. Technical ingress must pass before domain attachment; readiness also requires registry delegation, managed TLS, and public verification.

`WEBSITE-AUTHOR-001` adds one HoldType-shaped personal Twitter link to the site header. It authorizes `https://x.com/potapenko`, an accessible English label, and the existing local Tabler icon system; it does not open adjacent navigation, content, analytics, localization, or footer scope.

`INSTALL-UX-001` replaces the prior public setup presentation with one short agent prompt linked to the GitHub installation guide. `RELEASE-0.6.0-001` and `BASE-REL-015` advance the guide's pinned artifacts to release 0.6.0. The agent installs Homebrew first when absent, the CLI through Homebrew, and then all four skills as a separately owned phase. Homebrew remains CLI-only and must never modify agent-host directories. `COPY-CONTROLS-001` standardizes compact copy controls on the three task prompts, setup prompt, and CLI command without changing their text or meaning; `COPY-CONTROLS-RIGHT-001` corrects their placement to the conventional upper-right corner.

`SEMANTIC-TWIN-STORY-001` makes the deterministic semantic twin the primary public product object and moves skills to the consumer/router role; its original 0.5.0-versus-candidate split is superseded only for release state by `RELEASE-0.6.0-001` and `BASE-REL-015`. `SEMANTIC-TWIN-CAPABILITIES-001` restores the accepted landing capability surface and marketing hierarchy: semantic twin unifies the existing examples, tasks, diff, rule groups, and trust story; it does not replace them. Versions remain supporting release truth rather than the primary promise.

Advance the epoch before accepting a material semantic change. Current authority is `tz-v25`; editorial clarification may advance only the local specification revision and must preserve every protected behavior and exception.

Migration state: [Full-library Markdown migration](migration/README.md) completed structural reconciliation of the nine-document legacy package.
