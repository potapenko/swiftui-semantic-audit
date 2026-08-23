# Contract Change Envelope — RELEASE-0.6.1-001

- Task: prepare a locally verified, unpublished 0.6.1 patch candidate containing `PROJECT-WATCHER-INTEGRATION-001` on the operator-selected `master` branch.
- Change mode: `Evolve` for candidate release identity; the timeout/configuration implementation remains the compatible repair already authorized by `PROJECT-WATCHER-INTEGRATION-001`.
- Authorized by: user approval on 2026-08-23 of the proposed master integration and local 0.6.1 candidate workflow.
- Authorized domains: tool version, exact CI candidate gate, canonical dogfood baselines, watcher/router guidance, candidate documentation, release contracts, and local verification evidence.
- Protected domains: immutable 0.4.0/0.5.0/0.6.0 tags, archives, formulas, and receipts; current public 0.6.0 installation links and website facts; graph/config/cache/status/snapshot schemas; thirty rules and severities; seven one-shot command semantics; project manifest schema 1; provider independence; and indexed-only agent conclusions.
- Candidate identity: current source reports `0.6.1`; old schema-1 project manifests still decode a 300-second watcher timeout, while new manifests may store positive `watch.buildAndAnalysisTimeoutSeconds` and selected-source configuration paths under the integration contract.
- Distribution boundary: no push, tag, GitHub Release, archive, tap update, Homebrew installation, active skill-link change, or website deployment is authorized by this envelope. Public release state remains 0.6.0 until a separate publication action and terminal receipt.
- Shared owners: `ToolMetadata`, CI, the RuleTests and indexed-project baselines, the router watcher reference, public candidate notes, the specification registry, and release evidence.
- Required local evidence: focused ProjectWorkspace/WatcherRuntime tests; full locked package tests; debug and Release builds; exact 0.6.1 version output; setup/watch help; safe setup preview; fresh indexed project watcher generation and empty baseline diff; four skill validators plus repository YAML/link checks; documentation checks; website regression tests without publication; and `git diff --check`.
- Candidate stop conditions: baseline incompatibility, semantic dogfood drift not explained by the authorized source change, failed tests/build/help/skill/docs checks, unexpected website or installation changes, dirty unrelated paths, or any required external mutation.
- Pinned basis: integration checkpoint `695038f1c76786c03d2751d7f3bc33315b070dcb`, registry `spec-28`, combined epoch `tz-v23`, and `PROJECT-WATCHER-INTEGRATION-001`.
- Task-owned paths: the exact candidate write set declared in the active implementation plan; consumer repositories, external taps, installed packages, tags, remotes, and website sources remain excluded.

## Contract Delta

Previous behavior: public release 0.6.0 remained immutable while current source contained the compatible watcher integration repair but still reported 0.6.0 and carried stale candidate skill wording and baselines.

New behavior: current source is an explicitly unpublished 0.6.1 patch candidate whose version gates, skills, documentation, and canonical dogfood evidence align with the integrated timeout and selected-source configuration behavior. Publication remains a separate stop-gated operation.
