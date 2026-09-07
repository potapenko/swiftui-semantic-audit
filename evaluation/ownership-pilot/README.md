# Ownership pilot protocol

This small new task set was written and its expectations frozen before the first analyzer run on 2026-09-07, after stage-2 policy implementation. It was not used to tune the rules. The same agent wrote and reviewed it: this is a transparent smoke evaluation, not a blinded study, external validation, or a comparison between models.

## Questions fixed before execution

For each file, identify who can write the value, whether the local representation has an independent lifetime, whether a finding establishes a defect or requires judgment, and what behavior any remediation must preserve. `cases.json` pins expected supported findings and a decision rubric. Four cases intentionally contain a problem; four are valid. `StaleCapture` is an out-of-scope runtime negative control and must remain in the reported miss denominator rather than being discarded.

The CallbackEffect notification is required. DeferredRename and LeakingRename both require edits to remain private until Save; Cancel must discard. SummaryFlag has no debounce, server validation, or independent lifetime. StaleCapture must follow parent selection changes while retaining its view identity. These requirements are product intent supplied separately from source.

## Procedure and measures

Run `python3 evaluation/ownership-pilot/run.py --cli .build/debug/swiftui-audit`. The runner copies inputs into temporary storage, compiles all files into a fresh Index Store, requires explicit indexed results, and emits one JSON result to stdout. It leaves no snapshots or logs in the repository.

Count a supported defect as detected only when its expected rule set is present. Report unexpected findings separately from blocking high findings: a candidate on a valid native adapter is a review signal, not a proven defect. Keep the runtime control in all-task detection totals. Record full graph JSON bytes, audit JSON bytes, slice JSON bytes, source bytes, and the slice's conservative byte-based estimate; none is an actual model token or cost measurement. Slices use one real finding where available and the named view otherwise.

Review the actual slice questions, ownership/write topology and evidence before reading any missing source. Score decisions against the frozen rubric, including preserving required behavior and explicitly acknowledging unknown facts. Record self-review outcomes and missing context. Do not claim causal improvement over source-only reasoning without a separate randomized comparison.

The corpus and protocol are durable evaluation inputs. [Results](results.md) records the bounded outcome and source digest. Repeating this corpus after changes is regression evidence, no longer a held-out evaluation.
