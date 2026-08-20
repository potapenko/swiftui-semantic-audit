# Development

SwiftUI Semantic Audit is a Swift Package with reusable libraries and one executable product. Release evidence is tied to the active specification, immutable tag, archive checksum, and tap formula revision.

## Toolchain

- macOS 13 or later;
- Swift tools declaration 6.2;
- accepted build/test toolchain: Swift 6.3.3;
- SwiftSyntax `603.0.2`;
- swift-argument-parser `1.8.2`;
- IndexStoreDB pinned by revision for macOS indexed enrichment.

Use the committed `Package.resolved`. Resolve intentionally, then keep routine builds locked:

```bash
swift package resolve
swift build --disable-automatic-resolution
swift test --disable-automatic-resolution
```

Do not run `swift package update` as a routine verification step.

## Run the CLI from source

```bash
swift run --disable-automatic-resolution swiftui-audit --help
swift run --disable-automatic-resolution swiftui-audit --version
swift run --disable-automatic-resolution swiftui-audit doctor . --format json
```

Release build:

```bash
swift build -c release --disable-automatic-resolution
.build/release/swiftui-audit --help
```

## Package map

| Target | Responsibility |
| --- | --- |
| `AuditCore` | Versioned graph, audit, configuration, and shared data contracts |
| `SwiftSyntaxFrontend` | Deterministic source extraction |
| `SwiftUISemantics` | Bounded SwiftUI vocabulary and normalization facts |
| `SemanticNormalization` | Logical semantic-value grouping |
| `AuditRules` | The 30 deterministic/candidate rules and dominance |
| `SnapshotStore` | Canonical five-file persistence and integrity |
| `ContextSlicer` | Bounded finding/symbol context |
| `AnalysisCache` | Integrity-checked persistent frontend and indexed fact reuse |
| `SemanticDiff` | Snapshot/revision comparison, check policy, and doctor support |
| `SymbolResolution` | Optional macOS IndexStoreDB enrichment |
| `SwiftUIAuditCLI` | ArgumentParser commands and process/output policy |

The executable product is named `swiftui-audit`.

## Product contracts

Start every behavioral change at the [specification registry](../specs/README.md). The active package separates:

- product identity and invariants;
- analysis configuration;
- semantic IR and snapshot schema;
- rule and adjudication behavior;
- CLI behavior;
- acceptance and release evidence.

Source and tests prove realization. They do not silently redefine intended behavior.

## Verification layers

### Build and tests

```bash
swift build --disable-automatic-resolution
swift test --disable-automatic-resolution
```

Tests cover extraction, incremental frontend/indexed cache hits and invalidation, normalization, rules, configuration, snapshot integrity and determinism, slicing, diff, check, doctor, syntax identity, and indexed enrichment.

### Standalone dogfood

The CLI audits its fixtures and its own source. A compact local pass is:

```bash
swift run --disable-automatic-resolution swiftui-audit audit \
  Tests/Fixtures/RuleTests --syntax-only --format json

swift run --disable-automatic-resolution swiftui-audit audit \
  Sources --syntax-only --format json

swift run --disable-automatic-resolution swiftui-audit doctor . --format json
```

The canonical rule-fixture snapshot lives under [`Tests/Baselines/RuleTests`](../../Tests/Baselines/RuleTests). Do not regenerate it casually: the manifest revision and four semantic files are acceptance evidence.

### Indexed evidence

Indexed tests compile a fixture into a real raw Index Store and verify compiler-USR enrichment, identity, reads/writes/calls, configuration, and rule preservation. Indexed support is macOS-only.

### Skills

The repository must contain exactly:

```text
skills/swiftui-semantic
skills/swiftui-semantic-audit
skills/swiftui-dataflow-refactor
skills/swiftui-change-review
```

The router is the public entry point. Specialists retain their own evidence and acceptance gates. Agent-facing and public documentation must require explicit indexed analysis; frontend-only flags belong only to internal development, tests, and CI.

## Continuous integration

The GitHub Actions workflow:

1. selects the accepted Xcode/Swift toolchain;
2. resolves, builds, and tests with timeouts;
3. proves real indexed fixture enrichment;
4. audits rule, architecture-positive, architecture-negative, and project source fixtures and proves cached/uncached byte equivalence;
5. regenerates two snapshots and checks byte identity;
6. compares semantic files with the committed baseline;
7. runs diff, check, slice, and doctor;
8. validates the exact four-skill inventory, frontmatter, YAML, and links;
9. validates Markdown links throughout the public and normative documentation;
10. runs `git diff --check`.

CI does not require zero legacy findings. Its policy prevents new findings at or above the selected threshold against a compatible baseline.

## Writing documentation

Public documentation belongs under:

```text
docs/getting-started/
docs/concepts/
docs/workflows/
docs/reference/
docs/development/
```

Use relative links so pages work in GitHub and a local clone. Keep claims tied to implemented commands, schemas, and rules. Put normative behavior in `docs/specs`; public guides should explain it without creating a competing contract.

Before committing documentation:

- check every relative file and anchor link;
- compare command examples with executable help;
- ensure the root README truthfully distinguishes an in-progress candidate from a tagged release;
- run the prose lint as a heuristic, not an authority;
- run `git diff --check` and the relevant build/tests.

## Scope limits

Do not treat this package as a source rewriter, full type checker, SIL analyzer, general Swift architecture engine, model-provider integration, GUI, or IDE extension. New analysis remains bounded by explicit product contracts, deterministic evidence, negative fixtures, and a defined agent-judgment boundary.

[Back to documentation](../README.md)
