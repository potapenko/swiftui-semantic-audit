# Rule reference

Version 0.4.0 evaluates the unchanged 29 rules over the canonical semantic graph. A rule uses ownership, identity, read/write/call, binding, observation, configuration, and event topology. No rule is allowed to conclude from a property-wrapper or type name alone.

Severity describes the architectural risk selected by the contract. Confidence describes the evidence basis:

- `strong-inference` means explicit topology supports the finding;
- `candidate` means the topology is real but product intent or component role still needs agent judgment.

## State and data flow

| Rule | Severity | Confidence | Detects |
| --- | --- | --- | --- |
| `mirrored-state` | high | strong-inference | Local state identity-synchronized with an external representation. |
| `manual-two-way-sync` | high | strong-inference | A reciprocal identity-copy cycle between two distinct mutable declarations. |
| `value-setter-pair` | medium | strong-inference | A child value plus a callback that writes the same upstream value. |
| `callback-binding-tunnel` | medium | strong-inference | One identity-preserved value forwarded through at least three callbacks. |
| `observable-state-mirror` | high | strong-inference | Local state identity-synchronized with an observable-model member. |
| `stored-derived-state` | medium | strong-inference | Mutable state derived from inputs without an identity cycle back. |
| `command-shaped-binding` | medium | strong-inference | A custom Binding setter that runs a command, or combines a direct write with an additional call. |
| `binding-factory` | medium | candidate | Explicit Binding construction returned from a non-View function or computed property. |
| `observable-model-tunnel` | medium | strong-inference | One observable value passed through at least two View initializer boundaries. |
| `broad-observable-input` | medium | candidate | A View directly uses members of an externally observed or injected model. |

Important boundaries:

- a direct focused Binding is clean;
- a self-copy is not reciprocal synchronization;
- a transformed value is derivation, not an identity mirror;
- Binding factories and broad model inputs are evidence for architectural review, not automatic defects.

## Component and effect architecture

These rules use exact configuration when product roles, features, or composition roots are required.

| Rule | Severity | Confidence | Detects |
| --- | --- | --- | --- |
| `model-aware-descendant` | medium | candidate | A configured owner accepted by a non-composition-root View. |
| `multi-owner-component` | high | strong-inference | A non-root View with two or more independent configured mutable/reference owner inputs. |
| `cross-feature-owner-dependency` | high | strong-inference | A View in one configured feature depending on an owner from another feature. |
| `service-or-repository-in-view` | high | strong-inference | A non-root View accepting a configured repository, service, player, dependency bundle, or effect sink. |
| `environment-command-router` | medium | candidate | An injected environment value exposing commands or callbacks used by the View. |
| `multi-source-binding` | medium | strong-inference | A custom Binding whose getter/setter touches multiple independent values or reconstructs an aggregate from new and current state. |
| `manual-owner-synchronization` | high | strong-inference | A local mutable representation copied from an external owner in multiple lifecycle-triggered paths. |
| `hidden-command-in-lifecycle` | medium | candidate | Model commands, dispatch, normalization, or awaited work initiated by `onAppear`, `onChange`, or `task`. |
| `view-owned-external-effect` | high | candidate | A non-root presentation/leaf View initiating configured external work outside a lifecycle-command path. |
| `imperative-focus-lifecycle` | medium | strong-inference | `FocusState` writes from lifecycle, delayed task/dispatch, or restoration callbacks. |
| `selection-corrective-loop` | high | strong-inference | Multiple focus/selection restoration states in corrective event-driven copy/write cycles. |

Configuration does not guess. If a required type or feature role is absent, the role-aware conclusion is not emitted.

## Layout and platform boundaries

| Rule | Severity | Confidence | Detects |
| --- | --- | --- | --- |
| `geometry-driven-product-layout` | medium | candidate | Geometry or preference values used to decide product layout. |
| `geometry-escapes-layout-boundary` | medium | strong-inference | Measured geometry passed beyond its immediate layout closure. |
| `geometry-triggered-model-effect` | high | strong-inference | Geometry flow reaching a configured model, service, repository, network, pagination, or playback command. |
| `manual-positioning-as-layout` | medium | candidate | `offset` or `position` derived from container or sibling geometry. |
| `gesture-button-emulation` | medium | strong-inference | A tap gesture combined with manual button accessibility traits/action on the same View chain. |
| `imperative-platform-view-update` | high | strong-inference | `updateNSView` or `updateUIView` pushing presentation values, callbacks, counters, or commands into an existing native view. |
| `direct-global-platform-command` | high | strong-inference | A non-root View invoking bounded global AppKit/UIKit application, responder, or event-monitor commands. |
| `preview-requires-app-composition` | medium | candidate | A reusable non-root preview constructing application composition or configured owner/service inputs. |

Shape and Canvas-local drawing coordinates, local animation-only transforms, real `Button`, empty representable update methods, and focused previews are protected cases.

## Finding dominance

One evidence path should not produce redundant generic and specific findings. The engine applies these dominance rules:

- `model-aware-descendant` suppresses `broad-observable-input` for the same boundary;
- `multi-owner-component` suppresses per-owner model-aware findings;
- `hidden-command-in-lifecycle` suppresses `view-owned-external-effect` for the same call;
- geometry effect, escape, or manual positioning suppresses generic geometry-layout output for the same chain;
- mirror rules take precedence over broad observable input.

## Protected cases

The rules deliberately preserve:

1. **Direct Binding:** external mutable authority expressed without a second local mirror.
2. **Transactional draft:** a local copy with real commit and discard behavior.
3. **Intentional transformation:** non-identity conversion such as two units of one measurement.
4. **Legitimate local UI state:** state with an independent view lifetime and no external canonical duplicate.
5. **Direct or transforming Binding setter:** one direct write, including a transformation used only to compute that write.
6. **Weak similarity:** names, types, and nearby UI never cluster values by themselves.
7. **Legitimate component owner:** a View-local model or a valid screen/container model boundary.
8. **Local presentation state:** animation or transition state written only by its local presentation lifecycle.
9. **Native layout and drawing:** Shape and Canvas-local coordinates plus narrow immutable platform adapters.
10. **Exact authority:** roles, features, roots, and custom passive environment values come from validated configuration, not regexes.

## Reading a finding

A finding contains:

- stable ID;
- rule, severity, and confidence;
- referenced node and edge IDs;
- relative source evidence;
- suggested representation patterns;
- optional tunnel depth.

Suggested patterns are candidates, not edits. Before accepting a remediation, establish owner, canonical representation, lifetime, write authority, transformation, and transaction boundary.

The agent may classify intent and explain risk. It must not change graph facts or claim that a candidate is a defect without the missing product context.

Normative detail and fixture mapping: [`docs/specs/rules.md`](../specs/rules.md).
