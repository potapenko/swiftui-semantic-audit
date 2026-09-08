# Website contract

- Node type: hybrid
- Status: Active
- Contract revision: `spec-16`
- Authority: user-authorized website addenda through `WEBSITE-ANALYTICS-001` on 2026-09-08
- Stability: verified 0.6.0 release facts; update UX is an unpublished local candidate
- Read when: designing, implementing, publishing, or verifying the product website.
- Do not read when: work is limited to the Swift package, CLI, rules, or agent skills.
- Maximum size: 100 physical lines.

## Contract Delta

**WEB-DELTA-001 — Additive website surface.** `WEBSITE-001` evolves the previously
missing website domain into one English static landing page. It adds no CLI,
schema, rule, skill, installation, or released-product behavior. The source of
truth for product claims remains the product, rule, CLI, and release contracts.
Generated visual concepts are design evidence only; incorrect dates, commands,
rule identifiers, or capabilities in them are stale placeholders and forbidden
implementation inputs.

**WEB-DELTA-002 — Adaptation boundary.** HoldType contributes only its bounded
static-build, App Platform, publisher, metadata, accessibility, and QA mechanics.
Its visual design, localization system, product content, analytics, assets, and
release coupling are excluded.

**WEB-DELTA-003 — Publication and canonical host.** `WEBSITE-PUBLISH-001`
authorizes `https://swiftui-audit.dev/` as the eventual canonical public root,
`www` as a permanent redirect, and App Platform auto-deployment from `master`.
Bootstrap remains domain-free until the technical ingress passes. Domain
attachment waits for authoritative registration and DNS, so a pending purchase
cannot create a false public-domain or TLS claim.

**WEB-DELTA-004 — Personal author link.** `WEBSITE-AUTHOR-001` adds one external
header link to `https://x.com/potapenko`, adapting HoldType's icon-only desktop
and labelled mobile behavior. The target site's visual system, navigation order,
accessibility, and local Tabler asset boundary remain authoritative.

**WEB-DELTA-005 — Skill-first product interface.** `WEBSITE-SKILL-STORY-001`
makes `swiftui-semantic` in Codex or Claude Code the landing page's primary
product interface. Use cases are normal SwiftUI tasks asked through that one
skill. The CLI, router, and specialist workflows are subordinate implementation
details; product and installation semantics do not change.

**WEB-DELTA-006 — 0.5.0 release facts.** `RELEASE-0.5.0-001` updates only the
version, tagged links, thirty-rule count, and installation prompt after the
GitHub/Homebrew release is terminal. It does not change layout, narrative,
examples, interaction, assets, accessibility, or deployment mechanics.

**WEB-DELTA-007 — One-prompt installation.** `INSTALL-UX-001` replaces the
prior public setup with one short agent prompt that reads the GitHub guide.
The agent installs Homebrew first when absent, the CLI through Homebrew, and
then all four skills as a separately owned phase. `WEB-DELTA-010` and
`BASE-REL-015` advance the guide's pinned artifacts to release 0.6.0. The
formula remains CLI-only and must never modify agent-host directories.

**WEB-DELTA-008 — Semantic-twin-first story.** `SEMANTIC-TWIN-STORY-001`
supersedes only the product-priority rule in `WEB-DELTA-005`: the deterministic
semantic twin is now the primary product object, while `swiftui-semantic` and
the specialist skills are its agent-facing consumers. The landing leads with
the problem, twin, exact-state agent loop, use cases, proof, limits, and stable
installation. Its original 0.5.0-versus-preview split is superseded only for
release state by `WEB-DELTA-010` and terminal receipt `BASE-REL-015`.

**WEB-DELTA-009 — Capability-preserving correction.**
`SEMANTIC-TWIN-CAPABILITIES-001` restores the previously accepted landing
structure and every prior use-case/capability block. Semantic twin is the
unifying explanation, not a substitute for the X-Ray, detailed patterns,
task-shaped workflows, semantic diff, thirty-rule surface, trust, installation,
or FAQ. Release versions remain supporting truth and must not dominate the
hero, CTA, or section narrative.

**WEB-DELTA-010 — Receipt-gated 0.6.0 facts.** `RELEASE-0.6.0-001` authorizes
the landing's version, immutable links, installation prompt, and watcher copy
to advance together only after the terminal 0.6.0 publication receipt.
`BASE-REL-015` satisfies that gate, so the site describes only a
freshness-qualified indexed live twin
with explicit stale-state rejection; layout, capability breadth, interaction,
accessibility, deployment mechanics, and the no-bottles/no-automatic-skill-
installation boundary remain unchanged.

**WEB-DELTA-011 — Version-neutral social preview.** The user's 2026-08-23
decision removes the release badge from the social preview. Public metadata may
carry the current release version, but the image itself remains reusable across
releases; its layout, headline, graph, dimensions, and visual system stay fixed.

**WEB-DELTA-012/013 — Compact actionable copy controls.** `COPY-CONTROLS-001`
replaces the large setup-prompt action with one shared small, translucent gray
icon control at each user-applicable block: the three task prompts, the install prompt, and the CLI-only command. `UPDATE-UX-001` extends the same control to the added update prompt. Copy success remains
visually and accessibly reported. Demonstration code, inline terminology,
prompt text, commands, installation ownership, and release facts stay unchanged.
`COPY-CONTROLS-RIGHT-001` corrects placement to the conventional upper-right
corner while preserving the accepted size, styling, targets, and feedback.

**WEB-DELTA-014 — One-prompt update.** `UPDATE-UX-001` adds a second compact agent prompt for an existing installation inside the established setup block. The prompt uses the stable `https://swiftui-audit.dev/#install` entry point, keeps the Homebrew CLI and four sibling skills as separate update phases, and requires verification that they resolve to the same stable release. The existing install prompt, CLI-only command, current public version, release artifacts, and no-blind-link-replacement boundary remain unchanged.
## Choose the governing child

- [Experience and Content](website/experience-and-content.md) — audience, narrative, examples, visual system, claims, and accessibility.
- [Delivery and Acceptance](website/delivery-and-acceptance.md) — source/build
  boundaries, DigitalOcean deployment, metadata, interactions, QA, and the [GA4 analytics contract](website/analytics.md).
