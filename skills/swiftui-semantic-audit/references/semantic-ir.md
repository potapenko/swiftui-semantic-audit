# Semantic IR reference

Read this reference when interpreting audit or slice JSON, stable identities, evidence, confidence, or resolution.

## Graph vocabulary

Node kinds: `module`, `type`, `view`, `function`, `closure`, `property`, `state`, `observableState`, `binding`, `input`, `callback`, `derivedValue`, `event`, `effect`, `semanticValue`.

Edge kinds: `owns`, `reads`, `writes`, `binds`, `observes`, `injects`, `passes`, `calls`, `sets`, `copiesTo`, `derivesFrom`, `triggers`, `aliases`, `creates`, `typedAs`, `flowsTo`.

Schema v2 nodes may contain sorted exact `roles` and one `feature` supplied by validated project configuration. These are deterministic classification facts; absence is not permission to infer a role from spelling. `typedAs` links a declaration/input to its declared type, while `flowsTo` records bounded argument or closure-parameter flow.

Confidence values: `deterministic`, `strong-inference`, `candidate`, `llm-inferred`. Never promote a weaker fact merely because a remediation seems plausible.

## Audit JSON

An audit report contains `schemaVersion`, `toolVersion`, `resolution`, `configurationDigest`, `metrics`, `semanticValues`, and `findings`. A finding contains its stable `id`, `rule`, `severity`, `confidence`, referenced `nodes` and `edges`, `evidence`, `suggestedPatterns`, and optional tunnel `depth`.

Evidence uses repository-relative `file`, one-based `startLine`/`endLine`, and `kind`. Source locations are proof anchors, not permission to scan unrelated files.

An explicit `Binding(get:set:)` contributes a generated `binding` node, getter/setter closures, a `sets` edge identifying the setter, and enclosing control `binds` topology. `binding-factory` is evidence on that construction rather than a new schema kind. Source-count metrics count logical ownership roots, not every Binding projection or `Bindable` receiver.

## Slice JSON

An LLM slice contains `finding`, `semanticValues`, `nodes`, `edges`, `sourceEvidence`, `questions`, and `metadata`. Metadata records the selection, requested budget, conservative estimated tokens, and truncation. Mandatory context is retained; too-small budgets fail rather than silently dropping the envelope.

## Resolution and identity

- Accept only `indexed` results in this agent workflow.
- `indexed` adds compiler IndexStoreDB symbol/use facts on macOS and is required for cross-file ownership, propagation, callback, and computed-binding analysis.
- Pass a fresh validated Index Store explicitly for live-source commands; automatic discovery or fallback is not sufficient evidence for this workflow.
- Explicit index selection fails when the store, library, helper, or project coverage is invalid.
- Stable node, edge, semantic-value, finding, and change IDs do not use line number as primary identity.
- Compare snapshots only when graph and report resolution match on both sides, both are indexed, and their configuration digests match.

Canonical snapshots contain exactly `manifest.json`, `nodes.jsonl`, `edges.jsonl`, `findings.jsonl`, and `summary.json`. The manifest records the canonical configuration digest or `none`. Snapshots reject absolute evidence paths, dangling references, unsorted IDs, symlinks, unexpected files, unsafe outputs, and inconsistent schemas, resolutions, or configuration digests.
