# Run artifact hygiene

Read this reference before a semantic workflow runs commands that may emit
machine output, diagnostics, snapshots, receipts, hashes, or timing metadata.

## Keep auxiliary evidence temporary

- Separating JSON stdout, stderr, process status, and command metadata is a
  logical contract. It does not require one permanent file per stream or stage.
- Capture streams through the process runner when possible. When files are
  necessary, create a uniquely named task-scoped temporary directory outside
  the source repository, the active Codex home, and installed skill/package
  directories.
- Remove only run-created temporary files after their result has been accepted.
  On failure, keep them only long enough to report or hand off the exact command,
  status, stderr, and missing evidence. Never remove a pre-existing path.
- Do not use `~/.codex/artifacts`, another version-controlled configuration
  directory, or a skill installation directory as a scratch root.

The CLI's normal user cache remains an execution optimization governed by its
cache contract. Do not copy cache entries into the run-evidence directory.

## Persist only deliberate evidence

Use durable storage only when the user explicitly requests artifacts or an
approved plan, goal, or handoff requires evidence across turns. Before writing:

1. choose an explicit application-state location outside every Git repository,
   Codex configuration home, and installed package;
2. record the run ID, owner, consumer, and cleanup condition or retention limit;
3. keep only the smallest evidence the consumer needs, normally a canonical
   snapshot and one compact terminal receipt rather than duplicated raw logs,
   timestamps, and hash files for every command;
4. report the durable path and retention condition in the handoff; and
5. never stage or commit the generated evidence.

Canonical semantic snapshots are not auxiliary receipts. When the workflow
deliberately selects a baseline or current snapshot destination, preserve the
exact five-file snapshot contract and the existing path-safety checks. Do not
place unrelated command logs or receipts inside that snapshot directory.
