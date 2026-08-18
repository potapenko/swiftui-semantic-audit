# Outputs, snapshots, and semantic diff

The CLI exposes one semantic model through several transports: graph JSON, audit JSON, a five-file snapshot, an LLM-ready slice, semantic diff, and check policy. Resolution and configuration identity travel with the evidence.

## Graph output

`scan` emits a canonical graph with:

- `schemaVersion`;
- `resolution`;
- deterministically ordered nodes;
- deterministically ordered edges;
- configured roles/features and configuration digest where applicable.

Nodes have stable IDs, kinds, names, qualified names, evidence, and confidence. Edges have stable IDs, kinds, endpoints, evidence, and confidence. Every endpoint must exist in the same graph.

The current schema includes ownership, reads, writes, bindings, observation, injection, passing, calls, sets, identity copies, derivation, triggers, aliases, creation, declared types, and bounded value flow.

## Audit output

`audit --format json` adds:

- tool version;
- raw metrics;
- normalized semantic values;
- findings.

A semantic value groups representations of one logical value when topology supports that relation. It does not group values from naming or type similarity alone.

Raw metrics include mutable semantic values, state representations, Binding edges, manual synchronization edges, callback tunnels, derived mutable values, duplicated sources of truth, and ownership violations. Keep the raw numbers; an aggregate improvement never replaces behavior and invariant checks.

## Snapshot layout

`snapshot` persists exactly:

```text
manifest.json
nodes.jsonl
edges.jsonl
findings.jsonl
summary.json
```

### `manifest.json`

Records schema version, tool version, Swift version, repository revision, relative `generatedFrom`, and the canonical configuration digest or `none`.

### JSONL files

`nodes.jsonl`, `edges.jsonl`, and `findings.jsonl` contain one compact, sorted JSON record per line, ending with a newline.

### `summary.json`

Records resolution, entity counts, raw metrics, and semantic values.

## Snapshot safety

Readers reject:

- missing or unexpected files;
- non-regular files and symlinks;
- malformed or unsorted records;
- duplicate IDs and dangling references;
- inconsistent counts, schema, resolution, or configuration;
- absolute evidence paths;
- unsafe source/output relationships.

Writers stage output before replacement. They replace only an empty directory or an existing valid snapshot and restore the prior valid snapshot if replacement fails. The accepted design supports one writer; it does not provide a concurrent-writer lock.

## Determinism

Repeated snapshot generation from unchanged source, toolchain, repository revision, configuration, and resolution is byte-identical across all five files.

When comparing a committed baseline after a later commit:

- the four semantic files remain byte-exact;
- only `manifest.json.repositoryRevision` may be normalized;
- every other manifest field must remain exact;
- the fresh manifest revision must equal checked-out `HEAD`.

This distinction prevents a new commit hash from making unchanged semantic evidence look unstable.

## Bounded slices

`slice --format llm-json` selects exactly one finding or symbol and emits:

- finding;
- semantic values;
- relevant nodes and edges;
- source evidence;
- questions and metadata.

The mandatory envelope keeps the selected finding, affected values, ownership, read/write paths, and evidence. Traversal is bounded. Token estimation is conservative and byte-based; the command fails when a positive budget cannot fit the mandatory content.

## Semantic diff

`diff` compares compatible snapshots or syntax-only Git revisions. It can report:

```text
NODE_ADDED
NODE_REMOVED
OWNERSHIP_CHANGED
READ_PATH_ADDED
READ_PATH_REMOVED
WRITE_PATH_ADDED
WRITE_PATH_REMOVED
BINDING_ADDED
BINDING_REMOVED
MANUAL_SYNC_ADDED
MANUAL_SYNC_REMOVED
DERIVATION_CHANGED
SOURCE_OF_TRUTH_COUNT_CHANGED
```

The report includes base/current identities, metric changes, new and resolved findings, and affected semantic values with representation and source counts.

Continuity is conservative. A true rename can appear as node removal plus addition rather than a guessed identity match.

## Check policy

`check` combines compatible current analysis with a baseline and a severity threshold. It fails only for new findings at or above that threshold.

The JSON report records:

- baseline and current identity;
- selected threshold;
- pass state;
- total new findings;
- failing findings.

Policy failure exits `2`. A passing check means the selected new-finding policy passed. It does not mean behavior tests passed, every legacy finding is gone, or the architecture is globally clean.

## Comparison integrity

Never compare:

- indexed evidence with syntax-only evidence;
- snapshots with different schema versions;
- snapshots with different configuration digests;
- failed or partial output as if it were an empty result.

For agent change review, use compatible indexed snapshots. Git revision operands are intentionally syntax-only and therefore belong to standalone comparison, not the indexed agent-review workflow.

Normative detail: [`docs/specs/semantic-ir.md`](../specs/semantic-ir.md).
