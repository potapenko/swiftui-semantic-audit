# Findings, Snapshots, and Incremental Cache

- Node type: leaf
- Status: Active
- Contract revision: `spec-4`
- Authority: [Semantic IR contract](../semantic-ir.md)
- Read when: selecting semantic graph, evidence, normalization, finding, snapshot, cache, slice, diff, or resolution contracts.
- Do not read when: the task does not read, write, compare, or transport semantic data.
- Maximum size: 100 physical lines.


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
