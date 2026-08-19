#!/usr/bin/env python3
"""Apply the DigitalOcean App Spec and verify the deployed static site."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Sequence
from pathlib import Path
from typing import Any


DEFAULT_APP_NAME = "swiftui-semantic-audit"
DEFAULT_COMPONENT_NAME = "landing"
REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_APP_SPEC = REPOSITORY_ROOT / ".do/app.yaml"
MAX_RESPONSE_BYTES = 2 * 1024 * 1024
MISSING_PATH = "__swiftui_semantic_audit_missing__"
TOKEN_ENVIRONMENT_NAMES = (
    "DIGITALOCEAN_ACCESS_TOKEN",
    "DIGITALOCEAN_TOKEN",
    "DO_API_TOKEN",
)
TOKEN_PATTERN = re.compile(r"\bdop_v1_[A-Za-z0-9_-]+")
COMMIT_PATTERN = re.compile(r"[0-9a-fA-F]{7,64}\Z")


class PublishError(RuntimeError):
    """Raised when deployment or verification cannot complete safely."""


def redact(value: str) -> str:
    result = TOKEN_PATTERN.sub("<redacted-token>", value)
    for name in TOKEN_ENVIRONMENT_NAMES:
        token = os.environ.get(name)
        if token:
            result = result.replace(token, "<redacted-token>")
    return result


def parse_json(text: str, *, command: Sequence[str]) -> Any:
    try:
        return json.loads(text)
    except json.JSONDecodeError as error:
        rendered = " ".join(command)
        raise PublishError(f"{rendered} returned invalid JSON: {error}") from error


def objects(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        for key in ("apps", "items"):
            value = payload.get(key)
            if isinstance(value, list):
                return [item for item in value if isinstance(item, dict)]
        return [payload]
    return []


def app_object(payload: Any) -> dict[str, Any]:
    candidates = objects(payload)
    if not candidates:
        raise PublishError("DigitalOcean app response is empty")
    candidate = candidates[0]
    app = candidate.get("app", candidate)
    if not isinstance(app, dict):
        raise PublishError("DigitalOcean app response has an unexpected shape")
    return app


def find_optional_app_id(payload: Any, app_name: str) -> str | None:
    matches: list[str] = []
    for app in objects(payload):
        spec = app.get("spec")
        name = spec.get("name") if isinstance(spec, dict) else app.get("name")
        app_id = app.get("id")
        if name == app_name and isinstance(app_id, str) and app_id:
            matches.append(app_id)
    if len(matches) > 1:
        raise PublishError(f"DigitalOcean app name {app_name!r} is not unique")
    return matches[0] if matches else None


def find_app_id(payload: Any, app_name: str) -> str:
    app_id = find_optional_app_id(payload, app_name)
    if app_id is None:
        raise PublishError(f"DigitalOcean app {app_name!r} was not found")
    return app_id


def app_id_from_payload(payload: Any) -> str:
    app = app_object(payload)
    app_id = app.get("id")
    if not isinstance(app_id, str) or not app_id:
        raise PublishError("DigitalOcean app response has no ID")
    return app_id


def deployment_details(
    payload: Any, *, component_name: str = DEFAULT_COMPONENT_NAME
) -> tuple[str, str, str]:
    app = app_object(payload)
    deployment = app.get("active_deployment")
    if not isinstance(deployment, dict):
        deployment = app.get("deployment")
    if not isinstance(deployment, dict):
        raise PublishError("DigitalOcean app does not report an active deployment")

    deployment_id = deployment.get("id")
    phase = deployment.get("phase") or deployment.get("status")
    if not isinstance(deployment_id, str) or not deployment_id:
        raise PublishError("active deployment has no ID")
    if not isinstance(phase, str) or not phase:
        raise PublishError(f"deployment {deployment_id} has no phase")

    commit: str | None = None
    components = deployment.get("static_sites")
    if isinstance(components, list):
        for component in components:
            if not isinstance(component, dict):
                continue
            if component.get("name") == component_name:
                candidate = component.get("source_commit_hash")
                if isinstance(candidate, str):
                    commit = candidate
                    break
        if commit is None and len(components) == 1 and isinstance(components[0], dict):
            candidate = components[0].get("source_commit_hash")
            if isinstance(candidate, str):
                commit = candidate
    if commit is None:
        candidate = deployment.get("source_commit_hash")
        if isinstance(candidate, str):
            commit = candidate
    if commit is None or not COMMIT_PATTERN.fullmatch(commit):
        raise PublishError(
            f"deployment {deployment_id} has no valid source commit for {component_name!r}"
        )
    return deployment_id, phase.upper(), commit.lower()


def normalized_https_root(value: str, *, label: str) -> str:
    candidate = value.strip()
    if "://" not in candidate:
        candidate = f"https://{candidate}"
    parts = urllib.parse.urlsplit(candidate)
    if parts.scheme != "https" or not parts.hostname:
        raise PublishError(f"{label} must be an absolute HTTPS URL")
    if parts.username or parts.password or parts.query or parts.fragment:
        raise PublishError(f"{label} must not contain credentials, a query, or a fragment")
    if parts.path not in ("", "/"):
        raise PublishError(f"{label} must identify a site root")
    try:
        port = parts.port
    except ValueError as error:
        raise PublishError(f"{label} has an invalid port: {error}") from error
    authority = parts.hostname
    if ":" in authority and not authority.startswith("["):
        authority = f"[{authority}]"
    if port is not None:
        authority = f"{authority}:{port}"
    return f"https://{authority}/"


def default_ingress_url(payload: Any) -> str:
    app = app_object(payload)
    ingress = app.get("default_ingress")
    if isinstance(ingress, str) and ingress:
        value = ingress
    elif isinstance(ingress, dict):
        value = ingress.get("hostname") or ingress.get("domain")
    else:
        value = None
    if not isinstance(value, str) or not value:
        for key in ("live_url", "live_url_base"):
            fallback = app.get(key)
            if isinstance(fallback, str) and fallback:
                value = fallback
                break
    if not isinstance(value, str) or not value:
        raise PublishError("DigitalOcean app does not report a default ingress")
    return normalized_https_root(value, label="DigitalOcean default ingress")


def remaining(deadline: float) -> float:
    value = deadline - time.monotonic()
    if value <= 0:
        raise PublishError("DigitalOcean publish timed out")
    return value


def run_process(
    command: Sequence[str], *, timeout: float, expect_json: bool
) -> Any:
    try:
        result = subprocess.run(
            list(command),
            check=False,
            capture_output=True,
            text=True,
            timeout=max(1.0, timeout),
        )
    except subprocess.TimeoutExpired as error:
        raise PublishError(f"{' '.join(command)} timed out") from error
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "unknown error"
        raise PublishError(
            f"{' '.join(command)} failed: {redact(detail)}"
        )
    if not expect_json:
        return None
    return parse_json(result.stdout, command=command)


def run_doctl_json(doctl: str, arguments: Sequence[str], *, timeout: float) -> Any:
    return run_process(
        [doctl, *arguments, "--output", "json"],
        timeout=timeout,
        expect_json=True,
    )


def validate_app_spec(doctl: str, app_spec: Path, *, timeout: float) -> None:
    run_process(
        [doctl, "apps", "spec", "validate", str(app_spec)],
        timeout=timeout,
        expect_json=False,
    )


def cache_bust(url: str, deployment_id: str) -> str:
    parts = urllib.parse.urlsplit(url)
    query = urllib.parse.parse_qsl(parts.query, keep_blank_values=True)
    query.append(("deployment", deployment_id))
    return urllib.parse.urlunsplit(
        (parts.scheme, parts.netloc, parts.path, urllib.parse.urlencode(query), parts.fragment)
    )


def verification_targets(
    base_url: str, *, deployment_id: str, commit: str
) -> list[dict[str, Any]]:
    base = normalized_https_root(base_url, label="verification URL")
    definitions = (
        ("/", "", 200, (f'data-site-build="{commit}"', '<html lang="en"')),
        ("/robots.txt", "robots.txt", 200, ("User-agent: *", "Sitemap:")),
        ("/sitemap.xml", "sitemap.xml", 200, ("<urlset", "<loc>")),
        (f"/{MISSING_PATH}", MISSING_PATH, 404, ()),
    )
    return [
        {
            "label": label,
            "url": cache_bust(urllib.parse.urljoin(base, route), deployment_id),
            "status": status,
            "required": required,
        }
        for label, route, status, required in definitions
    ]


def fetch(url: str, *, timeout: float) -> tuple[int, bytes]:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "swiftui-semantic-audit-publish-verifier/1"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            status = response.getcode()
            body = response.read(MAX_RESPONSE_BYTES + 1)
    except urllib.error.HTTPError as error:
        status = error.code
        body = error.read(MAX_RESPONSE_BYTES + 1)
    if len(body) > MAX_RESPONSE_BYTES:
        raise PublishError(f"verification response is larger than {MAX_RESPONSE_BYTES} bytes")
    return status, body


def verify_target(
    target: dict[str, Any],
    *,
    deadline: float,
    request_timeout: float,
    attempts: int,
    retry_delay: float,
) -> None:
    last_error = "no response"
    for attempt in range(1, attempts + 1):
        try:
            status, body = fetch(
                target["url"], timeout=min(request_timeout, remaining(deadline))
            )
            missing = [
                marker
                for marker in target["required"]
                if marker.encode("utf-8") not in body
            ]
            if status == target["status"] and not missing:
                return
            details = [f"status {status}, expected {target['status']}"]
            if missing:
                details.append(f"missing {missing!r}")
            last_error = "; ".join(details)
        except (OSError, urllib.error.URLError, PublishError) as error:
            last_error = redact(str(error))
        if attempt == attempts:
            break
        wait = min(retry_delay, remaining(deadline))
        if wait > 0:
            time.sleep(wait)
    raise PublishError(
        f"verification failed for {target['label']} at {target['url']}: {last_error}"
    )


def verify_public_site(
    base_url: str,
    *,
    deployment_id: str,
    commit: str,
    deadline: float,
    request_timeout: float,
    attempts: int,
    retry_delay: float,
) -> None:
    for target in verification_targets(
        base_url, deployment_id=deployment_id, commit=commit
    ):
        print(f"Verifying {target['label']} at {target['url']}")
        verify_target(
            target,
            deadline=deadline,
            request_timeout=request_timeout,
            attempts=attempts,
            retry_delay=retry_delay,
        )


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--app-id", default=os.environ.get("DIGITALOCEAN_APP_ID"))
    result.add_argument("--app-name", default=DEFAULT_APP_NAME)
    result.add_argument("--component-name", default=DEFAULT_COMPONENT_NAME)
    result.add_argument("--spec", type=Path, default=DEFAULT_APP_SPEC)
    result.add_argument(
        "--url",
        help="optional public root URL to verify after the technical App Platform URL",
    )
    result.add_argument("--timeout", type=float, default=600.0)
    result.add_argument("--request-timeout", type=float, default=20.0)
    result.add_argument("--http-attempts", type=int, default=8)
    result.add_argument("--retry-delay", type=float, default=3.0)
    result.add_argument("--doctl", default="doctl")
    result.add_argument("--dry-run", action="store_true")
    return result


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parser().parse_args(argv)
    if (
        arguments.timeout <= 0
        or arguments.request_timeout <= 0
        or arguments.http_attempts <= 0
        or arguments.retry_delay < 0
    ):
        raise PublishError("timeouts and HTTP attempts must be positive")
    if arguments.url:
        normalized_https_root(arguments.url, label="public URL")

    app_spec = arguments.spec.absolute()
    if app_spec.is_symlink() or not app_spec.is_file():
        raise PublishError(f"DigitalOcean app spec not found or unsafe: {app_spec}")
    doctl = shutil.which(arguments.doctl)
    if not doctl:
        raise PublishError(f"{arguments.doctl!r} is not installed")

    if arguments.dry_run:
        print("DRY RUN:", doctl, "apps spec validate", app_spec)
        if arguments.app_id:
            print(
                "DRY RUN:",
                doctl,
                "apps update",
                arguments.app_id,
                "--spec",
                app_spec,
                "--update-sources --wait --output json",
            )
        else:
            print("DRY RUN:", doctl, "apps list --output json")
            print(
                "DRY RUN: if absent:",
                doctl,
                "apps create --spec",
                app_spec,
                "--wait --output json",
            )
            print(
                "DRY RUN: if uniquely present:",
                doctl,
                "apps update <app-id> --spec",
                app_spec,
                "--update-sources --wait --output json",
            )
            print("DRY RUN: duplicate app names fail")
        print("DRY RUN: verify technical ingress /, /robots.txt, /sitemap.xml, and 404")
        if arguments.url:
            print("DRY RUN: then verify public URL", arguments.url)
        return 0

    deadline = time.monotonic() + arguments.timeout
    print(f"Validating App Platform spec {app_spec}")
    validate_app_spec(doctl, app_spec, timeout=remaining(deadline))

    app_id = arguments.app_id
    if not app_id:
        apps = run_doctl_json(
            doctl, ["apps", "list"], timeout=remaining(deadline)
        )
        app_id = find_optional_app_id(apps, arguments.app_name)

    if app_id is None:
        print(f"Creating DigitalOcean app {arguments.app_name!r} from {app_spec}")
        created = run_doctl_json(
            doctl,
            ["apps", "create", "--spec", str(app_spec), "--wait"],
            timeout=remaining(deadline),
        )
        app_id = app_id_from_payload(created)
    else:
        print(f"Applying spec and latest source to DigitalOcean app {app_id}")
        run_doctl_json(
            doctl,
            [
                "apps",
                "update",
                app_id,
                "--spec",
                str(app_spec),
                "--update-sources",
                "--wait",
            ],
            timeout=remaining(deadline),
        )
    app = run_doctl_json(
        doctl, ["apps", "get", app_id], timeout=remaining(deadline)
    )
    deployment_id, phase, commit = deployment_details(
        app, component_name=arguments.component_name
    )
    if phase != "ACTIVE":
        raise PublishError(f"deployment {deployment_id} finished as {phase}")

    technical_url = default_ingress_url(app)
    urls = [technical_url]
    if arguments.url:
        public_url = normalized_https_root(arguments.url, label="public URL")
        if public_url != technical_url:
            urls.append(public_url)
    for url in urls:
        verify_public_site(
            url,
            deployment_id=deployment_id,
            commit=commit,
            deadline=deadline,
            request_timeout=arguments.request_timeout,
            attempts=arguments.http_attempts,
            retry_delay=arguments.retry_delay,
        )
    print(f"Published commit {commit} and verified: {', '.join(urls)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PublishError as error:
        print(f"error: {redact(str(error))}", file=sys.stderr)
        raise SystemExit(1) from error
