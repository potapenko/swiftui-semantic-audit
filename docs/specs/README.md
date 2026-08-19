# Specification registry

Status: active  
Contract epoch: `tz-v6`
Local specification revision: `spec-7`
Pinned authority digest: `sha256:68f8a43d924659024b7d29fabb9ad302817c271838a7919b24bd942626927cac`  
Router addendum: user-authorized `ROUTER-001` on 2026-08-18
Indexed-skills addendum: user-authorized `INDEXED-SKILLS-001` on 2026-08-18
Boundary-analysis addendum: user-authorized `BOUNDARY-001` on 2026-08-18
Architecture-analysis addendum: user-authorized `ARCHITECTURE-001` on 2026-08-18
Realistic-fixtures acceptance addendum: user-authorized `REALISTIC-FIXTURES-001` on 2026-08-18; product semantics remain at `tz-v5`
Incremental-cache addendum: user-authorized `INCREMENTAL-CACHE-001` on 2026-08-19; advances the combined contract to `tz-v6`
Release baseline: `unreleased`

This directory is the self-contained active specification package for SwiftUI Semantic Audit. It faithfully restates the user-approved Russian ТЗ without expanding product semantics. Clause IDs are stable references for implementation, review, and QA.

## Precedence

When documents appear to disagree, apply this order:

1. the user-approved ТЗ at epoch `tz-v1`, its pinned digest, the explicit `ROUTER-001`, `INDEXED-SKILLS-001`, `BOUNDARY-001`, `ARCHITECTURE-001`, and `INCREMENTAL-CACHE-001` requests that advance the combined contract to `tz-v6`, and the behavior-preserving `REALISTIC-FIXTURES-001` acceptance addendum;
2. [`product-contract.md`](product-contract.md) for product boundaries and invariants;
3. domain contracts (`semantic-ir.md`, `rules.md`, `cli.md`);
4. [`acceptance.md`](acceptance.md) for proof obligations;
5. [`release-baseline.md`](release-baseline.md) for current realization and accepted residuals;
6. README, skills, examples, tests, and source as evidence of realization, not independent intent.

A local spec edit cannot authorize a semantic change. Any semantic delta requires user authority and a new contract epoch or revision. `ROUTER-001` is authorized only by the user's explicit request for one short skill entry point that selects among the three accepted specialist workflows.

## Registry

| Contract | Domain | Authority | Status/stability | Read when | Baseline |
| --- | --- | --- | --- | --- | --- |
| [`product-contract.md`](product-contract.md) | Goal, scope, invariants, LLM boundary, operations, safety, non-goals, workflow routing | Normative restatement of ТЗ plus authorized addenda through `INCREMENTAL-CACHE-001` | active / evolving `tz-v6` | Any product decision or behavior claim | unreleased |
| [`analysis-config.md`](analysis-config.md) | Explicit role, feature, composition-root, and environment classification | `ARCHITECTURE-001` configuration contract | active / config schema 1 | Role-aware project analysis | unreleased |
| [`semantic-ir.md`](semantic-ir.md) | Graph, evidence, confidence, semantic values, snapshots, diff | Normative restatement of ТЗ plus `BOUNDARY-001` and `ARCHITECTURE-001` | active / schema v2 | Reading/writing graph or snapshot contracts | unreleased schema v2 |
| [`rules.md`](rules.md) | Twenty-nine rules, severities, exclusions, adjudication | Normative restatement of ТЗ plus `BOUNDARY-001` and `ARCHITECTURE-001` | active / evolving rule set | Auditing, classifying, refactoring | twenty-nine-rule target |
| [`cli.md`](cli.md) | Commands, flags, resolution, stdout/status, path/failure policy | Normative restatement plus authorized addenda | active / CLI 0.4.0 target | Running or documenting commands | seven public commands |
| [`acceptance.md`](acceptance.md) | Fixtures, determinism, skills, CI, Definition of Done | Normative acceptance map for ТЗ §§44–51 plus authorized addenda through `INCREMENTAL-CACHE-001` | active | Implementing or verifying | 86-test local candidate; hosted CI pending |
| [`evidence-map.md`](evidence-map.md) | Clause ownership and all-54-section plus authorized-addendum coverage | Governance map | active | Tracing authority to evidence | P1–P12 map |
| [`release-baseline.md`](release-baseline.md) | Current realization, dependency pins, residuals | Descriptive evidence; never higher than normative contracts | active / volatile | Release/readiness/status work | unreleased cache product source at `38146ff…`; hosted acceptance pending |

## Domain ownership

- `PC-*`: product and architectural invariants.
- `IR-*`: semantic graph, provenance, persistence, and diff data contracts.
- `RULE-*`: finding and adjudication contracts.
- `CLI-*`: command, resolution, output, failure, and path behavior.
- `ACC-*`: fixtures, quality gates, CI, and completion proof.
- `BASE-*`: current unreleased realization and accepted limitations.

## Reading routes

- Agent workflow: start with `swiftui-semantic`, then follow its selected specialist → product contract → rules → CLI → semantic IR.
- CLI/API integration: product contract → CLI → semantic IR → acceptance.
- Snapshot/diff work: semantic IR → CLI → acceptance → release baseline.
- Release/CI review: acceptance → release baseline → evidence map.
- Contract audit: product contract → every domain contract → evidence map.

## Change control

The pinned base plus authorized addenda through `INCREMENTAL-CACHE-001` authorizes a Swift package and `swiftui-audit` CLI with deterministic syntax extraction, optional indexed enrichment, content-addressed incremental analysis caching, twenty-nine bounded rules, snapshot/slice/diff/check/doctor, explicit project-role configuration, agent skills, documentation, fixtures, dogfood, and CI. Architecture analysis covers collision-safe pre-index identities, type/feature/composition-root classification, component boundaries, lifecycle/focus/selection flow, geometry-driven product behavior, SwiftUI control semantics, narrow representable update analysis, and preview composition pressure. `REALISTIC-FIXTURES-001` strengthens acceptance with a compilable multi-file good/bad corpus, mixed-corpus invariance, and syntax/indexed finding parity without adding a thirtieth rule or extending bounded control-flow semantics. `INCREMENTAL-CACHE-001` changes only how deterministic facts are reused: cached and uncached semantic outputs remain identical, and the agent remains the adjudicator. Agent workflows remain explicitly indexed. The standalone CLI retains build-free fallback. The contract does not authorize automatic rewriting, provider-specific LLM calls, SIL/full type checking, name-based application-role classification, generic AppKit/UIKit linting, or general non-SwiftUI analysis outside the bounded adapter/global-command rules.

Advance the epoch before accepting a material semantic change. Editorial clarification may advance only the local specification revision and must preserve every protected behavior and exception.
