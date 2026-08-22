# CLI project setup and watcher

- Node type: leaf
- Status: Active
- Contract revision: `spec-1`
- Authority: [CLI contract](../cli.md) and [project runtime](../project-runtime.md)
- Read when: invoking or integrating the `project` namespace.
- Maximum size: 100 physical lines.

## Shape

**CLI-PRJ-001.** Add one public top-level namespace without changing existing command semantics:

```text
swiftui-audit project setup [<path>] [--apply] [--start] [--create-baseline] [--format json]
swiftui-audit project watch [<path>] [--once] [--format json]
swiftui-audit project start [<path>] [--format json]
swiftui-audit project status [<path>] [--wait indexed] [--timeout <seconds>] [--format json]
swiftui-audit project stop [<path>] [--format json]
swiftui-audit project baseline update [<path>] [--format json]
```

**CLI-PRJ-002.** Project commands use deterministic JSON on stdout and diagnostics on stderr. Setup conflicts, invalid manifests, lock contention, service failure, wait timeout, stale evidence, and baseline incompatibility exit nonzero.

**CLI-PRJ-003.** `setup` defaults to a non-mutating canonical plan. `--apply` is required for repository or application-state writes. `--start` and `--create-baseline` are valid only with `--apply`.

**CLI-PRJ-004.** `watch --once` performs one generation and exits; plain `watch` remains foreground and responds to termination. `start` is idempotent and waits boundedly for the worker to publish starting/running status.

**CLI-PRJ-005.** `status --wait indexed` succeeds only for a fresh indexed generation and fails on its positive timeout. `baseline update` requires that same condition and never mutates Git staging or history.
