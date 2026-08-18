---
name: swiftui-change-review
description: Review AI-generated or human SwiftUI changes through semantic diff and focused graph slices before raw Git diff. Use when Codex needs to assess state ownership, mutable representations, write paths, bindings, derived values, invariants, or lifetime changes and separate behavioral semantic risk from implementation-only edits.
---

# SwiftUI Change Review

## Review semantic change first

1. Use an installed `swiftui-audit`, or use `swift run --disable-automatic-resolution swiftui-audit` in this repository.
2. Require compatible indexed snapshots for both sides. Each snapshot must have been created from a fresh validated compiler Index Store while that exact source state was built. Do not use Git-revision operands for semantic review because they cannot preserve indexed resolution.
3. Obtain a semantic diff before reading the raw Git diff:
   - For two indexed snapshots:

     ```bash
     swiftui-audit diff <base-indexed-snapshot> <current-indexed-snapshot> --format json
     ```

   - For a changed worktree, build it, validate the current Index Store, and create the current snapshot with `--index-store <path>`. Require the caller to provide a compatible indexed baseline snapshot; if it does not exist, report that semantic comparison is blocked.
4. Parse JSON only from stdout. Keep stderr, command metadata, and exit status separate.
5. Read [references/review-contract.md](references/review-contract.md) when interpreting change kinds and deciding review priority.
6. Review ownership changes, new mutable representations, added write/call paths, removed invariants, Binding additions/removals, custom setter effects, model-boundary depth, broad observable inputs, manual synchronization, derivation, logical source counts, and state lifetime.
7. Slice each suspicious current finding or affected symbol before opening source:

   ```bash
   swiftui-audit slice <current-indexed-snapshot> --finding <finding-id> --format llm-json --token-budget 10000
   swiftui-audit slice <current-indexed-snapshot> --symbol <stable-id-or-name> --format llm-json --token-budget 10000
   ```

8. Inspect only slice evidence locations and directly required declarations. Read raw Git diff afterward to evaluate implementation-only changes and source mechanics not represented by the semantic graph.

## Preserve the fact boundary

Use model reasoning to classify intent, risk, and remediation. Never let it change AST, symbol, read/write, compiler relation, or source-location facts. Do not assume or invoke a model-provider API from the CLI.

Never recommend “Use Binding everywhere” or “Minimize `@State`.” Review correct ownership, canonical source of truth, explicit focused dependencies, minimal manual synchronization, correct lifetime, and correct transaction semantics. Guard transactional drafts, intentional transformations, legitimate local UI state, legitimate screen/container model ownership, and side effects in Binding setters.

## Failure policy

Stop and report the exact command, exit status, stderr, and missing evidence when JSON is invalid, an indexed snapshot is missing or invalid, either input is not indexed, resolutions mismatch, a slice selector is unknown or ambiguous, a token budget is insufficient, or fresh indexed coverage is unavailable. Do not infer a clean review from an empty or failed diff.

Treat non-indexed or mixed resolution as a hard guard, not a warning. Request matching indexed snapshots. Return `unknown` for ownership or lifetime when evidence is insufficient.

## Report findings

Report behavior/semantic findings first, ordered by risk and tied to semantic changes plus source evidence. Report implementation-only findings separately. State indexed resolution, snapshot identities, new/resolved findings, affected values, and any review limitation. A semantic-clean result does not prove behavior tests passed; report test evidence independently.
