# CLI Global Behavior, Resolution, and Scan

- Node type: leaf
- Status: Active
- Contract revision: `spec-7`
- Authority: [CLI contract](../cli.md)
- Read when: selecting command syntax, flags, output, status, resolution, cache, failure, or timeout behavior.
- Do not read when: the task does not invoke, document, or integrate the CLI.
- Maximum size: 100 physical lines.


## Global behavior

**CLI-GEN-001 — Shape.** Provide one executable with seven analysis subcommands: `scan`, `audit`, `snapshot`, `slice`, `diff`, `check`, `doctor`. `PROJECT-WATCHER-001` adds one public `project` namespace while preserving all seven command contracts.

**CLI-GEN-002 — Machine stream.** Write requested JSON to stdout (or the explicit `scan --output` file). Keep diagnostics/errors on stderr. JSON uses sorted keys, unescaped slashes, and a final newline.

**CLI-GEN-003 — Failures.** Invalid arguments, malformed inputs, unsafe paths, invalid revisions, missing/ambiguous selectors, explicit index failure, resolution mismatch, and doctor errors exit nonzero. `check` exits `2` when policy fails.

**CLI-GEN-004 — Locked development path.** In this repository, run `swift run --disable-automatic-resolution swiftui-audit …` after dependency resolution.

**CLI-GEN-005 — Version.** `swiftui-audit --version` writes the exact `ToolMetadata.version` followed by a newline and exits successfully without reading a project or invoking an external tool.

## Resolution options

**CLI-RES-001.** `scan`, `audit`, `snapshot`, live-source `slice`, and `check` accept `--syntax-only` and `--index-store <path>`; they are mutually exclusive.

**CLI-RES-002.** With neither flag, automatically search validated local `.build/**/debug/index/store` and release equivalents. Enrich only for one usable candidate; otherwise return syntax-only.

**CLI-RES-003.** Explicit stores must have raw `vN/units` and `vN/records` shape, usable `libIndexStore.dylib`, executable helper, and project coverage. Explicit failure is terminal; automatic failure falls back.

**CLI-RES-004.** Indexed enrichment is macOS-only. It is bounded by an external process timeout and marks an accepted graph `resolution: "indexed"`.

**CLI-CFG-001.** Live-source `scan`, `audit`, `snapshot`, `slice`, and `check` accept `--config <path>`. Without it they apply the bounded discovery rule in `CFG-005`. Explicit invalid configuration fails; absence means topology-only analysis.

**CLI-CFG-002.** JSON reports and snapshot manifests expose the canonical configuration digest. Diff/check reject different digests. Git-revision operands use only a `.swiftui-audit.json` blob at the revision root.

**CLI-CACHE-001.** Live-source `scan`, `audit`, `snapshot`, `slice`, and `check` use the persistent incremental cache by default. `--cache-directory <path>` selects an explicit cache root and `--no-cache` forces a full uncached rebuild. The options are mutually exclusive and never apply to an already-persisted snapshot or a Git-revision operand.

**CLI-CACHE-002.** The default cache root is the user cache directory under a project-identity hash. Cache diagnostics stay off the default product stream. Invalid, incompatible, or incomplete entries are rebuilt without weakening resolution or changing requested JSON stdout.

## Execution options

**CLI-EXEC-001.** Live-source `scan`, `audit`, `snapshot`, `slice`, and `check` accept `--jobs <count>`. The count must be positive; `1` selects serial frontend and rule evaluation, and omission uses the host's active processor count. The option does not apply to an already-persisted snapshot or Git-revision operand and must not change canonical output, status, resolution, cache behavior, or failure policy.

## `scan`

**CLI-SCAN-001.** Syntax:

```text
swiftui-audit scan <path> [--format json] [--output <file>]
                     [--index-store <path> | --syntax-only] [--config <path>]
                     [--jobs <count>]
```

Build a semantic graph for one Swift file or directory. JSON is the only and default format. `--output` writes atomically to the explicit file instead of stdout.
