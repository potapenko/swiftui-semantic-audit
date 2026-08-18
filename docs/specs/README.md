# Specification registry

Status: active  
Contract epoch: `tz-v2`
Local specification revision: `spec-2`
Pinned authority digest: `sha256:68f8a43d924659024b7d29fabb9ad302817c271838a7919b24bd942626927cac`  
Router addendum: user-authorized `ROUTER-001` on 2026-08-18
Release baseline: `unreleased`

This directory is the self-contained active specification package for SwiftUI Semantic Audit. It faithfully restates the user-approved Russian ТЗ without expanding product semantics. Clause IDs are stable references for implementation, review, and QA.

## Precedence

When documents appear to disagree, apply this order:

1. the user-approved ТЗ at epoch `tz-v1`, its pinned digest, and the explicit `ROUTER-001` request that advances the combined contract to `tz-v2`;
2. [`product-contract.md`](product-contract.md) for product boundaries and invariants;
3. domain contracts (`semantic-ir.md`, `rules.md`, `cli.md`);
4. [`acceptance.md`](acceptance.md) for proof obligations;
5. [`release-baseline.md`](release-baseline.md) for current realization and accepted residuals;
6. README, skills, examples, tests, and source as evidence of realization, not independent intent.

A local spec edit cannot authorize a semantic change. Any semantic delta requires user authority and a new contract epoch or revision. `ROUTER-001` is authorized only by the user's explicit request for one short skill entry point that selects among the three accepted specialist workflows.

## Registry

| Contract | Domain | Authority | Status/stability | Read when | Baseline |
| --- | --- | --- | --- | --- | --- |
| [`product-contract.md`](product-contract.md) | Goal, scope, invariants, LLM boundary, operations, safety, non-goals, workflow routing | Normative restatement of ТЗ §§1–8, 23–27, 33, 37–43, 46–54 plus `ROUTER-001` | active / evolving `tz-v2` | Any product decision or behavior claim | unreleased |
| [`semantic-ir.md`](semantic-ir.md) | Graph, evidence, confidence, semantic values, snapshots, diff | Normative restatement of ТЗ §§3–4, 9–15, 27–33 | active / schema v1 | Reading/writing graph or snapshot contracts | unreleased schema v1 |
| [`rules.md`](rules.md) | Six PoC rules, severities, exclusions, adjudication | Normative restatement of ТЗ §§16–25, 33, 38–45 | active / stable PoC set | Auditing, classifying, refactoring | six-rule baseline |
| [`cli.md`](cli.md) | Commands, flags, resolution, stdout/status, path/failure policy | Normative restatement plus accepted P1–P5 interface evidence | active / CLI 0.1.0 | Running or documenting commands | seven public commands |
| [`acceptance.md`](acceptance.md) | Fixtures, determinism, skills, CI, Definition of Done | Normative acceptance map for ТЗ §§44–51 plus `ROUTER-001` | active | Implementing or verifying | 64-test baseline plus four-skill validation |
| [`evidence-map.md`](evidence-map.md) | Clause ownership and all-54-section plus router-addendum coverage | Governance map | active | Tracing authority to evidence | P1–P8 map |
| [`release-baseline.md`](release-baseline.md) | Current realization, dependency pins, residuals | Descriptive evidence; never higher than normative contracts | active / volatile | Release/readiness/status work | unreleased at `f24751c…` + accepted working tree |

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

The pinned base plus `ROUTER-001` authorizes a Swift package and `swiftui-audit` CLI with deterministic syntax extraction, optional indexed enrichment, six PoC rules, snapshot/slice/diff/check/doctor, three specialist agent skills, one routing skill, documentation, fixtures, dogfood, and CI. It does not authorize automatic rewriting, provider-specific LLM calls, SIL/full type checking, GUI/IDE/Xcode extensions, or general non-SwiftUI analysis.

Advance the epoch before accepting a material semantic change. Editorial clarification may advance only the local specification revision and must preserve every protected behavior and exception.
