# Finding Adjudication and Remediation

- Node type: leaf
- Status: Active
- Contract revision: `spec-3`
- Authority: [Rule and adjudication contract](../rules.md)
- Read when: selecting any of the twenty-nine findings, exclusions, dominance, adjudication, or fixture expectations.
- Do not read when: the task does not evaluate, interpret, or verify findings.
- Maximum size: 100 physical lines.


## Finding dominance

**RULE-DOM-001.** Suppress a generic finding for the same evidence path when a more specific rule explains it: model-aware suppresses broad input for one boundary; multi-owner suppresses per-owner model-aware findings; lifecycle-command suppresses view-effect for the same call; geometry effect/escape/manual positioning suppress generic geometry-layout for the same chain. Existing mirror rules retain precedence over broad observable input.

## Required distinctions

**RULE-EXC-001 — Direct Binding.** A correctly owned direct Binding produces no violation merely for being mutable or externally owned.

**RULE-EXC-002 — Transactional draft.** A local draft with real commit and discard topology is not automatically a Binding violation. Classify from actions/calls/copies, not names. Missing or fake discard must not suppress a mirror.

**RULE-EXC-003 — Intentional transformation.** A bidirectional non-identity transformation such as Celsius/Fahrenheit is derivation, not direct identity synchronization, and must not produce a direct-Binding recommendation.

**RULE-EXC-004 — Legitimate local UI state.** View-owned state with an independent UI lifetime and no duplicated external canonical value is valid.

**RULE-EXC-005 — Binding effects.** The presence of Binding does not prove good architecture. A custom setter with a standalone command or unrelated effect is reported, while a direct identity setter and a transformation used only to compute the assigned value remain clean.

**RULE-EXC-006 — Weak similarity.** Names, types, and UI proximity alone cannot cluster semantic values or trigger automatic refactoring.

**RULE-EXC-007 — Component owner.** A View-owned local model without an external observation/injection boundary is not a broad observable input. A screen or container may legitimately receive a model; `broad-observable-input` therefore remains a candidate for agent adjudication.

**RULE-EXC-008 — Local presentation state.** State used only for local animation/transition presentation and written only by local animation lifecycle is not stored derived product state.

**RULE-EXC-009 — Native layout/drawing.** Canvas and Shape-local coordinates are not product geometry. A narrow immutable representable with an empty update method is not imperative platform update.

**RULE-EXC-010 — Exact authority.** Composition roots, product roles, feature boundaries, and passive custom environment values come only from validated configuration or bounded compiler/platform facts, never name regexes.

## Agent adjudication

**RULE-LLM-001 — Allowed classifications.** Classify candidates as accidental mirror, transactional draft, derived state, transformed state, legitimate local UI state, command-shaped mutation, Binding factory boundary, observable-model tunnel, legitimate screen/container ownership, over-broad component input, or unknown.

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
