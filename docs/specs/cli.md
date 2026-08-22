# CLI contract

- Node type: hybrid
- Status: Active
- Contract revision: `spec-9`
- Read when: selecting command syntax, flags, output, status, resolution, cache, failure, or timeout behavior.
- Do not read when: the task does not invoke, document, or integrate the CLI.
- Maximum size: 100 physical lines.

Revision: `spec-9`
Executable: `swiftui-audit`  
Tool version in schema: `0.6.0`
Status: active; 0.6.0 project-watcher candidate unreleased; 0.5.0 and 0.4.0 immutable

All syntax below was verified against the accepted P1–P5 executable help.

## Choose the governing child

- [CLI Global Behavior, Resolution, and Scan](cli/global-resolution-and-scan.md) — global streams/status, resolution/config/cache options, and scan.
- [CLI Audit, Snapshot, and Slice](cli/audit-snapshot-and-slice.md) — audit, five-file snapshot, and bounded llm-json slice behavior.
- [CLI Diff, Check, and Doctor](cli/diff-check-and-doctor.md) — semantic comparison, regression policy, and environment diagnosis.
- [CLI Failures, Timeouts, and Examples](cli/failures-and-examples.md) — external boundary policy and representative invocations.
- [CLI Project Setup and Watcher](cli/project-setup-and-watcher.md) — project setup, freshness-qualified watching, lifecycle, status, and baseline promotion.
