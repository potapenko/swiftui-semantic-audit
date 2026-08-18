# Product contract

Revision: `spec-4`
Authority: epoch `tz-v4`, pinned base digest, `ROUTER-001`, `INDEXED-SKILLS-001`, and `BOUNDARY-001` in the [registry](README.md)
Status: active, unreleased

## Goal and consumer

**PC-GOAL-001 — Product identity.** `swiftui-audit` is a deterministic semantic compiler from Swift/SwiftUI source to a compact state/data-flow graph for LLM-agent reasoning, architectural self-audit, and semantic diff. It is not a conventional linter or code-review bot.

**PC-GOAL-002 — Primary consumer.** Optimize the interface for coding agents. Present state, ownership, dependencies, reads, writes, bindings, effects, derivation, and synchronization paths before full source.

**PC-GOAL-003 — Practical outcome.** Enable an agent to detect imperative SwiftUI state-flow patterns, prove duplicated/manual synchronization and selected component-boundary leaks, adjudicate intent, and verify a behavior-preserving move toward canonical declarative data architecture.

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

## Supported operations

**PC-OPS-001 — Graph and findings.** Provide `scan` and `audit` over a Swift file or directory, including a build-free syntax-only path.

**PC-OPS-002 — Persistent context.** Provide deterministic five-file snapshots and bounded finding/symbol slices.

**PC-OPS-003 — Change control.** Provide semantic diff over snapshots or Git revisions and a `check` policy that fails only for new findings at/above a configured threshold.

**PC-OPS-004 — Environment diagnosis.** Provide a non-mutating `doctor` command for Swift, Xcode/toolchain, project type, SwiftSyntax compatibility, Index Store readiness, and Git.

**PC-OPS-005 — Specialist agent workflows.** Supply reusable audit, refactor, and change-review skills that use JSON first, slice before source, preserve indexed resolution, and enforce the LLM fact boundary.

**PC-OPS-006 — Single routing entry point.** Supply `swiftui-semantic` as the concise user-facing skill. It classifies the requested outcome, loads only the appropriate specialist workflow first, and sequences audit, refactor, and review only when the task crosses those phases. It must preserve deterministic facts, resolution, baseline identities, evidence, invariants, and failure state across handoffs rather than duplicating or weakening specialist gates.

**PC-OPS-007 — Indexed agent boundary.** Agent-facing semantic audit, refactor, and review workflows require a fresh validated compiler Index Store, pass its path explicitly for live-source analysis, and accept only `resolution: "indexed"`. They must not recommend the build-free frontend mode, omit resolution flags in reliance on automatic discovery, or present a lower-resolution result as a semantic workflow result. Missing indexed coverage is a blocking evidence failure, not permission to weaken the workflow. The standalone CLI retains its build-free fallback for non-agent uses and deterministic test/dogfood coverage.

**PC-OPS-008 — Boundary analysis.** Represent explicit `Binding(get:set:)` construction and its getter/setter closures, detect command-shaped setters and Binding factories, identify the same observable model crossing multiple View boundaries, and emit a candidate when a leaf View directly depends on externally observed model members. Keep deterministic topology separate from the agent's decision about legitimate screen ownership or component isolation.

## Resolution and platform

**PC-RES-001 — Syntax-only guarantee.** Support useful analysis without a build or index and label it `resolution: "syntax-only"`.

**PC-RES-002 — Indexed enrichment.** On macOS, accept an explicit compiler Index Store or conservatively discover a unique validated local store and enrich with compiler symbol/use relations.

**PC-RES-003 — Conservative fallback.** Automatic indexed mode may return syntax-only output when readiness or unambiguous coverage is absent. Explicit index requests fail instead of silently weakening resolution.

**PC-RES-004 — Comparison integrity.** Reject graph/report inconsistency and comparisons between indexed and syntax-only inputs.

## Determinism, path safety, and failure

**PC-SAFE-001 — Deterministic serialization.** Sort graph entities, findings, semantic values, changes, and JSON keys canonically. Repeated snapshot generation from unchanged source, toolchain, revision, and resolution must be byte-equivalent across all five files. When comparing a committed baseline across later commits, `nodes.jsonl`, `edges.jsonl`, `findings.jsonl`, and `summary.json` remain byte-exact; only `manifest.json.repositoryRevision` may be normalized, while every other manifest field remains exact and the fresh revision must equal the checked-out `HEAD`.

**PC-SAFE-002 — Stable identity.** Prefer compiler symbol identity; otherwise derive IDs from module, qualified declaration, kind, and structural discriminator. Do not use line number as primary identity.

**PC-SAFE-003 — Relative provenance.** Never persist absolute source paths in canonical graph evidence or `generatedFrom`.

**PC-SAFE-004 — Snapshot boundary.** Require exactly five regular non-symlink files, canonical ID order, referential integrity, matching schema/resolution, and safe non-overlapping source/output locations. Replace only a validated existing snapshot.

**PC-SAFE-005 — Bounded externals.** Bound Git, Swift, Xcode, index helper, and similar process calls. Fail the current attempt on timeout rather than waiting indefinitely.

**PC-SAFE-006 — Machine output.** Emit requested JSON/JSONL to stdout or explicit output files. Keep diagnostics on stderr and express policy failure with a nonzero status.

**PC-SAFE-007 — Fail closed on ambiguity.** Reject unknown/ambiguous slice selectors, invalid budgets, unsafe paths, invalid revisions, malformed snapshots, explicit index failures, and resolution mismatches. Do not fabricate missing facts.

## PoC scope

**PC-SCOPE-001 — Supported vocabulary.** Cover SwiftUI view discovery, `@State`, `@Binding`, `@Bindable`, `@Environment`, property access, assignments, callbacks/closures, initializer propagation, `.onChange`, `.onAppear`, `.task`, `.task(id:)`, and common controls (`TextField`, `Toggle`, `Slider`, `Picker`) to the extent exercised by accepted fixtures.

**PC-SCOPE-002 — Required rules.** Ship mirrored state, manual two-way synchronization, value+setter pair, callback Binding tunnel, observable-state mirror, stored derived state, command-shaped Binding, Binding factory, observable-model tunnel, and broad observable input.

**PC-SCOPE-003 — Full rebuild.** A full graph rebuild is acceptable in the PoC. Incremental caching by content/tool/schema hash is a future direction, not a current guarantee.

**PC-SCOPE-004 — Source-count semantics.** Count logical ownership roots, not wrapper instances. A focused `State → Binding → Binding` chain has one source; an external borrowed Binding or observable root plus a distinct local State has two. Binding projections and `@Bindable` receivers are representations, not independent owners.

## Non-goals

**PC-NONGOAL-001.** Do not make SIL, a full Swift type checker, full interprocedural/alias/control-flow analysis, or generic support for every Swift framework part of the PoC foundation.

**PC-NONGOAL-002.** Do not provide automatic source rewriting, embedded LLM API integration, an IDE plugin, GUI, Xcode extension, security analysis, or performance analysis.

**PC-NONGOAL-003.** Future analysis of concurrency, async tasks, actors, dependency injection, navigation, persistence, resources, networking, errors, and general effects is directional context only, not current behavior.

**PC-NONGOAL-004.** Do not classify arbitrary plain properties as feature models, controllers, or services from names or types alone. General component-role inference requires a later typed semantic contract; `broad-observable-input` is limited to explicit observed/injected topology and remains an agent-adjudicated candidate.

## Dogfood and release

**PC-DOG-001 — Dogfood.** Run the CLI against its accepted fixtures and its own Swift sources as part of development and CI.

**PC-DOG-002 — Regression policy.** Prevent new high-severity findings relative to the committed compatible-resolution baseline; legacy findings need not all be zero.

**PC-REL-001 — Release truth.** Until a public release is intentionally published, describe the product as `unreleased` and tie evidence to the current implementation revision and working tree.
