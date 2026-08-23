# Website Experience and Content

- Node type: leaf
- Status: Active
- Contract revision: `spec-9`
- Authority: [Website contract](../website.md)
- Maximum size: 100 physical lines.
## Audience and outcome

**WEB-GOAL-001.** Address SwiftUI developers and design engineers who use
coding agents and can read SwiftUI, run Homebrew, and follow an agent prompt.
The page sells a deterministic semantic twin for inspectable agent reasoning,
not a linter score, automatic correctness, or the number of rules.

**WEB-GOAL-002.** A visitor should understand the product outcome, see the accepted
breadth of SwiftUI problems and agent tasks, understand the deterministic fact
boundary, and reach one stable setup prompt without reading the full README.

## Narrative and examples

**WEB-STORY-001.** Preserve the accepted marketing order: outcome-led hero;
semantic X-ray; three detailed code use cases; protected case; audit/refactor/review
tasks; semantic diff; six rule groups; trust/limits; installation; FAQ.

**WEB-STORY-002.** The X-ray uses the accepted duplicate-owner topology:
external Binding, local State, lifecycle copy, reciprocal synchronization,
`mirrored-state`, `manual-two-way-sync`, and the direct-Binding alternative.

**WEB-STORY-003.** Preserve both use-case layers: fixture-backed command-shaped
Binding, component-boundary, and derived-state examples, plus task-shaped audit,
refactor, and review prompts. The full catalog supplements these examples.

**WEB-STORY-004.** The protected case shows a real local transactional draft
with explicit Apply and Discard. It must state that no finding is expected and
must not expose a fake fix control.

**WEB-TWIN-001.** Define the semantic twin from `PC-GOAL-004` in the hero,
fact boundary, and evidence examples. Keep the explanation outcome-led; do not
insert separate context-gap, anatomy-ledger, or pipeline sections before the
visitor sees concrete product value.

**WEB-SKILL-001.** Present `swiftui-semantic` in Codex or Claude Code as the recommended consumer and router for the twin. Show concrete requests for that one skill; do not make the CLI, specialist workflows, or skill itself the semantic product object.

**WEB-LOOP-001.** Explain the exact-state workflow through the existing task
and semantic-diff proof. Keep build/index/configuration requirements in concise
supporting copy; do not turn internal pipeline steps into the main sales story
or imply a released watcher receipt before that receipt is terminal.

**WEB-INSTALL-001.** Lead with one short prompt that tells the local agent to
read the GitHub guide, install Homebrew first if absent, install the CLI through
Homebrew, and then install all four skills. Pin 0.5.0 until the terminal 0.6.0
receipt, then advance the CLI and all four skills together to 0.6.0. Homebrew installs
only the CLI and must never modify agent-host directories; compact CLI commands and the full guide remain secondary.

**WEB-FRESH-001.** Before public 0.6.0, describe the twin as built on demand for an exact source state and keep watcher details out of the released capability path. After a terminal 0.6.0 publication receipt, the landing may lead with a freshness-qualified live twin only alongside its indexed receipt and stale-state rejection. `Always-fresh` is never unconditional.

**WEB-VERSION-001.** Version numbers belong in metadata, immutable links,
installation detail, and the public-versus-candidate clarification. They are
not the hero promise, primary CTA, section theme, repeated value claim, or
social-preview artwork. The social preview contains no release badge.

## Visual and interaction contract

**WEB-VIS-001.** Use one art-directed theme without a theme toggle or automatic
OS recoloring. Combine warm paper, cool evidence canvas, and dark analysis
surfaces; use one dark syntax theme for every code sample.

**WEB-VIS-002.** Match the selected Annotated X-Ray design: editorial hierarchy,
ruled alignment, generous spacing, precise annotations, restrained radii and
shadows, and code as the primary visual material. Do not use a card wall,
cyberpunk glow, generic SaaS gradients, stock imagery, mascots, or a fake GUI.

**WEB-VIS-003.** Desktop examples may use Before/Evidence/After columns. Mobile
preserves the same reading order as a vertical sequence with usable code
overflow and no information available only on hover.

**WEB-AUTHOR-001.** The header links to `https://x.com/potapenko`. Desktop uses
the local Tabler Twitter mark with an accessible name; the responsive navigation
reveals `Follow @potapenko on Twitter` as visible text. The link does not add
tracking, a new route, or a second author surface elsewhere on the page.

## Copy, claims, and accessibility

**WEB-COPY-001.** English copy is factual, concise, and edited with the
`de-ai-writing` landing rules. Ban rhetorical questions, urgency, fake empathy,
vague authority, lifestyle theater, and unsupported qualitative outcomes.

**WEB-CLAIM-001.** Before the terminal receipt, supported claims remain release
0.5.0, an on-demand deterministic twin, 30 bounded rules, and seven analysis commands.
Afterward they may advance to release 0.6.0 and its receipt-qualified project
watcher while preserving snapshots/diff, separate judgment, provider independence,
and the Homebrew-versus-agent-skill installation boundary.

**WEB-CLAIM-002.** Never claim automatic rewriting, guaranteed correctness,
zero configuration, complete SwiftUI bug coverage, fully deterministic
recommendations, or that audit/diff replaces builds, tests, source review, or
the surrounding agent host's data policy.
**WEB-A11Y-001.** Critical content works without JavaScript. Provide semantic
landmarks, heading order, skip navigation, keyboard-visible focus, labelled
controls, non-color status cues, AA contrast, reduced-motion support, and responsive reading from 320 CSS pixels upward.
