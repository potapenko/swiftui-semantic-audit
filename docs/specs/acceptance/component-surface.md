# Reusable Component Surface Acceptance

- Node type: leaf
- Status: Active
- Contract revision: `spec-1`
- Authority: [Acceptance and QA contract](../acceptance.md)
- Read when: implementing or verifying `COMPONENT-SURFACE-001`.
- Do not read when: component roles and the reusable-owner rule are out of scope.
- Maximum size: 100 physical lines.

## Configuration and exact authority

**ACC-COMP-001.** Load schema 1 unchanged, including its canonical digest, accepted owner roles, discovery, and fail-closed behavior. Schema 1 rejects schema-2-only fields and roles. Schema 2 accepts exact `viewRoles` and `component-model`, canonicalizes them into the digest, and never infers either from names.

**ACC-COMP-002.** Positive boundaries cover a reusable View receiving an application/feature owner through plain property, `@Bindable`, `@Binding`, and Environment topology, plus a `component-model` received through Environment.

## Exceptions and dominance

**ACC-COMP-003.** No reusable-owner finding appears for a screen/container, unclassified View, focused value/Binding/action, explicit per-item `component-model`, locally owned component model, passive Environment value, or role-like unconfigured name. A `ForEach` over distinct observable item models remains clean.

**ACC-COMP-004.** `multi-owner-component` suppresses the new rule on the same boundary path. The new rule suppresses matching `model-aware-descendant` and `broad-observable-input`; `cross-feature-owner-dependency` and `observable-model-tunnel` remain independent.

## Slice and realistic corpus

**ACC-COMP-005.** A finding slice asks whether multiple instances coexist, whether the dependency is shared or per-instance, whether it is the component's domain model or an app/feature owner, whether values/focused Binding/actions can express the surface, and whether lifetime must be independent.

**ACC-COMP-006.** The configured realistic corpus remains exactly 34 findings with no Good evidence and syntax/indexed per-rule/per-file parity. One generic model-aware finding is replaced by the specific reusable-owner candidate through dominance; all other findings remain stable.

**ACC-COMP-007.** Cached/uncached and serial/parallel reports remain byte-identical. RuleTests semantic files remain byte-identical; only the manifest tool version and product-source revision may change under the existing snapshot contract.
