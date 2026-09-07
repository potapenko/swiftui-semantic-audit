# Evidence integrity restoration

- Authority: user approval on 2026-09-07 of audit improvement stage 1.
- Mode: Restore; additive transport clarification of existing evidence contracts.
- State: implemented and locally verified on the operator-selected `master`; saved by this checkpoint.
- Consumer: implementation and acceptance of the three reproduced trust defects.

## Contract basis and delta

Traversal: `docs/specs/README.md` (`spec-37`, epoch `tz-v29`) → product architecture/operations → semantic IR graph and slice/resolution → rule adjudication → CLI resolution → fixture/skill acceptance and release residuals. Source inspection confirms partial and stale indexes are accepted, write-through drafts suppress mirrors, and slices omit analysis identity.

Preserve `PC-RES-003`, `IR-RES-002`, `RULE-EXC-002`, and `IR-SLICE-001`: reject incomplete indexed coverage and sources newer than their index; do not suppress a mirror when writes escape the commit boundary; carry resolution, configuration and deterministic input identity into every new slice. Timestamp checks detect stale evidence but are not a compiler source-content attestation; callers still build the exact requested source state. No new rule or platform policy is authorized.

The compatible slice additions retain old JSON readability as explicitly unknown provenance. New slices identify their full graph/report input by SHA-256 and retain a supplied snapshot manifest. That digest identifies semantic evidence, not all source bytes or runtime behavior. Provenance is mandatory within the slice budget and identical for every selector/budget over the same input.

## Write set and protected boundaries

- `Sources/SymbolResolution/**`: complete coverage, conservative freshness and cache validation.
- `Sources/SemanticNormalization/SemanticNormalizer.swift`: transaction write-boundary validation.
- `Sources/ContextSlicer/**`, `Sources/SwiftUIAuditCLI/Main.swift`: self-contained slice provenance.
- Corresponding SymbolResolution, RuleTests and ContextSlicer tests.
- Selected spec leaves/registry, output/reference and first-audit guidance, this record.

Keep graph/config schemas, canonical five-file snapshots, existing good fixture results, automatic CLI fallback, thirty rule IDs, installation, watcher lifecycle, platform severity policy and public 0.6.0 untouched. No publication or installation is included.

## Acceptance

Require focused regressions for partial/stale indexes, warm cache rejection/recovery, leaked draft writes, indexed/syntax/snapshot slice provenance, legacy decode and exact budget behavior. Run the affected package suites and CLI reproductions; protect canonical fixture snapshot semantic bytes and realistic indexed rule parity. Full package tests are warranted because index and normalization changes feed every analysis command. Finish with a current-branch checkpoint commit.

## Delivered behavior and verification

- Index acceptance requires every requested Swift file and rejects newer modification/change times. Source content/timestamps and index-unit identities invalidate warm results; a change during enrichment fails the attempt. Pre-repair whole-result cache keys cannot bypass validation. Rebuilding the exact scope recovers indexed output.
- Transaction classification validates all upstream writes and calls entering their commit paths. Compiler duplicates at the same evidence location and shared read-only accessors preserve correct drafts. Direct `onChange` writes and lifecycle calls to a shared commit helper remain findings in both syntax and real indexed analysis.
- New slices carry resolution, configuration and deterministic full-input provenance inside the token budget. Persisted slices retain the supplied historical manifest. Inconsistent inputs fail; legacy JSON decodes with unknown provenance.
- Full locked `swift test` passed: 105 XCTest cases, including realistic 34-finding syntax/index parity and the compiler-backed leak regressions; the command also completed the package's Swift Testing suites. Locked Release build passed. The final diagnostic-only shortening received focused coverage/freshness checks and a rebuilt Release executable.
- CLI dogfood passed: 20 expected fixture findings, live/persisted slice provenance, empty same-input diff, passing baseline check, zero own-source findings, and five-file snapshot determinism. All four semantic files match the committed fixture baseline byte for byte; manifest normalization changes only repository revision and the fresh revision equals the checked-out HEAD.
- Documentation links, anchors, public-copy constraints, spec line limits and `git diff --check` passed. Temporary compiler fixtures and snapshots were removed by their owning runs.

Pinned clarification leaves: [CLI resolution](../specs/cli/global-resolution-and-scan.md) `spec-9`, [transaction adjudication](../specs/rules/adjudication-and-remediation.md) `spec-5`, and [slice/resolution](../specs/semantic-ir/slice-diff-and-resolution.md) `spec-5`. Registry revision is `spec-37`; semantic epoch remains `tz-v29`.

Residuals: timestamp freshness is conservative validation, not compiler source-content attestation or runtime proof. `doctor .` correctly warns that the package build index does not cover every fixture under the repository root. This checkpoint is current source only: installed CLI/skills, public 0.6.0, hosted CI, landing copy and platform-rule severity were not changed or re-accepted here.
