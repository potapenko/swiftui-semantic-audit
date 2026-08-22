# Project setup and watcher runtime contract

- Node type: leaf
- Status: Active
- Contract revision: `spec-1`
- Authority: `PROJECT-WATCHER-001`, epoch `tz-v17`
- Read when: setting up, starting, querying, stopping, or integrating continuous project analysis.
- Do not read when: using only the existing one-shot analysis commands.
- Maximum size: 100 physical lines.

## Project manifest and setup

**PRJ-CFG-001.** Discover only `.swiftui-audit/project.json` at the selected project root. Schema 1 stores one relative source root, an optional relative `.swiftui-audit.json` path, one typed build adapter, watcher timing, and a relative canonical baseline path. Multi-root workspaces remain a later compatible schema extension.

**PRJ-CFG-002.** Paths reject emptiness, absolutes, traversal, symlink escapes, source/baseline overlap, and roots outside the project. Setup never infers product roles or writes `.swiftui-audit.json` from names.

**PRJ-SETUP-001.** `project setup` is preview-only without `--apply`. Preview and apply expose the same canonical plan. Apply creates only absent planned files/directories, accepts byte-identical existing files, and rejects unknown or conflicting contents.

**PRJ-SETUP-002.** Discovery may select SwiftPM or one unambiguous Xcode container/scheme. Ambiguity is a machine-readable blocker, not permission to guess. Typed adapters own exact bounded arguments; tracked manifests do not execute arbitrary shell strings.

## Runtime state and freshness

**PRJ-STATE-001.** Cache stays in the user cache root. Live snapshots, status, locks, launch metadata, and bounded logs live under an explicit application-state root keyed by canonical project identity. Runtime artifacts never enter the source repository.

**PRJ-STATE-002.** Status records project/tool/manifest identity, monotonic generation, workspace digest, service state, syntax-preview state, indexed state, Index Store identity, configuration digest, live snapshot path, baseline compatibility, last semantic-diff summary, and a compact last error.

**PRJ-FRESH-001.** An indexed generation is fresh only when its workspace digest equals the current watched inputs, explicit Index Store coverage validates, graph/report resolution is `indexed`, and configuration identity matches. A later event immediately makes the prior indexed generation stale.

**PRJ-FRESH-002.** Syntax preview is provisional and never satisfies an agent workflow's indexed requirement. Build or enrichment failure preserves the last valid snapshot only as stale evidence and reports the failure.

**PRJ-FRESH-003.** Events are coalesced and debounced. At most one analysis generation writes at a time. Superseded work cannot publish as current. Every published snapshot uses the existing validated atomic five-file writer.

## Lifecycle and baseline

**PRJ-LIFE-001.** `project watch` runs in the foreground. `start`, `status`, and `stop` manage one bounded per-project background worker. A runtime lock rejects a second writer. Login autostart is not part of schema 1.

**PRJ-LIFE-002.** External builds, service operations, and waits have positive timeouts. Default logs are concise; verbose tracing is opt-in. Stop affects only the selected project service.

**PRJ-BASE-001.** Baseline promotion requires a fresh indexed live snapshot and atomically writes the existing exact five-file format to the manifest's repository-relative baseline destination. It never stages or commits Git changes.

**PRJ-AGENT-001.** Installed agent workflows may consume a watcher snapshot only with a matching fresh status receipt. Otherwise they wait boundedly or use the existing explicit Index Store live-source path; they never downgrade to syntax-only conclusions.
