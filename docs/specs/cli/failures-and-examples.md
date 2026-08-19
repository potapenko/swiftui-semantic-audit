# CLI Failures, Timeouts, and Examples

- Node type: leaf
- Status: Active
- Contract revision: `spec-4`
- Authority: [CLI contract](../cli.md)
- Read when: selecting command syntax, flags, output, status, resolution, cache, failure, or timeout behavior.
- Do not read when: the task does not invoke, document, or integrate the CLI.
- Maximum size: 100 physical lines.


## Failure and timeout policy

**CLI-FAIL-001.** Never silently parse stderr as JSON or treat a failed command as an empty result.

**CLI-FAIL-002.** External Git/Swift/Xcode/index helper operations have explicit bounds (current implementation uses 10–120 second operation timeouts depending on the boundary and allows the compiler-index helper the largest bound for full projects).

**CLI-FAIL-003.** Preserve produced artifacts and retry only the failed/missing stage when safe. Do not mutate branches or worktrees for revision analysis.

## Examples

```bash
swiftui-audit scan Sources --syntax-only --format json
swiftui-audit audit Sources --syntax-only --format json
swiftui-audit snapshot Sources --output .semantic/current --syntax-only --format json
swiftui-audit slice .semantic/current --finding finding:0123456789abcdef --format llm-json
swiftui-audit diff .semantic/base .semantic/current --format json
swiftui-audit check --baseline .semantic/base Sources --fail-on-new high --syntax-only --format json
swiftui-audit doctor . --format json
```
