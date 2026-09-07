# Ownership pilot results

Run date: 2026-09-07. Source candidate: 0.6.1, stage-2 platform assessment; recorded in the `AUDIT-FOLLOWTHROUGH-001` checkpoint. All eight inputs compiled together with the local Swift toolchain and were analyzed with an explicit fresh Index Store and cache disabled. Every graph, report and slice identified indexed resolution.

Frozen input identity (SHA-256 over `cases.json` followed by sorted source names and bytes): `bf1cd1d6aff1528424df3b70184c85d5240281cd60337e7e5a2a792a2fba65c7`.

## Detection and review burden

| Task | Supplied intent | Observed result | Decision after evidence review |
| --- | --- | --- | --- |
| LiveRename | Immediate editing | No finding | Keep direct Binding; the external owner is not identified in this file. |
| DeferredRename | Private edits until Save, Cancel discards | No finding; slice includes Save/Cancel write paths | Keep pending state and both actions. A direct Binding would change behavior. |
| LeakingRename | Same deferred-edit requirement | `mirrored-state` and `manual-two-way-sync`, high/strong-inference | The slice shows `onChange → save → title`. Remove that write-through path, preserving explicit Save/Cancel. |
| StatusLabel | Display the latest caption in NSTextField | `imperative-platform-view-update`, medium/candidate | Keep the native projection. No evidence establishes a need for a Coordinator or an immutable adapter. |
| SummaryFlag | Immediate, local display; no separate validation lifetime | `stored-derived-state`, medium/strong-inference | A computed flag matches the stated requirement; verify empty/nonempty transitions and initial rendering. |
| ComputedFlag | Same display requirement | No finding | Keep the computed property. |
| CallbackEffect | Updating enabled must also notify | `command-shaped-binding`, medium/strong-inference | The setter writes enabled and calls notify. Preserve both operations and their timing; no unconditional replacement with a direct Binding. |
| StaleCapture | Follow changed parent input while retaining view identity | No finding: known runtime miss | Inspect the State initialization in source. The slice alone does not prove update/lifetime behavior; a retained-identity behavior test is needed. |

The expected rule sets appeared in all **3/3 supported problem cases**. Including the deliberately retained runtime control, detection is **3/4 problem cases**, with **1 miss**. Among the four valid cases, **1/4 receives a review signal** and **0/4 receives a high finding**. Treating every finding as a proven defect would create one false positive here. A high-only gate detects only the high-priority leak case; it is not intended to detect every problem.

The eight written decisions match their frozen behavior-preservation rubrics by this agent's self-review. This is a check of the reported reasoning, not an independently graded 100% accuracy result. Product intent was supplied separately; the author knew the cases. No model-versus-model or source-only comparison was performed, and no productivity improvement can be inferred.

## Context cost

Bytes below are UTF-8 serialized output, not model tokens. Slices use the first emitted finding or the exact view ID when no finding exists. No token budget was supplied; mandatory provenance and evidence remain present.

| Task | Source bytes | Graph JSON bytes | Audit JSON bytes | Slice JSON bytes | Conservative slice estimate |
| --- | ---: | ---: | ---: | ---: | ---: |
| LiveRename | 135 | 16,414 | 1,551 | 13,664 | 4,555 |
| DeferredRename | 403 | 47,372 | 4,071 | 40,988 | 13,663 |
| LeakingRename | 461 | 52,548 | 3,833 | 55,584 | 18,528 |
| StatusLabel | 284 | 22,441 | 3,396 | 17,193 | 5,731 |
| SummaryFlag | 343 | 37,510 | 2,557 | 38,497 | 12,833 |
| ComputedFlag | 292 | 30,910 | 2,002 | 25,946 | 8,649 |
| CallbackEffect | 273 | 27,127 | 2,802 | 28,697 | 9,566 |
| StaleCapture | 314 | 23,970 | 1,788 | 23,191 | 7,731 |

Total slice output is **243,760 bytes**, versus **258,292 graph bytes** and **2,505 source bytes**. Three finding slices exceed their full graph size. This set demonstrates useful explicit paths, not cheap context: on short files the JSON representation is much larger than source. These unbudgeted measurements do not establish how often a practical budget can fit mandatory evidence on larger projects.

## Limits and next decisions

The first harness run used a bare view name that also matched the file's module, producing unhelpful module slices on no-finding cases. The runner was corrected to select the exact view ID from the graph, then rerun; the table uses that corrected selection. Inputs, expectations and analyzer rules were unchanged. This is a selection ambiguity worth documenting, not a reason to treat the tiny initial slices as a context saving.

A view-level slice can expose write paths without including the normalized transaction classification. Call graphs also include compiler-generated accessors; the consumer must distinguish those from source-level commands. StaleCapture remains a missed runtime condition. Use the smallest precise finding/property ID and a budget, then inspect source rather than drawing a clean-bill-of-health conclusion.

The evaluation is deliberately small, authored in-house, and limited to one toolchain. It does not establish general recall, real-project false-positive rates, token savings, or agent quality gains. Further precision work should address context size and selector usefulness before expanding the rule catalog. The pilot was not used to retune the analyzer.
