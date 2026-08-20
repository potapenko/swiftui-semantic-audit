# Rule reference

Read this reference when classifying findings, checking an exception, or proposing remediation.

| Rule | Triggered topology | Default severity | Safe interpretation |
| --- | --- | --- | --- |
| `mirrored-state` | Any external representation, including a Binding, and distinct local `State` synchronize by reciprocal identity copies without a transaction | high | Candidate accidental mirror; direct Binding without the local mirror remains clean |
| `manual-two-way-sync` | Two mutable representations copy in both directions by identity | high | Candidate single-source-of-truth defect; Binding is only one possible representation |
| `value-setter-pair` | A child receives a value and callback that writes the same upstream value | medium | Candidate Binding boundary if the child does not transform or own the value |
| `callback-binding-tunnel` | At least three callback levels forward the same semantic value without ownership or transformation | medium | Candidate direct dependency/Binding path; preserve intermediate behavior |
| `observable-state-mirror` | Observable model member and local `State` copy by identity | high | Candidate `Bindable`/Binding access to model-owned state |
| `stored-derived-state` | Mutable `State` is assigned from other values without an identity cycle | medium | Candidate computed/derived value; prove no independent lifetime or edits |
| `command-shaped-binding` | An explicit custom Binding setter performs a command or combines a write with another call | medium | Separate focused value mutation from explicit actions without changing effect timing |
| `binding-factory` | A non-View function or computed property vends an explicit Binding | medium | Candidate API-boundary smell; prove owner and lifetime before changing it |
| `observable-model-tunnel` | One observable model crosses at least two View initializer boundaries | medium | Candidate dependency tunnel; preserve legitimate screen/container ownership |
| `broad-observable-input` | A View directly uses members through an externally observed/injected model | medium | Candidate over-broad leaf dependency; adjudicate the View's role before narrowing |
| `model-aware-descendant` | A non-root View accepts one exactly configured model/controller/store/presenter | medium | Candidate focused boundary; composition roots are excluded |
| `multi-owner-component` | A non-root View accepts two or more configured owners | high | Prefer a focused input or move orchestration to a root |
| `cross-feature-owner-dependency` | A View and accepted owner belong to different configured features | high | Verify the declared feature boundary before remediation |
| `service-or-repository-in-view` | A non-root View accepts a configured external-effect owner | high | Prefer an explicit focused value/action boundary |
| `environment-command-router` | An injected value exposes callable command topology | medium | Passive environment values remain clean unless callable facts exist |
| `reusable-component-owner-dependency` | An exact configured reusable component accepts an app/feature owner, or injects a component model through Environment | medium | Candidate instance/lifetime boundary; explicit per-item component models may be correct |
| `multi-source-binding` | One explicit Binding reads/writes multiple independent semantic values | medium | Preserve aggregate/transform semantics while making ownership explicit |
| `manual-owner-synchronization` | External owner data is copied to local state from multiple lifecycle paths | high | Check transaction semantics before replacing synchronization |
| `hidden-command-in-lifecycle` | A non-root lifecycle closure starts configured work | medium | Make the event/effect boundary explicit |
| `view-owned-external-effect` | A non-root View starts configured owner/service work | high | Keep legitimate composition-root orchestration |
| `imperative-focus-lifecycle` | Lifecycle or restoration topology writes `FocusState` | medium | Direct user-action focus writes remain adjudicated |
| `selection-corrective-loop` | Multiple focus/selection states form corrective copy cycles | high | A single editor-owned `TextSelection` is clean |
| `geometry-driven-product-layout` | Measured geometry determines product layout | medium | Canvas and Shape-local drawing coordinates are excluded |
| `geometry-escapes-layout-boundary` | Geometry flows beyond its immediate layout closure | medium | Keep measurements local to layout when possible |
| `geometry-triggered-model-effect` | Geometry reaches a configured model/service command | high | Separate layout measurement from product effects |
| `manual-positioning-as-layout` | `offset`/`position` derives from container or sibling geometry | medium | Local animation-only transforms remain clean |
| `gesture-button-emulation` | Tap gesture and manual button accessibility share one View chain | medium | Prefer `Button` semantics |
| `imperative-platform-view-update` | `updateNSView`/`updateUIView` pushes values, callbacks, or commands | high | Empty narrow representable updates remain clean |
| `direct-global-platform-command` | A non-root View calls a bounded global AppKit/UIKit command | high | Move platform effects behind an explicit boundary |
| `preview-requires-app-composition` | A reusable View preview constructs configured app/service ownership | medium | Prefer focused preview inputs |

The topology-backed rules use `strong-inference`; `binding-factory`, `broad-observable-input`, and `reusable-component-owner-dependency` remain `candidate`. Evidence edges and locations are deterministic source facts. A suggested pattern is not an automatic edit.

## Required exception checks

- Treat a draft with explicit commit and discard topology as a transactional draft, even when it mirrors a model value during editing.
- Treat Celsius/Fahrenheit and other non-identity mappings as transformed state, not direct Binding candidates.
- Keep local UI state when its owner and lifetime belong to the view and it does not duplicate an external canonical value.
- Treat a custom Binding setter with unrelated effects as suspicious even though it uses `Binding`.
- Keep a direct custom Binding clean when its setter performs one direct identity write; keep transformation-only assignment clean.
- Count a `State → Binding → Binding` path as one logical source, while retaining an external borrowed root plus a distinct local `State` as two.
- Keep View-owned local models and focused value/action inputs clean. A screen/container may legitimately own or receive a broad model.
- Require validated exact configuration for role-, feature-, and composition-root conclusions; never infer them from a type or property name.
- Keep passive environment values, local animation state, Canvas/Shape coordinates, `Button`, empty representable updates, and focused previews clean.
- Keep exact screens/containers, explicit or locally owned per-instance component models, focused values/bindings/actions, and unclassified Views clean for the reusable-owner rule.
- Do not convert the reusable-owner candidate into blanket model removal, Binding-everywhere, or a ViewModel-per-View requirement.
- Do not merge values from name similarity, matching type, or nearby UI alone.

## Adjudication questions

1. Who owns the semantic value?
2. Which representation is canonical?
3. Which paths read and write it?
4. Is synchronization identity-preserving or transforming?
5. Are commit, cancel, save, rollback, or discard events present?
6. Does any representation require a distinct lifetime?
7. Would the proposed representation remove manual synchronization without hiding effects or changing behavior?
8. Is the receiving View a screen/container owner or a reusable leaf component?
9. Which focused values, bindings, and actions express its minimum dependency surface?
10. Can multiple component instances coexist, and is the dependency shared or distinct per instance?
11. Is the dependency an app/feature owner or the component's own domain model with an independent lifetime?
