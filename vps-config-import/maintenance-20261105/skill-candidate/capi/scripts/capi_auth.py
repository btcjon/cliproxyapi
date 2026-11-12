"""Endpoint-scoped CAPI authentication; never print keys except into curl's private config pipe."""
from pathlib import Path
from urllib.parse import urlsplit
import json, os, sys

def validate_endpoint(url: str) -> bool:
    u = urlsplit(url)
    local = u.hostname in {"localhost", "127.0.0.1", "::1"}
    if u.username or u.password or u.query or u.fragment or not u.hostname:
        raise ValueError("CAPI URL must not contain credentials, query or fragment")
    if u.scheme != "https" and not (u.scheme == "http" and local):
        raise ValueError("Remote CAPI requires HTTPS; plain HTTP is restricted to loopback")
    return local

def auth_header(url: str) -> str:
    local = validate_endpoint(url)
    u = urlsplit(url)
    key = os.environ.get("CAPI_API_KEY", "")
    path = os.environ.get("CAPI_API_KEY_FILE")
    if not path and (local or u.hostname == "llm-proxy.genr8ive.ai"):
        known = Path.home() / ".cli-proxy-api/inbound-api-key"
        if known.is_file():
            path = str(known)
    if not key and path:
        p = Path(path).expanduser()
        if p.stat().st_mode & 0o077:
            raise ValueError("CAPI key file must be owner-only")
        key = p.read_text().strip()
    if not key and local:
        key = "sk-dummy"  # Preserved local compatibility mode; not valid public authentication.
    if not key:
        raise ValueError("Set CAPI_API_KEY or CAPI_API_KEY_FILE for this remote endpoint")
    if any(ord(c) < 32 or ord(c) == 127 for c in key):
        raise ValueError("CAPI key contains invalid control characters")
    if not local and key == "sk-dummy":
        raise ValueError("Dummy compatibility key is restricted to loopback")
    return "Bearer " + key

if __name__ == "__main__":
    try:
        header = "Authorization: " + auth_header(sys.argv[1])
        print("header = " + json.dumps(header))
    except (ValueError, OSError, IndexError) as exc:
        print("CAPI authentication setup failed: " + str(exc), file=sys.stderr)
        sys.exit(2)
