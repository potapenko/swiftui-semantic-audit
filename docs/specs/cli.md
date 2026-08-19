# CLI contract

- Node type: hybrid
- Status: Active
- Contract revision: `spec-6`
- Read when: selecting command syntax, flags, output, status, resolution, cache, failure, or timeout behavior.
- Do not read when: the task does not invoke, document, or integrate the CLI.
- Maximum size: 100 physical lines.

Revision: `spec-6`
Executable: `swiftui-audit`  
Tool version in schema: `0.4.0`
Status: active, release candidate 0.4.0

All syntax below was verified against the accepted P1–P5 executable help.

## Choose the governing child

- [CLI Global Behavior, Resolution, and Scan](cli/global-resolution-and-scan.md) — global streams/status, resolution/config/cache options, and scan.
- [CLI Audit, Snapshot, and Slice](cli/audit-snapshot-and-slice.md) — audit, five-file snapshot, and bounded llm-json slice behavior.
- [CLI Diff, Check, and Doctor](cli/diff-check-and-doctor.md) — semantic comparison, regression policy, and environment diagnosis.
- [CLI Failures, Timeouts, and Examples](cli/failures-and-examples.md) — external boundary policy and representative invocations.
