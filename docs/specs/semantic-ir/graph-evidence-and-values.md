# Semantic Graph, Evidence, and Values

- Node type: leaf
- Status: Active
- Contract revision: `spec-5`
- Authority: [Semantic IR contract](../semantic-ir.md)
- Read when: selecting semantic graph, evidence, normalization, finding, snapshot, cache, slice, diff, or resolution contracts.
- Do not read when: the task does not read, write, compare, or transport semantic data.
- Maximum size: 100 physical lines.


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

**IR-GRAPH-010 — Component classification.** Config schema 2 uses existing schema-v2 node `roles` for exact `screen`, `container`, `reusable-component`, `component-model`, and passive-environment facts. No node or edge kind is added, roles remain sorted, and absence of a role remains unknown rather than an inferred classification.

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
