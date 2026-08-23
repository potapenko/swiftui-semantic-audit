# CLI contract

- Node type: hybrid
- Status: Active
- Contract revision: `spec-10`
- Read when: selecting command syntax, flags, output, status, resolution, cache, failure, or timeout behavior.
- Do not read when: the task does not invoke, document, or integrate the CLI.
- Maximum size: 100 physical lines.

Revision: `spec-10`
Executable: `swiftui-audit`  
Tool version in schema: `0.6.0`
Status: active; 0.5.0 is the current public release and 0.4.0/0.5.0 artifacts are immutable; 0.6.0 is publication-authorized with its terminal receipt pending

Project-namespace syntax and option ownership were reconciled against the
accepted executable help and CI-validated invocation matrix. Existing analysis
command contracts use documented shorthand; executable help remains exhaustive.

## Choose the governing child

- [CLI Global Behavior, Resolution, and Scan](cli/global-resolution-and-scan.md) — global streams/status, resolution/config/cache options, and scan.
- [CLI Audit, Snapshot, and Slice](cli/audit-snapshot-and-slice.md) — audit, five-file snapshot, and bounded llm-json slice behavior.
- [CLI Diff, Check, and Doctor](cli/diff-check-and-doctor.md) — semantic comparison, regression policy, and environment diagnosis.
- [CLI Failures, Timeouts, and Examples](cli/failures-and-examples.md) — external boundary policy and representative invocations.
- [CLI Project Setup and Watcher](cli/project-setup-and-watcher.md) — project setup, freshness-qualified watching, lifecycle, status, and baseline promotion.
