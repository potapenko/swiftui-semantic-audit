# CLI contract

Revision: `spec-4`
Executable: `swiftui-audit`  
Tool version in schema: `0.4.0`
Status: active, unreleased

All syntax below was verified against the accepted P1–P5 executable help.

## Global behavior

**CLI-GEN-001 — Shape.** Provide one executable with seven public subcommands: `scan`, `audit`, `snapshot`, `slice`, `diff`, `check`, `doctor`.

**CLI-GEN-002 — Machine stream.** Write requested JSON to stdout (or the explicit `scan --output` file). Keep diagnostics/errors on stderr. JSON uses sorted keys, unescaped slashes, and a final newline.

**CLI-GEN-003 — Failures.** Invalid arguments, malformed inputs, unsafe paths, invalid revisions, missing/ambiguous selectors, explicit index failure, resolution mismatch, and doctor errors exit nonzero. `check` exits `2` when policy fails.

**CLI-GEN-004 — Locked development path.** In this repository, run `swift run --disable-automatic-resolution swiftui-audit …` after dependency resolution.

## Resolution options

**CLI-RES-001.** `scan`, `audit`, `snapshot`, live-source `slice`, and `check` accept `--syntax-only` and `--index-store <path>`; they are mutually exclusive.

**CLI-RES-002.** With neither flag, automatically search validated local `.build/**/debug/index/store` and release equivalents. Enrich only for one usable candidate; otherwise return syntax-only.

**CLI-RES-003.** Explicit stores must have raw `vN/units` and `vN/records` shape, usable `libIndexStore.dylib`, executable helper, and project coverage. Explicit failure is terminal; automatic failure falls back.

**CLI-RES-004.** Indexed enrichment is macOS-only. It is bounded by an external process timeout and marks an accepted graph `resolution: "indexed"`.

**CLI-CFG-001.** Live-source `scan`, `audit`, `snapshot`, `slice`, and `check` accept `--config <path>`. Without it they apply the bounded discovery rule in `CFG-005`. Explicit invalid configuration fails; absence means topology-only analysis.

**CLI-CFG-002.** JSON reports and snapshot manifests expose the canonical configuration digest. Diff/check reject different digests. Git-revision operands use only a `.swiftui-audit.json` blob at the revision root.

**CLI-CACHE-001.** Live-source `scan`, `audit`, `snapshot`, `slice`, and `check` use the persistent incremental cache by default. `--cache-directory <path>` selects an explicit cache root and `--no-cache` forces a full uncached rebuild. The options are mutually exclusive and never apply to an already-persisted snapshot or a Git-revision operand.

**CLI-CACHE-002.** The default cache root is the user cache directory under a project-identity hash. Cache diagnostics stay off the default product stream. Invalid, incompatible, or incomplete entries are rebuilt without weakening resolution or changing requested JSON stdout.

## `scan`

**CLI-SCAN-001.** Syntax:

```text
swiftui-audit scan <path> [--format json] [--output <file>]
                     [--index-store <path> | --syntax-only] [--config <path>]
```

Build a semantic graph for one Swift file or directory. JSON is the only and default format. `--output` writes atomically to the explicit file instead of stdout.

## `audit`

**CLI-AUDIT-001.** Syntax:

```text
swiftui-audit audit <path> [--format json]
                      [--index-store <path> | --syntax-only] [--config <path>]
```

Evaluate exactly the twenty-nine current rules. Human output reports total and per-rule counts; JSON emits the complete audit report.

## `snapshot`

**CLI-SNAP-001.** Syntax:

```text
swiftui-audit snapshot [<path>] [--output <directory>] [--format json]
                         [--index-store <path> | --syntax-only] [--config <path>]
```

Defaults: source `.`, output `.semantic`. Persist exactly the five files in [IR-SNAP-001](semantic-ir.md#persistent-snapshot). Optional JSON stdout is a manifest+summary receipt.

**CLI-SNAP-002.** Reject `/`, an empty target, source/output identity, output that is an ancestor of source, unsafe canonicalization, or replacement of a nonempty invalid directory. Absolute evidence and `generatedFrom` paths are invalid.

**CLI-SNAP-003.** Determinism checks within one revision compare all five files byte for byte. Cross-commit committed-baseline checks compare the four semantic files byte for byte and may normalize only manifest `repositoryRevision`; all other manifest fields must match exactly, and a fresh snapshot must record the checked-out `HEAD`.

## `slice`

**CLI-SLICE-001.** Syntax:

```text
swiftui-audit slice [<input>] (--finding <id> | --symbol <selector>)
                      [--format llm-json] [--token-budget <positive-int>]
                      [--index-store <path> | --syntax-only] [--config <path>]
```

Require exactly one selector. Input resolution order is an explicit input, then `.semantic`, then live source. `--index-store` applies only to live source.

**CLI-SLICE-002.** Symbol selectors accept exact stable ID, qualified name, or an unambiguous suffix. Reject unknown and ambiguous selectors. Reject nonpositive or too-small budgets.

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
