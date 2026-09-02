# SKILL-BALANCED-INVOCATION-001 Contract Change Envelope

- Change ID: `SKILL-BALANCED-INVOCATION-001`
- Mode: Evolve
- Authorized by: user diagnosis, approved correction plan, and explicit implementation instruction on 2026-09-02.
- Outcome: restore useful automatic semantic assistance without allowing setup, watcher, build, snapshot, or strict audit gates to take over an ordinary SwiftUI task.
- Authorized domains: router invocation policy and description, router assist/strict mode selection, focused workflow documentation, skill validation, evidence mapping, and local skill activation.
- Protected domains: three specialist skills remain explicit-only; CLI commands and resolution behavior; semantic graph, rules, schemas, watcher behavior, strict indexed evidence requirements, provider independence, artifact hygiene, released 0.6.0 artifacts, unpublished 0.6.1 CLI behavior, and the public website.
- Previous behavior: `SKILL-NON-INTERFERENCE-001` made all four skills explicit-only. This prevented interference but also removed useful automatic semantic assistance from relevant ownership and data-flow work.
- New behavior: only `swiftui-semantic` permits implicit invocation. Implicit assist mode uses already-ready, fresh, compatible indexed evidence when it materially helps the current task, remains bounded to that task, and never creates semantic infrastructure or blocks ordinary progress. Explicit router or specialist invocation enters the existing strict indexed workflow.
- Compatibility: intentional router-invocation correction. Specialist workflows, deterministic facts, strict indexed gates, CLI behavior, watcher behavior, and released bundles remain unchanged.
- Specification delta: `PC-OPS-005..007`, `ACC-SKILL-002..006/009`, `ACC-CI-004`, `ACC-DOD-022`, combined epoch `tz-v29`.
- Required QA: validate all four skills with `quick_validate.py`; parse YAML; require implicit policy only for the router; validate prompts, links, CLI matrix, artifact hygiene, strict indexed guidance, assist-mode boundaries, focused documentation, and clean diffs; run fresh-context positive and negative routing checks; activate one clean commit-pinned local bundle while retaining prior rollback assets.
- Task-owned paths: four skill packages, the new assist-mode reference, router reference, skill-validation CI, this envelope, applicable product/acceptance/evidence/release contracts, and focused README/workflow documentation.
- Forbidden expansion: Swift implementation changes, CLI version or command changes, relaxed strict indexed evidence, lower-resolution semantic claims, watcher changes, automatic source rewriting, publication, tag/release creation, upstream tap changes, or website changes.
- Release state: public 0.6.0 and its tagged skills remain immutable. This change updates current source and, after acceptance, only the operator machine's unpublished local four-skill bundle.

## Mode boundary

1. Implicit assist mode is selected only when semantic ownership, duplicated or derived state, manual synchronization, Binding/Observation/Environment flow, or component-boundary data flow materially affects the user's task.
2. Assist mode may consume a ready fresh watcher snapshot, a compatible indexed snapshot, or an already-available project-covering Index Store through one bounded audit and, only when needed for the current decision, one focused slice. It does not configure or start a watcher, run setup, build only to produce an index, create or promote a baseline, or launch the full specialist pipeline.
3. If qualifying evidence is absent, assist mode continues the user's task with ordinary source and test evidence and mentions the semantic verification gap only when relevant.
4. Explicit `$swiftui-semantic`, explicit specialist invocation, or an explicit request to run the semantic audit/refactor/review workflow enters strict mode and retains the complete indexed gates.

## Acceptance scenarios

1. A relevant SwiftUI ownership or data-flow task can automatically receive bounded semantic evidence when fresh indexed state is already ready.
2. A relevant task without ready indexed state continues normally and does not trigger setup, watcher lifecycle, a build solely for indexing, snapshot creation, or a blocking audit gate.
3. An unrelated layout, styling, generic framework, performance, concurrency, or security task does not select the semantic router.
4. Explicit router and specialist invocations retain the full strict indexed workflow and its failure policy.
5. The three specialist skills remain unavailable for implicit invocation.

## Local acceptance receipt

- Source checkpoint: `c0d5ab499bbb4eab4353057af1440f6248406c57` on the operator-selected `master`.
- Built bundle: clean detached checkout `/Users/eugenepotapenko/.local/share/swiftui-semantic-audit/0.6.1-candidate-c0d5ab4` at the exact source checkpoint.
- Validation: all four `quick_validate.py` runs passed; repository skill/YAML/policy/prompt/link checks, documentation/anchor checks, workflow YAML parsing, specification line limits, and diff hygiene passed.
- Fresh-context behavior: relevant ownership/manual-sync work without indexed evidence selected only the router and continued without commands or infrastructure; layout/animation selected no semantic skill; explicit `$swiftui-semantic` selected strict audit and stopped without indexed evidence; ordinary ownership review selected the router without directly activating a specialist.
- Activation: all four `/Users/eugenepotapenko/.codex/skills/swiftui-*` links resolve to the new bundle and match source bytes. `swiftui-semantic` reports `allow_implicit_invocation: true`; the three specialists report `false`.
- Rollback: prior candidate `0.6.1-candidate-04c8fb8`, earlier `0.6.1-candidate-fe50f87`, and released `0.6.0` bundles remain unchanged and available.
- External state: no CLI, Homebrew formula, Git remote, tag, release, website, consumer project, watcher service, or public artifact changed.
