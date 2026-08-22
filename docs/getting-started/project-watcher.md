# Set up continuous semantic project state

This page documents the unreleased 0.6.0 candidate. Release 0.5.0 remains the current Homebrew installation until a separate publication.

The project watcher keeps a fast provisional preview and a freshness-qualified indexed snapshot ready for a coding agent. Source remains authoritative. Runtime state lives outside the repository; only the project manifest and an explicitly promoted canonical baseline are designed for Git.

## Agent setup

In a checkout that contains the 0.6.0 CLI and updated skills, ask:

```text
Use $swiftui-semantic to set up continuous semantic analysis for this project.
```

The router checks the environment, previews setup, resolves only explicit project ambiguity, applies the plan, creates an initial indexed baseline, starts the watcher, and waits boundedly for fresh evidence.

## Manual setup

Preview performs no writes:

```bash
swiftui-audit project setup . --format json
```

For an unambiguous Swift package, apply and start in one command:

```bash
swiftui-audit project setup . \
  --apply --create-baseline --start --format json
```

For Xcode, supply only fields that preview reports as blockers:

```bash
swiftui-audit project setup . \
  --container App.xcworkspace \
  --scheme App \
  --platform "iOS Simulator" \
  --source-root App \
  --apply --create-baseline --start --format json
```

The tracked manifest is `.swiftui-audit/project.json`. It stores relative paths and a typed SwiftPM or Xcode build adapter; it never stores an arbitrary shell command.

## Freshness and status

Wait for agent-usable state:

```bash
swiftui-audit project status . --wait indexed --timeout 120 --format json
```

Require `fresh: true`, `resolution: "indexed"`, and equal workspace/indexed digests. The receipt also carries the exact Index Store, configuration digest, generation, live snapshot, baseline path, compatibility, and compact diff counts.

A file change immediately makes the previous indexed generation stale. A provisional preview can still update, but agent conclusions wait for a successful build and compiler-index enrichment. Build failure preserves the last snapshot only as stale diagnostics.

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

`watch` is foreground. `start` registers one bounded per-project launchd service for the current login session. `stop` affects only that project. Schema 1 does not enable login autostart.

Runtime snapshots, status, locks, service metadata, and bounded logs are under `~/Library/Application Support/swiftui-audit/projects/<project-id>/`; reusable analysis facts remain under the user cache directory.

Next: [Run a first audit](first-audit.md) or [CLI reference](../reference/cli.md).
