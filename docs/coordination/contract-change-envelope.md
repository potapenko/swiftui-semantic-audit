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
- Current contract revision or epoch: `tz-v2` (`tz-v1` base plus `ROUTER-001`).
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
