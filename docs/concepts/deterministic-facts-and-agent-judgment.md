# Deterministic facts and agent judgment

SwiftUI Semantic Audit keeps extraction separate from interpretation. This boundary lets different coding agents use the same evidence without letting a model rewrite inconvenient facts.

## The semantic twin

The semantic twin is a deterministic, simplified representation of supported
Swift/SwiftUI program facts. It is built from source and, for agent workflows,
fresh indexed compiler evidence. That evidence comes either from a watcher live
snapshot paired with its matching fresh indexed status receipt or from a fresh
build with an explicit validated Index Store. The twin preserves ownership,
state, Bindings, reads, writes, derivations, dependencies, component boundaries,
lifecycle, effects, identity, confidence, and source provenance while leaving
unrelated syntax in the source.

The twin is not an LLM summary, model-written pseudocode, a source replacement,
a runtime simulation, or a complete account of program behavior. The CLI owns
the facts; the surrounding agent may interpret a bounded slice of them.

## The fact pipeline

```text
Swift source
  → SwiftSyntax facts
  → optional compiler-index facts
  → semantic graph
  → normalization and rules
  → bounded slice
  → agent adjudication
```

The first six stages build the semantic twin deterministically for the same
source, toolchain, configuration, and resolution. The last stage can use
project context and product intent.

## What the CLI owns

The CLI establishes and serializes:

- declaration and generated-node identities;
- node and edge kinds;
- ownership, read, write, call, pass, binding, copy, trigger, and derivation topology;
- compiler-derived symbol relations in indexed mode;
- source evidence and relative locations;
- configured roles, features, composition roots, and the configuration digest;
- rule identifier, severity, confidence, and referenced topology;
- snapshots, semantic changes, and policy results.

These records have different meanings. Declarations and read/write edges are extracted facts; findings, severity and suggested patterns are deterministic rule assessments over those facts. Repeating an assessment does not prove that the code is wrong. An agent may quote and interpret the records, but may not silently change their contents.

## What the agent may add

The agent can add conclusions that syntax alone cannot settle:

- the intended owner and lifetime;
- whether a candidate is an accidental mirror or a real draft;
- whether a transformation is product-significant;
- whether a model boundary is legitimate at that component level;
- the risk of a hidden command;
- a conditional remediation;
- the smallest missing evidence needed to decide.

These conclusions should remain visibly separate from deterministic output.

## Confidence levels

| Confidence | Meaning |
| --- | --- |
| `deterministic` | Direct syntax or compiler fact |
| `strong-inference` | Rule conclusion supported by explicit topology |
| `candidate` | Evidence exists, but intent or component role still needs adjudication |
| `llm-inferred` | External reasoning metadata, never a replacement for graph facts |

A likely remediation does not justify upgrading confidence. Confidence describes the evidence that exists, not how strongly an agent prefers a design.

## Signals, defects, and policy gates

A native adapter must update its platform view when SwiftUI inputs change.
Current-source `imperative-platform-view-update` therefore reports a
`medium / candidate` boundary to inspect, with no prescribed rewrite. Look for
non-repeatable commands or feedback into application state before calling it a
defect. Keep ordinary native synchronization when that is all the evidence shows.
Immutable 0.6.0 retains its earlier `high / strong-inference` assessment.

Severity controls the CLI policy threshold; confidence describes the assessment's
basis. The default `check --fail-on-new high` does not block solely for the
current-source native-update signal. Choosing `medium` or `low` deliberately
includes it. Other rules retain their documented severities and confidence.

A useful agent answer states the observed path, the supplied product invariant,
its assessment (including `unknown`), and a conditional change with the behavior
it must preserve. A general preference for declarative code is insufficient.

## Why slices come before source

An audit report can contain many nodes and findings. `slice` selects one finding or symbol and keeps its semantic values, ownership, relevant paths, evidence, and questions inside a bounded envelope.

This gives the agent a concrete starting point for avoiding two common errors:

- reconstructing architecture from an arbitrary subset of files;
- reading so much source that the decisive path is lost among unrelated details.

The [ownership pilot](../../evaluation/ownership-pilot/results.md) found that mandatory JSON evidence can outweigh a short source file and sometimes the full graph. A slice is a selection mechanism, not a guaranteed token saving.

The slice is not the end of investigation. It routes source reading to the evidence locations and directly required declarations.

## Indexed evidence

Indexed mode enriches the graph with project-covering compiler identity and use relations. The bundled workflow treats that compiler-backed identity as a required part of semantic evidence.

The bundled agent workflows therefore require:

- the exact source state being evaluated;
- either a watcher live snapshot with a matching fresh indexed status receipt
  for the current workspace and configuration, or a fresh build with an
  explicit validated Index Store path;
- `resolution: "indexed"` in every accepted snapshot or live-source result;
- compatible indexed snapshots for semantic review.

Without a matching watcher receipt, the workflow waits boundedly for fresh
indexed status or uses the explicit Index Store route. It never treats a stale
snapshot or lower-resolution result as current indexed evidence.

Results from a lower resolution must not be substituted for, compared with, or described as indexed workflow evidence.

## Provider independence

The executable has no OpenAI, Anthropic, or other model-provider integration. It emits JSON or LLM-ready JSON. The surrounding host decides which agent reads it.

This makes the semantic contract reusable and testable without binding extraction to a model, prompt format, account, or network call.

## Failure is evidence

Invalid JSON, ambiguous selectors, missing indexed coverage, resolution mismatch, configuration mismatch, unsafe paths, and insufficient slice budgets fail closed. An empty or failed result must not be interpreted as a clean architecture.

When deterministic evidence cannot establish owner, lifetime, transformation, or transaction behavior, the correct agent result is `unknown` plus a precise next evidence request.

Continue with the [audit workflow](../workflows/audit.md) or [output reference](../reference/outputs-snapshots-and-diff.md).
