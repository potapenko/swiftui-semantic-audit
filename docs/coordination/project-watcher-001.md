# PROJECT-WATCHER-001 Contract Change Envelope

- Change ID: `PROJECT-WATCHER-001`
- Mode: Evolve
- Authorized by: user approval on 2026-08-22 of the project setup and watcher implementation plan.
- Outcome: add an opt-in project bootstrap and continuously refreshed semantic workspace mirror for coding agents.
- Authorized domains: project manifest, setup preview/apply, foreground/background watcher lifecycle, freshness receipts, live indexed snapshots, baseline promotion, CLI project namespace, agent workflow integration, documentation, fixtures, and CI.
- Protected domains: released 0.5.0 artifacts; graph schema 2; cache schema 1; thirty rules and severities; the existing seven command semantics; exact five-file canonical snapshots; provider independence; indexed-only agent conclusions; no automatic Swift rewriting; Homebrew remains CLI-only.
- Shared owners: `SemanticInputLoader`, snapshot storage, semantic diff, process runner, CLI command registry, the four installed skills, specs, and CI.
- New behavior: unreleased tool 0.6.0 adds `swiftui-audit project` with setup, watch, start, status, stop, and baseline lifecycle. Runtime state lives outside repositories. A tracked `.swiftui-audit/project.json` and optional indexed baseline provide project integration.
- Freshness rule: a watcher result is agent-usable only when its workspace digest still matches source, its explicit Index Store validates project coverage, its resolution is `indexed`, and its configuration digest matches the current project configuration.
- Setup safety: setup is preview-only unless `--apply` is present, never overwrites an unknown file, and reports every project/runtime write. It does not infer product roles from names.
- Service safety: one writer owns a project runtime lock; external builds and waits are bounded; stale indexed results remain visible only as stale evidence and are never promoted automatically.
- Storage: cache remains under the user cache root; live snapshots, service metadata, and bounded logs use an explicit application-state root with the project service as retention owner; only canonical baselines may be stored in the repository.
- Compatibility: additive unreleased minor evolution. Existing commands work without project setup. Existing snapshots remain readable and keep their exact schema.
- Forbidden expansion: IDE/GUI integration, login autostart, arbitrary untrusted shell commands from a tracked manifest, cloud services, new analysis rules, role inference, automatic commits, release publication, or website changes.
- Required evidence: setup preview/apply/idempotence and path-safety tests; event coalescing; stale/fresh state tests; single-writer tests; indexed fixture end-to-end; snapshot/diff equivalence; foreground/background lifecycle; four-skill validation; locked build/tests; existing dogfood and CI.
- Task-owned paths: `Package.swift`, project/watcher/CLI sources, matching tests/fixtures, four skills and references, applicable specs/coordination/docs, README/development docs, and CI.

## Contract Delta

Previous behavior: seven one-shot CLI commands could cache analysis facts and persist explicit snapshots, but no project bootstrap or continuously refreshed semantic state existed.

New behavior: an explicit project manifest and managed watcher continuously produce freshness-qualified semantic state, reuse the accepted analysis pipeline, expose bounded machine-readable status, and allow deliberate promotion to a Git-tracked baseline.

Release state: implementation candidate only. Publishing 0.6.0, changing the Homebrew formula, or changing the public website requires a separate release envelope.
