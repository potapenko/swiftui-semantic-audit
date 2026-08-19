#!/usr/bin/env python3
"""Build the English static landing page into a bounded public directory."""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.parse
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from typing import Any, Iterable, Sequence


SITE_URL_TOKEN = "{{SITE_URL}}"
BUILD_MARKER_TOKEN = "{{BUILD_MARKER}}"
SOCIAL_PREVIEW = Path("assets/social-preview.png")
SOCIAL_PREVIEW_DIMENSIONS = (1200, 630)
SITE_ICON = Path("assets/site-icon.svg")
ROOT_FILES = (Path("index.html"), Path("styles.css"), Path("script.js"))
ICON_FILES = (
    "LICENSE-tabler.txt",
    "alert-triangle.svg",
    "arrow-right.svg",
    "arrows-exchange.svg",
    "book-2.svg",
    "brand-github.svg",
    "brand-twitter.svg",
    "check.svg",
    "copy.svg",
    "cube.svg",
    "external-link.svg",
    "hierarchy-2.svg",
    "info-circle.svg",
    "leaf.svg",
    "link.svg",
    "lock.svg",
    "menu-2.svg",
    "pencil.svg",
    "scale.svg",
    "shield-check.svg",
    "terminal-2.svg",
    "user.svg",
    "x.svg",
)
ASSET_FILES = (
    SITE_ICON,
    SOCIAL_PREVIEW,
    *(Path("assets/icons") / name for name in ICON_FILES),
)
PUBLIC_SOURCE_FILES = (*ROOT_FILES, *ASSET_FILES)
GENERATED_FILES = (Path("robots.txt"), Path("sitemap.xml"))
MARKER_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}\Z")


class SiteBuildError(RuntimeError):
    """Raised when the public artifact cannot be built safely."""


class MetadataProbe(HTMLParser):
    """Collect the small metadata surface the builder guarantees."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.html_attributes: dict[str, str] = {}
        self.links: list[dict[str, str]] = []
        self.metadata: list[dict[str, str]] = []
        self.title_parts: list[str] = []
        self.json_ld_parts: list[str] = []
        self._in_title = False
        self._in_json_ld = False

    def handle_starttag(
        self, tag: str, attributes: list[tuple[str, str | None]]
    ) -> None:
        attrs = {name: value or "" for name, value in attributes}
        if tag == "html":
            self.html_attributes = attrs
        elif tag == "link":
            self.links.append(attrs)
        elif tag == "meta":
            self.metadata.append(attrs)
        elif tag == "title":
            self._in_title = True
        elif tag == "script" and attrs.get("type", "").lower() == "application/ld+json":
            self._in_json_ld = True

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self._in_title = False
        elif tag == "script" and self._in_json_ld:
            self._in_json_ld = False

    def handle_data(self, data: str) -> None:
        if self._in_title:
            self.title_parts.append(data)
        if self._in_json_ld:
            self.json_ld_parts.append(data)


def normalized_site_url(value: str) -> str:
    candidate = value.strip()
    parts = urllib.parse.urlsplit(candidate)
    if parts.scheme != "https" or not parts.hostname:
        raise SiteBuildError("site URL must be an absolute HTTPS URL")
    if parts.username or parts.password or parts.query or parts.fragment:
        raise SiteBuildError("site URL must not contain credentials, a query, or a fragment")
    if parts.path not in ("", "/"):
        raise SiteBuildError("site URL must identify the site root")
    try:
        port = parts.port
    except ValueError as error:
        raise SiteBuildError(f"site URL has an invalid port: {error}") from error
    authority = parts.hostname
    if ":" in authority and not authority.startswith("["):
        authority = f"[{authority}]"
    if port is not None:
        authority = f"{authority}:{port}"
    return f"https://{authority}/"


def validated_build_marker(value: str) -> str:
    marker = value.strip()
    if not MARKER_PATTERN.fullmatch(marker):
        raise SiteBuildError(
            "build marker must be 1-128 letters, digits, dots, underscores, or hyphens"
        )
    return marker


def ensure_regular_source(source_root: Path, relative: Path) -> Path:
    if relative.is_absolute() or ".." in relative.parts:
        raise SiteBuildError(f"unsafe public source path: {relative}")
    current = source_root
    for component in relative.parts:
        current = current / component
        if current.is_symlink():
            raise SiteBuildError(f"public source must not be a symlink: {relative}")
    if not current.is_file():
        raise SiteBuildError(f"public source is missing or not a file: {relative}")
    try:
        current.resolve(strict=True).relative_to(source_root.resolve(strict=True))
    except (OSError, ValueError) as error:
        raise SiteBuildError(f"public source escapes the website directory: {relative}") from error
    return current


def validate_source_tree(source_root: Path) -> dict[Path, Path]:
    if source_root.is_symlink() or not source_root.is_dir():
        raise SiteBuildError(f"website source must be a real directory: {source_root}")

    sources = {
        relative: ensure_regular_source(source_root, relative)
        for relative in PUBLIC_SOURCE_FILES
    }
    assets_root = source_root / "assets"
    actual_assets: set[Path] = set()
    for candidate in assets_root.rglob("*"):
        relative = candidate.relative_to(source_root)
        if candidate.is_symlink():
            raise SiteBuildError(f"website assets must not contain symlinks: {relative}")
        if candidate.is_file():
            actual_assets.add(relative)
    expected_assets = set(ASSET_FILES)
    if actual_assets != expected_assets:
        missing = sorted(str(path) for path in expected_assets - actual_assets)
        unexpected = sorted(str(path) for path in actual_assets - expected_assets)
        details: list[str] = []
        if missing:
            details.append(f"missing {missing!r}")
        if unexpected:
            details.append(f"unexpected {unexpected!r}")
        raise SiteBuildError("asset allowlist mismatch: " + "; ".join(details))
    return sources


def prepare_output_directory(output_dir: Path, source_root: Path) -> Path:
    if output_dir.is_symlink():
        raise SiteBuildError(f"output directory must not be a symlink: {output_dir}")
    if output_dir.exists():
        if not output_dir.is_dir():
            raise SiteBuildError(f"output path is not a directory: {output_dir}")
        if any(output_dir.iterdir()):
            raise SiteBuildError(f"output directory must be empty: {output_dir}")

    resolved = output_dir.resolve(strict=False)
    source = source_root.resolve(strict=True)
    if resolved == source:
        raise SiteBuildError("output directory must not replace the website source")
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def read_png_dimensions(path: Path) -> tuple[int, int]:
    try:
        with path.open("rb") as image_file:
            header = image_file.read(24)
    except OSError as error:
        raise SiteBuildError(f"could not read PNG {path}: {error}") from error
    if (
        len(header) != 24
        or header[:8] != b"\x89PNG\r\n\x1a\n"
        or header[12:16] != b"IHDR"
    ):
        raise SiteBuildError(f"social preview must be a PNG: {path}")
    return int.from_bytes(header[16:20], "big"), int.from_bytes(header[20:24], "big")


def validate_svg(path: Path) -> None:
    try:
        root = ET.fromstring(path.read_bytes())
    except (OSError, ET.ParseError) as error:
        raise SiteBuildError(f"invalid SVG asset {path}: {error}") from error
    if root.tag.rsplit("}", 1)[-1] != "svg":
        raise SiteBuildError(f"SVG asset has no svg root element: {path}")
    for element in root.iter():
        if element.tag.rsplit("}", 1)[-1].lower() == "script":
            raise SiteBuildError(f"SVG asset contains a script element: {path}")


def metadata_value(metadata: Iterable[dict[str, str]], key: str) -> str:
    values = [
        item.get("content", "").strip()
        for item in metadata
        if item.get("name") == key or item.get("property") == key
    ]
    if len(values) != 1 or not values[0]:
        raise SiteBuildError(f"HTML must contain exactly one nonempty {key!r} metadata value")
    return values[0]


def json_ld_nodes(value: Any) -> Iterable[dict[str, Any]]:
    if isinstance(value, list):
        for item in value:
            yield from json_ld_nodes(item)
    elif isinstance(value, dict):
        yield value
        graph = value.get("@graph")
        if isinstance(graph, list):
            for item in graph:
                yield from json_ld_nodes(item)


def validate_html(rendered: str, *, site_url: str, build_marker: str) -> None:
    if SITE_URL_TOKEN in rendered or BUILD_MARKER_TOKEN in rendered:
        raise SiteBuildError("unresolved website build token remains in index.html")
    probe = MetadataProbe()
    try:
        probe.feed(rendered)
        probe.close()
    except Exception as error:
        raise SiteBuildError(f"could not parse index.html: {error}") from error

    if probe.html_attributes.get("lang") != "en":
        raise SiteBuildError("index.html must declare lang=\"en\"")
    if probe.html_attributes.get("data-site-build") != build_marker:
        raise SiteBuildError("index.html has no exact deployment build marker")
    if not "".join(probe.title_parts).strip():
        raise SiteBuildError("index.html must contain a nonempty title")

    metadata_value(probe.metadata, "description")
    robots = metadata_value(probe.metadata, "robots")
    theme_color = metadata_value(probe.metadata, "theme-color")
    if "index" not in robots or "follow" not in robots:
        raise SiteBuildError("robots metadata must allow indexing and following")
    if not re.fullmatch(r"#[0-9A-Fa-f]{6}", theme_color):
        raise SiteBuildError("theme-color must be a six-digit hexadecimal color")

    link_by_relation: dict[str, list[dict[str, str]]] = {}
    for link in probe.links:
        for relation in link.get("rel", "").lower().split():
            link_by_relation.setdefault(relation, []).append(link)
    canonicals = link_by_relation.get("canonical", [])
    if len(canonicals) != 1 or canonicals[0].get("href") != site_url:
        raise SiteBuildError("index.html must contain one canonical link for the built site URL")
    icons = link_by_relation.get("icon", [])
    if not any(
        icon.get("href") == SITE_ICON.as_posix()
        and icon.get("type") == "image/svg+xml"
        for icon in icons
    ):
        raise SiteBuildError("index.html must reference the allowlisted SVG site icon")

    expected_social_url = urllib.parse.urljoin(site_url, SOCIAL_PREVIEW.as_posix())
    required_metadata = {
        "og:title": None,
        "og:description": None,
        "og:type": "website",
        "og:url": site_url,
        "og:image": expected_social_url,
        "og:image:type": "image/png",
        "og:image:width": str(SOCIAL_PREVIEW_DIMENSIONS[0]),
        "og:image:height": str(SOCIAL_PREVIEW_DIMENSIONS[1]),
        "og:image:alt": None,
        "twitter:card": "summary_large_image",
        "twitter:title": None,
        "twitter:description": None,
        "twitter:image": expected_social_url,
        "twitter:image:alt": None,
    }
    for key, expected in required_metadata.items():
        value = metadata_value(probe.metadata, key)
        if expected is not None and value != expected:
            raise SiteBuildError(f"metadata {key!r} must be {expected!r}")

    json_ld_text = "".join(probe.json_ld_parts).strip()
    if not json_ld_text:
        raise SiteBuildError("index.html must contain SoftwareApplication JSON-LD")
    try:
        structured_data = json.loads(json_ld_text)
    except json.JSONDecodeError as error:
        raise SiteBuildError(f"invalid JSON-LD: {error}") from error
    applications = [
        node
        for node in json_ld_nodes(structured_data)
        if node.get("@type") == "SoftwareApplication"
        or (
            isinstance(node.get("@type"), list)
            and "SoftwareApplication" in node["@type"]
        )
    ]
    if len(applications) != 1:
        raise SiteBuildError("JSON-LD must contain exactly one SoftwareApplication node")
    application = applications[0]
    for key in ("name", "description", "applicationCategory", "operatingSystem"):
        if not isinstance(application.get(key), str) or not application[key].strip():
            raise SiteBuildError(f"SoftwareApplication JSON-LD must define {key}")
    if application.get("url") != site_url:
        raise SiteBuildError("SoftwareApplication JSON-LD URL must match the canonical URL")


def render_index(source: str, *, site_url: str, build_marker: str) -> str:
    if SITE_URL_TOKEN not in source:
        raise SiteBuildError(f"index.html must contain {SITE_URL_TOKEN}")
    expected_marker = f'data-site-build="{BUILD_MARKER_TOKEN}"'
    if source.count(expected_marker) != 1:
        raise SiteBuildError(f"index.html must contain exactly one {expected_marker}")
    rendered = source.replace(SITE_URL_TOKEN, site_url).replace(
        BUILD_MARKER_TOKEN, build_marker
    )
    validate_html(rendered, site_url=site_url, build_marker=build_marker)
    return rendered


def sitemap(site_url: str) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        "  <url>\n"
        f"    <loc>{site_url}</loc>\n"
        "  </url>\n"
        "</urlset>\n"
    )


def robots(site_url: str) -> str:
    return f"User-agent: *\nAllow: /\nSitemap: {site_url}sitemap.xml\n"


def build_site(
    source_root: Path,
    output_dir: Path,
    *,
    site_url: str,
    build_marker: str,
) -> tuple[Path, ...]:
    source_root = source_root.absolute()
    site_url = normalized_site_url(site_url)
    build_marker = validated_build_marker(build_marker)
    sources = validate_source_tree(source_root)

    if read_png_dimensions(sources[SOCIAL_PREVIEW]) != SOCIAL_PREVIEW_DIMENSIONS:
        raise SiteBuildError(
            f"social preview must be {SOCIAL_PREVIEW_DIMENSIONS[0]} by "
            f"{SOCIAL_PREVIEW_DIMENSIONS[1]} pixels"
        )
    for relative in ASSET_FILES:
        if relative.suffix == ".svg":
            validate_svg(sources[relative])

    try:
        index_source = sources[Path("index.html")].read_text(encoding="utf-8")
        rendered_index = render_index(
            index_source, site_url=site_url, build_marker=build_marker
        )
        payloads = {
            relative: sources[relative].read_bytes()
            for relative in PUBLIC_SOURCE_FILES
            if relative != Path("index.html")
        }
    except (OSError, UnicodeError) as error:
        raise SiteBuildError(f"could not read website source: {error}") from error

    output_dir = prepare_output_directory(output_dir.absolute(), source_root)
    rendered_payloads = {
        Path("index.html"): rendered_index.encode("utf-8"),
        **payloads,
        Path("robots.txt"): robots(site_url).encode("utf-8"),
        Path("sitemap.xml"): sitemap(site_url).encode("utf-8"),
    }
    for relative in sorted(rendered_payloads, key=lambda path: path.as_posix()):
        destination = output_dir / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(rendered_payloads[relative])
    return tuple(sorted(rendered_payloads, key=lambda path: path.as_posix()))


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--source-dir",
        type=Path,
        default=Path(__file__).resolve().parent,
        help="website source directory (defaults to this script's directory)",
    )
    result.add_argument("--output-dir", type=Path, required=True)
    result.add_argument("--site-url", required=True)
    result.add_argument("--build-marker", required=True)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parser().parse_args(argv)
    built = build_site(
        arguments.source_dir,
        arguments.output_dir,
        site_url=arguments.site_url,
        build_marker=arguments.build_marker,
    )
    print(f"Built {len(built)} public files in {arguments.output_dir}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SiteBuildError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
