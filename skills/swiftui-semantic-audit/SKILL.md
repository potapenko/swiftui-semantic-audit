---
name: swiftui-semantic-audit
description: Audit Swift and SwiftUI state/data-flow architecture with swiftui-audit before reading broad source. Use when Codex needs to investigate state ownership, duplicated mutable representations, manual synchronization, callback plumbing, derived state, Observation or Binding topology, or to explain semantic audit findings in a SwiftUI codebase.
---

# SwiftUI Semantic Audit

## Establish the command and resolution

1. Use an installed `swiftui-audit` binary when available. In this repository, use `swift run --disable-automatic-resolution swiftui-audit`.
2. Select one resolution for the whole investigation:
   - Pass `--syntax-only` for deterministic syntax facts without an index.
   - Pass `--index-store <path>` only for a validated compiler Index Store.
   - Omit both only when conservative automatic discovery and syntax-only fallback are acceptable.
3. Never compare or combine `indexed` and `syntax-only` evidence as if they had equal resolution.
4. Treat the CLI as provider-independent. Do not assume or add an OpenAI, Anthropic, or other model API call.

## Audit before source

1. Run JSON audit before opening arbitrary Swift source:

   ```bash
   swiftui-audit audit <source-path> --syntax-only --format json
   ```

2. Parse JSON from stdout. Keep stderr, exit status, and command metadata separate from semantic data.
3. Rank findings by severity and confidence, then group them by overlapping nodes, edges, evidence, or semantic values.
4. Select relevant findings. Slice each one before inspecting implementation source:

   ```bash
   swiftui-audit slice <source-or-snapshot> --finding <finding-id> --syntax-only --format llm-json --token-budget 10000
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
- unknown when evidence is insufficient.

Base the classification on ownership, read/write topology, lifetime, commit/discard events, and transformations. Do not optimize for wrapper counts. Never prescribe “Use Binding everywhere” or “Minimize `@State`.” Optimize correct ownership, one canonical source of truth, explicit dependencies, minimal manual synchronization, correct lifetime, and correct transaction semantics.

Allow LLM reasoning to add intent, risk, classification, or remediation. Never let it alter AST facts, symbol identities, reads, writes, compiler-derived relations, or source locations.

## Failure policy

Stop and report the exact command, exit status, stderr, and unresolved evidence when:

- a command fails or stdout is not valid JSON for the requested format;
- a finding or symbol is missing or ambiguous;
- a slice cannot fit its mandatory envelope;
- indexed enrichment was explicitly requested but is unavailable or lacks project coverage;
- graph/report or compared-input resolutions disagree;
- evidence cannot establish ownership, lifetime, transformation, or transaction boundaries.

Do not replace missing deterministic facts with model guesses. Return `unknown` and the smallest next evidence request.

## Report

Report semantic value, current owner and representations, read/write/synchronization paths, confidence and resolution, classification, evidence locations, risk, and a conditional remediation. Separate deterministic CLI facts from LLM adjudication.
