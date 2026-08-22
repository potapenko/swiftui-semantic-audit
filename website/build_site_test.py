from __future__ import annotations

import binascii
import struct
import tempfile
import unittest
import zlib
from html.parser import HTMLParser
from pathlib import Path

from website import build_site


SITE_URL = "https://example.ondigitalocean.app/"
BUILD_MARKER = "0123456789abcdef"
INSTALL_GUIDE_URL = (
    "https://github.com/potapenko/swiftui-semantic-audit/"
    "blob/master/docs/getting-started/installation.md"
)
SETUP_PROMPT = (
    "Install SwiftUI Semantic Audit from this GitHub guide. Install Homebrew "
    "first if needed, then the CLI and all four agent skills:\n"
    f"{INSTALL_GUIDE_URL}"
)


def png(width: int, height: int) -> bytes:
    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + kind
            + payload
            + struct.pack(">I", binascii.crc32(kind + payload) & 0xFFFFFFFF)
        )

    rows = b"".join(b"\x00" + b"\x00\x00\x00" * width for _ in range(height))
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(rows, level=9))
        + chunk(b"IEND", b"")
    )


def fixture_index() -> str:
    return """<!doctype html>
<html lang="en" data-site-build="{{BUILD_MARKER}}">
<head>
  <meta charset="utf-8">
  <meta name="description" content="Deterministic SwiftUI architecture evidence for coding agents.">
  <meta name="robots" content="index,follow">
  <meta name="theme-color" content="#08121F">
  <title>SwiftUI Semantic Audit</title>
  <link rel="canonical" href="{{SITE_URL}}">
  <link rel="icon" href="assets/site-icon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="styles.css">
  <meta property="og:title" content="SwiftUI Semantic Audit">
  <meta property="og:description" content="Deterministic SwiftUI architecture evidence for coding agents.">
  <meta property="og:type" content="website">
  <meta property="og:url" content="{{SITE_URL}}">
  <meta property="og:image" content="{{SITE_URL}}assets/social-preview.png">
  <meta property="og:image:type" content="image/png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="SwiftUI ownership evidence diagram">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="SwiftUI Semantic Audit">
  <meta name="twitter:description" content="Deterministic SwiftUI architecture evidence for coding agents.">
  <meta name="twitter:image" content="{{SITE_URL}}assets/social-preview.png">
  <meta name="twitter:image:alt" content="SwiftUI ownership evidence diagram">
  <script type="application/ld+json">{
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    "name": "SwiftUI Semantic Audit",
    "description": "Deterministic SwiftUI architecture evidence for coding agents.",
    "applicationCategory": "DeveloperApplication",
    "operatingSystem": "macOS",
    "url": "{{SITE_URL}}"
  }</script>
</head>
<body><main id="main"><h1>SwiftUI Semantic Audit</h1></main><script src="script.js"></script></body>
</html>
"""


def create_source(root: Path) -> None:
    (root / "index.html").write_text(fixture_index(), encoding="utf-8")
    (root / "styles.css").write_text("body { color: #08121f; }\n", encoding="utf-8")
    (root / "script.js").write_text("document.documentElement.classList.add('js');\n", encoding="utf-8")
    (root / "assets/icons").mkdir(parents=True)
    svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '<path d="M2 12h20"/></svg>\n'
    )
    (root / build_site.SITE_ICON).write_text(svg, encoding="utf-8")
    (root / build_site.SOCIAL_PREVIEW).write_bytes(png(1200, 630))
    for name in build_site.ICON_FILES:
        (root / "assets/icons" / name).write_text(svg, encoding="utf-8")


def tree_payload(root: Path) -> dict[str, bytes]:
    return {
        path.relative_to(root).as_posix(): path.read_bytes()
        for path in root.rglob("*")
        if path.is_file()
    }


class ProductionPageProbe(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.references: list[str] = []
        self.copy_controls: list[tuple[str, str]] = []

    def handle_starttag(
        self, tag: str, attributes: list[tuple[str, str | None]]
    ) -> None:
        attrs = {name: value or "" for name, value in attributes}
        if element_id := attrs.get("id"):
            self.ids.append(element_id)
        for name in ("href", "src"):
            if reference := attrs.get(name):
                self.references.append(reference)
        if target := attrs.get("data-copy-target"):
            self.copy_controls.append((target, attrs.get("aria-describedby", "")))


class BuildSiteTests(unittest.TestCase):
    def test_builds_exact_deterministic_allowlist(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "website"
            source.mkdir()
            create_source(source)
            first = root / "first"
            second = root / "second"

            built = build_site.build_site(
                source,
                first,
                site_url=SITE_URL,
                build_marker=BUILD_MARKER,
            )
            build_site.build_site(
                source,
                second,
                site_url=SITE_URL,
                build_marker=BUILD_MARKER,
            )

            expected = {
                *(path.as_posix() for path in build_site.PUBLIC_SOURCE_FILES),
                *(path.as_posix() for path in build_site.GENERATED_FILES),
            }
            self.assertEqual({path.as_posix() for path in built}, expected)
            self.assertEqual(tree_payload(first), tree_payload(second))
            rendered = (first / "index.html").read_text(encoding="utf-8")
            self.assertIn(f'data-site-build="{BUILD_MARKER}"', rendered)
            self.assertNotIn("{{", rendered)
            self.assertEqual(
                (first / "robots.txt").read_text(encoding="utf-8"),
                "User-agent: *\nAllow: /\n"
                f"Sitemap: {SITE_URL}sitemap.xml\n",
            )
            self.assertIn(f"<loc>{SITE_URL}</loc>", (first / "sitemap.xml").read_text())
            self.assertFalse((first / "build_site.py").exists())

    def test_rejects_nonempty_output(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "website"
            source.mkdir()
            create_source(source)
            output = root / "public"
            output.mkdir()
            (output / "stale.txt").write_text("stale", encoding="utf-8")

            with self.assertRaisesRegex(build_site.SiteBuildError, "must be empty"):
                build_site.build_site(
                    source,
                    output,
                    site_url=SITE_URL,
                    build_marker=BUILD_MARKER,
                )

    def test_rejects_symlinked_public_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "website"
            source.mkdir()
            create_source(source)
            real_script = root / "real-script.js"
            real_script.write_text("", encoding="utf-8")
            (source / "script.js").unlink()
            (source / "script.js").symlink_to(real_script)

            with self.assertRaisesRegex(build_site.SiteBuildError, "symlink"):
                build_site.build_site(
                    source,
                    root / "public",
                    site_url=SITE_URL,
                    build_marker=BUILD_MARKER,
                )

    def test_rejects_assets_outside_the_allowlist(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "website"
            source.mkdir()
            create_source(source)
            (source / "assets/draft.png").write_bytes(b"draft")

            with self.assertRaisesRegex(build_site.SiteBuildError, "unexpected"):
                build_site.build_site(
                    source,
                    root / "public",
                    site_url=SITE_URL,
                    build_marker=BUILD_MARKER,
                )


class ProductionPageContractTests(unittest.TestCase):
    def test_internal_links_assets_copy_hooks_and_claims(self) -> None:
        source_root = Path(__file__).resolve().parent
        source = (source_root / "index.html").read_text(encoding="utf-8")
        probe = ProductionPageProbe()
        probe.feed(source)
        probe.close()

        duplicates = sorted(
            element_id for element_id in set(probe.ids) if probe.ids.count(element_id) > 1
        )
        self.assertEqual(duplicates, [])
        known_ids = set(probe.ids)
        for reference in probe.references:
            if reference.startswith("#"):
                self.assertIn(reference[1:], known_ids)
            elif reference.startswith(("http://", "https://", "{{")):
                continue
            else:
                local_path = reference.split("?", 1)[0].split("#", 1)[0]
                self.assertTrue(
                    (source_root / local_path).is_file(),
                    f"missing local page reference: {reference}",
                )

        self.assertEqual(
            probe.copy_controls,
            [("agent-setup-prompt", "agent-setup-status")],
        )
        for target, status in probe.copy_controls:
            self.assertIn(target, known_ids)
            self.assertIn(status, known_ids)

        self.assertIn('<main id="main-content">', source)
        self.assertIn('<section id="install"', source)
        install = source.split('<section id="install"', 1)[1].split("</section>", 1)[0]
        self.assertIn(
            '<h2 id="install-title">Install with one prompt</h2>',
            install,
        )
        self.assertNotIn('class="step-number"', install)
        self.assertIn(
            f'<pre id="agent-setup-prompt" tabindex="0"><code>{SETUP_PROMPT}</code></pre>',
            install,
        )
        self.assertIn(
            '<pre id="install-cli-command" tabindex="0"><code>'
            "brew install potapenko/tap/swiftui-semantic-audit</code></pre>",
            install,
        )
        self.assertIn('<h3 id="install-cli-title">CLI only</h3>', install)
        self.assertIn(f'href="{INSTALL_GUIDE_URL}"', install)
        self.assertNotIn('class="install-next"', install)
        self.assertNotIn("189dc44c928f7f61b393f6e4ca7d8f6f5d183a48", source)
        self.assertIn("One skill to invoke", source)
        self.assertIn("Which skill should I use?", source)
        self.assertNotIn("$swiftui-semantic-audit", source)
        self.assertNotIn("$swiftui-dataflow-refactor", source)
        self.assertNotIn("$swiftui-change-review", source)
        self.assertIn('href="https://x.com/potapenko"', source)
        self.assertIn('aria-label="Follow @potapenko on Twitter"', source)
        self.assertIn('src="assets/icons/brand-twitter.svg"', source)

        rules = source.split('<section id="rules"', 1)[1].split("</section>", 1)[0]
        self.assertEqual(rules.count("<li><code>"), 29)

        lowered = source.lower()
        for forbidden in (
            "automatically rewrites project source",
            "guaranteed correctness",
            "zero configuration",
            "finds every swiftui bug",
            "replaces builds and tests",
            "fully deterministic recommendations",
        ):
            self.assertNotIn(forbidden, lowered)

    def test_rejects_invalid_site_url_and_marker(self) -> None:
        with self.assertRaisesRegex(build_site.SiteBuildError, "absolute HTTPS"):
            build_site.normalized_site_url("http://example.com/")
        with self.assertRaisesRegex(build_site.SiteBuildError, "site root"):
            build_site.normalized_site_url("https://example.com/subpath")
        with self.assertRaisesRegex(build_site.SiteBuildError, "build marker"):
            build_site.validated_build_marker('bad" marker')

    def test_rejects_incorrect_social_preview_dimensions(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "website"
            source.mkdir()
            create_source(source)
            (source / build_site.SOCIAL_PREVIEW).write_bytes(png(600, 315))

            with self.assertRaisesRegex(build_site.SiteBuildError, "1200 by 630"):
                build_site.build_site(
                    source,
                    root / "public",
                    site_url=SITE_URL,
                    build_marker=BUILD_MARKER,
                )

    def test_rejects_missing_required_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "website"
            source.mkdir()
            create_source(source)
            index = source / "index.html"
            index.write_text(
                index.read_text(encoding="utf-8").replace(
                    '<meta name="theme-color" content="#08121F">\n', ""
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(build_site.SiteBuildError, "theme-color"):
                build_site.build_site(
                    source,
                    root / "public",
                    site_url=SITE_URL,
                    build_marker=BUILD_MARKER,
                )


if __name__ == "__main__":
    unittest.main()
