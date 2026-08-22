# Project watcher setup and freshness

## Set up one project

1. Use the installed `swiftui-audit` binary and run `swiftui-audit doctor <project-root> --format json`.
2. Preview without mutation:

   ```bash
   swiftui-audit project setup <project-root> --format json
   ```

3. Parse the plan. Resolve only an explicit blocker such as source root, Xcode container, shared scheme, or platform. Never infer product roles or generate `.swiftui-audit.json` entries from names.
4. Apply, create the initial indexed baseline, and start the managed watcher:

   ```bash
   swiftui-audit project setup <project-root> --apply --create-baseline --start --format json
   ```

5. Wait boundedly for agent-usable evidence:

   ```bash
   swiftui-audit project status <project-root> --wait indexed --timeout 120 --format json
   ```

6. Require `fresh: true`, `resolution: "indexed"`, equal `workspaceDigest` and `indexedWorkspaceDigest`, a regular five-file `liveSnapshotPath`, and the expected configuration digest. Report the tracked manifest/baseline paths separately from the external runtime root. Setup never stages or commits files.

## Reuse continuous state

When `.swiftui-audit/project.json` exists, run `project start` idempotently and obtain the bounded fresh status before a specialist performs a manual build. The receipt's live snapshot may replace repeated live-source extraction only while every freshness field matches. Use its `indexStorePath`, configuration digest, generation, and snapshot path unchanged across handoff.

For a refactor, promote a fresh pre-edit state deliberately:

```bash
swiftui-audit project baseline update <project-root> --format json
```

After edits, wait for a later fresh generation and compare the manifest baseline with the returned live snapshot. Never promote automatically after an edit.

If status is stale, failed, incompatible, timed out, or absent, do not use the watcher snapshot. Either repair/start the configured watcher or return to the specialist's explicit fresh Index Store workflow. Never weaken the indexed requirement.

## Operate safely

- `project watch` is foreground; `project start` and `project stop` manage only the selected project service.
- Treat build failures and the last stale snapshot as diagnostics, not current semantic evidence.
- Runtime state and logs remain outside repositories. Only the explicit project manifest and canonical baseline are durable repository artifacts.
- Do not edit, stage, commit, or remove project files unless the user authorized that surrounding task.
