# Product Architecture and Boundaries

- Node type: leaf
- Status: Active
- Contract revision: `spec-7`
- Authority: [Product contract](../product-contract.md)
- Read when: selecting the product goal, invariants, supported operations, scope, or release boundary.
- Do not read when: a narrower linked domain contract fully governs the task.
- Maximum size: 100 physical lines.


## Goal and consumer

**PC-GOAL-001 — Product identity.** `swiftui-audit` is a deterministic semantic compiler from Swift/SwiftUI source to a compact state/data-flow graph for LLM-agent reasoning, architectural self-audit, and semantic diff. It is not a conventional linter or code-review bot.

**PC-GOAL-002 — Primary consumer.** Optimize the interface for coding agents. Present state, ownership, dependencies, reads, writes, bindings, effects, derivation, and synchronization paths before full source.

**PC-GOAL-003 — Practical outcome.** Enable an agent to detect imperative SwiftUI state-flow patterns, prove duplicated/manual synchronization and selected component-boundary leaks, adjudicate intent, and verify a behavior-preserving move toward canonical declarative data architecture.

**PC-GOAL-004 — Semantic twin.** The product-facing name for the compact graph, evidence, slices, and compatible snapshots is a semantic twin: a deterministic, simplified representation of supported Swift/SwiftUI program facts built from source and, for agent workflows, fresh compiler-index evidence. It preserves ownership, state, Bindings, reads, writes, derivations, dependencies, component boundaries, lifecycle, effects, identity, confidence, and source provenance while discarding nonessential syntax. It is not an LLM summary, model-written pseudocode, source authority, runtime simulation, or complete behavioral model.

## Semantic-first architecture

**PC-ARCH-001 — Fact pipeline.** Preserve this boundary:

```text
Swift source → SwiftSyntax facts → optional indexed facts → semantic graph
             → rules/snapshots → bounded slice → agent adjudication
```

**PC-ARCH-002 — Semantic normalization.** Normalize SwiftUI constructs into a small vocabulary of ownership, reads, writes, binding, observation, injection, derivation, copies, triggers, and calls. Analyze value movement rather than wrapper spelling.

**PC-ARCH-003 — Source role.** Keep source as evidence and fallback detail. Agents audit and slice first, then inspect only evidence locations and directly required declarations.

**PC-ARCH-004 — Package shape.** Provide reusable Swift library targets and one `swiftui-audit` executable with subcommands. SwiftSyntax is the parser/frontend; `swift-argument-parser` owns the CLI; IndexStoreDB may enrich cross-file facts on macOS.

**PC-ARCH-005 — Provider independence.** Keep extraction, graph construction, rules, persistence, slicing, and diff independent of OpenAI, Codex, Claude, ChatGPT, and prompt/runtime implementations.

## Ownership and correctness invariants

**PC-INV-001 — Ownership over wrappers.** Ask who owns a semantic value, which representation is canonical, and what lifetime/write authority applies before recommending a property wrapper.

**PC-INV-002 — Optimization target.** Optimize for correct ownership, a single canonical source of truth where appropriate, explicit dependencies, minimal manual synchronization, correct lifetime, and correct transaction semantics.

**PC-INV-003 — Forbidden heuristics.** Never use “Binding everywhere” or “minimize `@State`” as a product rule. A Binding with unrelated setter effects can still be architecturally suspicious.

**PC-INV-004 — Exceptions.** Do not collapse transactional drafts, intentional transformations, or legitimate view-local UI state into direct Binding merely because multiple representations exist.

**PC-INV-005 — Metric discipline.** Retain raw metrics. Never accept a change solely because an aggregate debt score decreased. Require no new high-confidence violations, reduction of targeted violations, and preserved behavior.

## Deterministic facts and LLM boundary

**PC-LLM-001 — Extractor boundary.** Never use an LLM as the parser or deterministic extractor.

**PC-LLM-002 — Adjudicator role.** An LLM may classify a candidate, name intent, explain risk, or recommend remediation after receiving a minimal deterministic slice.

**PC-LLM-003 — Immutable facts.** LLM reasoning must not alter AST facts, symbol identities, read/write edges, compiler-derived relations, or source locations.

**PC-LLM-004 — No embedded provider.** The PoC CLI must not call a model-provider API. It emits provider-neutral `llm-json`; the surrounding agent performs reasoning.
