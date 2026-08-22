# Set up continuous semantic project state

This page documents the unreleased 0.6.0 candidate. Release 0.5.0 remains the current Homebrew installation until a separate publication.

The project watcher keeps a fast provisional preview and a freshness-qualified indexed snapshot ready for a coding agent. Source remains authoritative. Runtime state lives outside the repository; only the project manifest and an explicitly promoted canonical baseline are designed for Git.

## Candidate preflight

The released Homebrew formula is still `0.5.0` and does not provide the project
namespace. Use a candidate build from a checkout that reports both:

```bash
swiftui-audit --version
swiftui-audit project --help
```

Continue only when the first command reports `0.6.0` and the second lists the
project commands. The examples below assume that candidate binary is first on
`PATH`.

## Agent setup

In a checkout that contains the 0.6.0 CLI and updated skills, ask:

```text
Use $swiftui-semantic to set up continuous semantic analysis for this project.
```

The router verifies the candidate capability, previews setup, resolves only
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
  --apply --start --format json
```

The tracked manifest is `.swiftui-audit/project.json`. It stores relative paths and a typed SwiftPM or Xcode build adapter; it never stores an arbitrary shell command.

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

In the current 0.6.0 candidate, `watch` is foreground. `start` registers one
per-project launchd service and returns without waiting for an indexed
generation; readiness comes only from the later `status --wait indexed`
receipt. `stop` affects only that project. Schema 1 does not enable login
autostart. The recorded service state describes the last analysis transition;
do not treat it as an independent process-liveness probe.

Runtime snapshots, status, locks, service metadata, and logs are under
`~/Library/Application Support/swiftui-audit/projects/<project-id>/`; reusable
analysis facts remain under the user cache directory.

Next: [Run a first audit](first-audit.md) or [CLI reference](../reference/cli.md).
