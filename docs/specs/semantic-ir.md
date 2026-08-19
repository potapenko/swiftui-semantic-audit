# Semantic IR contract

- Node type: hybrid
- Status: Active
- Contract revision: `spec-4`
- Read when: selecting semantic graph, evidence, normalization, finding, snapshot, cache, slice, diff, or resolution contracts.
- Do not read when: the task does not read, write, compare, or transport semantic data.
- Maximum size: 100 physical lines.

Revision: `spec-4`
Schema: `2`
Status: active

## Choose the governing child

- [Semantic Graph, Evidence, and Values](semantic-ir/graph-evidence-and-values.md) — graph schema, provenance, confidence, semantic values, and normalization.
<a id="persistent-snapshot"></a>
- [Findings, Snapshots, and Incremental Cache](semantic-ir/findings-snapshots-and-cache.md) — audit reports, five-file persistence, deterministic replacement, and non-authoritative cache facts.
- [Context Slice, Semantic Diff, and Resolution](semantic-ir/slice-diff-and-resolution.md) — bounded LLM envelopes, comparisons, check reports, and resolution integrity.
