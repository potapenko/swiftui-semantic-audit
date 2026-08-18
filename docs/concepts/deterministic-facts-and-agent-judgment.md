# Deterministic facts and agent judgment

SwiftUI Semantic Audit keeps extraction separate from interpretation. This boundary lets different coding agents use the same evidence without letting a model rewrite inconvenient facts.

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

The first six stages are deterministic for the same source, toolchain, configuration, and resolution. The last stage can use project context and product intent.

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

These are machine facts. An agent may quote, group, and reason from them. It may not change them in its explanation.

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

## Why slices come before source

An audit report can contain many nodes and findings. `slice` selects one finding or symbol and keeps its semantic values, ownership, relevant paths, evidence, and questions inside a bounded envelope.

This gives the agent a concrete starting point and reduces two common errors:

- reconstructing architecture from an arbitrary subset of files;
- reading so much source that the decisive path is lost among unrelated details.

The slice is not the end of investigation. It routes source reading to the evidence locations and directly required declarations.

## Indexed evidence

Indexed mode enriches the graph with project-covering compiler identity and use relations. The bundled workflow treats that compiler-backed identity as a required part of semantic evidence.

The bundled agent workflows therefore require:

- a fresh build of the exact source state;
- an explicit validated Index Store path;
- `resolution: "indexed"` in every live-source result;
- compatible indexed snapshots for semantic review.

Results from a lower resolution must not be substituted for, compared with, or described as indexed workflow evidence.

## Provider independence

The executable has no OpenAI, Anthropic, or other model-provider integration. It emits JSON or LLM-ready JSON. The surrounding host decides which agent reads it.

This makes the semantic contract reusable and testable without binding extraction to a model, prompt format, account, or network call.

## Failure is evidence

Invalid JSON, ambiguous selectors, missing indexed coverage, resolution mismatch, configuration mismatch, unsafe paths, and insufficient slice budgets fail closed. An empty or failed result must not be interpreted as a clean architecture.

When deterministic evidence cannot establish owner, lifetime, transformation, or transaction behavior, the correct agent result is `unknown` plus a precise next evidence request.

Continue with the [audit workflow](../workflows/audit.md) or [output reference](../reference/outputs-snapshots-and-diff.md).
