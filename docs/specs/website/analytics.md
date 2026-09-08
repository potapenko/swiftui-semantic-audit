# Website analytics

- Node type: leaf
- Status: Active
- Contract revision: `spec-1`
- Authority: user-approved `WEBSITE-ANALYTICS-001`, 2026-09-08; combined epoch `tz-v31`.
- Read when: implementing or verifying website analytics.
- Requires: [Delivery and Acceptance](delivery-and-acceptance.md), `WEB-TECH-001`, `WEB-BUILD-001`, `WEB-INTERACT-001`, `WEB-DO-001`, `WEB-QA-001`, `WEB-QA-003`.

## Contract delta

`WEB-DELTA-015` (Evolve) supersedes only the previous exclusion of analytics.
The user approved one GA4 property and Web stream for the current site,
production-only Google tag integration, focused checks, a checkpoint on master,
and publication including the 12 already-local commits. CLI, rules, releases,
layout, navigation, copy feedback, and build allowlist stay protected. Content changes only to remove the obsolete footer claim `No analytics`.

**WEB-GA-001.** The property is `SwiftUI Semantic Audit`, reporting country
Montenegro and currency EUR. The Web stream is `SwiftUI Audit Website` for
`https://swiftui-audit.dev`, stream ID `15740007709`, measurement ID
`G-P4CWE2XWMB`. Enhanced measurement is off; collect standard page views and
GA4's associated automatic session/engagement events, without custom events,
Google Signals, or advertising personalization.

**WEB-GA-002.** Load the asynchronous Google tag only when the actual origin is
`https://swiftui-audit.dev`. Local previews, technical ingress, and other origins
must neither load the tag nor queue analytics. Initialize the configured ID
once per document; the config command sends the page view without a duplicate
manual event. A blocked or unavailable Google tag must not prevent navigation,
copy controls, or access to content. The measurement ID is public configuration.

**WEB-GA-003.** Acceptance covers the built public configuration, production
initialization, excluded origins, and blocked-tag usability. Run the focused
website/build checks and JavaScript syntax validation. After deployment, verify
the exact public build and observe the site's page view in GA4 Realtime or
DebugView. A network request alone is not receipt of data in the property.

## Publication

On 2026-09-08, source checkpoint `783d2f9` added GA4; `88155d6` removed the
obsolete footer claim. DigitalOcean deployment
`365c1ac9-00c7-4896-941b-011a68af3444` reached ACTIVE for
`88155d618123932167bfdacd01e1c63a19191684` on the canonical domain.
The 22 focused build/publisher checks passed; the footer correction passed the
10 website checks. Syntax, changed-spec links/size, and diff checks passed.
Public verification covered exact build markers, metadata routes, 404, GA4 ID,
and origin guard. The Codex browser observed the final marker, exactly one
Google tag, no obsolete claim, no console errors/warnings, and working copy
feedback. The hosted website job passed for the initial analytics checkpoint.

GA4 Realtime/DebugView ingestion remains unverified: Safari interaction was
interrupted by tab changes/closure. The operator was asked to release Safari
for the final check. Resume by selecting the existing `SwiftUI Semantic Audit`
property and Web stream above; do not create another property. A real canonical
page visit has already been made. This residual prevents claiming end-to-end
GA4 acceptance; the public installation itself is verified.
