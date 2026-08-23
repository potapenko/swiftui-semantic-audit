# CLI invocation matrix

Read this reference before forming a `swiftui-audit` command. Options belong to
the command and input kind shown below; do not carry an option from one command
to the next merely because both participate in the same workflow.

| Command and input | `--index-store` | `--config` | Indexed evidence rule |
| --- | --- | --- | --- |
| `doctor [<project-root>] --format json` | Never accepted | Never accepted | Checks environment and automatically discoverable readiness; it does not validate one explicitly selected store. |
| Live-source `scan`, `audit`, `snapshot`, or `check` | Required for an agent workflow | Pass when authoritative classification is needed, or when `check` must match a configured baseline | Require JSON `resolution: "indexed"`. |
| Live-source `slice` | Required for an agent workflow | Match the live analysis configuration | Require slice metadata to preserve indexed resolution. |
| `slice <persisted-snapshot>` | Never accepted | Never accepted | Validate that the snapshot itself is indexed and has the expected configuration digest. |
| `diff <snapshot> <snapshot>` | Never accepted | Never accepted | Both snapshots must already be indexed and configuration-compatible. |
| Any `project` subcommand | Never accepted | Never accepted | The watcher owns the typed build. A status receipt is usable only with `fresh: true` and `resolution: "indexed"`; it exposes `indexStorePath`, workspace/configuration identities, generation, and `liveSnapshotPath`. |

Only live-source analysis commands accept live cache and job controls. Do not
add `--cache-directory`, `--no-cache`, or `--jobs` to `doctor`, persisted-snapshot
`slice`, `diff`, or a `project` subcommand.

## Select and prove the exact Index Store

1. Use the project build output or a matching fresh watcher status receipt to
   identify the exact raw Index Store path.
2. Run `doctor` separately when environment readiness needs diagnosis:

   ```bash
   swiftui-audit doctor <project-root> --format json
   ```

   Never append `--index-store` or `--config` to this command.
3. Prove the selected path by passing it to the first live-source analysis
   command and requiring `resolution: "indexed"` in that command's JSON:

   ```bash
   swiftui-audit audit <source-path> --index-store <path> --config <path> --format json
   ```

4. For persisted inputs, use only persisted-input options:

   ```bash
   swiftui-audit slice <indexed-snapshot> --finding <finding-id> --format llm-json
   swiftui-audit diff <base-indexed-snapshot> <current-indexed-snapshot> --format json
   ```

An option error is a command-construction failure. Re-read this matrix and
correct the invocation; do not describe the installed version as lacking a
required option unless that option belongs to the command in this table.
