---
name: swiftui-semantic
description: Route SwiftUI semantic-twin evidence to audit, refactor, or change-review workflows, and set up continuous project state when the unreleased 0.6.0 capability is present. Use when Codex needs one entry point for ownership investigation, synchronization or Binding fixes, semantic change review, or project-watcher setup.
---

# SwiftUI Semantic Twin Router

Treat the semantic twin as the deterministic fact source shared by every route.
It preserves supported ownership and data-flow facts, evidence, compatible
snapshots, and bounded slices. It is not an LLM summary; the selected specialist
and surrounding agent supply judgment without rewriting those facts.

## Choose the workflow

Classify the requested outcome before reading broad Swift source:

- Read and follow [project watcher setup](references/project-watcher.md) when the user asks to configure, bootstrap, start, stop, or inspect continuous semantic analysis for a project. That route requires an unreleased `0.6.0` candidate capability preflight.
- Read and follow [swiftui-semantic-audit](../swiftui-semantic-audit/SKILL.md) for investigation, diagnosis, architecture explanation, ownership or component-boundary analysis, or an ambiguous state/data-flow problem.
- Read and follow [swiftui-dataflow-refactor](../swiftui-dataflow-refactor/SKILL.md) when the user asks to change SwiftUI state ownership, remove manual synchronization, replace callback plumbing, or correct Binding, Observation, derived-state, or lifetime architecture.
- Read and follow [swiftui-change-review](../swiftui-change-review/SKILL.md) when changes, commits, snapshots, or a diff already exist and the user asks whether they are safe or architecturally correct.

For setup, read the watcher reference and execute only that bounded workflow. Otherwise read only the selected specialist `SKILL.md` first, then load the references that specialist requires. Do not merge shortened versions of all three workflows or skip a specialist's gates.

Before the selected workflow emits command output or snapshots, read and apply [run artifact hygiene](references/artifact-hygiene.md). Stream separation does not require permanent per-command files.

Use [references/routing.md](references/routing.md) when the request combines phases, its starting state is unclear, or the workflow must hand evidence from one specialist to another.

## Route mixed work deliberately

Use the smallest sequence that covers the request:

1. Start with semantic audit when intent, ownership, or the relevant finding cluster is unknown.
2. Continue with data-flow refactor only when the user requested a change and ownership, lifetime, transaction, transformation, and behavior invariants are established.
3. Finish with change review when a produced or pre-existing change needs independent semantic evaluation.

For a direct refactor request, select the refactor skill immediately because it already requires baseline, audit, slice, build, tests, diff, and check. For a direct review request, select the review skill immediately. Do not add an audit phase merely to make the workflow longer.

## Preserve handoff state

Keep these facts unchanged when moving between specialists:

- source path and repository;
- `indexed` resolution and the validated Index Store identity/path used for live-source analysis;
- the validated analysis-configuration digest, or the explicit fact that the workflow is topology-only;
- baseline and current snapshot identities;
- the live semantic-twin generation and matching freshness receipt when watcher state is used;
- finding, semantic-value, and symbol IDs;
- deterministic nodes, edges, evidence, and source locations;
- established owner, lifetime, write authority, transaction boundary, transformations, custom-Binding effects, component-boundary depth, dependency surface, and behavior invariants;
- command exit statuses and stderr separately from JSON stdout.

Never reinterpret missing deterministic evidence during a handoff. Return `unknown` or request the smallest missing evidence.

Require every specialist result to report `resolution: "indexed"`. Stop the workflow when a fresh project-covering Index Store or compatible indexed snapshot is unavailable; do not weaken the workflow through automatic resolution fallback.

## Keep the semantic boundary

Use `swiftui-audit` to build the deterministic semantic twin and the agent as
the adjudicator. Never add or assume a model-provider API. Do not recommend
“Use Binding everywhere” or “Minimize `@State`.” Optimize for correct
ownership, canonical source of truth, explicit dependencies, minimal manual
synchronization, correct lifetime, and preserved transaction and
transformation semantics.

Report which specialist workflow was selected, why it fits the task, any later workflow transition, and the final verification evidence.
