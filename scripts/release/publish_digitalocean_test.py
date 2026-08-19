from __future__ import annotations

import contextlib
import importlib.util
import io
import os
import subprocess
import time
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).with_name("publish_digitalocean.py")
MODULE_SPEC = importlib.util.spec_from_file_location("publish_digitalocean", MODULE_PATH)
assert MODULE_SPEC is not None and MODULE_SPEC.loader is not None
publish = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(publish)


COMMIT = "a" * 40
APP_RESPONSE = {
    "app": {
        "default_ingress": "swiftui-semantic-audit-abc.ondigitalocean.app",
        "active_deployment": {
            "id": "deployment-1",
            "phase": "ACTIVE",
            "static_sites": [
                {
                    "name": "landing",
                    "source_commit_hash": COMMIT,
                }
            ],
        },
    }
}


class PublishDigitalOceanTests(unittest.TestCase):
    def test_selects_one_app_by_name(self) -> None:
        payload = [
            {"id": "other", "spec": {"name": "other-app"}},
            {
                "id": "selected",
                "spec": {"name": "swiftui-semantic-audit"},
            },
        ]
        self.assertEqual(
            publish.find_app_id(payload, "swiftui-semantic-audit"), "selected"
        )
        with self.assertRaisesRegex(publish.PublishError, "was not found"):
            publish.find_app_id([], "swiftui-semantic-audit")
        with self.assertRaisesRegex(publish.PublishError, "is not unique"):
            publish.find_app_id(
                [payload[1], {"id": "duplicate", "spec": payload[1]["spec"]}],
                "swiftui-semantic-audit",
            )

    def test_reads_active_deployment_commit_and_technical_ingress(self) -> None:
        self.assertEqual(
            publish.deployment_details(APP_RESPONSE),
            ("deployment-1", "ACTIVE", COMMIT),
        )
        self.assertEqual(
            publish.default_ingress_url(APP_RESPONSE),
            "https://swiftui-semantic-audit-abc.ondigitalocean.app/",
        )

    def test_rejects_missing_or_invalid_deployment_commit(self) -> None:
        payload = {
            "app": {
                "active_deployment": {
                    "id": "deployment-1",
                    "phase": "ACTIVE",
                    "static_sites": [{"name": "landing"}],
                }
            }
        }
        with self.assertRaisesRegex(publish.PublishError, "source commit"):
            publish.deployment_details(payload)

    def test_verification_targets_cover_root_metadata_and_unknown_path(self) -> None:
        targets = publish.verification_targets(
            "https://example.ondigitalocean.app/",
            deployment_id="deployment-1",
            commit=COMMIT,
        )
        self.assertEqual(
            [target["label"] for target in targets],
            ["/", "/robots.txt", "/sitemap.xml", f"/{publish.MISSING_PATH}"],
        )
        self.assertEqual([target["status"] for target in targets], [200, 200, 200, 404])
        self.assertIn(f'data-site-build="{COMMIT}"', targets[0]["required"])
        self.assertTrue(
            all("deployment=deployment-1" in target["url"] for target in targets)
        )

    def test_target_verification_requires_status_and_markers(self) -> None:
        target = {
            "label": "/",
            "url": "https://example.com/?deployment=1",
            "status": 200,
            "required": ("expected",),
        }
        with mock.patch.object(publish, "fetch", return_value=(200, b"expected")):
            publish.verify_target(
                target,
                deadline=time.monotonic() + 1,
                request_timeout=0.5,
                attempts=1,
                retry_delay=0,
            )
        with mock.patch.object(publish, "fetch", return_value=(200, b"wrong")):
            with self.assertRaisesRegex(publish.PublishError, "missing"):
                publish.verify_target(
                    target,
                    deadline=time.monotonic() + 1,
                    request_timeout=0.5,
                    attempts=1,
                    retry_delay=0,
                )

    def test_dry_run_does_not_call_digitalocean(self) -> None:
        output = io.StringIO()
        with (
            mock.patch.object(publish.shutil, "which", return_value="/usr/local/bin/doctl"),
            mock.patch.object(publish, "validate_app_spec") as validate,
            mock.patch.object(publish, "run_doctl_json") as doctl,
            contextlib.redirect_stdout(output),
        ):
            result = publish.main(
                [
                    "--dry-run",
                    "--spec",
                    str(publish.DEFAULT_APP_SPEC),
                    "--app-id",
                    "app-1",
                ]
            )
        self.assertEqual(result, 0)
        validate.assert_not_called()
        doctl.assert_not_called()
        self.assertIn("apps spec validate", output.getvalue())
        self.assertIn("--update-sources --wait", output.getvalue())

    def test_main_validates_applies_and_verifies_technical_url_first(self) -> None:
        doctl_calls: list[list[str]] = []
        verified: list[str] = []

        def fake_doctl(_binary: str, arguments: list[str], *, timeout: float):
            del timeout
            doctl_calls.append(arguments)
            if arguments == ["apps", "list"]:
                return [
                    {
                        "id": "app-1",
                        "spec": {"name": "swiftui-semantic-audit"},
                    }
                ]
            if arguments[:2] == ["apps", "update"]:
                return {"app": {"id": "app-1"}}
            if arguments == ["apps", "get", "app-1"]:
                return APP_RESPONSE
            raise AssertionError(arguments)

        def fake_verify(url: str, **_kwargs: object) -> None:
            verified.append(url)

        with (
            mock.patch.object(publish.shutil, "which", return_value="/usr/local/bin/doctl"),
            mock.patch.object(publish, "validate_app_spec") as validate,
            mock.patch.object(publish, "run_doctl_json", side_effect=fake_doctl),
            mock.patch.object(publish, "verify_public_site", side_effect=fake_verify),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            result = publish.main(
                [
                    "--spec",
                    str(publish.DEFAULT_APP_SPEC),
                    "--url",
                    "https://audit.example/",
                ]
            )

        self.assertEqual(result, 0)
        validate.assert_called_once()
        self.assertEqual(doctl_calls[0], ["apps", "list"])
        self.assertEqual(
            doctl_calls[1],
            [
                "apps",
                "update",
                "app-1",
                "--spec",
                str(publish.DEFAULT_APP_SPEC.absolute()),
                "--update-sources",
                "--wait",
            ],
        )
        self.assertEqual(doctl_calls[2], ["apps", "get", "app-1"])
        self.assertEqual(
            verified,
            [
                "https://swiftui-semantic-audit-abc.ondigitalocean.app/",
                "https://audit.example/",
            ],
        )

    def test_redacts_tokens_from_doctl_errors(self) -> None:
        token = "dop_v1_secret-value"
        completed = subprocess.CompletedProcess(
            args=["doctl"], returncode=1, stdout="", stderr=f"bad token {token}"
        )
        with (
            mock.patch.dict(os.environ, {"DIGITALOCEAN_ACCESS_TOKEN": token}),
            mock.patch.object(publish.subprocess, "run", return_value=completed),
        ):
            with self.assertRaises(publish.PublishError) as raised:
                publish.run_process(["doctl", "apps", "list"], timeout=1, expect_json=True)
        self.assertNotIn(token, str(raised.exception))
        self.assertIn("<redacted-token>", str(raised.exception))

    def test_app_spec_is_a_single_domain_free_static_component(self) -> None:
        text = publish.DEFAULT_APP_SPEC.read_text(encoding="utf-8")
        self.assertEqual(text.count("static_sites:"), 1)
        for fragment in (
            "name: swiftui-semantic-audit",
            "rule: DEPLOYMENT_FAILED",
            "rule: DOMAIN_FAILED",
            "name: landing",
            "environment_slug: html",
            "repo: potapenko/swiftui-semantic-audit",
            "branch: master",
            "deploy_on_push: true",
            "source_dir: /website",
            "output_dir: public",
            "index_document: index.html",
            'value: "${APP_URL}"',
            'value: "${_self.COMMIT_HASH}"',
        ):
            self.assertIn(fragment, text)
        for forbidden in (
            "domains:",
            "ingress:",
            "routes:",
            "cors:",
            "catchall_document:",
        ):
            self.assertNotIn(forbidden, text)


if __name__ == "__main__":
    unittest.main()
