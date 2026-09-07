# Audit follow-through

Authority: on 2026-09-07 the user explicitly requested execution of the complete four-stage audit plan without stopping between stages. Stage 1 is saved at `f3467a0`. This task completes stages 2–4 in the current `master` branch. Mode: Evolve for platform assessment, Reconcile for public/source documentation, and bounded evaluation for the pilot. No new persistent goal or delegated work is created.

## Contract traversal and delta

Read `docs/specs/README.md` spec-37 → product architecture/operations (spec-7/19) → rules branch/core/platform/adjudication (spec-4/4/4/5), semantic IR graph/slice (spec-5/5), CLI check (spec-4), acceptance fixtures/dogfood (spec-10/16), website branch and experience/delivery (spec-10/5), release capability/residuals. The new approved delta advances the root to spec-38 and epoch tz-v30; unrelated historical release receipts remain pinned.

`RULE-PLATFORM-UPDATE-001` becomes medium/candidate because native-view updating alone proves no architectural defect. Keep all operation evidence and the rule ID; remove unconditional immutable-representable/coordinator prescriptions. Slices ask about repeatability, native synchronization, commands, and feedback into application state. Existing default high-severity check remains unchanged; an explicit medium/low threshold includes these review signals. Other rules, severities, IDs, graph/config schemas, deterministic facts, and five-file snapshot transport are protected.

The basis includes Apple's [updateNSView](https://developer.apple.com/documentation/swiftui/nsviewrepresentable/updatensview(_:context:)) and [updateUIView](https://developer.apple.com/documentation/swiftui/uiviewrepresentable/updateuiview(_:context:)) contracts: updating native view state is a normal representable responsibility. Current evidence showed a simple NSTextField value projection receiving high/strong-inference. This is an authorized policy correction, not proof that every representable boundary is safe.

## Execution and owned paths

1. Update selected rule/IR/website contracts before implementation; change `Sources/AuditRules/ArchitectureRules.swift`, platform questions in `Sources/ContextSlicer/ContextSlicer.swift`, corresponding RuleTests/CheckTests/ContextSlicerTests and realistic confidence expectations.
2. Freeze eight new tasks, expected facts and decision rubrics under `evaluation/ownership-pilot/` before running the analyzer. Include clean, problematic, platform, and unsupported-runtime cases. Compile and analyze them with a fresh explicit index, measure detection and JSON context size, then review bounded evidence against the frozen rubric. Do not tune the rules to the pilot. Record misses and limits honestly; this single-agent pilot is not a blinded controlled study or evidence of general productivity gains.
3. Rewrite README to lead with one example, installation, first result, limits and deeper docs. Align release-specific invocation guidance in the installation and concept/reference guides. Rewrite landing copy within the existing visual structure, preserving all capability blocks, consistent names, ownership terminology, installation prompts and immutable public release facts. Show a real output excerpt with reproducible provenance.
4. Run affected Swift suites, locked build, fixture and indexed parity checks, the pilot, site tests/build, documentation checks, and rendered responsive/interaction QA. Save changes in checkpoint commits on master.

Additional owned paths: `README.md`, selected files under `docs/concepts/`, `docs/reference/`, `docs/getting-started/`, `docs/specs/`, `docs/development/`, this record, `website/index.html`, `website/styles.css` for the new evidence disclosure overflow, narrow site acceptance text assertions and `design-qa.md` if needed. Evaluation inputs/protocol/results are deliberate deliverables; command logs and screenshots remain temporary outside the repository.

No publication, installation, release tag, remote push, dependency upgrade, visual redesign, new rules, or automatic source rewriting is included in the audit plan. Local rendered QA uses Playwright because no Browser skill is installed. Source edits and local verification do not update the installed/public product.

## Acceptance status

All four audit-plan stages are implemented in current source (stage 1 at `f3467a0`; stages 2–4 saved by this checkpoint).

- Stage 2: native update remains fully evidenced, now medium/candidate without a prescribed adapter rewrite. Focused check-policy regression passes; default high passes and explicit medium fails as documented. Other severities and thirty rule IDs are unchanged.
- Stage 3: the [eight-task pilot](../../evaluation/ownership-pilot/results.md) compiles and runs against a fresh explicit index. It detects 3/3 supported problem cases and misses the runtime control (3/4 including that control); one valid adapter gets a review signal and no valid case gets a high finding. Slice output totals 243,760 bytes for 2,505 source bytes. The result does not establish token savings or general agent accuracy. The exact-view selector correction and self-review limitations are recorded.
- Stage 4: README now leads with one complete example, then installation/first result and limitations. Landing examples preserve names and actions, clarify Binding access versus ownership, and show real source-linked finding fields. Installation now distinguishes current-source assist policy from the actual 0.6.0 tag metadata; public installation and release facts remain pinned.
- Verification: locked full Swift tests passed (106 XCTest + 15 Swift Testing), Release build passed, realistic syntax/index parity remains 34 findings with no Good-file evidence, fixture snapshots remain byte-identical to each other and the committed baseline apart from the allowed manifest revision. Website/build/publisher tests passed (21), as did docs/anchors, spec size limits, frozen-input identity and whitespace checks. [Rendered QA](../../design-qa.md) covers desktop/mobile, keyboard, JSON disclosure, exact clipboard content, no-JavaScript and console health.
- No installed or public artifact was changed. Temporary compiler stores, snapshots, browser observations and preview artifacts were cleaned by their owners after acceptance. Future pilot repetitions are regression evidence, not newly held-out results.
