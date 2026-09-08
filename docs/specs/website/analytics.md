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

Pending deployment and live GA4 receipt; a local checkpoint alone is not public acceptance.
