# SKILL-NON-INTERFERENCE-001 Contract Change Envelope

- Change ID: `SKILL-NON-INTERFERENCE-001`
- Mode: Evolve
- Authorized by: user diagnosis, approved plan, and explicit implementation instruction on 2026-08-25.
- Outcome: make the four SwiftUI semantic skills explicit-only so ordinary SwiftUI work is never intercepted by semantic audit, refactor, review, watcher, or Index Store gates.
- Authorized domains: skill invocation policy, skill descriptions and prompts, router/specialist framing, workflow documentation, validation, evidence mapping, and local skill activation.
- Protected domains: CLI commands and resolution behavior; semantic graph, rules, schemas, watcher behavior, indexed evidence requirements inside an invoked workflow, provider independence, artifact hygiene, released 0.6.0 artifacts, unpublished 0.6.1 CLI behavior, and the public website.
- Previous behavior: broad descriptions allowed automatic skill selection for ordinary ownership, Binding, state, diagnosis, refactor, and review requests; once selected, the indexed semantic workflow could block the user's primary task.
- New behavior: all four skills set `policy.allow_implicit_invocation: false` and are available only through explicit `$skill-name` invocation. Descriptions and bodies state the same boundary. Indexed unavailability blocks only the explicitly invoked semantic result and never authorizes lower-resolution claims.
- Compatibility: intentional skill-invocation change. Explicit semantic workflows retain their existing routing, deterministic fact boundary, indexed-only gates, commands, and failure semantics. The standalone CLI remains unchanged.
- Specification delta: `PC-OPS-005..007`, `ACC-SKILL-002..006/009`, `ACC-DOD-020`, combined epoch `tz-v27`.
- Required QA: validate all four skills with `quick_validate.py`; parse YAML; require explicit-only policy; validate prompts, links, CLI matrix, artifact hygiene, indexed-only guidance, documentation, and clean diffs; activate one commit-pinned local bundle while retaining 0.6.0 rollback assets.
- Task-owned paths: four skill packages, router reference, skill-validation CI, this envelope, applicable product/acceptance/evidence/release contracts, and focused workflow documentation.
- Forbidden expansion: Swift implementation changes, CLI version or command changes, relaxed indexed evidence, syntax-only agent guidance, watcher changes, automatic source rewriting, publication, tag/release creation, upstream tap changes, or website changes.
- Release state: public 0.6.0 and its tagged skills remain immutable. This change updates only current source and, after acceptance, the operator machine's unpublished local four-skill bundle.

## Acceptance scenarios

1. An ordinary SwiftUI implementation, debugging, architecture, refactor, or review request does not inject or activate any of the four skills.
2. Explicit `$swiftui-semantic` invocation selects exactly the requested watcher, audit, refactor, or review route.
3. Explicit specialist invocation runs its complete indexed workflow without weakening existing gates.
4. Missing indexed evidence stops only the explicitly requested semantic result, reports the smallest missing evidence, and does not become a claim about unrelated task progress.

## Local acceptance receipt

- Source checkpoint: `04c8fb84ecc1021cc22853277049222348e03da0` on the operator-selected `master`.
- Built bundle: clean detached checkout `/Users/eugenepotapenko/.local/share/swiftui-semantic-audit/0.6.1-candidate-04c8fb8` at the exact source checkpoint.
- Validation: all four `quick_validate.py` runs passed; repository YAML, policy, prompt, link, CLI-matrix, artifact-hygiene, Markdown-line-limit, and diff checks passed.
- Activation: all four `/Users/eugenepotapenko/.codex/skills/swiftui-*` links resolve to the built bundle, each active metadata file reports `policy.allow_implicit_invocation: false`, and each active `SKILL.md` is byte-identical to the source checkpoint.
- Rollback: the prior `0.6.1-candidate-fe50f87` checkout and released `0.6.0` skill bundle remain unchanged and available.
- External state: no CLI, Homebrew formula, Git remote, tag, release, website, consumer project, watcher service, or public artifact changed.
