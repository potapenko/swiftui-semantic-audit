# CLI Diff, Check, and Doctor

- Node type: leaf
- Status: Active
- Contract revision: `spec-4`
- Authority: [CLI contract](../cli.md)
- Read when: selecting command syntax, flags, output, status, resolution, cache, failure, or timeout behavior.
- Do not read when: the task does not invoke, document, or integrate the CLI.
- Maximum size: 100 physical lines.


## `diff`

**CLI-DIFF-001.** Syntax:

```text
swiftui-audit diff <base> <current> [--repository <path>] [--format json]
```

Each operand is an existing snapshot directory or a Git revision. Default repository is `.`. Git revisions are verified commits, reconstructed from regular Swift blobs with path traversal rejected, and analyzed syntax-only without checkout/worktree mutation.

**CLI-DIFF-002.** Require each snapshot's graph/report resolution to agree and both operands to share one resolution.

## `check`

**CLI-CHECK-001.** Syntax:

```text
swiftui-audit check --baseline <snapshot-or-revision> [<current-source>]
                     [--repository <path>] [--fail-on-new low|medium|high]
                     [--format json]
                     [--index-store <path> | --syntax-only] [--config <path>]
```

Defaults: current source `.`, repository `.`, threshold `high`. Load current source at resolution compatible with the baseline, diff, and fail only when a new finding reaches the threshold.

**CLI-CHECK-002.** A syntax-only baseline forces automatic current selection to syntax-only. An indexed baseline requires usable indexed current analysis. Explicitly mixing modes fails.

## `doctor`

**CLI-DOC-001.** Syntax:

```text
swiftui-audit doctor [<path>] [--format json]
```

Default path is `.`. Inspect without mutation:

- Swift version and recognizable semantic version;
- Xcode version/build when available;
- `xcrun` Swift toolchain path;
- Swift package, Xcode project, or source-directory type;
- SwiftSyntax release-train compatibility;
- macOS IndexStoreDB/backend/library/raw-store/coverage readiness;
- Git version and worktree membership.

**CLI-DOC-002.** Required Swift/Git failures or SwiftSyntax incompatibility are errors. Optional Xcode/index readiness may be warnings because syntax-only operation remains valid. Exit nonzero only for overall error.
