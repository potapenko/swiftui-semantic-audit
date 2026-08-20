# CLI reference

`swiftui-audit` 0.5.0 exposes seven public subcommands. JSON written to stdout is the machine contract. Diagnostics belong on stderr, and callers must always inspect process status.

Run the executable help for the checked-out build:

```bash
swiftui-audit --help
swiftui-audit --version
swiftui-audit <command> --help
```

`--version` prints the same `0.5.0` value embedded in reports and snapshots and does not inspect the current project.

When developing inside this repository, replace `swiftui-audit` with:

```bash
swift run --disable-automatic-resolution swiftui-audit
```

Every live-source command accepts `--cache-directory <path>` or `--no-cache`. The first selects an explicit persistent cache root; the second forces a full rebuild. They are mutually exclusive. Snapshot and Git-revision inputs are already materialized and do not accept live-source cache options.

## Commands

### `scan`

```text
swiftui-audit scan <path> [--format json] [--output <file>]
                     --index-store <path> [--config <path>]
```

Build the canonical semantic graph for one Swift file or a directory. JSON is the only and default format. `--output` writes atomically to the selected file instead of stdout.

### `audit`

```text
swiftui-audit audit <path> [--format json]
                      --index-store <path> [--config <path>]
```

Normalize state/data flow and evaluate all 30 current rules. Human output gives total and per-rule counts. JSON contains the complete report, metrics, semantic values, and findings.

### `snapshot`

```text
swiftui-audit snapshot [<path>] [--output <directory>] [--format json]
                         --index-store <path> [--config <path>]
```

Defaults: source `.`, output `.semantic`. The output directory contains exactly five canonical files. Optional JSON stdout is a manifest and summary receipt.

The command rejects unsafe or overlapping source/output paths and refuses to replace a nonempty directory unless it is already a valid snapshot.

### `slice`

```text
swiftui-audit slice [<input>] (--finding <id> | --symbol <selector>)
                      [--format llm-json] [--token-budget <positive-int>]
                      [--index-store <path>] [--config <path>]
```

Select exactly one finding or symbol and return a bounded context envelope. Input resolution is:

1. explicit input;
2. `.semantic` in the current directory;
3. live source.

Index and config options apply to live source and must be passed explicitly there. A snapshot already carries its indexed evidence and configuration digest. Symbol selectors accept an exact stable ID, an exact qualified name, or an unambiguous suffix.

### `diff`

```text
swiftui-audit diff <base> <current> [--repository <path>] [--format json]
```

Each operand is a snapshot directory or a Git commit revision. Snapshot inputs must use the same resolution and configuration digest. Git operands are reconstructed from validated Swift blobs in a temporary directory without checkout, branch switching, or worktree creation. They do not preserve compiler-index evidence and are not suitable for the agent review workflow.

### `check`

```text
swiftui-audit check --baseline <snapshot-or-revision> [<current-source>]
                     [--repository <path>] [--fail-on-new low|medium|high]
                     [--format json]
                     --index-store <path> [--config <path>]
```

Defaults: current source `.`, repository `.`, threshold `high`. The command fails only when a new finding reaches or exceeds the threshold.

An indexed baseline requires usable indexed current analysis. Different evidence resolution or configuration digests fail before policy evaluation.

Policy failure exits with status `2` and still emits the requested machine report.

### `doctor`

```text
swiftui-audit doctor [<path>] [--format json]
```

Default path: `.`. The command inspects without mutation:

- Swift version and recognizable semantic version;
- Xcode version and build when available;
- the `xcrun` Swift toolchain path;
- Swift package, Xcode project, or source-directory type;
- SwiftSyntax release-train compatibility;
- IndexStoreDB, compiler library, raw store, and coverage readiness on macOS;
- Git version and worktree membership.

Swift, Git, or SwiftSyntax incompatibility can make the overall result an error. Treat Xcode and index-readiness warnings as blockers before an agent workflow.

## Indexed analysis

User-facing live-source commands require `--index-store <path>`. The path must point to a fresh compiler Index Store that covers the exact source state under analysis. A valid result reports `resolution: "indexed"`.

Do not omit the option in reliance on discovery. An explicit index request fails when the raw store, compatible compiler library, helper, or project coverage is unavailable. The bundled skills treat that failure as missing evidence and stop.

## Configuration

The live-source commands accept `--config <path>`. Without it, discovery is deliberately narrow:

- directory analysis reads only `.swiftui-audit.json` directly inside that directory;
- file analysis reads only `.swiftui-audit.json` in the file's parent;
- there is no ancestor walk or home-directory default.

See [Configuration](configuration.md).

## Incremental cache

`scan`, `audit`, `snapshot`, live-source `slice`, and the current side of `check` cache deterministic frontend facts by relative path and source content. Indexed facts additionally depend on compiler-unit identity. Changed declaration names conservatively invalidate files whose lexical identifiers may depend on them.

The default location is the user cache directory under a hash of the canonical source root. Cache files live outside the five-file snapshot, contain no source text, and are integrity-checked before reuse. Invalid, incompatible, incomplete, tool/schema-mismatched, or compiler-unit-mismatched entries are cache misses. Every invocation still assembles a complete graph and reevaluates normalization and all 30 rules.

For a cache-equivalence check, repeat the same command with `--no-cache` and compare JSON bytes. Resolution, configuration digest, graph/report schemas, findings, and exit policy must remain identical.

## Machine-output discipline

- Parse JSON or JSONL only from stdout or the explicit output file.
- Treat stderr as diagnostics, never as an empty JSON substitute.
- Check exit status before interpreting the payload.
- Preserve `resolution`, schema/tool versions, and `configurationDigest` with stored results.
- Compare only results with matching evidence resolution and configuration digest.

JSON uses sorted keys, unescaped slashes, and a final newline. Canonical collections and records are sorted by stable identity.

## Failure policy

The CLI fails closed for invalid arguments, unsafe paths, malformed snapshots, invalid revisions, explicit index failure, ambiguous selectors, insufficient positive slice budgets, inconsistent graph/report data, mixed resolution, and mismatched configuration.

External Git, Swift, Xcode, and index-helper operations have explicit timeouts. A timeout fails the current attempt instead of waiting indefinitely.

## Examples

Indexed, configured agent evidence:

```bash
swiftui-audit audit Sources \
  --index-store /absolute/path/to/index/store \
  --config .swiftui-audit.json \
  --format json
```

Canonical baseline and policy check:

```bash
swiftui-audit snapshot Sources \
  --output .semantic/base \
  --index-store /absolute/path/to/index/store \
  --config .swiftui-audit.json \
  --format json

swiftui-audit check \
  --baseline .semantic/base \
  Sources \
  --fail-on-new high \
  --index-store /absolute/path/to/current/index/store \
  --config .swiftui-audit.json \
  --format json
```

Normative detail: [`docs/specs/cli.md`](../specs/cli.md).
