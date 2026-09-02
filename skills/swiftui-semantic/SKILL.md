---
name: swiftui-semantic
description: Use indexed SwiftUI semantic evidence when ownership, duplicated or derived state, manual synchronization, Binding/Observation/Environment flow, or component-boundary data-flow materially affects a task. Explicit semantic workflow requests enter strict mode.
---

# SwiftUI Semantic Twin Router

## Select the operating mode

An automatically selected invocation is **implicit assist mode** unless the
user crosses the explicit boundary below. This remains true when the request
mentions semantic evidence, a snapshot, an Index Store, or asks which skill is
helping. Read and follow [assist mode](references/assist-mode.md). Do not load a
specialist in this mode.

Use **strict mode** only when the user invokes `$swiftui-semantic` or directly
asks to run or perform the semantic audit, semantic data-flow refactor, semantic
change review, or full semantic-twin workflow. A directly invoked specialist is
already strict; follow its `SKILL.md` without routing back through this entry
point.

Do not infer strict mode merely because an automatically matched task mentions
state, ownership, Binding, Observation, Environment, architecture, a diff, or
a review.

Whenever semantic evidence is used, treat the semantic twin as the deterministic fact source shared by every selected route.
It preserves supported ownership and data-flow facts, evidence, compatible
snapshots, and bounded slices. It is not an LLM summary; the selected specialist
and surrounding agent supply judgment without rewriting those facts.

Before forming any CLI command in either mode, read and follow the shared [CLI
invocation matrix](references/cli-invocation-matrix.md). It assigns resolution
and configuration flags by command and input kind; do not transfer a flag
between commands merely because they belong to one workflow.

## Choose the strict workflow

Classify the requested outcome before reading broad Swift source:

- Read and follow [project watcher setup](references/project-watcher.md) when the user asks to configure, bootstrap, start, stop, or inspect continuous semantic analysis for a project. That route requires a watcher capability preflight; the managed-timeout and selected-source configuration repair requires the unpublished `0.6.1` candidate or a later compatible release.
- Read and follow [swiftui-semantic-audit](../swiftui-semantic-audit/SKILL.md) for investigation, diagnosis, architecture explanation, ownership or component-boundary analysis, or an ambiguous state/data-flow problem.
- Read and follow [swiftui-dataflow-refactor](../swiftui-dataflow-refactor/SKILL.md) when the user asks to change SwiftUI state ownership, remove manual synchronization, replace callback plumbing, or correct Binding, Observation, derived-state, or lifetime architecture.
- Read and follow [swiftui-change-review](../swiftui-change-review/SKILL.md) when changes, commits, snapshots, or a diff already exist and the user asks whether they are safe or architecturally correct.

For setup, read the watcher reference and execute only that bounded workflow.
Otherwise read only the selected specialist `SKILL.md` first, then load the
references that specialist requires. Do not merge shortened versions of all
three workflows or skip a specialist's gates.

Before the selected workflow emits command output or snapshots, read and apply [run artifact hygiene](references/artifact-hygiene.md). Stream separation does not require permanent per-command files.

Use [references/routing.md](references/routing.md) when a strict request combines
phases, its starting state is unclear, or the workflow must hand evidence from
one specialist to another.

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

Require every specialist result to report `resolution: "indexed"`. Stop the
strict semantic workflow when a fresh project-covering Index Store or compatible
indexed snapshot is unavailable; do not weaken the workflow through automatic
resolution fallback or treat this semantic limitation as a blocker for
unrelated work.

## Keep the semantic boundary

Use `swiftui-audit` to build the deterministic semantic twin and the agent as
the adjudicator. Never add or assume a model-provider API. Do not recommend
“Use Binding everywhere” or “Minimize `@State`.” Optimize for correct
ownership, canonical source of truth, explicit dependencies, minimal manual
synchronization, correct lifetime, and preserved transaction and
transformation semantics.

In assist mode, report semantic evidence only when it changed or materially
supported the task decision. In strict mode, report which specialist workflow
was selected, why it fits the task, any later transition, and the final
verification evidence.
