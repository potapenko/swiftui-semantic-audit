# Website

This directory is the source boundary for the English SwiftUI Semantic Audit
landing page. The production artifact is generated into a separate empty
directory; DigitalOcean serves only that artifact.

## Source layout

- `index.html` contains the semantic page, metadata, and build placeholders.
- `styles.css` owns the single art-directed theme and responsive layout.
- `script.js` adds the mobile navigation and copy buttons. All product content
  remains readable when JavaScript is unavailable.
- `assets/site-icon.svg` and `assets/social-preview.png` are the site metadata
  images.
- `assets/icons/` contains the local Tabler icon subset used by the page.
- `build_site.py` creates and validates the publishable artifact.

The source HTML uses two required placeholders:

- `{{SITE_URL}}` becomes a normalized absolute base URL ending in `/`.
- `{{BUILD_MARKER}}` becomes the deployment marker checked after publication.

Do not serve `index.html` directly in production. The builder must resolve both
placeholders first.

## Build and preview

Choose a new empty output directory, then run the builder from `website/`:

```sh
python3 build_site.py \
  --output-dir <empty-dir> \
  --site-url https://example.invalid/ \
  --build-marker local-preview
```

Preview the generated artifact, not the source directory:

```sh
python3 -m http.server 4173 --directory <output-dir>
```

The generated artifact has an exact allowlist. Source scripts, tests, QA
material, and this README are not published. The committed `public/` path, when
used by the hosting build, must start empty.

## Verification

From the repository root:

```sh
python3 -m unittest \
  website/build_site_test.py \
  scripts/release/publish_digitalocean_test.py
node --check website/script.js
git diff --check
```

The page must remain usable without JavaScript and from 320 CSS pixels upward.
Check keyboard focus, heading order, code overflow, reduced motion, and contrast
before publication.

## DigitalOcean publication

Inspect the deployment plan without changing external state:

```sh
scripts/release/publish_digitalocean.py --dry-run
```

A live deployment is an operator-approved action:

```sh
scripts/release/publish_digitalocean.py [--url https://authorized-domain/]
```

The publisher validates the committed App Platform spec, creates the uniquely
named app on its first run or updates the one existing match, waits within a
bounded deadline, and verifies the technical DigitalOcean ingress before an
optional public URL. Duplicate app names fail closed. Authentication comes from
the operator's local `doctl` session; no DigitalOcean token belongs in the
repository.

App Platform watches `master` directly through `deploy_on_push: true`; GitHub
Actions remains build/test CI and does not need a DigitalOcean token. The first
deployment intentionally uses the technical `ondigitalocean.app` hostname. The
canonical apex and `www` redirect are added only after that hostname passes and
`swiftui-audit.dev` has authoritative registry and DNS delegation.

The accepted technical ingress is
<https://swiftui-semantic-audit-nuhky.ondigitalocean.app/>. It is diagnostic and
noncanonical after the final domain cutover; until then its generated metadata
uses the same technical base URL so every published absolute URL remains valid.

## Content evidence

The large duplicate-owner example and protected transaction come from accepted
fixtures. The compact command Binding, model tunnel, and derived-state stories
use accepted fixture shapes and label editorial remediation where behavior
tests are still required. Product claims stay within release `0.4.0`: the CLI
does not rewrite source, call a model provider, replace behavior tests, or turn
candidate findings into automatic decisions.
