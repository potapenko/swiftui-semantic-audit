# Contract Change Envelope

- Task: Build SwiftUI Semantic Audit completely from the approved specification.
- Change mode: `evolve` (greenfield implementation).
- User-authorized outcome: A complete Swift Package and `swiftui-audit` CLI satisfying the referenced specification and its Definition of Done.
- Authorized domains: Semantic IR, SwiftSyntax extraction, symbol resolution, SwiftUI normalization, rule engine, snapshots, slices, semantic diff, CLI policy/doctor, fixtures/tests, agent skills, documentation, and CI.
- Authorized clauses: ТЗ sections 1–54.
- Protected adjacent domains: Existing `LICENSE`, current Git branch/history, unrelated user files, system toolchains, external services, and any behavior explicitly deferred by ТЗ section 40.
- Shared owners that may be touched without changing consumer behavior: None at project start.
- Authority status: Active user-supplied contract.
- Stability or release baseline: Greenfield; no prior implementation or release baseline.
- Required evidence: Package resolution, debug build, full tests, deterministic snapshot proof, fixture acceptance, CLI end-to-end runs, independent contract/code review, and requirement-by-requirement completion audit.
- Allowed specification delta: Editorial project documentation and stable clause/acceptance mappings that faithfully restate the user-supplied contract.
- Forbidden specification delta: New product behavior, provider-specific LLM integration, SIL/full type-checker foundation, automatic rewriting, GUI/IDE/Xcode extension, or weakening transactional/transform exceptions.
- Material decisions requiring the user: Only a proven contract conflict, protected-domain expansion, destructive/external authority requirement, or materially different product fork.
- Current contract revision or epoch: `tz-v5` (`tz-v1` base plus authorized addenda through `ARCHITECTURE-001`).
- Pinned contract digest: `sha256:68f8a43d924659024b7d29fabb9ad302817c271838a7919b24bd942626927cac`.
- Required review and QA: Independent review of each integration wave, SwiftPM build/test, CLI fixture validation, deterministic byte comparison, semantic diff/check policy verification, and final completion audit.

## Contract Delta — ROUTER-001

- Change mode: `evolve`.
- Authorized by: User request on 2026-08-18 for one short skill link that chooses among the three existing skills.
- Previous behavior: Users had to select and link audit, refactor, or review directly.
- New behavior: `swiftui-semantic` is the single recommended entry point and routes to one or more unchanged specialist workflows according to task phase.
- Compatibility: Additive and unreleased; the three specialist skills remain independently usable and behaviorally protected.
- Specification delta: `PC-OPS-006`, `ACC-SKILL-001..005`, epoch `tz-v2`.
- QA: Four-skill validation, exact CI inventory, broken-link checks, and fresh-context audit/refactor/review/mixed routing tests.

## Contract Delta — INDEXED-SKILLS-001

- Change mode: `evolve`.
- Authorized by: User request on 2026-08-18 to remove `syntax-only` from the skills after it caused an agent to select incomplete analysis by default.
- Previous behavior: Specialist skills presented build-free analysis as a normal selectable workflow and used it in their primary command examples.
- New behavior: The router and all specialist workflows require a fresh validated compiler Index Store, pass it explicitly for live-source commands, accept only indexed results, and stop when indexed evidence is unavailable. Change review requires compatible indexed snapshots.
- Protected behavior: The standalone CLI retains its build-free mode, schemas, deterministic fixtures/baselines, dogfood, and mixed-resolution safety guards.
- Compatibility: Agent workflow behavior changes intentionally before public release; CLI behavior and public flags remain unchanged.
- Specification delta: `PC-OPS-005`, `PC-OPS-007`, `ACC-SKILL-004..006`, epoch `tz-v3`.
- QA: Four-skill validation, YAML/link validation, zero frontend-only guidance under `skills/`, explicit indexed command review, and CI regression enforcement.

## Contract Delta — BOUNDARY-001

- Change mode: `evolve`.
- Authorized by: User approval on 2026-08-18 of the implementation plan derived from external real-project evaluation.
- Previous behavior: The frontend did not model `Binding(get:set:)`; the six rules did not report command-shaped setters, Binding factories, observable model propagation, or broad observed leaf inputs; wrapper instances could inflate `duplicatedSourcesOfTruth`.
- New behavior: Tool version `0.2.0` retains schema v1, models explicit custom Binding topology, ships four bounded additional findings, and counts logical ownership roots rather than wrapper instances.
- Protected behavior: Existing six rules and exceptions, deterministic/LLM boundary, syntax-only CLI support, indexed-only agent workflows, seven commands, snapshot safety, resolution integrity, provider independence, and no automatic rewriting.
- Forbidden expansion: Name-based controller/service classification, full type checking, general effect/concurrency analysis, or automatic component refactoring.
- Specification delta: `PC-OPS-008`, `PC-SCOPE-002/004`, `PC-NONGOAL-004`, `IR-GRAPH-007`, `IR-AUDIT-005`, four `RULE-*` clauses, `ACC-FIX-007..010`, `ACC-TEST-005`, epoch `tz-v4`.
- QA: Positive and negative fixtures, syntax-only and explicit indexed tests, full build/test, deterministic baseline regeneration, diff/check/slice/doctor dogfood, four-skill validation, scoped review, commit, and upstream push.

## Contract Delta — ARCHITECTURE-001

- Change mode: `evolve`, with a restore sub-slice for pre-index identity collisions.
- Authorized by: User approval on 2026-08-18 of the plan derived from the second real-project agent evaluation.
- Previous behavior: Syntax extraction could collide before compiler-USR enrichment; ten rules covered state-flow and four bounded component boundaries but not explicit application roles, lifecycle/focus/selection architecture, geometry-driven product behavior, platform adapter commands, or preview composition pressure.
- New behavior: Tool `0.3.0` / schema v2 uses collision-safe provisional identities, exact project configuration, typed/feature topology, and twenty-nine bounded rules with dominance and negative fixtures.
- Protected behavior: seven commands, deterministic serialization, relative evidence, explicit indexed agent workflows, syntax-only standalone CLI, existing rule exceptions, transformation/transaction/local UI state protections, provider independence, and no rewriting.
- Forbidden expansion: role inference from spelling, full type checking/SIL/control-flow, generic AppKit/UIKit linting, automatic architecture refactoring, or a new severity above `high`.
- Specification delta: `PC-OPS-009`, `PC-SAFE-002`, schema v2 `IR-GRAPH-008/009`, `analysis-config.md`, nineteen new rules plus bounded extensions to existing rules, epoch `tz-v5`.
- QA: collision and same-name cross-file fixtures, real indexed remap, configuration validation/digest tests, positive/negative and dominance matrices, deterministic baselines, full CLI dogfood, skills, hosted CI, scoped commits and pushes.

## Contract Delta — REALISTIC-FIXTURES-001

- Change mode: `evolve` for acceptance coverage, with a `restore` sub-slice for existing indexed architecture semantics.
- Authorized by: User approval on 2026-08-18 of a realistic multi-file bad/good architecture test pack derived from the read-only Playphrase evaluation.
- Previous behavior: The 77-test suite covered every rule with focused fixtures, but did not prove exact findings in one compilable multi-file feature corpus, stability amid many clean files, or syntax/indexed per-rule/per-file parity. Indexed enrichment could treat `owns` plus `observes`/`injects` for one property as multiple typed boundaries and could associate a compiler-shared method target with receiver evidence from another View.
- New behavior: A twelve-file configured corpus emits exactly 34 findings across 24 rules, keeps all good counterparts clean, preserves findings with forty added clean files, and produces the same matrix in two byte-identical fresh indexed enrichments. Typed boundaries prefer one specific SwiftUI boundary edge, and configured calls require receiver evidence from the same source range.
- Protected behavior: Tool `0.3.0`, schema v2, twenty-nine rules and their severities/exceptions, exact role configuration, seven CLI commands, standalone build-free support, indexed-only agent workflows, canonical RuleTests baseline, provider independence, and no rewriting.
- Forbidden expansion: A thirtieth rule, general control-flow/value-freshness inference, role inference from names, behavior claims for stale mounted values or collection-window progression, or changes to Playphrase source.
- Specification delta: `ACC-FIX-016..017`, `ACC-TEST-008`, `ACC-CI-004`, `ACC-DOD-009`, local revision `spec-6`; product epoch remains `tz-v5`.
- QA: locked build and 81 tests; exact syntax/indexed 34-finding matrix; byte-stable repeated indexed output; forty-file distractor test; old architecture positive/negative checks; Sources dogfood; canonical baseline comparison; CI YAML parse; scoped commits and pushes.
