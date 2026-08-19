# Website Delivery and Acceptance

- Node type: leaf
- Status: Active
- Contract revision: `spec-2`
- Authority: [Website contract](../website.md)
- Maximum size: 100 physical lines.

## Source and build boundary

**WEB-TECH-001.** Keep the site under `website/` as semantic HTML, one CSS file,
minimal vanilla JavaScript, local assets, and a Python-standard-library builder.
Do not add a frontend framework, package manager, localization layer, backend,
analytics, cookie layer, or runtime external font dependency.

**WEB-BUILD-001.** Generate only the explicit public allowlist into an empty
`website/public/` boundary. Reject symlinked or unsafe sources and nonempty
outputs. Generate `robots.txt` and `sitemap.xml`; exclude source documentation,
tests, QA references, and build scripts. Repeated builds are byte-equivalent.

**WEB-ASSET-001.** Use real selected-design assets and a consistent third-party
icon family rather than CSS drawings, emoji, handcrafted SVG art, or placeholder
imagery. Publish an accessible site icon and a 1200 by 630 social preview.

## Interaction and metadata

**WEB-INTERACT-001.** JavaScript may enhance copy buttons and the responsive
navigation. Copy controls report success without replacing the visible command;
the page remains complete and navigable when scripts fail or are disabled.

**WEB-META-001.** Emit one canonical URL, English language metadata, title and
description, Open Graph/X metadata, social preview dimensions, JSON-LD software
application data, theme color, robots, and sitemap. Technical bootstrap uses
the validated App Platform base URL. After the authorized primary domain is
active, builds use `https://swiftui-audit.dev/` for canonical and public metadata.

## DigitalOcean delivery

**WEB-DO-001.** Deploy one App Platform static-site component from repository
branch `master`, source `website`, and generated output `public`, with deployment
and domain failure alerts. Bootstrap without domains and verify the technical
ingress first. Once authoritative registration exists, attach
`swiftui-audit.dev` as PRIMARY, attach `www.swiftui-audit.dev` as ALIAS, and use
top-level ingress for a permanent `www`-to-apex redirect plus component routing.
Do not use deprecated component routes/CORS or a SPA catchall.

**WEB-DO-002.** A bounded publisher validates the committed App Spec with the
authenticated local `doctl` context. It creates the uniquely named app when
absent, updates the one existing match with the latest source, and rejects
duplicate names. It waits for terminal deployment, verifies the technical
hostname first, optionally verifies a public URL, cache-busts by deployment ID,
and applies one overall deadline plus bounded HTTP attempts. It must not contain
or print a token.

## Acceptance

**WEB-QA-001.** Automated acceptance covers safe deterministic build, exact
allowlist, metadata, internal links and anchors, copy-control hooks, no-JavaScript
content, App Spec shape, publisher dry-run/selection behavior, and forbidden
marketing claims. CI runs these checks without publishing.

**WEB-QA-002.** Visual acceptance compares the selected ImageGen target with the
rendered page at the same desktop viewport and also checks 1024, 768, 390, and
320 CSS pixels. Verify fonts, hierarchy, spacing, tokens, code readability,
icons, focus, reduced motion, mobile navigation, copy feedback, and zoom/text
wrapping. The root `design-qa.md` must end in `final result: passed`.

**WEB-QA-003.** Deployment acceptance verifies the technical root,
`/robots.txt`, and `/sitemap.xml`, confirms the deployment marker, tests the
expected unknown-path response, and records the deployed commit. Domain/DNS
acceptance separately requires authoritative registration, only the intended
apex/`www` record changes, managed HTTPS, apex content and metadata, and a
permanent `www` redirect.

**WEB-REL-001.** The website remains unreleased until a DigitalOcean deployment
receipt exists. A checkpoint commit, local preview, or Active contract does not
authorize a public-domain claim. Public-domain readiness requires its separate
DNS/TLS verification receipt.
