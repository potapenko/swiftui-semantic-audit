# SwiftUI Semantic Audit

`swiftui-audit` 0.3.0 is a deterministic semantic compiler from Swift/SwiftUI source into a compact state/data-flow graph for coding-agent reasoning, architectural self-audit, and semantic diff.

It is not a style linter, source-rewriting bot, or model-backed code reviewer. SwiftSyntax and optional compiler-index enrichment establish facts; rules produce evidence-backed candidates; an agent may adjudicate ambiguous intent without changing syntax, symbol, read/write, or source-location facts.

## Requirements

- macOS 13 or later;
- Swift 6.3-compatible toolchain (the package pins SwiftSyntax `603.0.2`);
- Git for revision operands;
- Xcode command-line tools for indexed mode.

Syntax-only analysis does not require a project build or Index Store. Indexed enrichment is macOS-only and uses IndexStoreDB at revision `003ac41513ba291f10ff1a0147ae68588914668d`.

## Build and run

Resolve once, then use locked dependencies:

```bash
swift package resolve
swift build --disable-automatic-resolution
swift test --disable-automatic-resolution
```

Run from the package:

```bash
swift run --disable-automatic-resolution swiftui-audit --help
```

For repeated use, build release mode and invoke the product directly:

```bash
swift build -c release --disable-automatic-resolution
.build/release/swiftui-audit doctor --format json
```

## Quick start

Start with findings, not arbitrary source files:

```bash
swift run --disable-automatic-resolution swiftui-audit audit Sources --syntax-only --format json
```

Take one emitted finding ID and request a bounded LLM context:

```bash
swift run --disable-automatic-resolution swiftui-audit slice Sources \
  --finding finding:0123456789abcdef \
  --syntax-only \
  --format llm-json \
  --token-budget 10000
```

Capture and compare deterministic snapshots:

```bash
swift run --disable-automatic-resolution swiftui-audit snapshot Sources \
  --output .semantic/base \
  --syntax-only \
  --format json

swift run --disable-automatic-resolution swiftui-audit snapshot Sources \
  --output .semantic/current \
  --syntax-only \
  --format json

swift run --disable-automatic-resolution swiftui-audit diff \
  .semantic/base .semantic/current --format json
```

Gate only new findings at or above a threshold:

```bash
swift run --disable-automatic-resolution swiftui-audit check \
  --baseline .semantic/base \
  Sources \
  --fail-on-new high \
  --syntax-only \
  --format json
```

## Commands

| Command | Purpose | Machine format |
| --- | --- | --- |
| `scan <path>` | Build the semantic graph | JSON (default); optional `--output <file>` |
| `audit <path>` | Evaluate the 29 state/data-flow and architecture rules | `--format json` |
| `snapshot [path]` | Persist a canonical five-file sidecar | optional JSON summary with `--format json` |
| `slice [input]` | Return a minimal subgraph for one `--finding` or `--symbol` | `--format llm-json` |
| `diff <base> <current>` | Compare snapshot directories or Git revisions | `--format json` |
| `check --baseline <base> [path]` | Fail on new findings at/above `--fail-on-new` | `--format json`; failing policy exits 2 |
| `doctor [path]` | Inspect Swift, Xcode, package, index, and Git readiness | `--format json` |

Run `swiftui-audit <command> --help` for the authoritative arguments.

## Syntax-only and indexed modes

`scan`, `audit`, `snapshot`, `slice` on live source, and `check` accept:

- `--syntax-only`: disable all index enrichment;
- `--index-store <path>`: require an explicit validated raw Index Store;
- neither flag: try conservative local auto-discovery, otherwise remain syntax-only.

The same live-source commands accept `--config <path>`. Without it, they discover only `.swiftui-audit.json` directly in the analyzed directory (or the analyzed file's parent). The validated configuration supplies exact composition roots, product roles, feature ownership, path features, and passive environment values. Role-aware rules remain silent when their required classification is absent; the tool never guesses application roles from names.

An explicit index request fails if the store, `libIndexStore`, helper, or project coverage is unavailable. Automatic mode enriches only when exactly one validated local candidate covers the project; otherwise it safely falls back to `resolution: "syntax-only"`.

Compare only inputs with matching resolution. Git-revision operands are syntax-only, so use syntax-only snapshots when comparing against them.

## Agent workflow

1. Build the target to produce a fresh project-covering Index Store, then pass its path explicitly to every live-source agent command.
2. Validate the project's `.swiftui-audit.json` when role-aware architecture analysis is in scope and pass it explicitly with `--config <path>`.
3. Run `audit --index-store <path> --config <path> --format json` before broad source inspection and require `resolution: "indexed"`.
4. Group relevant findings by semantic value and topology, including custom Binding setters and component boundaries.
5. Run `slice --index-store <path> --config <path> --format llm-json` for a finding or unambiguous symbol.
6. Inspect source only at evidence locations when implementation detail is needed.
7. Classify accidental mirrors separately from transactions, transformations, command-shaped setters, legitimate model owners, and over-broad component inputs.
8. After an edit, build/test, refresh the Index Store, audit again, compare indexed snapshots, and run `check`.

Do not optimize for “Binding everywhere” or fewer `@State` properties. Optimize correct ownership, one canonical source of truth, explicit dependencies, minimal manual synchronization, and correct lifetime/transaction behavior.

Use one concise entry point:

- [`swiftui-semantic`](skills/swiftui-semantic/SKILL.md).

It selects or sequences the appropriate specialist workflow:

- [`swiftui-semantic-audit`](skills/swiftui-semantic-audit/SKILL.md);
- [`swiftui-dataflow-refactor`](skills/swiftui-dataflow-refactor/SKILL.md);
- [`swiftui-change-review`](skills/swiftui-change-review/SKILL.md).

## Outputs

Canonical snapshots contain exactly:

```text
manifest.json
nodes.jsonl
edges.jsonl
findings.jsonl
summary.json
```

Records are stably ordered and end with a newline. Evidence and `generatedFrom` paths are relative; absolute paths, dangling references, inconsistent schemas/resolutions, symlinks, unexpected entries, unsafe output targets, and source/output overlap are rejected.

Repeated snapshots at the same source/toolchain/revision/resolution are byte-identical across all five files. A committed baseline compared after a later commit keeps the four semantic files byte-exact and normalizes only `manifest.json.repositoryRevision`; every other manifest field remains exact, and the fresh revision must equal `HEAD`.

Machine-readable results are written to stdout. Treat stderr and process status as command diagnostics, not JSON payload. `slice` uses a conservative byte-based token estimate and fails if the mandatory envelope cannot fit.

## Current limitations

- PoC coverage is the documented SwiftUI vocabulary and 29 rules, not a full Swift type checker or general interprocedural analyzer.
- Product roles, features, and composition roots come only from validated configuration; the tool does not infer controllers, services, or feature models from names.
- Indexed enrichment is macOS-only and conservatively skips ambiguous same-line use-site matches.
- Automatic index discovery is local to validated `.build` candidates.
- Full graph rebuild is allowed; there is no incremental cache guarantee.
- Snapshot writes have no concurrent-writer lock.
- Slice traversal is bounded and token estimation is byte-based.
- Exact-qualified semantic continuity treats true renames conservatively as remove/add.
- There is no automatic source rewrite, model-provider integration, IDE/GUI/Xcode extension, SIL analysis, or support for every Swift framework.

## Development

```bash
swift build --disable-automatic-resolution
swift test --disable-automatic-resolution
swift run --disable-automatic-resolution swiftui-audit doctor . --format json
```

The deterministic dogfood baseline for rule fixtures is under [`Tests/Baselines/RuleTests`](Tests/Baselines/RuleTests). CI builds and tests the locked package, audits fixtures and project sources, checks the committed baseline, proves snapshot reproducibility, exercises slicing and doctor output, and validates the routing skill plus all three specialist skills.

Start with the [specification registry](docs/specs/README.md) for the active contract, precedence, evidence ownership, acceptance mapping, and unreleased baseline.

## License

Licensed under the repository [LICENSE](LICENSE).
