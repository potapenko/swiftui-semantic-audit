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

All current findings use `strong-inference`; evidence edges and locations remain deterministic source facts. A suggested pattern is not an automatic edit.

## Required exception checks

- Treat a draft with explicit commit and discard topology as a transactional draft, even when it mirrors a model value during editing.
- Treat Celsius/Fahrenheit and other non-identity mappings as transformed state, not direct Binding candidates.
- Keep local UI state when its owner and lifetime belong to the view and it does not duplicate an external canonical value.
- Treat a custom Binding setter with unrelated effects as suspicious even though it uses `Binding`.
- Do not merge values from name similarity, matching type, or nearby UI alone.

## Adjudication questions

1. Who owns the semantic value?
2. Which representation is canonical?
3. Which paths read and write it?
4. Is synchronization identity-preserving or transforming?
5. Are commit, cancel, save, rollback, or discard events present?
6. Does any representation require a distinct lifetime?
7. Would the proposed representation remove manual synchronization without hiding effects or changing behavior?
