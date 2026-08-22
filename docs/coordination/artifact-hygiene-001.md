# ARTIFACT-HYGIENE-001 Contract Delta

- Status: Active candidate
- Date: 2026-08-22
- Mode: Evolve
- External authority: user-approved remediation after inspecting generated run evidence under the version-controlled Codex home
- Combined contract epoch: `tz-v16`
- Domain: agent workflow artifact lifecycle
- Clauses: `PC-OPS-011`, `ACC-SKILL-008`, `ACC-DOD-015`

## Previous behavior

The four skills required JSON stdout, diagnostics, process status, and command
metadata to remain separate, but did not define whether separation required
files, where auxiliary evidence could live, or when it should be removed.
Long-running workflows therefore accumulated reusable command receipts and raw
outputs under a version-controlled Codex configuration home.

## Authorized behavior

- Logical stream separation does not require permanent per-command files.
- Auxiliary evidence is temporary by default and lives outside source
  repositories, Codex configuration homes, and installed skill/package trees.
- Durable cross-handoff evidence requires an explicit non-repository state root,
  minimum necessary contents, and a named retention owner or cleanup condition.
- Explicit canonical snapshots retain the five-file snapshot contract and may
  use a destination deliberately selected by the workflow.
- Existing local run evidence is removed from Git tracking without being
  physically deleted by this change.

## Compatibility and protected domains

This is additive workflow safety. It does not change CLI commands, JSON, graph,
cache, snapshot schemas, indexed-resolution gates, rules, findings, public
release 0.5.0, tagged skills, website behavior, or Homebrew distribution.

## Acceptance

- All four skills link one shared artifact-hygiene policy directly.
- Skill validation proves the policy is reachable and existing metadata/links
  remain valid.
- The Codex configuration repository ignores its artifact root and no longer
  tracks prior run evidence, while the local files remain present.
- Both affected repositories finish with scoped checkpoint commits.
