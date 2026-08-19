# Website contract

- Node type: hybrid
- Status: Active
- Contract revision: `spec-2`
- Authority: user-authorized `WEBSITE-001` and `WEBSITE-PUBLISH-001` on 2026-08-19
- Stability: evolving, unreleased
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

## Choose the governing child

- [Experience and Content](website/experience-and-content.md) — audience,
  narrative, examples, visual system, claims, and accessibility.
- [Delivery and Acceptance](website/delivery-and-acceptance.md) — source/build
  boundaries, DigitalOcean deployment, metadata, interactions, and QA.
