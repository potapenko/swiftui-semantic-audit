# Refactor gates

Read this reference before selecting a canonical representation and before accepting the change.

## Representation decision

| Representation | Select when | Reject when |
| --- | --- | --- |
| `State` | The view owns mutable UI state for its own lifetime | It duplicates externally owned canonical data |
| `Binding` | A child needs direct read/write access to an externally owned value | The child needs independent draft lifetime, transformation, or unrelated setter effects |
| `Bindable` | A view needs bindings to properties of an observable model it can access | It would create or obscure model ownership |
| `Environment` | A dependency is intentionally injected through the view environment | The dependency should be explicit at this boundary or lifetime becomes unclear |
| derived value | The value is fully computed from canonical inputs | It has independent mutation, persistence, or transaction behavior |
| transactional draft | Edits are isolated until explicit commit and can be discarded | Writes synchronize continuously or discard is not real |

## Before edit

- Record the chosen semantic value/finding IDs and resolution.
- Record canonical owner, mutable representations, read/write paths, and evidence.
- Identify behavior tests and commit/cancel/transform/effect invariants.
- Preserve the baseline directory unchanged.

## Acceptance

- Build and behavior tests pass.
- `check --fail-on-new high` passes.
- No new high-confidence violation exists.
- Targeted architectural violations decrease or are truthfully retained.
- Manual synchronization does not increase.
- Ownership, lifetime, dependencies, and transaction semantics are at least as explicit.
- Semantic diff matches the intended architectural change; implementation-only edits are reviewed separately.

Do not accept by aggregate score alone. A lower metric does not justify incorrect ownership or behavior.
