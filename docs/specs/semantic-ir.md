# Semantic IR contract

Revision: `spec-4`
Schema: `2`
Status: active

## Graph model

**IR-GRAPH-001 — Properties.** The IR is versioned, deterministic, serializable, graph-queryable, compact, reasonably language-independent, and SwiftUI-aware.

**IR-GRAPH-002 — Node kinds.** Schema v1 admits:

```text
module type view function closure property state observableState binding
input callback derivedValue event effect semanticValue
```

**IR-GRAPH-003 — Edge kinds.** Schema v1 admits:

```text
owns reads writes binds observes injects passes calls sets copiesTo
derivesFrom triggers aliases creates
```

**IR-GRAPH-004 — Stable node.** A node contains stable `id`, `kind`, short `name`, `qualifiedName`, evidence, and confidence.

**IR-GRAPH-005 — Stable edge.** An edge contains stable `id`, `kind`, `from`, `to`, evidence, and confidence. Endpoints must exist in the same graph.

**IR-GRAPH-006 — Canonical graph.** A graph contains `schemaVersion`, `resolution`, sorted nodes, and sorted edges. Canonical JSON is pretty-printed with sorted keys, unescaped slashes, and a trailing newline.

**IR-GRAPH-007 — Explicit Binding construction.** Represent `Binding(get:set:)` with a generated `binding` node using `binding-construction` evidence. The node creates its getter and setter closures; a `sets` edge identifies the setter role, and enclosing controls may bind to the constructed node. A factory context is recorded as evidence without adding a schema-v2 node or edge kind.

**IR-GRAPH-008 — Typed architecture facts.** Schema v2 adds `typedAs` and `flowsTo` edge kinds. `typedAs` connects a declaration/input to its declared type. `flowsTo` preserves non-assignment argument/closure-parameter value flow used by geometry, focus, selection, and effect rules. Nodes may carry sorted configured `roles` and one optional `feature`; these are deterministic configuration facts, not inferred names.

**IR-GRAPH-009 — Collision-safe frontend identity.** Syntax nodes carry relative-file and lexical structural discriminators until an indexed declaration/use can be remapped to its compiler USR. Multiple provisional nodes may share a human `qualifiedName`; selectors must reject ambiguity.

## Evidence and confidence

**IR-EVID-001 — Provenance.** Every nontrivial semantic fact carries evidence with repository-relative `file`, one-based `startLine`, `endLine`, and an extraction `kind`.

**IR-EVID-002 — Canonical evidence.** Deduplicate and order evidence by file, start, end, and kind.

**IR-EVID-003 — Confidence.** Use exactly:

- `deterministic` for syntax/compiler facts;
- `strong-inference` for topology-backed rule/normalization conclusions;
- `candidate` for insufficiently adjudicated relations;
- `llm-inferred` for external reasoning metadata.

Never upgrade confidence because an intended remediation seems likely.

**IR-EVID-004 — LLM separation.** Classification, semantic names, intent, risk, and remediation may be external inferences. AST/symbol/read/write/source facts remain immutable deterministic evidence.

## Semantic values and normalization

**IR-VALUE-001 — Logical value.** A semantic value groups multiple symbols that represent the same logical value. It contains a stable ID, sorted representation node IDs, relation edge IDs, confidence, optional classification, and evidence.

**IR-VALUE-002 — Evidence order.** Prefer direct assignment, Binding projection, get/set pairs, initializer forwarding, callback writes to the upstream value, and bidirectional identity synchronization. Name similarity, matching type, and nearby UI are insufficient by themselves.

**IR-VALUE-003 — Transformation boundary.** Use derivation edges for non-identity transformation; do not identity-cluster transformed representations automatically.

**IR-VALUE-004 — Transaction classification.** A topology with real commit and discard behavior may classify as `transactional-draft`; wrapper/property names alone must not establish or suppress the classification.

## Findings and metrics

**IR-AUDIT-001 — Finding.** A finding includes stable `id`, rule, severity, confidence, sorted referenced nodes/edges, canonical evidence, sorted suggested patterns, and optional tunnel depth.

**IR-AUDIT-002 — Audit report.** An audit report contains schema/tool versions, resolution, metrics, semantic values, and canonically ordered findings.

**IR-AUDIT-003 — Raw metrics.** Track mutable semantic values, state representations, Binding edges, manual synchronization edges, callback tunnels, derived mutable values, duplicated sources of truth, and ownership violations.

**IR-AUDIT-004 — Suggestions.** Suggested patterns are candidates, not edits or proof of intent.

**IR-AUDIT-005 — Logical sources.** Source counts operate on a normalized semantic value. Count owned mutable roots plus at most one unconnected external borrowed root. Do not count each Binding projection or `@Bindable` receiver independently; preserve a distinct external root when a local State mirrors it without an upstream pass/alias path.

## Persistent snapshot

**IR-SNAP-001 — Exact layout.** A canonical snapshot directory contains only:

```text
manifest.json
nodes.jsonl
edges.jsonl
findings.jsonl
summary.json
```

**IR-SNAP-002 — Manifest.** `manifest.json` contains schema/tool/Swift versions, repository revision, relative `generatedFrom`, and the canonical analysis-configuration digest or `none`.

**IR-SNAP-003 — JSONL.** Nodes, edges, and findings use one sorted compact JSON record per line with a final newline. Summary JSON contains resolution, counts, metrics, and semantic values.

**IR-SNAP-004 — Integrity.** Readers reject missing/unexpected/non-regular/symlink entries, malformed records, duplicate or unsorted IDs, dangling graph/finding/value references, count mismatch, absolute paths, and inconsistent schema/resolution.

**IR-SNAP-005 — Replacement.** Writers stage then atomically replace only an empty directory or a valid existing snapshot. They restore the prior valid snapshot if replacement fails.

**IR-SNAP-006 — Determinism.** Repeated generation over unchanged source, toolchain, revision, and resolution must be byte-equivalent across all five files. A committed baseline compared from a later commit must match `nodes.jsonl`, `edges.jsonl`, `findings.jsonl`, and `summary.json` byte for byte. Normalize only `manifest.json.repositoryRevision` for that cross-commit comparison; require schema, tool version, Swift version, relative `generatedFrom`, and all semantic counts/resolution to remain exact, and require the fresh manifest revision to equal the current `HEAD`.

## Incremental cache

**IR-CACHE-001 — Non-authoritative facts.** The cache stores deterministic intermediate frontend or compiler-index facts, never agent conclusions. A cache entry is usable only when its complete layer-specific identity matches; otherwise the analyzer rebuilds that entry.

**IR-CACHE-002 — File identity and invalidation.** Frontend entries are identified by normalized relative path, source SHA-256, module identity, tool version, graph schema, and cache schema. Declaration-surface changes conservatively invalidate files whose recorded lexical identifiers may depend on the changed names. Add, delete, rename, configuration, compiler, and index-unit changes must not leave stale nodes, edges, evidence, roles, features, or resolution.

**IR-CACHE-003 — Equivalence and isolation.** Warm-cache and uncached graph/report bytes are identical. Cache artifacts live outside the five-file snapshot, store no source text, use relative source provenance, and use immutable or atomic writes safe against partial concurrent writers.

## Context slice

**IR-SLICE-001 — Envelope.** LLM JSON contains `finding`, `semanticValues`, `nodes`, `edges`, `sourceEvidence`, `questions`, and metadata.

**IR-SLICE-002 — Selection.** Select exactly one finding ID or stable/qualified/unambiguous symbol. Reject unknown or ambiguous selectors.

**IR-SLICE-003 — Budget.** Retain the mandatory finding/value/topology/evidence envelope. Apply a conservative byte-based token estimate, mark truncation, and fail when the requested positive budget cannot fit mandatory context.

**IR-SLICE-004 — Minimality.** Bound graph traversal and prioritize finding, affected values, ownership, read/write paths, evidence, and nearby relevant operations. Do not send the full graph by default.

## Semantic diff

**IR-DIFF-001 — Inputs.** Compare valid snapshots or reconstructed Git revisions with matching resolution.

**IR-DIFF-002 — Change kinds.** Emit:

```text
NODE_ADDED NODE_REMOVED OWNERSHIP_CHANGED
READ_PATH_ADDED READ_PATH_REMOVED WRITE_PATH_ADDED WRITE_PATH_REMOVED
BINDING_ADDED BINDING_REMOVED MANUAL_SYNC_ADDED MANUAL_SYNC_REMOVED
DERIVATION_CHANGED SOURCE_OF_TRUTH_COUNT_CHANGED
```

**IR-DIFF-003 — Report.** Include base/current identities, before/after metrics, canonical changes, new/resolved findings, and affected semantic values with representation/source counts.

**IR-DIFF-004 — Continuity.** Match stable identities and exact-qualified semantic continuity conservatively. A true rename may appear as node removal plus addition.

**IR-DIFF-005 — Check report.** Include baseline/current identity, severity threshold, pass state, total new findings, and failing findings. Only new findings at or above the threshold fail policy.

## Resolution

**IR-RES-001.** Use `resolution: "syntax-only"` for frontend-only graphs and `resolution: "indexed"` only after accepted compiler-index enrichment.

**IR-RES-002.** Preserve resolution consistently across graph, audit report, snapshot, slice, diff, and check. Reject mixed or internally inconsistent inputs.

**IR-RES-003.** Indexed enrichment occurs after collision-safe syntax extraction and remaps every unambiguous declaration/use to compiler USR identity while preserving configured roles, feature, evidence, and topology.
