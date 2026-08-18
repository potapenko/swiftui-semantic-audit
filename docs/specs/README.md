# Specification registry

Status: active  
Contract epoch: `tz-v4`
Local specification revision: `spec-4`
Pinned authority digest: `sha256:68f8a43d924659024b7d29fabb9ad302817c271838a7919b24bd942626927cac`  
Router addendum: user-authorized `ROUTER-001` on 2026-08-18
Indexed-skills addendum: user-authorized `INDEXED-SKILLS-001` on 2026-08-18
Boundary-analysis addendum: user-authorized `BOUNDARY-001` on 2026-08-18
Release baseline: `unreleased`

This directory is the self-contained active specification package for SwiftUI Semantic Audit. It faithfully restates the user-approved Russian ТЗ without expanding product semantics. Clause IDs are stable references for implementation, review, and QA.

## Precedence

When documents appear to disagree, apply this order:

1. the user-approved ТЗ at epoch `tz-v1`, its pinned digest, and the explicit `ROUTER-001`, `INDEXED-SKILLS-001`, and `BOUNDARY-001` requests that advance the combined contract to `tz-v4`;
2. [`product-contract.md`](product-contract.md) for product boundaries and invariants;
3. domain contracts (`semantic-ir.md`, `rules.md`, `cli.md`);
4. [`acceptance.md`](acceptance.md) for proof obligations;
5. [`release-baseline.md`](release-baseline.md) for current realization and accepted residuals;
6. README, skills, examples, tests, and source as evidence of realization, not independent intent.

A local spec edit cannot authorize a semantic change. Any semantic delta requires user authority and a new contract epoch or revision. `ROUTER-001` is authorized only by the user's explicit request for one short skill entry point that selects among the three accepted specialist workflows.

## Registry

| Contract | Domain | Authority | Status/stability | Read when | Baseline |
| --- | --- | --- | --- | --- | --- |
| [`product-contract.md`](product-contract.md) | Goal, scope, invariants, LLM boundary, operations, safety, non-goals, workflow routing | Normative restatement of ТЗ §§1–8, 23–27, 33, 37–43, 46–54 plus `ROUTER-001`, `INDEXED-SKILLS-001`, and `BOUNDARY-001` | active / evolving `tz-v4` | Any product decision or behavior claim | unreleased |
| [`semantic-ir.md`](semantic-ir.md) | Graph, evidence, confidence, semantic values, snapshots, diff | Normative restatement of ТЗ §§3–4, 9–15, 27–33 | active / schema v1 | Reading/writing graph or snapshot contracts | unreleased schema v1 |
| [`rules.md`](rules.md) | Ten rules, severities, exclusions, adjudication | Normative restatement of ТЗ §§16–25, 33, 38–45 plus `BOUNDARY-001` | active / accepted rule set | Auditing, classifying, refactoring | ten-rule baseline |
| [`cli.md`](cli.md) | Commands, flags, resolution, stdout/status, path/failure policy | Normative restatement plus accepted P1–P5 interface evidence and `BOUNDARY-001` | active / CLI 0.2.0 | Running or documenting commands | seven public commands |
| [`acceptance.md`](acceptance.md) | Fixtures, determinism, skills, CI, Definition of Done | Normative acceptance map for ТЗ §§44–51 plus `ROUTER-001` and `BOUNDARY-001` | active | Implementing or verifying | 69-test baseline plus four-skill validation |
| [`evidence-map.md`](evidence-map.md) | Clause ownership and all-54-section plus authorized-addendum coverage | Governance map | active | Tracing authority to evidence | P1–P9 map |
| [`release-baseline.md`](release-baseline.md) | Current realization, dependency pins, residuals | Descriptive evidence; never higher than normative contracts | active / volatile | Release/readiness/status work | unreleased product source at `e81f10d…` plus accepted QA |

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

The pinned base plus `ROUTER-001`, `INDEXED-SKILLS-001`, and `BOUNDARY-001` authorizes a Swift package and `swiftui-audit` CLI with deterministic syntax extraction, optional indexed enrichment, ten bounded rules, snapshot/slice/diff/check/doctor, three specialist agent skills, one routing skill, documentation, fixtures, dogfood, and CI. The boundary addendum covers explicit custom Binding topology, Binding factories, observable-model propagation, externally observed leaf inputs, and topology-based source counting. Agent-facing semantic audit, refactor, and review workflows require explicit indexed analysis and must fail rather than silently accept a lower-resolution result. This workflow constraint does not remove the CLI's protected build-free fallback. The contract does not authorize automatic rewriting, provider-specific LLM calls, SIL/full type checking, GUI/IDE/Xcode extensions, name-based controller/service classification, or general non-SwiftUI analysis.

Advance the epoch before accepting a material semantic change. Editorial clarification may advance only the local specification revision and must preserve every protected behavior and exception.
