# Set up continuous semantic project state

Release `0.6.0` adds continuous semantic project state. Current source prepares
an unpublished `0.6.1` patch candidate with managed timeout configuration and
selected-source analysis-config discovery. The explicit exact-state workflow
introduced in `0.5.0` remains available when watcher evidence is not.

The project watcher keeps a fast provisional preview and a freshness-qualified indexed snapshot ready for a coding agent. Source remains authoritative. Runtime state lives outside the repository; only the project manifest and an explicitly promoted canonical baseline are designed for Git.

## Release preflight

The immutable [installation guide](installation.md) installs public `0.6.0`.
The repaired setup behavior below requires a source candidate reporting `0.6.1`
and the matching repository skill bundle. Verify its surfaces:

```bash
swiftui-audit --version
swiftui-audit project --help
swiftui-audit project setup --help
swiftui-audit doctor . --format json
```

Continue only when the first command reports `0.6.1`, the project namespace is
present, and setup help lists `--watch-timeout`. `doctor` checks readiness and
accepts neither `--index-store` nor `--config`; it does not prove watcher
freshness. The status receipt below does.

## Agent setup

With the `0.6.1` candidate CLI and matching repository skills selected, ask:

```text
Use $swiftui-semantic to set up continuous semantic analysis for this project.
```

The router verifies the installed capability, previews setup, resolves only
explicit project ambiguity, applies the plan, starts the watcher, and waits
boundedly for fresh indexed evidence. It creates a baseline only when the user
also wants a Git-trackable semantic comparison point.

## Manual setup

Preview performs no writes:

```bash
swiftui-audit project setup . --format json
```

For an unambiguous Swift package, apply and start in one command:

```bash
swiftui-audit project setup . \
  --apply --start --format json
```

For Xcode, supply only fields that preview reports as blockers:

```bash
swiftui-audit project setup . \
  --container App.xcworkspace \
  --scheme App \
  --platform "iOS Simulator" \
  --source-root App \
  --watch-timeout 900 \
  --apply --start --format json
```

The tracked manifest is `.swiftui-audit/project.json`. It stores relative paths and a typed SwiftPM or Xcode build adapter; it never stores an arbitrary shell command. `--watch-timeout` is positive seconds for build plus indexed analysis and is written only while creating a new manifest:

```json
{
  "schemaVersion": 1,
  "watch": {
    "buildAndAnalysisTimeoutSeconds": 900,
    "debounceMilliseconds": 250,
    "indexQuiescenceMilliseconds": 1000
  }
}
```

The fragment omits the required source, build, and baseline members for brevity. Existing schema-1 manifests without `buildAndAnalysisTimeoutSeconds` retain the 300-second default. Setup never rewrites an existing manifest; edit its `watch` object deliberately when changing the value.

For a new manifest, setup uses a regular repository-root `.swiftui-audit.json` when present. If it is absent, setup checks only `.swiftui-audit.json` directly inside the selected `--source-root` and records that repository-relative path, such as `PlayphrasemeApp/.swiftui-audit.json`. It does not search descendants or infer roles. An existing manifest and its `analysisConfiguration` remain authoritative.

Add `--create-baseline` to the apply command only when an initial full-fidelity
comparison baseline is wanted.

## Freshness and status

Wait for agent-usable state:

```bash
swiftui-audit project status . --wait indexed --timeout 120 --format json
```

Require `fresh: true`, `resolution: "indexed"`, equal `workspaceDigest` and
`indexedWorkspaceDigest`, and the expected `configurationDigest`. The receipt
also names the `indexStorePath`, generation, `liveSnapshotPath`, baseline path,
compatibility and diff data when available, plus a compact last error.

Use `liveSnapshotPath` only with that same status receipt. A snapshot path from
another generation, a provisional preview, or stale status is not agent evidence.

Once a file change is observed, or a status query recomputes a different current
workspace digest, the prior indexed generation is stale. A provisional preview
can still update, but agent conclusions wait for a successful build and
compiler-index enrichment. Build failure preserves the last snapshot only as
stale diagnostics.

## Baseline lifecycle

Before an intended refactor, promote the current fresh state:

```bash
swiftui-audit project baseline update . --format json
```

After editing, wait for a later fresh generation and compare `.swiftui-audit/baseline` with the returned `liveSnapshotPath`. Baseline promotion never stages or commits files and is never automatic after an edit.

The Git baseline is optional. Omit `--create-baseline` when the external live mirror is enough, and inspect the five-file baseline size before choosing to commit it for a large project. The baseline stays full-fidelity so existing `diff`, `check`, and bounded-slice workflows can consume it without a second schema.

## Lifecycle

```bash
swiftui-audit project start . --format json
swiftui-audit project stop . --format json
swiftui-audit project watch . --format json
swiftui-audit project watch . --once --format json
```

Since `0.6.0`, `watch` is foreground. `start`, `status`, and `stop` manage one
bounded per-project background worker. Agent readiness comes
only from a fresh `status --wait indexed` receipt. `stop` affects only that
project, and schema 1 does not enable login autostart. Foreground
`project watch --timeout <seconds>` overrides the manifest for that process;
otherwise the manifest value is used. `project start` records the manifest
timeout in the managed service arguments, so after changing it run `project
stop` and then `project start` to register the new value.

Runtime snapshots, status, locks, service metadata, and bounded logs are under
`~/Library/Application Support/swiftui-audit/projects/<project-id>/`; reusable
analysis facts remain under the user cache directory.

Next: [Run a first audit](first-audit.md) or [CLI reference](../reference/cli.md).
