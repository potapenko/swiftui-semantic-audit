# Product Operations, Scope, and Release

- Node type: leaf
- Status: Active
- Contract revision: `spec-11`
- Authority: [Product contract](../product-contract.md)
- Read when: selecting the product goal, invariants, supported operations, scope, or release boundary.
- Do not read when: a narrower linked domain contract fully governs the task.
- Maximum size: 100 physical lines.


## Supported operations

**PC-OPS-001 — Graph and findings.** Provide `scan` and `audit` over a Swift file or directory, including a build-free syntax-only path.

**PC-OPS-002 — Persistent context.** Provide deterministic five-file snapshots and bounded finding/symbol slices.

**PC-OPS-003 — Change control.** Provide semantic diff over snapshots or Git revisions and a `check` policy that fails only for new findings at/above a configured threshold.

**PC-OPS-004 — Environment diagnosis.** Provide a non-mutating `doctor` command for Swift, Xcode/toolchain, project type, SwiftSyntax compatibility, Index Store readiness, and Git.

**PC-OPS-005 — Specialist agent workflows.** Supply reusable audit, refactor, and change-review skills that use JSON first, slice before source, preserve indexed resolution, and enforce the LLM fact boundary.

**PC-OPS-006 — Single routing entry point.** Supply `swiftui-semantic` as the concise user-facing skill. It classifies the requested outcome, loads only the appropriate specialist workflow first, and sequences audit, refactor, and review only when the task crosses those phases. It must preserve deterministic facts, resolution, baseline identities, evidence, invariants, and failure state across handoffs rather than duplicating or weakening specialist gates.

**PC-OPS-007 — Indexed agent boundary.** Agent-facing semantic audit, refactor, and review workflows require a fresh validated compiler Index Store, pass its path explicitly for live-source analysis, and accept only `resolution: "indexed"`. They must not recommend the build-free frontend mode, omit resolution flags in reliance on automatic discovery, or present a lower-resolution result as a semantic workflow result. Missing indexed coverage is a blocking evidence failure, not permission to weaken the workflow. The standalone CLI retains its build-free fallback for non-agent uses and deterministic test/dogfood coverage.

**PC-OPS-008 — Boundary analysis.** Represent explicit `Binding(get:set:)` construction and its getter/setter closures, detect command-shaped setters and Binding factories, identify the same observable model crossing multiple View boundaries, and emit a candidate when a leaf View directly depends on externally observed model members. Keep deterministic topology separate from the agent's decision about legitimate screen ownership or component isolation.

**PC-OPS-009 — Architecture analysis.** With explicit project classification where product roles are required, detect model-aware descendants, multiple mutable/reference owners, cross-feature owner dependencies, service/repository presentation inputs, environment command routers, multi-source Binding topology, lifecycle-owned synchronization/effects, imperative focus/selection correction, geometry-driven product behavior, gesture button emulation, imperative representable updates, direct global platform commands, and preview composition pressure.

**PC-OPS-010 — Reusable component surface.** Config schema 2 may classify exact Views as screens, containers, or reusable components and exact types as component models. Emit one medium/candidate finding when a reusable component accepts an application/feature owner, or receives a component model through Environment. Preserve explicit per-instance component models, local component ownership, focused values/bindings/actions, passive environment, screen/container ownership, and unclassified code as non-conclusions for this rule.

**PC-OPS-011 — Agent run artifact hygiene.** Stream separation is logical and does not require permanent per-command files. Auxiliary command output, status, timestamps, hashes, and receipts are temporary by default and stay outside source repositories, Codex configuration homes, and installed skill/package directories. Durable cross-handoff evidence requires an explicit non-repository state root, minimum necessary contents, and a retention owner or cleanup condition. Canonical snapshots may use an explicitly selected workflow path and retain their exact five-file contract.

## Resolution and platform

**PC-RES-001 — Syntax-only guarantee.** Support useful analysis without a build or index and label it `resolution: "syntax-only"`.

**PC-RES-002 — Indexed enrichment.** On macOS, accept an explicit compiler Index Store or conservatively discover a unique validated local store and enrich with compiler symbol/use relations.

**PC-RES-003 — Conservative fallback.** Automatic indexed mode may return syntax-only output when readiness or unambiguous coverage is absent. Explicit index requests fail instead of silently weakening resolution.

**PC-RES-004 — Comparison integrity.** Reject graph/report inconsistency and comparisons between indexed and syntax-only inputs.

## Determinism, path safety, and failure

**PC-SAFE-001 — Deterministic serialization.** Sort graph entities, findings, semantic values, changes, and JSON keys canonically. Repeated snapshot generation from unchanged source, toolchain, revision, and resolution must be byte-equivalent across all five files. When comparing a committed baseline across later commits, `nodes.jsonl`, `edges.jsonl`, `findings.jsonl`, and `summary.json` remain byte-exact; only `manifest.json.repositoryRevision` may be normalized, while every other manifest field remains exact and the fresh revision must equal the checked-out `HEAD`.

**PC-SAFE-002 — Stable identity.** Prefer compiler USR identity. Before indexed remapping, derive collision-safe IDs from module, normalized relative file, qualified declaration, kind, signature, and lexical structural path. Do not use line number as primary identity. Resolve same-named file-local declarations inside their own file before considering module-wide candidates.

**PC-SAFE-003 — Relative provenance.** Never persist absolute source paths in canonical graph evidence or `generatedFrom`.

**PC-SAFE-004 — Snapshot boundary.** Require exactly five regular non-symlink files, canonical ID order, referential integrity, matching schema/resolution, and safe non-overlapping source/output locations. Replace only a validated existing snapshot.

**PC-SAFE-005 — Bounded externals.** Bound Git, Swift, Xcode, index helper, and similar process calls. Fail the current attempt on timeout rather than waiting indefinitely.

**PC-SAFE-006 — Machine output.** Emit requested JSON/JSONL to stdout or explicit output files. Keep diagnostics on stderr and express policy failure with a nonzero status.

**PC-SAFE-007 — Fail closed on ambiguity.** Reject unknown/ambiguous slice selectors, invalid budgets, unsafe paths, invalid revisions, malformed snapshots, explicit index failures, and resolution mismatches. Do not fabricate missing facts.

## PoC scope

**PC-SCOPE-001 — Supported vocabulary.** Cover SwiftUI view discovery, `@State`, `@Binding`, `@Bindable`, `@Environment`, property access, assignments, callbacks/closures, initializer propagation, `.onChange`, `.onAppear`, `.task`, `.task(id:)`, and common controls (`TextField`, `Toggle`, `Slider`, `Picker`) to the extent exercised by accepted fixtures.

**PC-SCOPE-002 — Required rules.** Ship the thirty rules enumerated in [`rules.md`](../rules.md), preserving deterministic topology and explicit role authority.

**PC-SCOPE-003 — Incremental analysis.** Live-source commands reuse persistent content-addressed frontend and indexed facts for unchanged files. Cache keys cover relative path, source content, tool/cache/graph schema, module identity, compiler/index identity where applicable, and every semantic input needed by that layer. Changed declarations invalidate dependent files conservatively. Cached and uncached results must be byte-equivalent; malformed or incompatible cache entries are misses, never semantic evidence.

**PC-SCOPE-004 — Source-count semantics.** Count logical ownership roots, not wrapper instances. A focused `State → Binding → Binding` chain has one source; an external borrowed Binding or observable root plus a distinct local State has two. Binding projections and `@Bindable` receivers are representations, not independent owners.

**PC-SCOPE-005 — Fresh global result.** Incrementality may reuse deterministic extraction facts, but every invocation assembles a complete canonical graph and evaluates normalization and all rules against the current project state. Cache behavior must not alter graph, report, snapshot, diff, check, slice, resolution, or configuration semantics.

**PC-SCOPE-006 — Deterministic parallel execution.** Eligible independent per-file frontend phases and independent audit rules may execute concurrently over immutable inputs. Order-dependent relationship resolution remains serial until it has an immutable fact/merge architecture. The public execution width is positive and bounded by the requested job count; its default follows the host's active processor count and `1` forces serial execution. Parallel and serial runs must produce byte-identical canonical graph and report output. IndexStoreDB access remains isolated behind the bounded helper and is not treated as a generally thread-safe shared database.

## Non-goals

**PC-NONGOAL-001.** Do not make SIL, a full Swift type checker, full interprocedural/alias/control-flow analysis, or generic support for every Swift framework part of the PoC foundation.

**PC-NONGOAL-002.** Do not provide automatic source rewriting, embedded LLM API integration, an IDE plugin, GUI, Xcode extension, security analysis, or performance analysis.

**PC-NONGOAL-003.** General analysis of concurrency, actors, dependency injection, navigation, persistence, resources, networking, and errors remains directional context. `ARCHITECTURE-001` permits only bounded call/effect topology needed by its named lifecycle, view-effect, Binding, geometry, and platform-command rules.

**PC-NONGOAL-004.** Do not classify arbitrary properties as application roles from names or type spelling alone. Role-aware rules require exact configuration under [`analysis-config.md`](../analysis-config.md). Explicit observed/injected topology may still produce the existing agent-adjudicated `broad-observable-input` candidate.

## Dogfood and release

**PC-DOG-001 — Dogfood.** Run the CLI against its accepted fixtures and its own Swift sources as part of development and CI.

**PC-DOG-002 — Regression policy.** Prevent new high-severity findings relative to the committed compatible-resolution baseline; legacy findings need not all be zero.

**PC-REL-001 — Release truth.** Until a public release is intentionally published, describe the product as `unreleased` and tie evidence to the current implementation revision and working tree.

**PC-REL-002 — Homebrew release.** Publish tool version `0.5.0` from an immutable Git tag and GitHub Release, then distribute the open-source CLI through the upstream `potapenko/homebrew-tap` formula `swiftui-semantic-audit`. The direct installation command is `brew install potapenko/tap/swiftui-semantic-audit`; the installed executable remains `swiftui-audit`.

**PC-REL-003 — Distribution boundary.** The formula builds the locked Swift package from tagged source, installs only the CLI into Homebrew's prefix, and functionally tests syntax-only analysis. It must not write agent-host skill directories, shell startup files, project source, or user configuration. Agent skills retain their separate documented installation flow.

**PC-REL-004 — Component release.** Tool `0.5.0` publishes the accepted `COMPONENT-SURFACE-001` behavior and updated four-skill workflow. It advances the current formula and documentation without replacing, retagging, republishing, or changing immutable 0.4.0 artifacts.
