# Product contract

- Node type: branch
- Status: Active
- Contract revision: `spec-21`
- Read when: selecting the product goal, invariants, supported operations, scope, or release boundary.
- Do not read when: a narrower linked domain contract fully governs the task.
- Maximum size: 100 physical lines.

Revision: `spec-21`
Authority: epoch `tz-v29`, pinned base digest and authorized addenda in the [registry](README.md)
Status: active; 0.6.0 is the current public release and 0.4.0/0.5.0/0.6.0 artifacts are immutable; the compatible watcher repair CLI is active locally through `BASE-REL-017` and balanced skill activation is pending a new receipt after `BASE-REL-018`

## Choose the governing child

- [Product Architecture and Boundaries](product-contract/architecture-and-boundaries.md) — goal, semantic architecture, ownership invariants, and the deterministic/LLM boundary.
- [Product Operations, Scope, and Release](product-contract/operations-scope-and-release.md) — commands, resolution, safety, PoC limits, non-goals, dogfood, and release truth.
