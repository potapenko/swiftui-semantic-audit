# Specification coverage and evidence map

- Node type: hybrid
- Status: Active
- Contract revision: `spec-13`
- Read when: tracing original sections or authorized addenda to stable clauses and evidence ownership.
- Do not read when: the governing contract is already selected and traceability is not in question.
- Maximum size: 100 physical lines.

Revision: `spec-13`
Authority: ТЗ epoch `tz-v1` plus user-authorized addenda through `PROJECT-WATCHER-001`, combined epoch `tz-v17`
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
| 8 | CLI analysis commands and project namespace | `PC-OPS-*`, `CLI-GEN-001`, `CLI-PRJ-*` | executable help |
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
| 21 | Suspicious Binding setter | `RULE-COMMAND-001`, `RULE-EXC-005`, `PC-INV-003` | custom Binding positive/negative fixtures |
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
| 43 | Incremental analysis | `PC-SCOPE-003/005`, `IR-CACHE-*`, `CLI-CACHE-*` | AnalysisCache, frontend/symbol resolution, focused cache tests |
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

`COMPONENT-SURFACE-001` maps to `PC-OPS-010`, `CFG-003/004/009`, `IR-GRAPH-010`, `RULE-REUSABLE-OWNER-001`, `RULE-DOM-001`, `RULE-EXC-011`, and `ACC-COMP-001..007`; realization owners are AuditCore configuration, AuditRules, ContextSlicer, configured fixtures, skills, and CI. `RELEASE-0.5.0-001` maps to `PC-REL-002..004`, `CLI-GEN-005`, `ACC-BREW-001..004`, `ACC-DOD-013..014`, and `WEB-CLAIM-001`; realization owners are the immutable tag/archive, tap formula, release docs, four tagged skills, and publication receipt.

`ARTIFACT-HYGIENE-001` maps to `PC-OPS-011`, `ACC-SKILL-008`, and `ACC-DOD-015`; realization owners are the shared skill reference, all four direct skill links, skill validation, and the Codex configuration ignore/runtime-evidence policy.

`PROJECT-WATCHER-001` maps to `PC-OPS-012`, `PRJ-*`, `CLI-PRJ-*`, `ACC-PRJ-*`, `ACC-WATCH-*`, and `ACC-DOD-016`; realization owners are ProjectWorkspace, WatcherRuntime, the CLI project namespace, the four skills, the tracked dogfood manifest/baseline, tests, docs, and CI.

## Choose the supporting map

- [Authorized addenda and evidence precedence](evidence-map/addenda-and-precedence.md) — addendum coverage and decision-specific evidence requirements.
- [Ownership map](evidence-map/ownership.md) — responsibility owners across facts, findings, persistence, comparison, judgment, and acceptance.
