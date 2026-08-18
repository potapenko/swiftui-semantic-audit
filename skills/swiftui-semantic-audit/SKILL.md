---
name: swiftui-semantic-audit
description: Audit Swift and SwiftUI state/data-flow architecture with swiftui-audit before reading broad source. Use when Codex needs to investigate ownership, duplicated state, synchronization, callback plumbing, custom Binding effects, Observation tunnels, broad component inputs, derived state, or semantic findings in a SwiftUI codebase.
---

# SwiftUI Semantic Audit

## Establish indexed analysis

1. Use an installed `swiftui-audit` binary when available. In this repository, use `swift run --disable-automatic-resolution swiftui-audit`.
2. Build the project when needed to produce a fresh compiler Index Store that covers the requested source. Validate its readiness and exact path with project build output and `swiftui-audit doctor <source-path> --format json`.
3. Pass `--index-store <path>` explicitly to every live-source audit or slice command. Do not omit it in reliance on automatic discovery.
4. Parse the result and require `resolution: "indexed"`. Treat any other resolution as insufficient evidence and stop.
5. Treat the CLI as provider-independent. Do not assume or add an OpenAI, Anthropic, or other model API call.
6. For role-, feature-, or composition-root-aware analysis, locate and validate the exact project `.swiftui-audit.json`, pass it with `--config <path>`, and retain its digest. If authoritative classification is absent, report that role-aware conclusions are unavailable; never infer roles from names.

## Audit before source

1. Run JSON audit before opening arbitrary Swift source:

   ```bash
   swiftui-audit audit <source-path> --index-store <path> --config <path> --format json
   ```

2. Parse JSON from stdout. Keep stderr, exit status, and command metadata separate from semantic data.
3. Rank findings by severity and confidence, then group them by overlapping nodes, edges, evidence, or semantic values.
4. Select relevant findings. Slice each one before inspecting implementation source:

   ```bash
   swiftui-audit slice <source-path> --finding <finding-id> --index-store <path> --config <path> --format llm-json --token-budget 10000
   ```

5. Follow only `sourceEvidence` locations when implementation detail is required. Expand beyond them only when a named dependency cannot be resolved from the slice, and state why.
6. Read [references/rules.md](references/rules.md) when classifying a finding or evaluating an exception.
7. Read [references/semantic-ir.md](references/semantic-ir.md) when interpreting graph fields, confidence, ownership, or resolution.

## Adjudicate intent without rewriting facts

Classify each candidate as one of:

- accidental mirror;
- transactional draft;
- derived state;
- transformed state;
- legitimate local UI state;
- command-shaped mutation or Binding factory boundary;
- observable-model tunnel or over-broad component input;
- legitimate screen/container ownership;
- unknown when evidence is insufficient.

Base the classification on ownership, read/write/call topology, lifetime, commit/discard events, transformations, explicit Binding getter/setter roles, model-propagation depth, and the receiving View's component role. Treat `binding-factory` and `broad-observable-input` as candidates requiring architectural adjudication. Do not optimize for wrapper counts. Never prescribe “Use Binding everywhere” or “Minimize `@State`.” Optimize correct ownership, one canonical source of truth, explicit dependencies, minimal manual synchronization, focused component inputs, correct lifetime, and correct transaction semantics.

Allow LLM reasoning to add intent, risk, classification, or remediation. Never let it alter AST facts, symbol identities, reads, writes, compiler-derived relations, or source locations.

## Failure policy

Stop and report the exact command, exit status, stderr, and unresolved evidence when:

- a command fails or stdout is not valid JSON for the requested format;
- a finding or symbol is missing or ambiguous;
- a slice cannot fit its mandatory envelope;
- indexed enrichment is unavailable, stale, or lacks project coverage;
- a command returns a resolution other than `indexed`;
- graph/report or compared-input resolutions disagree;
- compared inputs use different configuration digests, or required role configuration is absent;
- evidence cannot establish ownership, lifetime, transformation, or transaction boundaries.

Do not replace missing deterministic facts with model guesses. Return `unknown` and the smallest next evidence request.

## Report

Report semantic value, current owner and representations, logical source count, read/write/call/synchronization paths, Binding setter role or boundary depth when present, confidence, indexed resolution, validated Index Store path, configuration digest or explicit topology-only limitation, classification, evidence locations, risk, and a conditional remediation. Separate deterministic CLI facts from LLM adjudication.
