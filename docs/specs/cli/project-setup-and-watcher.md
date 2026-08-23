# CLI project setup and watcher

- Node type: leaf
- Status: Active
- Contract revision: `spec-3`
- Authority: [CLI contract](../cli.md), [project runtime](../project-runtime.md), and `PROJECT-WATCHER-INTEGRATION-001`
- Read when: invoking or integrating the `project` namespace.
- Maximum size: 100 physical lines.

## Shape

**CLI-PRJ-001.** Add one public top-level namespace without changing existing command semantics:

```text
swiftui-audit project setup [<path>] [--apply] [--start] [--create-baseline]
                            [--source-root <path>] [--container <path>]
                            [--scheme <name>] [--platform <name>]
                            [--watch-timeout <seconds>] [--format json]
swiftui-audit project watch [<path>] [--once] [--timeout <seconds>] [--format json]
swiftui-audit project start [<path>] [--format json]
swiftui-audit project status [<path>] [--wait indexed] [--timeout <seconds>] [--format json]
swiftui-audit project stop [<path>] [--format json]
swiftui-audit project baseline update [<path>] [--format json]
```

**CLI-PRJ-002.** Project commands use deterministic JSON on stdout and diagnostics on stderr. Setup conflicts, invalid manifests, lock contention, service failure, wait timeout, stale evidence, and baseline incompatibility exit nonzero.

**CLI-PRJ-003.** `setup` defaults to a non-mutating canonical plan. `--source-root`, `--container`, `--scheme`, `--platform`, and positive `--watch-timeout` are explicit inputs to that same preview/apply plan and never bypass manifest path safety or ambiguity checks. The timeout applies only while creating a manifest; an existing manifest remains authoritative and is never rewritten. `--apply` is required for repository or application-state writes. `--start` and `--create-baseline` are valid only with `--apply`.

**CLI-PRJ-004.** `watch --once` performs one generation and exits; plain `watch` remains foreground and responds to termination. An explicit positive `watch --timeout` bounds and overrides the manifest for its build-and-analysis attempts; omission uses the manifest value, including the legacy 300-second default. `start` is idempotent and registers the manifest timeout explicitly for the managed worker.

**CLI-PRJ-005.** `status --wait indexed` succeeds only for a fresh indexed generation and fails on its positive timeout. `baseline update` requires that same condition and never mutates Git staging or history.

**CLI-PRJ-006.** No `project` subcommand accepts live-source analysis options `--syntax-only`, `--index-store`, `--config`, `--cache-directory`, `--no-cache`, or `--jobs`. The project manifest and watcher own typed builds, configuration identity, cache/runtime state, Index Store selection, and freshness qualification.
