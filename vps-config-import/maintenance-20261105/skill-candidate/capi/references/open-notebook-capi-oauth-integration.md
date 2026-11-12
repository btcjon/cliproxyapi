# Open Notebook via CAPI OAuth proxy

Session-derived pattern for making a self-hosted Open Notebook instance use JB's OAuth-backed CAPI model pool instead of direct provider API keys.

## When to use

Use when an app has an OpenAI-compatible provider option and should consume CAPI's OAuth/account-pool intelligence rather than storing direct OpenAI/Google/Anthropic keys in the app.

## Pattern

1. Keep the app's public UI/API behind Caddy and localhost-only upstreams.
2. Configure an app credential/provider as OpenAI-compatible:
   - Base URL: `https://llm-proxy.genr8ive.ai/v1` for app containers that cannot reach host loopback safely, or `http://127.0.0.1:8317/v1` for host-local clients.
   - API key: configured inbound key for `https://llm-proxy.genr8ive.ai`. `sk-dummy` is only a loopback compatibility value. CAPI supplies real provider auth from its OAuth/account pool. Do not put the key in argv, logs, or chat.
   - Provider label in Open Notebook: `openai_compatible`.
3. Register language models manually if auto-discovery does not classify model types. Good defaults from the session:
   - Chat / large-context: `gpro-high`
   - Transformations/tools: `gflash-high`
4. Test the app's model through the app's own model-test endpoint/UI, not only CAPI `/v1/models`.
5. Separately handle embeddings. CAPI currently may not expose `/v1/embeddings`; Open Notebook needs embeddings for RAG/source search. Use a local embedding service when needed.

## Open Notebook concrete API flow

This is a session-derived API pattern, not a verified contract for the installed Open Notebook release. Before using it, inspect that release's schema: credential creation and model registration must return a nonempty string `id`, the test response must confirm `success: true`, and discovery must return a `models` list. If those fields differ, adapt the validators to the verified schema before any create request. Do not infer success from an arbitrary 2xx body.

The flow creates app state and its model test may consume provider quota. Use it only within the requested configuration/test scope. Privately load `OPEN_NOTEBOOK_PASSWORD` and `CAPI_API_KEY` into the process environment; do not substitute their values into command text. `OPEN_NOTEBOOK_API`, `CAPI_BASE_URL` and `CAPI_MODEL` select the app API, proxy and exact model. No credential is passed in a subprocess argument. Remote plain HTTP, redirects and credential-bearing URLs are rejected; loopback HTTP remains supported.

```bash
python3 - <<'PY'
import json
import os
import sys
from urllib.parse import quote, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

MAX_RESPONSE = 1024 * 1024
TIMEOUT_SECONDS = 20

class RecipeStopped(Exception):
    pass

class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise RecipeStopped("redirect refused")

def selected_url(value):
    if any(ord(c) < 32 or ord(c) == 127 for c in value):
        raise RecipeStopped("invalid endpoint")
    u = urlsplit(value)
    local = u.hostname in {"localhost", "127.0.0.1", "::1"}
    if (not u.hostname or u.username is not None or u.password is not None
            or u.query or u.fragment
            or not (u.scheme == "https" or (u.scheme == "http" and local))):
        raise RecipeStopped("invalid endpoint")
    return value.rstrip("/")

def required_secret(name):
    value = os.environ.get(name, "")
    if not value or any(ord(c) < 32 or ord(c) == 127 for c in value):
        raise RecipeStopped("credential setup missing or invalid")
    return value

def object_id(payload):
    value = payload.get("id")
    if (not isinstance(value, str) or not value.strip() or value in {".", ".."}
            or any(ord(c) < 32 or ord(c) == 127 for c in value)):
        raise RecipeStopped("missing or invalid returned ID")
    return value

def run():
    # Validate all local input before creating anything.
    base = selected_url(os.environ.get("OPEN_NOTEBOOK_API", "http://127.0.0.1:5055/api"))
    proxy = selected_url(os.environ.get("CAPI_BASE_URL", "https://llm-proxy.genr8ive.ai/v1"))
    password = required_secret("OPEN_NOTEBOOK_PASSWORD")
    inbound_key = required_secret("CAPI_API_KEY")
    if urlsplit(proxy).hostname not in {"localhost", "127.0.0.1", "::1"} and inbound_key == "sk-dummy":
        raise RecipeStopped("public endpoint requires inbound authentication")
    model = os.environ.get("CAPI_MODEL", "gpro-high")
    if not model.strip() or any(ord(c) < 32 or ord(c) == 127 for c in model):
        raise RecipeStopped("invalid selected model")
    opener = build_opener(NoRedirects())

    def post(path, payload=None):
        headers = {"Authorization": "Bearer " + password}
        data = b"" if payload is None else json.dumps(payload).encode("utf-8")
        if payload is not None:
            headers["Content-Type"] = "application/json"
        request = Request(base + path, data=data, headers=headers, method="POST")
        try:
            with opener.open(request, timeout=TIMEOUT_SECONDS) as response:
                if not 200 <= response.status < 300:
                    raise RecipeStopped("HTTP failure")
                raw = response.read(MAX_RESPONSE + 1)
                if len(raw) > MAX_RESPONSE:
                    raise RecipeStopped("response too large")
            result = json.loads(raw)
            if not isinstance(result, dict) or result.get("error") or result.get("success") is False:
                raise RecipeStopped("unsupported or failed response")
            return result
        except Exception:
            # A response or exception may contain either secret. Never print it.
            raise RecipeStopped("request failed or response unrecognized") from None

    credential = post("/credentials", {
        "name": "CAPI OAuth Proxy", "provider": "openai_compatible",
        "modalities": ["language"], "api_key": inbound_key, "base_url": proxy,
    })
    credential_id = object_id(credential)
    encoded_id = quote(credential_id, safe="")
    test = post("/credentials/" + encoded_id + "/test")
    if test.get("success") is not True:
        raise RecipeStopped("test success not confirmed")
    discovered = post("/credentials/" + encoded_id + "/discover")
    if not isinstance(discovered.get("models"), list):
        raise RecipeStopped("discovery schema unrecognized")
    registered = post("/models", {
        "name": model, "provider": "openai_compatible", "type": "language",
        "credential": credential_id,
    })
    object_id(registered)
    # Returned IDs are used internally; output has no server-derived strings.
    print("Credential creation, test, discovery and model registration confirmed.")
    print("Verify defaults and the model through the selected app UI/API.")

if __name__ == "__main__":
    try:
        run()
    except Exception:
        print("Stopped. Reconcile app state before another create; no automatic retry.", file=sys.stderr)
        sys.exit(1)
PY
```

The 20-second urllib timeout bounds socket operations; it is not a guaranteed total wall-clock deadline for a slowly streamed response. The one-megabyte response cap bounds accepted bytes.

The recipe stops after any rejected, malformed, oversized or timed-out response and never retries. Creation may have succeeded even when the response was lost or its ID was missing. Inspect the selected app's credential/model records before another create; do not rerun the whole recipe as recovery. Test/discovery failure also leaves the newly created credential for reconciliation. The returned ID is encoded only in request paths and retained exactly in the model payload. No server response, exception value or returned ID is printed.

Register other selected language models separately after checking the first result; assign defaults and perform the app's own model test through its verified UI/API. These steps preserve the session's `gpro-high` chat and `gflash-high` transformations/tools choices without claiming live availability.

## Embedding fallback used

Add an Ollama service to the Open Notebook compose network and pull `nomic-embed-text`:

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    volumes:
      - ./ollama_data:/root/.ollama
    restart: unless-stopped
    pull_policy: always
```

```bash
docker compose exec -T ollama ollama pull nomic-embed-text
```

Then create an Open Notebook `ollama` credential with:

```json
{
  "name": "Local Ollama Embeddings",
  "provider": "ollama",
  "modalities": ["embedding"],
  "base_url": "http://ollama:11434"
}
```

Register `nomic-embed-text` as an `embedding` model and set it as `default_embedding_model`. Verify Open Notebook reports embedding dimensions rather than only checking Ollama tags.

## Pitfalls

- Do not promise "Hermes drives Open Notebook" literally unless Hermes exposes an OpenAI-compatible inference endpoint. The practical architecture is: Open Notebook → OpenAI-compatible provider → CAPI → OAuth/account pools.
- Use public CAPI URL from containers unless host networking is deliberately configured; `127.0.0.1` inside a container points to the container, not the VPS host.
- CAPI `/v1/models` success does not prove embeddings/audio endpoints exist. Test `/v1/embeddings` or provide a separate embedding provider.
- Open Notebook's public app can return `401` for API routes while the UI returns `200`; that is expected when password auth is enabled. Verify both unauthenticated rejection and authenticated success.
