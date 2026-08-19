# Product contract

- Node type: branch
- Status: Active
- Contract revision: `spec-6`
- Read when: selecting the product goal, invariants, supported operations, scope, or release boundary.
- Do not read when: a narrower linked domain contract fully governs the task.
- Maximum size: 100 physical lines.

Revision: `spec-6`
Authority: epoch `tz-v6`, pinned base digest and authorized addenda through `INCREMENTAL-CACHE-001` in the [registry](README.md)
Status: active, unreleased

## Choose the governing child

- [Product Architecture and Boundaries](product-contract/architecture-and-boundaries.md) — goal, semantic architecture, ownership invariants, and the deterministic/LLM boundary.
- [Product Operations, Scope, and Release](product-contract/operations-scope-and-release.md) — commands, resolution, safety, PoC limits, non-goals, dogfood, and release truth.
