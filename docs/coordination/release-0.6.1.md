# Contract Change Envelope — RELEASE-0.6.1-001

- Task: prepare a locally verified, unpublished 0.6.1 patch candidate containing `PROJECT-WATCHER-INTEGRATION-001` on the operator-selected `master` branch.
- Change mode: `Evolve` for candidate release identity; the timeout/configuration implementation remains the compatible repair already authorized by `PROJECT-WATCHER-INTEGRATION-001`.
- Authorized by: user approval on 2026-08-23 of the proposed master integration and local 0.6.1 candidate workflow.
- Authorized domains: tool version, exact CI candidate gate, canonical dogfood baselines, watcher/router guidance, candidate documentation, release contracts, and local verification evidence.
- Protected domains: immutable 0.4.0/0.5.0/0.6.0 tags, archives, formulas, and receipts; current public 0.6.0 installation links and website facts; graph/config/cache/status/snapshot schemas; thirty rules and severities; seven one-shot command semantics; project manifest schema 1; provider independence; and indexed-only agent conclusions.
- Candidate identity: current source reports `0.6.1`; old schema-1 project manifests still decode a 300-second watcher timeout, while new manifests may store positive `watch.buildAndAnalysisTimeoutSeconds` and selected-source configuration paths under the integration contract.
- Distribution boundary: this envelope itself authorizes no push, public tag, GitHub Release, public release archive, upstream tap update, Homebrew installation, active skill-link change, or website deployment. [`LOCAL-0.6.1-ACTIVATION-001`](local-0.6.1-activation-001.md) subsequently opens only the pinned local Homebrew and four-skill activation; public release state remains 0.6.0 until a separate publication action and terminal receipt.
- Shared owners: `ToolMetadata`, CI, the RuleTests and indexed-project baselines, the router watcher reference, public candidate notes, the specification registry, and release evidence.
- Required local evidence: focused ProjectWorkspace/WatcherRuntime tests; full locked package tests; debug and Release builds; exact 0.6.1 version output; setup/watch help; safe setup preview; fresh indexed project watcher generation and empty baseline diff; four skill validators plus repository YAML/link checks; documentation checks; website regression tests without publication; and `git diff --check`.
- Candidate checkpoint: `2c07df251390cbda3fc3a277ce3d61fc897d4a44` on the operator-selected `master`, containing integration checkpoint `695038f1c76786c03d2751d7f3bc33315b070dcb`.
- Local acceptance receipt: all required local evidence is terminal — focused suites passed 8/7; full locked tests passed 93 XCTest plus 15 Swift Testing cases; Release build, exact version and setup/watch help passed; setup preview performed no writes; fresh indexed watcher output was 6,286 nodes/24,551 edges/zero findings with an empty baseline diff; RuleTests determinism/check/doctor passed; all four skills, repository YAML/links/docs, 21 website tests, website build/deployment dry-run, and diff hygiene passed.
- Remaining residual: hosted CI remains absent, as do all push, public tag, release archive, upstream tap, website deployment, and publication actions; local CLI and skill activation are separately governed and receipt-gated by `LOCAL-0.6.1-ACTIVATION-001`.
- Local activation state: terminal through `BASE-REL-017`; it changes only this machine and does not publish 0.6.1.
- Candidate stop conditions: baseline incompatibility, semantic dogfood drift not explained by the authorized source change, failed tests/build/help/skill/docs checks, unexpected website or installation changes, dirty unrelated paths, or any required external mutation.
- Pinned basis: integration checkpoint `695038f1c76786c03d2751d7f3bc33315b070dcb`, registry `spec-28`, combined epoch `tz-v23`, and `PROJECT-WATCHER-INTEGRATION-001`.
- Task-owned paths: the exact candidate write set declared in the active implementation plan; consumer repositories, external taps, installed packages, tags, remotes, and website sources remain excluded.

## Contract Delta

Previous behavior: public release 0.6.0 remained immutable while current source contained the compatible watcher integration repair but still reported 0.6.0 and carried stale candidate skill wording and baselines.

New behavior: current source is an explicitly unpublished 0.6.1 patch candidate whose version gates, skills, documentation, and canonical dogfood evidence align with the integrated timeout and selected-source configuration behavior. Publication remains a separate stop-gated operation.
