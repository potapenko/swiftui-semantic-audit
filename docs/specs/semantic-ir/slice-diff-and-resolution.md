# Context Slice, Semantic Diff, and Resolution

- Node type: leaf
- Status: Active
- Contract revision: `spec-4`
- Authority: [Semantic IR contract](../semantic-ir.md)
- Read when: selecting semantic graph, evidence, normalization, finding, snapshot, cache, slice, diff, or resolution contracts.
- Do not read when: the task does not read, write, compare, or transport semantic data.
- Maximum size: 100 physical lines.


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
