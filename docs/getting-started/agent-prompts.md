# Agent prompts

These prompts use the released SwiftUI Semantic Audit 0.5.0 router and its
three specialist skills. They do not add another skill, a migration command,
or automatic source rewriting.

In Codex, invoke the router as `$swiftui-semantic`. In Claude Code, replace that
spelling with `/swiftui-semantic`. For the final long-running prompt, keep the
`/goal` prefix in Codex; in Claude Code, remove the prefix and use the rest as a
project task brief.

## Before an agent workflow

The audit, refactor, review, and migration prompts require:

- `swiftui-audit --version` to report `0.5.0`;
- a normal build of the exact source state being analyzed;
- a fresh compiler Index Store that covers the project scope;
- the raw Index Store path passed explicitly to live-source commands;
- `resolution: "indexed"` in every resulting report or snapshot;
- a validated `.swiftui-audit.json` when a conclusion depends on project roles.

Stop instead of continuing with weaker evidence when the index is missing,
stale, or incomplete; a command fails; JSON is invalid; a selector is
ambiguous; snapshot resolution, schema, or configuration differs; or product
ownership and transaction behavior cannot be established.

For the underlying procedure, see [Installation](installation.md),
[Run a first audit](first-audit.md), and the [workflow index](../workflows/README.md).

<a id="install-the-agent-skills"></a>

## Install the CLI and agent skills

```text
Install SwiftUI Semantic Audit from this GitHub guide. Install Homebrew first if needed, then the CLI and all four agent skills:
https://github.com/potapenko/swiftui-semantic-audit/blob/master/docs/getting-started/installation.md
```

The GitHub installation guide is the canonical detailed procedure. It pins
artifacts to release `0.5.0` and keeps Homebrew's CLI ownership separate from
the agent-owned installation of all four skills.

## Add a bounded project instruction

This prompt adds the routing rule to the instruction file the current agent
host actually reads. It does not turn every SwiftUI task into an architecture
audit.

```text
Add a small repository instruction for SwiftUI Semantic Audit. First inspect
the current instruction hierarchy. In Codex, update the applicable AGENTS.md;
in Claude Code, update the applicable CLAUDE.md. If the host's repository-level
instruction file does not exist, create only that documented file.

Preserve every existing instruction and its precedence. Do not replace,
reformat, reorder, or summarize unrelated content. Merge with an equivalent
existing rule instead of adding a duplicate.

Add wording with this exact scope:

- Use the installed `swiftui-semantic` router for SwiftUI tasks that
  investigate, change, or review state ownership, data flow, Bindings, effects,
  lifetime, synchronization, or component boundaries.
- For live-source agent analysis, build the exact source state, pass a fresh
  project-covering compiler Index Store explicitly, require
  `resolution: "indexed"`, and stop when that evidence is unavailable.
- Preserve the tool's deterministic facts. Let the agent classify intent and
  return `unknown` when ownership, lifetime, transformation, or transaction
  evidence is missing.
- Do not apply this rule to unrelated styling, layout-only, performance,
  concurrency, or security work.
- Do not treat the tool as an automatic rewriter or replace project builds and
  behavior tests with a finding count.

Change no product code, build settings, audit configuration, or other agent
instructions. Show the exact instruction diff and name the file and scope in
which the new rule applies.
```

## Audit the whole project without editing it

Use this to produce an architecture report before deciding what to change. The
full procedure is in the [audit workflow](../workflows/audit.md).

```text
Use $swiftui-semantic to perform a read-only audit of this repository's SwiftUI
state and data-flow architecture. Do not edit product code, tests, build
settings, audit configuration, or agent instructions.

Establish the in-scope application targets and source roots from existing
project evidence. Exclude dependencies and generated sources unless they are
explicitly part of the requested product scope. Run the project's normal build
for the exact current source, validate a fresh project-covering compiler Index
Store, pass its raw path explicitly, and accept only
`resolution: "indexed"`.

Use an existing validated `.swiftui-audit.json` when present. Do not invent
application roles from names. If authoritative role configuration is absent,
run only conclusions supported by topology and state the role-aware limitation.

Audit before reading broad source. Group overlapping findings into
semantic-value clusters, then request bounded slices for the highest-risk clusters and
open source at their evidence locations first. Distinguish accidental mirrors,
manual synchronization, derived values, transactional drafts, legitimate
view-local state, custom Binding effects, and component-boundary candidates.
Return `unknown` where evidence is insufficient.

Report the audited scope, Index Store identity, configuration digest or
topology-only limitation, and a prioritized cluster table. For each cluster,
include finding and evidence IDs, current owner, mutable representations,
logical source count, read/write/Binding/effect paths, classification, risk,
conditional remediation, and missing evidence. Do not change files and do not
describe every candidate as a defect.
```

## Refactor one cluster

Append the target feature, finding ID, or semantic value to the first sentence
before using this prompt. See the [refactor workflow](../workflows/refactor.md).

```text
Use $swiftui-semantic to refactor exactly one SwiftUI state/data-flow cluster:
TARGET CLUSTER GOES HERE. Do not start a second cluster or perform adjacent
cleanup.

Before editing, build the exact baseline source, validate and pass a fresh
project-covering compiler Index Store, require `resolution: "indexed"`, create
a compatible indexed baseline snapshot, audit the target, and obtain a bounded
slice. State the intended owner, canonical representation, lifetime, write
authority, product behavior, ordering, transformations, side effects, and
commit/cancel/rollback semantics. Stop before editing if any required invariant
is unresolved or if the target contains more than one independent cluster.

Edit the smallest complete path, including only directly required call sites
and tests. Preserve behavior, effects, identity, public interfaces, and
transaction boundaries. Do not hide the same synchronization or command behind
a different wrapper or callback, and do not optimize for Binding everywhere,
the fewest State properties, or a lower aggregate score.

After the edit, run the normal build and relevant behavior tests. Produce a
fresh Index Store for the edited source, create the compatible current indexed
snapshot, run semantic diff and the no-new-high check, and review the current
change through the change-review workflow. Accept the cluster only when the
targeted problem improves, required behavior checks pass, no new high-severity
finding appears, and every ownership, write, effect, and dependency change is
explained by the intended refactor.

Return the changed files, preserved invariants, build and test results,
baseline and current snapshot identities, semantic diff summary, check status,
review findings, and any residual risk. Do not claim broader project migration.
```

## Review current changes

This prompt assumes that the exact baseline and current source states already
have compatible indexed snapshots. See the
[change-review workflow](../workflows/change-review.md).

```text
Use $swiftui-semantic to review the current SwiftUI changes for state
ownership, data-flow, lifetime, Binding, effect, synchronization, and
component-boundary regressions. Do not edit or fix the changes during this review.

Require baseline and current snapshots created from fresh project-covering
compiler Index Stores for their exact source states. Verify that both report
`resolution: "indexed"` and have matching graph schema and
analysis-configuration digests. Do not substitute Git-revision operands for those
snapshots. If either snapshot is missing or incompatible, report semantic
review as blocked instead of calling the change clean.

Inspect the semantic diff before the raw Git diff. Review ownership changes,
mutable representations, logical source counts, reads, writes, calls, Bindings,
synchronization, derivation, effects, component inputs, and new, resolved, or
retained findings. Slice suspicious current findings or symbols, open their
source evidence, and only then inspect the implementation diff for behavior,
ordering, guards, error handling, transaction semantics, APIs, and test gaps.

Report actionable findings in risk order with source evidence and the affected
semantic path. Separate semantic risks from implementation-only findings.
Include both snapshot identities, resolution and configuration compatibility,
available build and behavior-test evidence, and all review limitations. If
there are no actionable findings, say exactly what was checked; do not infer
runtime correctness from an empty semantic diff.
```

## Run a staged whole-project migration

This is a persistent coordination prompt, not a request for a one-pass rewrite.
It applies the existing audit, refactor, and review workflows one cluster at a
time.

```text
/goal Migrate this project's in-scope SwiftUI state and data-flow architecture
with $swiftui-semantic while preserving product behavior.

Use only the released router and its three specialist workflows. Do not invent
a migration skill, command, rule, or automatic rewrite. Treat this goal as
orchestration over bounded one-cluster refactors, never as permission for a
whole-project replacement.

Start with a read-only whole-project audit of the exact current source. Build
it normally, validate a fresh project-covering compiler Index Store, pass the
raw path explicitly, and require `resolution: "indexed"`. Use only an existing
validated project-role configuration; if role-aware conclusions need missing
authority, record the gap instead of guessing.

Create a restart-safe Markdown registry in the repository's established plan
location. Give each overlapping finding cluster one stable row with: registry
ID; semantic value; finding, node, edge, and source-evidence IDs; current and
intended owner; mutable representations; classification; behavior and
transaction invariants; required tests; dependencies; risk; baseline/current
snapshot identities; semantic diff and review result; checkpoint; status; and
blocking question. Define explicit statuses and allow at most one in-progress
row. On every restart, read the registry and verify repository and snapshot
state before choosing work. Do not rediscover or silently renumber completed
rows.

Process one approved, dependency-ready cluster per checkpoint. For that cluster
only: create a fresh indexed baseline snapshot; audit and slice; establish
owner, lifetime, effects, transformations, and commit/cancel semantics; make
the smallest complete edit; run the normal build and relevant behavior tests;
produce a fresh indexed current snapshot; run semantic diff and the
no-new-high check; complete a separate change-review pass; update the registry;
and save the repository checkpoint required by project policy. Do not begin the
next row until the current row has an evidence-backed terminal disposition and
its checkpoint succeeds.

Never improve the report by weakening source scope, project-role
configuration, thresholds, index requirements, or rules. Do not move the same
imperative mechanism into another wrapper or callback. Do not use an aggregate
score or zero-finding target as proof of architecture quality. Preserve
intentional drafts, transformations, local UI state, and transaction boundaries
when the evidence supports them.

When a cluster lacks product intent, compatible indexed evidence, a passing
build, required behavior tests, or a defensible semantic diff, mark it blocked
with the exact evidence and decision needed. Continue only with independent
clusters that remain safe and in scope.

Finish with a fresh project-wide build, Index Store, configured audit, and
registry reconciliation. The goal is complete only when every in-scope row has
an evidence-backed terminal disposition, the final audit is reconciled with the
registry, required builds and tests pass, no unexplained high-severity
regression remains, and the final review reports the remaining limitations.
```

## Related workflows

- [Install and verify release 0.5.0](installation.md)
- [Run a first indexed audit](first-audit.md)
- [Audit](../workflows/audit.md)
- [Refactor](../workflows/refactor.md)
- [Change review](../workflows/change-review.md)
