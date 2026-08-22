# Authorized Addenda and Evidence Precedence

- Node type: leaf
- Status: Active
- Contract revision: `spec-13`
- Authority: [Specification coverage and evidence map](../evidence-map.md)
- Read when: tracing an authorized addendum or selecting evidence for a product decision.
- Do not read when: only source-section coverage or ownership is needed.
- Maximum size: 100 physical lines.

## Authorized addendum coverage

| Addendum | Subject | Local contract | Realization/evidence owner |
| --- | --- | --- | --- |
| `ROUTER-001` | One concise skill link that selects audit, refactor, review, or the smallest valid sequence | `PC-OPS-006`, `ACC-SKILL-001..005` | `skills/swiftui-semantic`, CI validation, forward tests |
| `INDEXED-SKILLS-001` | Agent workflows require explicit indexed resolution and reject lower-resolution fallback | `PC-OPS-005`, `PC-OPS-007`, `ACC-SKILL-004..006` | all four skills, skill references, CI validation |
| `BOUNDARY-001` | Custom Binding, Binding factory, observable tunnel/input rules, and logical source counting | `PC-OPS-008`, `PC-SCOPE-002/004`, `RULE-COMMAND/FACTORY/MODEL-TUNNEL/BROAD-INPUT`, `IR-GRAPH-007`, `IR-AUDIT-005`, `ACC-FIX-007..010` | frontend, AuditCore/AuditRules, diff, fixtures, indexed tests |
| `ARCHITECTURE-001` | Collision-safe identity, exact project configuration, typed/feature topology, and nineteen architecture rules | `PC-OPS-009`, `PC-SAFE-002`, `IR-GRAPH-008/009`, `CFG-*`, architecture/layout/platform `RULE-*`, `ACC-FIX-011..015` | AuditCore configuration, frontend, SymbolResolution, AuditRules, architecture fixtures and indexed tests |
| `REALISTIC-FIXTURES-001` | Compilable multi-file good/bad corpus, mixed-directory invariance, and syntax/indexed matrix parity | existing `RULE-*`, `ACC-FIX-016..017`, `ACC-TEST-008`, `ACC-DOD-009` | `RealProjectPatterns`, focused rule/indexed tests, CLI CI dogfood |
| `INCREMENTAL-CACHE-001` | Persistent content-addressed frontend/indexed fact reuse with uncached byte equivalence | `PC-SCOPE-003/005`, `IR-CACHE-*`, `CLI-CACHE-*`, `ACC-CACHE-*`, `ACC-DOD-010` | AnalysisCache, GraphScanner, SymbolResolution, CLI, cache tests, CI |
| `PARALLEL-EXECUTION-001` | CPU-scaled frontend/rule execution with explicit job control and serial/parallel equivalence | `PC-SCOPE-006`, `CLI-EXEC-001`, `ACC-PERF-001` | GraphScanner, AuditEngine, CLI live-source commands, determinism and Thread Sanitizer tests |
| `HOMEBREW-RELEASE-001` | Stable 0.4.0 tag/release, version output, and upstream Homebrew tap distribution | `PC-REL-002..003`, `CLI-GEN-005`, `ACC-BREW-*`, `ACC-DOD-012` | `SwiftUIAuditCLI`, release documentation, `potapenko/homebrew-tap`, brew audit/install/test receipt |
| `COMPONENT-SURFACE-001` | Exact reusable/screen/container roles, component-model lifetime boundary, and one candidate rule | `PC-OPS-010`, `CFG-*`, `IR-GRAPH-010`, `RULE-REUSABLE-OWNER-001`, `ACC-COMP-*` | AuditCore config, AuditRules, ContextSlicer, fixtures, skills, CI |
| `RELEASE-0.5.0-001` | Stable publication of the accepted component candidate and tagged skills | `PC-REL-002..004`, `CLI-GEN-005`, `ACC-BREW-*`, `ACC-DOD-013..014`, `WEB-CLAIM-001` | immutable 0.5.0 tag/archive, release docs/site facts, `potapenko/homebrew-tap`, local and hosted receipts |
| `ARTIFACT-HYGIENE-001` | Temporary-by-default auxiliary agent evidence, explicit non-repository durable state, and bounded retention | `PC-OPS-011`, `ACC-SKILL-008`, `ACC-DOD-015` | shared skill policy, four direct links, CI validation, Codex ignore/runtime-evidence policy |
| `PROJECT-WATCHER-001` | Safe project bootstrap, freshness-qualified continuous indexed state, managed lifecycle, and baseline promotion | `PC-OPS-012`, `PRJ-*`, `CLI-PRJ-*`, `ACC-PRJ-*`, `ACC-WATCH-*`, `ACC-DOD-016` | ProjectWorkspace, WatcherRuntime, CLI, four skills, dogfood baseline, tests, CI |

## Evidence precedence by decision

| Decision | Expected contract | Protected behavior | Required evidence |
| --- | --- | --- | --- |
| Finding correctness | `rules.md`, `semantic-ir.md` | exceptions and fact boundary | graph/report JSON, fixture tests, slice |
| CLI behavior | `cli.md` | flags, status, path/resolution safety | command help, end-to-end invocation |
| Snapshot/diff | `semantic-ir.md` | determinism/integrity/mixed-mode guard | five-file byte compare, reader/diff tests |
| Watcher freshness | `project-runtime.md` | indexed-only agent evidence, runtime isolation, one writer | status receipt, explicit coverage, live snapshot validation, lifecycle tests |
| Refactor acceptance | `product-contract.md`, skills | behavior, ownership, lifetime, transaction | build/tests + audit/diff/check |
| Release readiness | `acceptance.md`, `release-baseline.md` | truthful candidate/released state and immutable distribution | full tests, dogfood, CI, tag/archive checksum, formula audit/install/test receipt |
