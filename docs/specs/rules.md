# Rule and adjudication contract

Revision: `spec-1`  
Rule set: six required PoC rules  
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

## Required distinctions

**RULE-EXC-001 — Direct Binding.** A correctly owned direct Binding produces no violation merely for being mutable or externally owned.

**RULE-EXC-002 — Transactional draft.** A local draft with real commit and discard topology is not automatically a Binding violation. Classify from actions/calls/copies, not names. Missing or fake discard must not suppress a mirror.

**RULE-EXC-003 — Intentional transformation.** A bidirectional non-identity transformation such as Celsius/Fahrenheit is derivation, not direct identity synchronization, and must not produce a direct-Binding recommendation.

**RULE-EXC-004 — Legitimate local UI state.** View-owned state with an independent UI lifetime and no duplicated external canonical value is valid.

**RULE-EXC-005 — Binding effects.** The presence of Binding does not prove good architecture. Unrelated analytics, persistence, or other effects in a setter require agent review; the current six-rule PoC does not claim the deferred suspicious-setter rule is implemented.

**RULE-EXC-006 — Weak similarity.** Names, types, and UI proximity alone cannot cluster semantic values or trigger automatic refactoring.

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

Perturbation fixtures prove renamed transactions, missing/fake discard, labeled setters, unary derivation, identity-transform exclusion, mismatched tunnels, and minimum tunnel depth.
