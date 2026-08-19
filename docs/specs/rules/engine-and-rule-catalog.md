# Rule Engine and Core Catalog

- Node type: leaf
- Status: Active
- Contract revision: `spec-3`
- Authority: [Rule and adjudication contract](../rules.md)
- Read when: selecting any of the twenty-nine findings, exclusions, dominance, adjudication, or fixture expectations.
- Do not read when: the task does not evaluate, interpret, or verify findings.
- Maximum size: 100 physical lines.


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
