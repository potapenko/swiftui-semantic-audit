# Change-review workflow

Use change review when edits, commits, or a patch already exist. Review the semantic change before the raw Git diff, then use the source diff to cover implementation details the graph does not represent.

## Entry point

- Codex: `$swiftui-semantic Review the current SwiftUI changes for ownership and lifetime regressions.`
- Claude Code: `/swiftui-semantic Review the current SwiftUI changes for ownership and lifetime regressions.`

The router selects `swiftui-change-review` directly.

## Evidence requirement

Semantic review requires two compatible indexed snapshots:

- the baseline snapshot was created after building the exact baseline source;
- the current snapshot was created after building the exact changed source;
- both record `resolution: "indexed"`;
- both use the same schema and analysis-configuration digest.

Git-revision operands do not preserve compiler-index evidence and therefore do not satisfy this workflow. If a compatible indexed baseline snapshot does not exist, report semantic comparison as blocked rather than calling the change clean.

## 1. Compare semantic snapshots

```bash
swiftui-audit diff \
  .semantic/baseline \
  .semantic/current \
  --format json > semantic-diff.json
```

Review these changes first:

- ownership changes;
- added or removed mutable representations;
- new read, write, call, Binding, or synchronization paths;
- source-of-truth count changes;
- derivation changes;
- model-boundary depth and broad component inputs;
- custom Binding effects;
- new and resolved findings;
- configuration or resolution inconsistency.

## 2. Slice suspicious current evidence

For a current finding:

```bash
swiftui-audit slice .semantic/current \
  --finding finding:0123456789abcdef \
  --format llm-json \
  --token-budget 10000 > review-slice.json
```

For an affected symbol:

```bash
swiftui-audit slice .semantic/current \
  --symbol usr-or-unambiguous-qualified-name \
  --format llm-json \
  --token-budget 10000 > review-slice.json
```

The snapshot already carries indexed facts, so no live-source index flag is needed for these commands.

## 3. Inspect source evidence, then Git diff

Open the slice evidence locations and directly required declarations. After the semantic path is understood, inspect the raw Git diff for:

- effect ordering and error handling;
- behavior or API changes outside the graph vocabulary;
- removed guards and invariants;
- transaction and cancellation behavior;
- tests that no longer cover the changed path;
- implementation defects unrelated to state topology.

Do not infer behavior-test success from a clean semantic diff.

## 4. Report findings by risk

Report behavior and semantic risks first, each tied to a semantic change and source evidence. Report implementation-only findings separately.

Include:

- baseline and current snapshot identities;
- indexed resolution and matching configuration digest;
- new, resolved, and retained findings;
- affected semantic values and source counts;
- ownership, write-path, Binding, effect, derivation, and lifetime changes;
- behavior-test evidence;
- limitations or missing evidence.

If there are no actionable findings, say which evidence was checked. Do not claim the application is behaviorally correct unless the relevant tests or runtime checks also passed.

## Stop conditions

Stop on invalid JSON, missing or non-indexed snapshots, mixed resolution, different configuration digests, ambiguous selectors, insufficient slice budget, or stale current index coverage. An empty diff produced from incompatible evidence is not a review result.
