#!/usr/bin/env python3
"""Offline fixtures for CAPI auth, diagnostics, and the image helper.

No live endpoint, provider, or credential file is used.
"""

from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

PACKAGE = Path(__file__).resolve().parents[1]
SCRIPTS = PACKAGE / "scripts"
SECRET = "fixture-inbound-key-not-a-real-secret"
PNG = (
    b"\x89PNG\r\n\x1a\n"
    b"\x00\x00\x00\rIHDR"
    b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00"
    b"\x90wS\xde"
    b"\x00\x00\x00\x0cIDATx\x9cc\xf8\xcf\xc0\x00\x00\x00\x03\x00\x01"
    b"\x00\x05\xfe\x02\xfe"
    b"\x00\x00\x00\x00IEND\xaeB`\x82"
)


def load_module(name: str, path: Path):
    scripts = str(path.parent)
    if scripts not in sys.path:
        sys.path.insert(0, scripts)
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class AuthAndImageTests(unittest.TestCase):
    def test_auth_header_rules_and_key_file_mode(self) -> None:
        auth = load_module("capi_auth_offline", SCRIPTS / "capi_auth.py")
        with tempfile.TemporaryDirectory() as tmp:
            key_file = Path(tmp) / "inbound-api-key"
            key_file.write_text(SECRET + "\n")
            os.chmod(key_file, 0o644)
            env = {
                "CAPI_API_KEY": "",
                "CAPI_API_KEY_FILE": str(key_file),
            }
            old = {k: os.environ.get(k) for k in env}
            os.environ.update(env)
            try:
                with self.assertRaises(ValueError):
                    auth.auth_header("http://127.0.0.1:8317")
                os.chmod(key_file, 0o600)
                self.assertEqual(auth.auth_header("http://127.0.0.1:8317"), "Bearer " + SECRET)
                with self.assertRaises(ValueError):
                    auth.auth_header("http://127.0.0.1:8317?x=1")
                with self.assertRaises(ValueError):
                    auth.auth_header("http://example.test")
                os.environ["CAPI_API_KEY"] = "sk-dummy"
                with self.assertRaises(ValueError):
                    auth.auth_header("https://llm-proxy.genr8ive.ai")
                os.environ["CAPI_API_KEY"] = SECRET
                self.assertEqual(
                    auth.auth_header("https://llm-proxy.genr8ive.ai"),
                    "Bearer " + SECRET,
                )
            finally:
                for key, value in old.items():
                    if value is None:
                        os.environ.pop(key, None)
                    else:
                        os.environ[key] = value

    def test_image_preflight_stops_before_http_without_pillow(self) -> None:
        image = load_module("capi_image_offline", SCRIPTS / "capi-gpt-image-2.py")
        calls = []

        def fail_open(*_args, **_kwargs):
            calls.append("open")
            raise AssertionError("HTTP was called")

        image._HTTP.open = fail_open
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "out.png"
            try:
                from PIL import Image  # noqa: F401
            except ImportError:
                pillow = False
            else:
                pillow = True
            if pillow:
                self.skipTest("advisor runtime unexpectedly has Pillow")
            with self.assertRaises(SystemExit) as caught:
                image._write_image({"data": [{"b64_json": "aaaa"}]}, out)
            self.assertIn("Pillow", str(caught.exception))
            self.assertFalse(out.exists())
            self.assertEqual(calls, [])

    def test_multipart_repeats_images_and_omits_key(self) -> None:
        image = load_module("capi_image_multipart", SCRIPTS / "capi-gpt-image-2.py")
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp) / "base.png"
            ref = Path(tmp) / "reference.png"
            base.write_bytes(PNG)
            ref.write_bytes(PNG + b"ref")
            body, boundary = image._multipart_body(
                {"model": "gpt-image-2", "prompt": "keep layout"},
                [base, ref],
            )
            self.assertEqual(body.count(b'name="image"'), 2)
            self.assertIn(b"gpt-image-2", body)
            self.assertNotIn(SECRET.encode(), body)
            self.assertIn(boundary.encode(), body)

    def test_invalid_image_preserves_existing_output_when_pillow_stubbed(self) -> None:
        import sys
        import types

        image = load_module("capi_image_write", SCRIPTS / "capi-gpt-image-2.py")

        class FakeImage:
            def __init__(self, data: bytes) -> None:
                self.data = data

            def verify(self) -> None:
                if b"BAD" in self.data:
                    raise OSError("bad")

            def load(self) -> None:
                if not self.data.startswith(b"\x89PNG"):
                    raise OSError("not png")

            def __enter__(self):
                return self

            def __exit__(self, *_args):
                return False

        fake = types.ModuleType("PIL")
        fake.Image = types.SimpleNamespace(open=lambda bio: FakeImage(bio.read()))
        sys.modules["PIL"] = fake
        try:
            import base64

            with tempfile.TemporaryDirectory() as tmp:
                out = Path(tmp) / "out.png"
                out.write_bytes(b"keep-me")
                bad = {"data": [{"b64_json": base64.b64encode(b"BAD-image").decode()}]}
                with self.assertRaises(SystemExit):
                    image._write_image(bad, out)
                self.assertEqual(out.read_bytes(), b"keep-me")
                good = {"data": [{"b64_json": base64.b64encode(PNG).decode()}]}
                image._write_image(good, out)
                self.assertEqual(out.read_bytes(), PNG)
                self.assertFalse(list(out.parent.glob(".capi-image-*")))
        finally:
            sys.modules.pop("PIL", None)


class DiagnosticScriptTests(unittest.TestCase):
    def _env(self, home: Path, capture: Path) -> dict[str, str]:
        bindir = capture / "bin"
        bindir.mkdir()
        curl = bindir / "curl"
        curl.write_text(
            "#!/bin/bash\n"
            "printf '%s\\0' \"$@\" > \"$CAPI_CAPTURE/argv\"\n"
            "cat > \"$CAPI_CAPTURE/stdin\"\n"
            "url=\"\"\n"
            "for arg in \"$@\"; do\n"
            "  case \"$arg\" in http://*|https://*) url=\"$arg\" ;; esac\n"
            "done\n"
            "if [[ \"$url\" == */v1/models ]]; then\n"
            "  printf '%s\\n' '{\"data\":[{\"id\":\"glm-4.7\"},{\"id\":\"gpt-image-2\"}]}'\n"
            "  exit 0\n"
            "fi\n"
            "if [[ \"$url\" == */v1/chat/completions ]]; then\n"
            "  printf '%s\\n' '{\"choices\":[{\"message\":{\"content\":\"hello there friend now\"}}],\"usage\":{\"total_tokens\":4}}'\n"
            "  exit 0\n"
            "fi\n"
            "echo \"unexpected curl $*\" >&2\n"
            "exit 9\n"
        )
        systemctl = bindir / "systemctl"
        systemctl.write_text("#!/bin/bash\nexit 1\n")
        curl.chmod(0o755)
        systemctl.chmod(0o755)
        jq = subprocess.check_output(["bash", "-lc", "command -v jq"], text=True).strip()
        os.symlink(jq, bindir / "jq")
        env = os.environ.copy()
        env.update(
            {
                "HOME": str(home),
                "PATH": str(bindir) + os.pathsep + env.get("PATH", ""),
                "CAPI_URL": "http://127.0.0.1:8317",
                "CAPI_API_KEY": SECRET,
                "CAPI_API_KEY_FILE": "",
                "CAPI_CAPTURE": str(capture),
                "PYTHONDONTWRITEBYTECODE": "1",
            }
        )
        return env

    def test_models_logs_and_completion_keep_key_out_of_argv(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            capture = root / "capture"
            log = home / ".cli-proxy-api" / "logs" / "main.log"
            log.parent.mkdir(parents=True)
            log.write_text("line-one\nline-two\nline-three\n")
            token = home / ".cli-proxy-api" / "codex-account.json"
            token.write_text('{"type":"codex","access_token":"do-not-print"}')
            os.chmod(token, 0o600)
            capture.mkdir()
            env = self._env(home, capture)
            models = subprocess.run(
                ["bash", str(SCRIPTS / "capi-models.sh"), "gpt-image"],
                cwd=PACKAGE,
                env=env,
                text=True,
                capture_output=True,
                timeout=20,
                check=False,
            )
            self.assertEqual(models.returncode, 0, models.stderr)
            self.assertEqual(models.stdout.strip(), "gpt-image-2")
            argv = (capture / "argv").read_bytes()
            stdin = (capture / "stdin").read_text()
            self.assertNotIn(SECRET.encode(), argv)
            self.assertIn("Authorization: Bearer " + SECRET, stdin)
            self.assertNotIn(SECRET, models.stdout)

            logs = subprocess.run(
                ["bash", str(SCRIPTS / "capi-logs.sh"), "2", "file"],
                cwd=PACKAGE,
                env=env,
                text=True,
                capture_output=True,
                timeout=20,
                check=False,
            )
            self.assertEqual(logs.returncode, 0, logs.stderr)
            self.assertIn("line-two", logs.stdout)
            self.assertNotIn("line-one", logs.stdout)
            self.assertNotIn("do-not-print", logs.stdout)

            tested = subprocess.run(
                ["bash", str(SCRIPTS / "capi-test.sh"), "glm-4.7", "Say hello"],
                cwd=PACKAGE,
                env=env,
                text=True,
                capture_output=True,
                timeout=20,
                check=False,
            )
            self.assertEqual(tested.returncode, 0, tested.stderr)
            self.assertIn("hello there friend now", tested.stdout)
            argv = (capture / "argv").read_bytes()
            stdin = (capture / "stdin").read_text()
            self.assertNotIn(SECRET.encode(), argv)
            self.assertIn(SECRET, stdin)
            self.assertNotIn(SECRET, tested.stdout)
            self.assertIn("glm-4.7", argv.decode())

            status = subprocess.run(
                ["bash", str(SCRIPTS / "capi-status.sh")],
                cwd=PACKAGE,
                env=env,
                text=True,
                capture_output=True,
                timeout=20,
                check=False,
            )
            self.assertEqual(status.returncode, 0, status.stderr)
            self.assertIn("codex: 1 (enabled)", status.stdout)
            self.assertNotIn("codex-account", status.stdout)
            self.assertNotIn("do-not-print", status.stdout)
            self.assertNotIn(SECRET, status.stdout)
            self.assertNotIn(SECRET.encode(), (capture / "argv").read_bytes())


if __name__ == "__main__":
    unittest.main()
