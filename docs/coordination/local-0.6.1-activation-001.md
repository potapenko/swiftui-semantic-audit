# Contract Change Envelope — LOCAL-0.6.1-ACTIVATION-001

- Task: activate the accepted unpublished 0.6.1 candidate CLI and all four bundled skills on the operator's local machine.
- Change mode: `Evolve` for local installation state only; product, analysis, manifest, and public release semantics are unchanged.
- Authorized by: explicit user request on 2026-08-23 to update the local CLI and skills after candidate acceptance.
- Pinned source: accepted master checkpoint `fe50f872fcaccab3a71e9402bdb4558c64f0f13b`, containing candidate checkpoint `2c07df251390cbda3fc3a277ce3d61fc897d4a44` and integration checkpoint `695038f1c76786c03d2751d7f3bc33315b070dcb`.
- Authorized local state: one no-remote local Homebrew tap, one separately named source-built candidate keg reporting 0.6.1, the active Homebrew CLI link, one commit-pinned versioned candidate checkout under the existing user-owned skill bundle root, and the four existing Codex skill links repointed together.
- Rollback boundary: preserve the released 0.6.0 Homebrew keg and immutable 0.6.0 skill bundle; fail closed if any existing target is not the expected 0.6.0 installation; restore prior links if grouped activation fails.
- Protected domains: public release 0.6.0, immutable tags/archives/formulas/receipts, upstream tap, remotes, website, consumer repositories and manifests, watcher service registration, schemas, rules, command semantics, and agent fact boundaries.
- Forbidden expansion: push, public tag, GitHub Release, upstream tap edit, public formula claim, website deployment, consumer manifest edit, service restart, automatic cleanup of the 0.6.0 rollback state, or describing the candidate as published.
- Required evidence: pinned archive checksum; no-remote tap identity; Homebrew dry-run, unlinked source build, functional formula test, deliberate link switch, active executable path/version/help/doctor; pinned clean skill checkout; four skill validators; exact active link targets; retained 0.6.0 rollback assets; clean repository; and a checkpointed local receipt.

## Contract Delta

Previous state: 0.6.1 was locally accepted but neither installed nor active; the released 0.6.0 Homebrew CLI and four tagged skills remained active.

New authorized state: this one machine may activate the pinned 0.6.1 candidate CLI and skills while public distribution and every external release surface remain at 0.6.0.

## Local Activation Receipt

- Source archive: checkpoint `fe50f872fcaccab3a71e9402bdb4558c64f0f13b`, retained at `~/.local/share/swiftui-semantic-audit/candidates/fe50f872fcaccab3a71e9402bdb4558c64f0f13b/swiftui-semantic-audit-0.6.1.tar.gz`, SHA-256 `440cd2f0ba6364b348d053f4d073a8fdf9be6bfe608badc3d9b2f364b7032fb0`; retention ends after published 0.6.1 replacement or explicit rollback/uninstall.
- Homebrew: no-remote tap `local/swiftui-candidate`; formula `swiftui-semantic-audit-candidate` built from source with automatic resolution disabled, passed dry-run, fetch/checksum, unlinked and linked functional tests, and is linked at keg 0.6.1. Active binary SHA-256 is `74979afbb54c02592e5ac3d726609d93f0e7bab9e1d45fa9f8646f45caa7cff8`.
- CLI verification: `/opt/homebrew/bin/swiftui-audit` resolves to `/opt/homebrew/Cellar/swiftui-semantic-audit-candidate/0.6.1/bin/swiftui-audit`, reports 0.6.1, exposes setup `--watch-timeout` and watch `--timeout`, passes ad-hoc signature verification, and returns doctor schema 2 with overall status `ok`.
- Skills: clean detached checkout `~/.local/share/swiftui-semantic-audit/0.6.1-candidate-fe50f87` is pinned to the exact source checkpoint; all four `quick_validate.py` and repository YAML/link checks passed; the four `~/.codex/skills` links resolve to that one checkout.
- Rollback and exclusions: released formula/keg 0.6.0 and its clean skill bundle remain installed and unmodified but unlinked. No push, tag, release, upstream tap, website, consumer repository, manifest, or watcher service state changed.
