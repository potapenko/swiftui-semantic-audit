# CLI Dogfood, Skills, and CI Acceptance

- Node type: leaf
- Status: Active
- Contract revision: `spec-16`
- Authority: [Acceptance and QA contract](../acceptance.md)
- Read when: selecting fixture, build, determinism, safety, dogfood, skill, CI, or completion obligations.
- Do not read when: the task does not implement or verify accepted behavior.
- Maximum size: 100 physical lines.


## CLI dogfood

**ACC-DOG-001.** Run and parse:

- `audit Tests/Fixtures/RuleTests --syntax-only --format json`;
- `snapshot Tests/Fixtures/RuleTests … --syntax-only --format json`;
- `diff <baseline> <regenerated> --format json`;
- `check --baseline Tests/Baselines/RuleTests Tests/Fixtures/RuleTests --fail-on-new high --syntax-only --format json`;
- `slice` on an emitted fixture finding with `--format llm-json`;
- `doctor . --format json`;
- `audit Sources --syntax-only --format json`.

**ACC-DOG-002.** Require valid schema v2 JSON, expected resolution, a passing baseline check, an empty same-input semantic diff, a nonempty bounded slice for a real finding, and no command timeout.

**ACC-DOG-003.** Dogfood does not require zero legacy findings. CI policy is no new high-severity finding relative to the compatible baseline.

**ACC-DOG-004.** Released 0.6.0 previews the repository's project setup without writes, runs one indexed watcher generation, validates the fresh status receipt and five-file live snapshot, and compares it with the tracked `.swiftui-audit/baseline`.

## Skills

**ACC-SKILL-001.** Create exactly one user-facing router and three specialist workflows:

- `swiftui-semantic`;
- `swiftui-semantic-audit`;
- `swiftui-dataflow-refactor`;
- `swiftui-change-review`.

**ACC-SKILL-002.** Each skill has frontmatter containing only `name` and a concise discriminating `description`, an imperative body under 500 lines, one-level linked references, and `agents/openai.yaml` with quoted interface strings, a 25–64 character short description, and a one-sentence default prompt naming `$skill-name`. Only `swiftui-semantic` sets `policy.allow_implicit_invocation: true`; all three specialists set it to `false`.

**ACC-SKILL-003.** Run the bundled `quick_validate.py` for all four; parse every YAML file; reject unfinished-marker placeholders and broken relative links.

**ACC-SKILL-004.** Every skill preserves JSON stdout discipline, indexed-resolution consistency, exact failure policy, provider independence, topology-over-wrapper reasoning, and the deterministic/LLM fact boundary.

**ACC-SKILL-005.** The router distinguishes implicit assist from strict mode. Assist mode reads its dedicated reference, stays inside the user's current SwiftUI task, and does not load a specialist. Explicit `$swiftui-semantic`, explicit specialist invocation, or an explicit request to run the semantic audit/refactor/review workflow enters strict mode: project setup/lifecycle uses the bounded watcher reference, investigation uses audit, requested semantic implementation uses refactor, and review of existing changes uses review. Mixed strict tasks use the smallest valid sequence, read the selected specialist completely, preserve handoff state, and never replace specialist acceptance gates with a shortened combined workflow.

**ACC-SKILL-006.** Every strict router or specialist workflow requires explicit indexed analysis for its semantic result. Skill Markdown contains no frontend-only guidance or examples, does not rely on automatic resolution fallback, validates `resolution: "indexed"`, and stops that strict semantic workflow when a fresh project-covering Index Store or compatible indexed snapshot is unavailable. Change review uses indexed snapshots rather than Git-revision operands that cannot preserve indexed resolution. Implicit assist mode may use only a ready fresh compatible indexed snapshot or one bounded audit and optional focused slice against an already-available project-covering Index Store; absent evidence skips semantic verification and never blocks the user's task.

**ACC-SKILL-007.** Audit, refactor, and review guidance treats reusable-owner findings as candidates, checks instance count and lifetime, and protects explicit per-item models, screen/container ownership, focused values/bindings/actions, and passive Environment. It forbids blanket model removal, Binding-everywhere, and one-View-one-ViewModel prescriptions.

**ACC-SKILL-008.** All four skills link the shared run-artifact policy directly. Auxiliary evidence uses task-scoped temporary storage outside source repositories, Codex configuration homes, and installed skill/package directories; permanent per-command files are not required to separate streams. Durable evidence is minimal, uses an explicit non-repository state root, and records retention. Explicit canonical snapshots keep `IR-SNAP-*` behavior and may use a workflow-selected destination.

**ACC-SKILL-009.** `swiftui-semantic` is the sole implicitly discoverable semantic skill. It activates only for materially relevant SwiftUI ownership, duplicated or derived state, manual synchronization, Binding/Observation/Environment flow, or component-boundary data flow. It does not activate for layout, styling, generic framework, performance, concurrency, or security work. Implicit assist never performs setup, watcher lifecycle, a build solely for indexing, snapshot creation, baseline promotion, or a full specialist pipeline. The three specialists remain explicit-only, and strict mode retains complete indexed gates.

## CI

**ACC-CI-001.** Run on official `macos-26`. The official runner catalog identifies it as the macOS 26 arm64 label, and its image inventory lists Xcode 26.6 at `/Applications/Xcode_26.6.app`. Select that toolchain explicitly and fail early unless it reports Swift >= 6.3.

**ACC-CI-002.** Use only official GitHub actions for repository operations and run shell/Swift/Python tools directly. Pin action major versions intentionally.

**ACC-CI-003.** Apply explicit job/step timeouts. Network use is limited to actions and Swift dependency resolution/cache availability.

**ACC-CI-004.** CI must:

1. checkout;
2. verify Swift >= 6.3 and print Xcode version;
3. resolve, build, and test;
4. audit legacy rule fixtures, configured architecture fixtures, negative architecture fixtures, and `Sources` in syntax-only JSON mode;
5. compile and audit `RealProjectPatterns` through a fresh explicit Index Store and audit the same corpus in syntax-only mode, requiring 34 findings including the specific reusable-owner replacement, no good-file evidence, and an identical per-rule/per-file matrix;
6. snapshot fixtures twice and compare all five files byte for byte;
7. prove cold-cache, warm-cache, and `--no-cache` report bytes are identical;
8. compare the generated snapshot with the committed baseline using exact semantic-file bytes and the revision-only manifest normalization in `ACC-DET-003`;
9. run `check --fail-on-new high`;
10. slice an emitted real finding;
11. run doctor JSON;
12. validate all four skills, their assist/strict boundary, shared artifact-hygiene link, and YAML metadata without repository or global-environment mutation; require implicit invocation only for the router, explicit-only policy for all specialists, and reject frontend-only resolution guidance anywhere under `skills/`;
13. parse JSON/YAML and check placeholders/links.
14. preview project setup, run one indexed watcher generation, validate fresh status/live snapshot, and compare the tracked project baseline.

**ACC-CI-005.** Current source candidate builds report exactly `0.6.1`, and CLI help exposes setup-owned `--watch-timeout` plus the foreground watch `--timeout` override. Candidate CI retains the legacy-field-omission project manifest, so real watcher dogfood also proves the 300-second decode default while focused tests cover configured propagation.

## Homebrew release

**ACC-BREW-001.** The formula source is an immutable `0.6.0` release archive with SHA-256 verification and the committed `Package.resolved`. Its install step builds only the `swiftui-audit` product with automatic dependency resolution disabled and installs the resulting executable in Homebrew's `bin`.

**ACC-BREW-002.** Before publication, `brew style`, strict new-formula audit, source installation, and `brew test` pass. The functional test analyzes a real Swift file in syntax-only JSON mode and validates schema version, tool version, and resolution rather than checking only executable presence or help text.

**ACC-BREW-003.** The installed CLI reports `0.6.0` through `--version`, preserves the semantics and help entries of the seven existing analysis commands, exposes the additive `project` namespace, and runs without a repository clone. Indexed analysis continues to use the selected user toolchain through `xcrun`; the formula does not embed or hard-code one user's Index Store path.

**ACC-BREW-004.** The published receipt pins upstream tag and commit, release archive checksum, tap formula commit, tested Homebrew/macOS/architecture, source-install result, and the exact direct install command. Unsupported bottle platforms remain source builds or explicit residuals rather than unverified release claims.
