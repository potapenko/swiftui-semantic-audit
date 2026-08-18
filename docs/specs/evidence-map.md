# Specification coverage and evidence map

Revision: `spec-3`
Authority: ТЗ epoch `tz-v1` plus user-authorized `ROUTER-001` and `INDEXED-SKILLS-001`, combined epoch `tz-v3`
Purpose: route every source section to stable local clauses and evidence owners

This map proves coverage; it does not create new requirements. Source and tests establish realization only after the normative contract is fixed.

| ТЗ § | Subject | Local contract | Realization/evidence owner |
| ---: | --- | --- | --- |
| 1 | Purpose | `PC-GOAL-001..003` | README, CLI workflows |
| 2 | Imperative state-flow problem | `PC-INV-001..005` | rule fixtures, skills |
| 3 | Semantic data movement | `PC-ARCH-002`, `IR-GRAPH-*` | AuditCore graph, frontend |
| 4 | High-level architecture | `PC-ARCH-001..005` | package targets, CLI |
| 5 | SwiftSyntax/IndexStoreDB/SourceKit-LSP/CLI stack | `PC-ARCH-004`, `PC-RES-*` | Package pins, SymbolResolution, CLI |
| 6 | Excluded PoC foundations | `PC-NONGOAL-001`, `PC-LLM-001` | package dependency boundary |
| 7 | Swift package organization | `PC-ARCH-004` | `Package.swift`, Sources/Tests topology |
| 8 | CLI and seven commands | `PC-OPS-*`, `CLI-GEN-001` | executable help |
| 9 | IR properties | `IR-GRAPH-001` | canonical models/encoders |
| 10 | Node model | `IR-GRAPH-002`, `IR-GRAPH-004` | `NodeKind`, `SemanticNode` |
| 11 | Edge model | `IR-GRAPH-003`, `IR-GRAPH-005` | `EdgeKind`, `SemanticEdge` |
| 12 | Evidence | `IR-EVID-001..002` | evidence validators/tests |
| 13 | Confidence | `IR-EVID-003..004` | `Confidence` enum, reports |
| 14 | Semantic value | `IR-VALUE-001` | normalization/report models |
| 15 | Clustering evidence | `IR-VALUE-002..003` | SemanticNormalization tests |
| 16 | Rule engine/finding | `RULE-ENGINE-*`, `IR-AUDIT-001` | AuditRules engine/models |
| 17 | Required rules 1–3: mirrored state, manual two-way sync, value+setter | `RULE-MIRROR-001`, `RULE-TWOWAY-001`, `RULE-SETTER-001` | bidirectional and setter fixtures |
| 18 | Callback Binding tunnel | `RULE-TUNNEL-001` | callback tunnel fixtures |
| 19 | Observable mirror | `RULE-OBS-001` | ObservableMirror fixture |
| 20 | Stored derived state | `RULE-DERIVED-001` | DerivedState/UnaryDerived fixtures |
| 21 | Suspicious Binding setter | `RULE-EXC-005`, `PC-INV-003` | documented deferred rule boundary |
| 22 | Ownership mismatch | `PC-INV-001..002`, `RULE-REM-001` | metrics/slices/skills |
| 23 | Transactional exceptions | `RULE-EXC-002`, `IR-VALUE-004` | transaction fixtures |
| 24 | LLM adjudicator | `PC-LLM-002`, `RULE-LLM-*` | audit skill |
| 25 | LLM cannot change facts | `PC-LLM-003`, `IR-EVID-004` | all skills |
| 26 | No provider API in PoC | `PC-LLM-004` | dependency and skill checks |
| 27 | Bounded LLM format | `IR-SLICE-*`, `CLI-SLICE-*` | ContextSlicer tests |
| 28 | Persistent sidecar | `IR-SNAP-001..006` | SnapshotStore/tests |
| 29 | Manifest | `IR-SNAP-002` | manifest factory/reader |
| 30 | Stable IDs | `PC-SAFE-002`, `IR-GRAPH-004..005` | StableID tests |
| 31 | Semantic diff kinds | `IR-DIFF-001..003` | SemanticDiff models/tests |
| 32 | Diff interpretation | `IR-DIFF-003..005` | diff fixtures, review skill |
| 33 | Metrics and acceptance criterion | `IR-AUDIT-003`, `PC-INV-005` | reports/check policy |
| 34 | Audit skill | `PC-OPS-005`, `ACC-SKILL-*` | `skills/swiftui-semantic-audit` |
| 35 | Refactor skill | `PC-OPS-005`, `ACC-SKILL-*` | `skills/swiftui-dataflow-refactor` |
| 36 | Change-review skill | `PC-OPS-005`, `ACC-SKILL-*` | `skills/swiftui-change-review` |
| 37 | Skill prohibitions | `PC-INV-003`, `RULE-REM-003` | router plus all three specialist skills |
| 38 | PoC syntax vocabulary | `PC-SCOPE-001` | frontend/vocabulary/tests |
| 39 | Six required rules | `PC-SCOPE-002`, `RULE-*` | AuditRules/RuleTests |
| 40 | Deferred features | `PC-NONGOAL-*` | release baseline limitations |
| 41 | Syntax-only mode | `PC-RES-001`, `IR-RES-001`, `CLI-RES-*` | all live-source commands |
| 42 | Semantic/indexed mode | `PC-RES-002..004`, `CLI-RES-*` | SymbolResolution/tests |
| 43 | Incremental direction | `PC-SCOPE-003` | accepted full-rebuild residual |
| 44 | Fixture strategy | `ACC-FIX-*` | `Tests/Fixtures`, test targets |
| 45 | Mandatory fixtures | `ACC-FIX-001..004` | RuleTests acceptance matrix |
| 46 | Dogfooding | `PC-DOG-001`, `ACC-DOG-*` | CI/local receipts |
| 47 | CI regression policy | `PC-DOG-002`, `ACC-CI-*` | GitHub Actions/check baseline |
| 48 | Agent feedback loop | `PC-OPS-005`, `ACC-DOG-*` | refactor skill |
| 49 | Agent UX | `PC-ARCH-003`, `IR-SLICE-004` | audit/review skills |
| 50 | PoC Definition of Done | `ACC-DOD-001..006` | completion review |
| 51 | Milestone order | `BASE-MILESTONE-001` | goal registry/release baseline |
| 52 | Provider-independent boundary | `PC-ARCH-005`, `PC-LLM-004` | package/skills |
| 53 | Long-term direction | `PC-NONGOAL-003` | non-binding roadmap context |
| 54 | Final product definition | `PC-GOAL-001..003` | README/product contract |

## Router addendum coverage

| Addendum | Subject | Local contract | Realization/evidence owner |
| --- | --- | --- | --- |
| `ROUTER-001` | One concise skill link that selects audit, refactor, review, or the smallest valid sequence | `PC-OPS-006`, `ACC-SKILL-001..005` | `skills/swiftui-semantic`, CI validation, forward tests |
| `INDEXED-SKILLS-001` | Agent workflows require explicit indexed resolution and reject lower-resolution fallback | `PC-OPS-005`, `PC-OPS-007`, `ACC-SKILL-004..006` | all four skills, skill references, CI validation |

## Evidence precedence by decision

| Decision | Expected contract | Protected behavior | Required evidence |
| --- | --- | --- | --- |
| Finding correctness | `rules.md`, `semantic-ir.md` | exceptions and fact boundary | graph/report JSON, fixture tests, slice |
| CLI behavior | `cli.md` | flags, status, path/resolution safety | command help, end-to-end invocation |
| Snapshot/diff | `semantic-ir.md` | determinism/integrity/mixed-mode guard | five-file byte compare, reader/diff tests |
| Refactor acceptance | `product-contract.md`, skills | behavior, ownership, lifetime, transaction | build/tests + audit/diff/check |
| Release readiness | `acceptance.md`, `release-baseline.md` | truthful unreleased status | full tests, dogfood, CI, independent review |

## Ownership map

- Product authority: user-approved base epoch `tz-v1` plus explicit `ROUTER-001` and `INDEXED-SKILLS-001`, combined as `tz-v3`; local documents remain bounded to those authorizations.
- Semantic schema owner: `AuditCore` plus SnapshotStore transport.
- Syntax fact owner: SwiftSyntaxFrontend and SwiftUISemantics vocabulary.
- Compiler fact owner: SymbolResolution/IndexStoreDB on macOS.
- Finding owner: AuditRules over normalized graph.
- Persistence/slice owner: SnapshotStore and ContextSlicer.
- Comparison/policy/doctor owner: SemanticDiff and CLI commands.
- Agent judgment owner: surrounding agent skills, limited by the immutable fact boundary.
- Acceptance owner: fixtures/tests, canonical baseline, dogfood commands, and CI.
