# Project watcher acceptance

- Node type: leaf
- Status: Active
- Contract revision: `spec-1`
- Authority: `PROJECT-WATCHER-001`
- Read when: implementing or verifying project setup and continuous analysis.
- Maximum size: 100 physical lines.

**ACC-PRJ-001.** Preview performs zero writes; apply matches the preview; a second apply is byte-identical; conflicts, unsafe paths, symlinks, and ambiguous project choices fail closed.

**ACC-PRJ-002.** SwiftPM and Xcode typed adapters expose exact bounded invocations. Tests use fakes for deterministic process behavior and one fresh compiler-backed fixture for accepted indexed coverage.

**ACC-WATCH-001.** Add/change/delete/rename/config events advance a monotonic generation, coalesce bursts, invalidate stale results immediately, and cannot let superseded work publish as current.

**ACC-WATCH-002.** Warm watcher output and the existing uncached one-shot pipeline are byte-equivalent. Every fresh agent-consumable snapshot is indexed, validates as an exact five-file snapshot, and carries the current configuration digest.

**ACC-WATCH-003.** Build failure, timeout, missing coverage, corrupt state, and service restart preserve a compact failure status without presenting stale indexed evidence as fresh.

**ACC-WATCH-004.** One project lock permits one writer. Foreground and background lifecycle are bounded, idempotent where specified, isolated per project, and leave no test processes or repository runtime artifacts.

**ACC-WATCH-005.** Baseline update requires fresh indexed state, uses the existing atomic writer contract, produces a compatible semantic diff, and does not stage or commit files.

**ACC-WATCH-006.** The router handles explicit setup requests and all four skills consume watcher evidence only with a fresh receipt. Existing explicit-index workflows remain the fallback; validation still rejects syntax-only agent guidance.

**ACC-WATCH-007.** Locked build, full tests, current dogfood, cache/no-cache equivalence, serial/parallel equivalence, snapshot determinism, skill validation, and hosted CI remain terminal before the 0.6.0 candidate is accepted.
