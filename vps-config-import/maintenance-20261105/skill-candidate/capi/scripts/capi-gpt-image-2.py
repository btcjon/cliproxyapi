#!/usr/bin/env python3
"""Generate or edit images through local CAPI gpt-image-2 without global OpenAI env.

Auth model:
- Caller uses shared CAPI inbound authentication; sk-dummy is loopback-only compatibility.
- Provider auth comes from CAPI's OAuth-backed account pool.
- No OPENAI_API_KEY is required or read.

Examples:
  python scripts/capi-gpt-image-2.py generate --prompt 'dark teal dashboard icon, no text' --out out.png
  python scripts/capi-gpt-image-2.py edit --prompt 'make image better' --image base.png --image ref.png --out out.png
"""
from __future__ import annotations

import argparse
import base64
import json
import io
import tempfile
import os
from pathlib import Path
from typing import Any
from urllib import error, request
from capi_auth import auth_header

DEFAULT_CAPI_URL = "http://127.0.0.1:8317"

class _NoRedirect(request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

_HTTP = request.build_opener(_NoRedirect())


def _http_json(url: str, payload: dict[str, Any]) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(url, data=data, headers={"Authorization": auth_header(url), "Content-Type": "application/json"}, method="POST")
    try:
        with _HTTP.open(req, timeout=300) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {exc.code} from CAPI: {body}") from exc


def _multipart_body(fields: dict[str, str], files: list[Path]) -> tuple[bytes, str]:
    boundary = "----capi-gpt-image-2-boundary"
    chunks: list[bytes] = []
    for name, value in fields.items():
        chunks.extend([f"--{boundary}\r\n".encode(), f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode(), value.encode(), b"\r\n"])
    for path in files:
        chunks.extend([f"--{boundary}\r\n".encode(), f'Content-Disposition: form-data; name="image"; filename="{path.name}"\r\n'.encode(), b"Content-Type: image/png\r\n\r\n", path.read_bytes(), b"\r\n"])
    chunks.append(f"--{boundary}--\r\n".encode())
    return b"".join(chunks), boundary


def _http_multipart(url: str, fields: dict[str, str], files: list[Path]) -> dict[str, Any]:
    body, boundary = _multipart_body(fields, files)
    req = request.Request(url, data=body, headers={"Authorization": auth_header(url), "Content-Type": f"multipart/form-data; boundary={boundary}"}, method="POST")
    try:
        with _HTTP.open(req, timeout=300) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as exc:
        body_text = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {exc.code} from CAPI: {body_text}") from exc


def _write_image(result: dict[str, Any], out: Path) -> None:
    try:
        b64 = result["data"][0]["b64_json"]
    except Exception as exc:
        raise SystemExit("CAPI response did not include data[0].b64_json:\n" + json.dumps(result, indent=2)[:4000]) from exc
    decoded = base64.b64decode(b64, validate=True)
    if not decoded:
        raise SystemExit("CAPI returned empty image data")
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("Image validation requires Pillow; use a Python runtime with Pillow installed") from exc
    # Verify structure and fully decode before touching the destination.
    try:
        with Image.open(io.BytesIO(decoded)) as image:
            image.verify()
        with Image.open(io.BytesIO(decoded)) as image:
            image.load()
    except Exception as exc:
        raise SystemExit("CAPI returned invalid or undecodable image data") from exc
    out.parent.mkdir(parents=True, exist_ok=True)
    staged = None
    try:
        with tempfile.NamedTemporaryFile(dir=out.parent, prefix=".capi-image-", delete=False) as fh:
            staged = Path(fh.name)
            fh.write(decoded)
            fh.flush()
            os.fsync(fh.fileno())
        os.replace(staged, out)
    finally:
        if staged is not None:
            staged.unlink(missing_ok=True)
    print(json.dumps({"success": True, "out": str(out), "bytes": len(decoded)}, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="CAPI gpt-image-2 helper (no global OpenAI env).")
    parser.add_argument("--capi-url", default=os.getenv("CAPI_URL", DEFAULT_CAPI_URL))
    sub = parser.add_subparsers(dest="cmd", required=True)
    gen = sub.add_parser("generate")
    gen.add_argument("--prompt", required=True)
    gen.add_argument("--model", default="gpt-image-2", help="Exact image model from the selected live catalog")
    gen.add_argument("--out", required=True, type=Path)
    gen.add_argument("--size", default="1024x1024")
    gen.add_argument("--quality", default="medium")
    edit = sub.add_parser("edit")
    edit.add_argument("--prompt", required=True)
    edit.add_argument("--model", default="gpt-image-2", help="Exact image model from the selected live catalog")
    edit.add_argument("--image", action="append", required=True, type=Path, help="Repeat for base + reference images")
    edit.add_argument("--out", required=True, type=Path)
    edit.add_argument("--size", default="1024x1024")
    edit.add_argument("--quality", default="medium")
    args = parser.parse_args()
    try:
        from PIL import Image  # Check before sending a quota-consuming request.
    except ImportError as exc:
        raise SystemExit("Image validation requires Pillow; use a Python runtime with Pillow installed") from exc
    base = args.capi_url.rstrip("/")
    if args.cmd == "generate":
        result = _http_json(f"{base}/v1/images/generations", {"model": args.model, "prompt": args.prompt, "size": args.size, "quality": args.quality, "n": 1})
    else:
        files = [Path(p) for p in args.image]
        missing = [str(p) for p in files if not p.exists()]
        if missing:
            raise SystemExit(f"Missing image file(s): {missing}")
        result = _http_multipart(f"{base}/v1/images/edits", {"model": args.model, "prompt": args.prompt, "size": args.size, "quality": args.quality}, files)
    _write_image(result, args.out)


if __name__ == "__main__":
    main()
