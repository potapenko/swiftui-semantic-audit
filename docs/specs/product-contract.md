# Product contract

- Node type: branch
- Status: Active
- Contract revision: `spec-16`
- Read when: selecting the product goal, invariants, supported operations, scope, or release boundary.
- Do not read when: a narrower linked domain contract fully governs the task.
- Maximum size: 100 physical lines.

Revision: `spec-16`
Authority: epoch `tz-v23`, pinned base digest and authorized addenda in the [registry](README.md)
Status: active; 0.6.0 is the current public release and 0.4.0/0.5.0/0.6.0 artifacts are immutable; compatible watcher integration repair is evolving in source

## Choose the governing child

- [Product Architecture and Boundaries](product-contract/architecture-and-boundaries.md) — goal, semantic architecture, ownership invariants, and the deterministic/LLM boundary.
- [Product Operations, Scope, and Release](product-contract/operations-scope-and-release.md) — commands, resolution, safety, PoC limits, non-goals, dogfood, and release truth.
