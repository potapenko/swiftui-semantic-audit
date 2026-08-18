# Rule and adjudication contract

Revision: `spec-2`  
Rule set: ten required rules  
Status: active

## Engine

**RULE-ENGINE-001 — Input/output.** Evaluate every rule over the canonical semantic graph plus normalization result and return zero or more evidence-backed findings.

**RULE-ENGINE-002 — Topology.** No rule may be based only on a property-wrapper name. Use ownership, identity/derivation, read/write/copy, forwarding, observation, and event topology.

**RULE-ENGINE-003 — Determinism.** Canonicalize nodes, edges, evidence, suggestions, and IDs. Repeated audits of unchanged graphs must be byte-stable.

## Required rules

**RULE-MIRROR-001 — `mirrored-state`.** Detect one local `state` representation identity-synchronized with an external representation. An external representation may itself be a Binding: direct Binding remains clean, but copying it into local `State` and synchronizing identity changes back is a mirror. Suppress observable members handled by the dedicated rule and accepted transaction classifications. Severity `high`; confidence `strong-inference`; candidate pattern `Binding`.

**RULE-TWOWAY-001 — `manual-two-way-sync`.** Detect an identity copy cycle between two distinct declaration-backed mutable representations of one semantic value, including a cycle between an external Binding and a separate local `State`. A self-copy is not reciprocal topology. Suppress observable-specific and accepted transactional pairs; do not report direct Binding or unrelated local state without the identity cycle. Severity `high`; confidence `strong-inference`; candidate pattern `Binding`.

**RULE-SETTER-001 — `value-setter-pair`.** Detect a child value and callback where the passed closure writes that same upstream value and the callback is not merely forwarding another callback. Severity `medium`; confidence `strong-inference`; candidate pattern `Binding`.

**RULE-TUNNEL-001 — `callback-binding-tunnel`.** Detect at least three callback nodes that forward one identity-preserved semantic value without ownership or transformation. Report exact depth. Reject mismatched values and depth two. Severity `medium`; confidence `strong-inference`; candidate pattern `Binding`.

**RULE-OBS-001 — `observable-state-mirror`.** Detect identity synchronization between one observable model member and one local `state` representation. Include observation support. Severity `high`; confidence `strong-inference`; candidate patterns `Bindable`, `Binding`.

**RULE-DERIVED-001 — `stored-derived-state`.** Detect mutable state derived from one or more inputs without an identity cycle back. Include unary derivation; exclude identity transformation cycles. Severity `medium`; confidence `strong-inference`; candidate pattern `derived-value`.

**RULE-COMMAND-001 — `command-shaped-binding`.** Detect an explicit `Binding(get:set:)` whose setter executes a standalone command/callback call instead of a direct value write, or combines a direct write with an additional standalone call. Do not report a getter plus one direct identity write, or a transformation call used only to produce the assigned value. Severity `medium`; confidence `strong-inference`; candidate patterns `action-closure`, `focused-binding`.

**RULE-FACTORY-001 — `binding-factory`.** Detect an explicit Binding construction in a non-View function or computed property whose declared result is `Binding`. This is architectural evidence, not proof that the factory is wrong. Severity `medium`; confidence `candidate`; candidate patterns `focused-binding`, `action-closure`.

**RULE-MODEL-TUNNEL-001 — `observable-model-tunnel`.** Detect one normalized semantic value containing an owned/external observable representation passed through at least two View initializer boundaries into observed representations. Report the exact boundary depth. Severity `medium`; confidence `strong-inference`; candidate patterns `focused-input`, `focused-binding`, `action-closure`.

**RULE-BROAD-INPUT-001 — `broad-observable-input`.** Detect a View that directly reads, writes, calls, or projects members through an externally observed or injected model representation. Require member-use topology; forwarding without direct member use is not enough. Exclude View-owned local `State` and roots already represented by the higher-severity observable-mirror topology. Severity `medium`; confidence `candidate`; candidate patterns `focused-input`, `focused-binding`, `action-closure`.

## Required distinctions

**RULE-EXC-001 — Direct Binding.** A correctly owned direct Binding produces no violation merely for being mutable or externally owned.

**RULE-EXC-002 — Transactional draft.** A local draft with real commit and discard topology is not automatically a Binding violation. Classify from actions/calls/copies, not names. Missing or fake discard must not suppress a mirror.

**RULE-EXC-003 — Intentional transformation.** A bidirectional non-identity transformation such as Celsius/Fahrenheit is derivation, not direct identity synchronization, and must not produce a direct-Binding recommendation.

**RULE-EXC-004 — Legitimate local UI state.** View-owned state with an independent UI lifetime and no duplicated external canonical value is valid.

**RULE-EXC-005 — Binding effects.** The presence of Binding does not prove good architecture. A custom setter with a standalone command or unrelated effect is reported, while a direct identity setter and a transformation used only to compute the assigned value remain clean.

**RULE-EXC-006 — Weak similarity.** Names, types, and UI proximity alone cannot cluster semantic values or trigger automatic refactoring.

**RULE-EXC-007 — Component owner.** A View-owned local model without an external observation/injection boundary is not a broad observable input. A screen or container may legitimately receive a model; `broad-observable-input` therefore remains a candidate for agent adjudication.

## Agent adjudication

**RULE-LLM-001 — Allowed classifications.** Classify candidates as accidental mirror, transactional draft, derived state, transformed state, legitimate local UI state, or unknown.

**RULE-LLM-002 — Allowed additions.** Add intent, semantic name, risk explanation, confidence in the classification, and conditional remediation.

**RULE-LLM-003 — Forbidden mutations.** Never change AST facts, symbol identity, read/write edges, compiler relations, or source evidence.

**RULE-LLM-004 — Unknown.** Return unknown and request the smallest missing evidence when ownership, lifetime, transformation, or transaction boundaries are not proven.

## Remediation policy

**RULE-REM-001.** Choose a representation only after establishing owner, canonical source, lifetime, write authority, and transaction boundary.

**RULE-REM-002.** Candidate representations include owned `State`, external `Binding`, observable projection through `Bindable`, injected `Environment`, computed/derived value, and transactional draft.

**RULE-REM-003.** Never direct an agent to use Binding everywhere or minimize `@State`. A remediation is acceptable only when it reduces targeted manual/duplicated flow without weakening behavior, ownership, effects, or lifetime.

## Acceptance fixture mapping

| Fixture | Expected rule result |
| --- | --- |
| `GoodDirectBinding` | none |
| `ValueSetterPair` | `value-setter-pair` |
| `BidirectionalOnChange` | `mirrored-state`, `manual-two-way-sync` |
| `TransactionalDraft` | no finding; one transactional semantic value |
| `DerivedState` | `stored-derived-state` |
| `CallbackTunnel` | `callback-binding-tunnel`, depth 3 |
| `ObservableMirror` | `observable-state-mirror` |
| `IntentionalTransformation` | no direct-Binding finding |
| `BindingMirroredLocally` | `mirrored-state`, `manual-two-way-sync` |
| `BindingTransactionalDraft` | no finding; one transactional semantic value |
| `BindingIndependentLocalState` | no finding |
| `BindingSelfCopy` | no finding; one self-copy is not a reciprocal pair |
| `CommandBinding` | `command-shaped-binding`, `broad-observable-input` |
| `BindingWithEffect` | `command-shaped-binding` |
| `BindingFactory` | `binding-factory` only |
| `ObservableModelTunnel` | `observable-model-tunnel`, depth 2 |
| `BroadObservableInput` | `broad-observable-input` |
| `DirectCustomBinding` | none |
| `TransformedBinding` | none |
| `FocusedBindingChain` | none; one logical source of truth |
| `LocalModelOwner` | none |
| `FocusedActionInput` | none |

Perturbation fixtures prove renamed transactions, missing/fake discard, labeled setters, unary derivation, identity-transform exclusion, mismatched tunnels, and minimum tunnel depth.
