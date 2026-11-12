# Hermes Workspace custom provider integration for CAPI

Use this when JB asks whether `https://hermes.genr8ive.ai/settings` / Hermes Workspace can expose CAPI models in its provider/model dropdowns.

## Correct provider shape

CAPI is an OpenAI-compatible endpoint, so model usage belongs under Hermes custom providers, not under native Anthropic/OpenAI provider auth.

```yaml
custom_providers:
  - name: capi
    title: CAPI / CLIProxyAPI
    base_url: https://llm-proxy.genr8ive.ai/v1
    api_key: CONFIGURED_INBOUND_KEY
    api_mode: chat_completions
```

`sk-dummy` is loopback-only compatibility, not public authentication. Do not place the inbound key in chat, argv, or shared files.

Local-only equivalent:

```yaml
custom_providers:
  - name: capi-local
    title: CAPI Local
    base_url: http://127.0.0.1:8317/v1
    api_key: sk-dummy
    api_mode: chat_completions
```

## Verification

Before promising UI availability, verify both CAPI and Workspace behavior:

Run from the selected CAPI package root. These requests read catalogs; they do not prove completion availability or Workspace dropdown behavior. Keep the public key in the selected private environment/key file.

```bash
set -euo pipefail
CAPI_URL=http://127.0.0.1:8317 bash scripts/capi-models.sh
CAPI_URL=https://llm-proxy.genr8ive.ai bash scripts/capi-models.sh
```


## Workspace dropdown pitfall

Hermes Workspace has two model-list paths:

1. `/api/models` — reads Hermes gateway/model catalog and may merge `~/.hermes/models.json`.
2. Settings → Model dropdown — calls `/api/claude-proxy/api/available-models?provider=<provider>`.

For vanilla Hermes, Workspace has a fallback in `src/routes/api/claude-proxy/$.ts` that synthesizes available models from Hermes `/v1/models` and filters by `provider`/`owned_by`. That works for native providers, but a custom provider named `capi` may not show CAPI's full live catalog unless Workspace is taught to query the custom provider's own `base_url + /models` with its configured API key.

## Best repair when dropdown misses CAPI models

Patch Workspace's available-models path so custom provider rows are resolved from config and queried directly:

- Read `custom_providers[]` from active Hermes config.
- Match the requested provider by `name` case-insensitively.
- If matched, request `${base_url.rstrip('/')}/models`.
- Send `Authorization: Bearer ${api_key}` from the configured inbound key. Do not fall back to `sk-dummy` for a non-loopback base URL.
- Normalize `data[].id` into `{ id, description? }` for the existing dropdown.
- Fall back to current Hermes `/v1/models` behavior if the direct request fails.

This is better than hardcoding CAPI models into `models.json`; CAPI's model catalog changes frequently.
