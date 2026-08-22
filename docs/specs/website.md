# Website contract

- Node type: hybrid
- Status: Active
- Contract revision: `spec-7`
- Authority: user-authorized website addenda through `INSTALL-UX-001` on 2026-08-22
- Stability: released baseline; `INSTALL-UX-001` evolving until publication
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
then all four skills as a separately owned phase. The guide pins installation
artifacts to release 0.5.0. The formula remains CLI-only and must never modify
agent-host directories.

## Choose the governing child

- [Experience and Content](website/experience-and-content.md) — audience,
  narrative, examples, visual system, claims, and accessibility.
- [Delivery and Acceptance](website/delivery-and-acceptance.md) — source/build
  boundaries, DigitalOcean deployment, metadata, interactions, and QA.
