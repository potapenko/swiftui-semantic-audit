# Architecture and Platform Rules

- Node type: leaf
- Status: Active
- Contract revision: `spec-4`
- Authority: [Rule and adjudication contract](../rules.md)
- Read when: selecting any of the thirty findings, exclusions, dominance, adjudication, or fixture expectations.
- Do not read when: the task does not evaluate, interpret, or verify findings.
- Maximum size: 100 physical lines.


## Architecture rules

**RULE-MODEL-DESC-001 — `model-aware-descendant`.** With an exact configured application/feature model, controller, store, or presenter role, detect a non-composition-root View that accepts the owner through a typed property or initializer boundary. Severity `medium`; confidence `candidate`; pattern `focused-input`.

**RULE-MULTI-OWNER-001 — `multi-owner-component`.** Detect a non-root View with two or more independent configured mutable/reference owner inputs. Report one finding with every owner and typed boundary. Severity `high`; confidence `strong-inference`.

**RULE-CROSS-FEATURE-001 — `cross-feature-owner-dependency`.** Detect a View assigned to one configured feature that reads, writes, calls, observes, or accepts an owner assigned to a different feature. Severity `high`; confidence `strong-inference`.

**RULE-SERVICE-VIEW-001 — `service-or-repository-in-view`.** Detect a non-root View accepting a configured repository, service, player, dependency bundle, or effect sink. Severity `high`; confidence `strong-inference`.

**RULE-ENV-COMMAND-001 — `environment-command-router`.** Detect an injected environment value whose typed/configured topology exposes callbacks or commands used by the View. Exclude bounded passive system values and configured passive values unless callable topology is present. Severity `medium`; confidence `candidate`.

**RULE-REUSABLE-OWNER-001 — `reusable-component-owner-dependency`.** With schema-2 exact configuration, detect a `reusable-component` View accepting an application model, feature model, controller, store, or presenter through an owned, bound, observed, or injected typed boundary. Also detect an injected `component-model`, whose per-instance lifetime is unclear through Environment. Severity `medium`; confidence `candidate`; patterns `focused-input`, `focused-binding`, `action-closure`, `explicit-component-model`.

**RULE-MULTI-SOURCE-BINDING-001 — `multi-source-binding`.** Detect an explicit Binding whose getter/setter reads or writes multiple independent semantic values, or whose setter reconstructs an aggregate using both the new value and current state. Severity `medium`; confidence `strong-inference`.

**RULE-MANUAL-OWNER-SYNC-001 — `manual-owner-synchronization`.** Detect a local mutable representation copied from an external owner in two or more lifecycle-triggered paths without a proven reciprocal Binding or real commit/discard transaction. Severity `high`; confidence `strong-inference`.

**RULE-LIFECYCLE-COMMAND-001 — `hidden-command-in-lifecycle`.** Detect model commands, dispatch, apply, clamp, normalization, or awaited work from `onAppear`, `onChange`, or `task`, excluding configured composition roots and purely local cancellable animation. Severity `medium`; confidence `candidate`.

**RULE-VIEW-EFFECT-001 — `view-owned-external-effect`.** Detect a non-root leaf/presentation View initiating configured model/service/player/repository work outside an already reported lifecycle-command path. Severity `high`; confidence `candidate`.

**RULE-FOCUS-LIFECYCLE-001 — `imperative-focus-lifecycle`.** Detect `FocusState` writes from lifecycle, delayed task/dispatch, or restoration callbacks. Direct user-action focus changes remain agent-adjudicated. Severity `medium`; confidence `strong-inference`.

**RULE-SELECTION-LOOP-001 — `selection-corrective-loop`.** Detect multiple local focus/selection restoration states participating in corrective copy/write cycles triggered by focus, modal, or text changes. A single editor-owned `TextSelection` is clean. Severity `high`; confidence `strong-inference`.

## Layout and platform rules

**RULE-GEOMETRY-LAYOUT-001 — `geometry-driven-product-layout`.** Detect GeometryReader/proxy, geometry-change, global/local frame, coordinate-space, or PreferenceKey values used to determine product layout. Exclude `Shape.path(in:)` and `Canvas` local drawing coordinates. Severity `medium`; confidence `candidate`.

**RULE-GEOMETRY-ESCAPE-001 — `geometry-escapes-layout-boundary`.** Detect measured geometry passed to a child View, helper, or presentation DTO beyond the immediate layout closure. Severity `medium`; confidence `strong-inference`.

**RULE-GEOMETRY-EFFECT-001 — `geometry-triggered-model-effect`.** Detect geometry flow that reaches a configured model/service/player/repository command, pagination, network, or playback call. Severity `high`; confidence `strong-inference`.

**RULE-MANUAL-POSITION-001 — `manual-positioning-as-layout`.** Detect `offset` or `position` arguments derived from container/sibling geometry. Exclude local animation-only transforms that do not determine product layout. Severity `medium`; confidence `candidate`.

**RULE-GESTURE-BUTTON-001 — `gesture-button-emulation`.** Detect a tap gesture combined with manual button accessibility traits/action on the same View chain. Severity `medium`; confidence `strong-inference`; pattern `Button`.

**RULE-PLATFORM-UPDATE-001 — `imperative-platform-view-update`.** Detect `updateNSView`/`updateUIView` that pushes presentation values, callbacks, request counters, or commands into an existing native view. An empty update method is clean. Severity `high`; confidence `strong-inference`.

**RULE-GLOBAL-PLATFORM-001 — `direct-global-platform-command`.** Detect a non-root View directly invoking bounded global AppKit/UIKit application, responder-chain, or event-monitor commands. Severity `high`; confidence `strong-inference`.

**RULE-PREVIEW-COMPOSITION-001 — `preview-requires-app-composition`.** Detect a reusable non-root View preview that constructs configured application composition or supplies configured owner/service graph inputs. Severity `medium`; confidence `candidate`.
