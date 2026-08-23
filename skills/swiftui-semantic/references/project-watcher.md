# Project watcher setup and freshness

Read [the CLI invocation matrix](cli-invocation-matrix.md) before forming a
command. No `project` subcommand accepts `--index-store` or `--config`; the
watcher owns the typed build and reports the selected identities through fresh
status.

## Verify the watcher capability

Run both commands before any project operation:

```bash
swiftui-audit --version
swiftui-audit project --help
swiftui-audit project setup --help
```

Public release `0.6.0` contains the base watcher. The managed-timeout and
selected-source configuration behavior in this reference requires the
unpublished `0.6.1` candidate or a later compatible release: require version
`0.6.1` for the current candidate, a working `project` namespace, and
`--watch-timeout` in setup help. If the capability check fails, do not pass the
new option or imply that immutable `0.6.0` contains the repair. Use the selected
specialist's explicit exact-state Index Store workflow instead, or tell the user
which watcher capability is missing.

## Set up one project

1. Run `swiftui-audit doctor <project-root> --format json` with the verified
   candidate binary. It diagnoses readiness without selecting a store. The
   command accepts neither `--index-store` nor `--config`.
2. Preview without mutation. For a new manifest whose indexed build can exceed
   300 seconds, set a positive managed timeout in that same plan:

   ```bash
   swiftui-audit project setup <project-root> --watch-timeout 900 --format json
   ```

3. Parse the plan. Resolve only an explicit blocker such as source root, Xcode container, shared scheme, or platform. Never infer product roles or generate `.swiftui-audit.json` entries from names. A root `.swiftui-audit.json` has precedence; only when it is absent may setup record the regular file directly inside the selected source root. Setup does not search descendants.
4. Apply and start the managed watcher:

   ```bash
   swiftui-audit project setup <project-root> --watch-timeout 900 \
     --apply --start --format json
   ```

5. Wait boundedly for agent-usable evidence:

   ```bash
   swiftui-audit project status <project-root> --wait indexed --timeout 120 --format json
   ```

6. Require `fresh: true`, `resolution: "indexed"`, equal `workspaceDigest` and `indexedWorkspaceDigest`, a regular five-file `liveSnapshotPath`, and the expected `configurationDigest`. Preserve the returned `indexStorePath` and generation. Report tracked manifest/baseline paths separately from the external runtime root. Setup never stages or commits files.

Add `--create-baseline` to step 4 only when the user wants an initial
full-fidelity comparison baseline. Continuous external live state does not
require a Git baseline.

`--watch-timeout` applies only while creating a manifest. An existing manifest
is authoritative and setup never rewrites it; a legacy schema-1 manifest without
`buildAndAnalysisTimeoutSeconds` retains 300 seconds. To change an existing
project, deliberately edit that member, run `project stop`, then run `project
start` so the managed service receives new launch arguments. A foreground
`project watch --timeout <seconds>` remains the highest-precedence override for
that process.

## Reuse continuous state

When `.swiftui-audit/project.json` exists, run `project start` idempotently, then
obtain the bounded fresh status before a specialist performs a manual build.
`start` only registers the service; it does not prove readiness. The receipt's
live snapshot may replace repeated live-source extraction only while every
freshness field matches. Use its `indexStorePath`, configuration digest,
generation, and snapshot path unchanged across handoff.

For a refactor, promote a fresh pre-edit state deliberately:

```bash
swiftui-audit project baseline update <project-root> --format json
```

After edits, wait for a later fresh generation and compare the manifest baseline with the returned live snapshot. Never promote automatically after an edit.

If status is stale, failed, incompatible, timed out, or absent, do not use the watcher snapshot. Either repair/start the configured watcher or return to the specialist's explicit fresh Index Store workflow. Never weaken the indexed requirement.

## Operate safely

- `project watch` is foreground; `project start` and `project stop` manage only the selected project service.
- Managed `project start` registers the manifest timeout; restart the selected service after changing it.
- Treat build failures and the last stale snapshot as diagnostics, not current semantic evidence.
- Runtime state and bounded logs remain outside repositories. Only the explicit project manifest and canonical baseline are durable repository artifacts.
- Do not edit, stage, commit, or remove project files unless the user authorized that surrounding task.
