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

The topology-backed rules use `strong-inference`; `binding-factory` and `broad-observable-input` remain `candidate`. Evidence edges and locations are deterministic source facts. A suggested pattern is not an automatic edit.

## Required exception checks

- Treat a draft with explicit commit and discard topology as a transactional draft, even when it mirrors a model value during editing.
- Treat Celsius/Fahrenheit and other non-identity mappings as transformed state, not direct Binding candidates.
- Keep local UI state when its owner and lifetime belong to the view and it does not duplicate an external canonical value.
- Treat a custom Binding setter with unrelated effects as suspicious even though it uses `Binding`.
- Keep a direct custom Binding clean when its setter performs one direct identity write; keep transformation-only assignment clean.
- Count a `State → Binding → Binding` path as one logical source, while retaining an external borrowed root plus a distinct local `State` as two.
- Keep View-owned local models and focused value/action inputs clean. A screen/container may legitimately own or receive a broad model.
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
