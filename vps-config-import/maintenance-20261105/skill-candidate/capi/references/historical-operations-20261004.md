> Reference guide retaining historical service, auth and model examples. For current diagnostic execution use [current-diagnostics.md](references/current-diagnostics.md). Older `sudo systemctl ... cliproxyapi` examples target a system deployment, not the destination user unit. A dummy key is only local compatibility; never use it as public authentication. No historical example authorizes account changes. This guide is contained in the CAPI package. The fresh snapshot has no sibling `cliproxyapi` package, so do not follow `../cliproxyapi/guide.md`. Recorded SSH hosts and the 2026-07-23 catalog are historical evidence, not a fresh installation or current host authority.

---

name: capi
description: "Use when operating CAPI, CLIProxyAPI, gpt-image-2 on :8317, LLM proxies, or model routing."
---
# CLIProxyAPI (CAPI)

Multi-provider LLM proxy that unifies access to Claude, Gemini, GPT, GLM, Kimi and more behind OpenAI-compatible and Anthropic-native endpoints.

## Use When

- JB asks about CAPI / CLIProxyAPI setup, health, model routing, model catalogs, provider pools, or OpenAI-compatible/Anthropic-native proxy endpoints.
- You need to configure Hermes, Workspace, OpenClaw, SDKs, or local scripts to use `https://llm-proxy.genr8ive.ai` or local CAPI on `127.0.0.1:8317`.
- You need read-only diagnostics for CAPI service status, logs, model availability, or integration wiring.
- You need to use the CAPI image endpoint/reference-edit workflow instead of a direct provider key.

## Do Not Use

- Do not use this skill for generic provider advice when CAPI is not part of the path.
- Do not add accounts, rotate credentials, edit `~/.cli-proxy-api/config.yaml`, restart services, trigger manual updates, or change provider routing without explicit user approval.
- Do not run OAuth login flows or browser-profile/auth callbacks unless JB has approved that account-bound action for this session.
- Do not assume the static model list below is current; CAPI catalogs drift. Verify live before naming available models as fact.
- Do **not** route SuperGrok / Hermes `xai-oauth` through CAPI. Call `https://api.x.ai/v1` with the Hermes OAuth bearer (exported `hermes-agent` → `references/xai-oauth-direct.md`). CAPI `-xai-login` is a separate, approval-gated lane.

## Safety and Prerequisites

- Prefer the bundled read-only diagnostics: `scripts/capi-status.sh`, `scripts/capi-models.sh`, and `scripts/capi-logs.sh`. `scripts/capi-test.sh` sends a completion request and consumes provider quota; run it only within the requested model-test scope.
- Scripts require `bash`, `curl`, and `jq`; service/log modes may also need `systemctl`, `journalctl`, `sudo`, or readable `~/.cli-proxy-api/logs/` files.
- Treat this as account-bound infrastructure: model tests may spend quota, logs may contain sensitive request metadata, and auth files under `~/.cli-proxy-api/*.json` are credential material. Never paste tokens or raw auth file contents.
- Use `CAPI_URL` to point scripts at local vs public endpoints; default is the public HTTPS endpoint unless a script documents otherwise.
- JB's current CAPI runtime policy is **no active Anthropic/Claude lane**. Do not run `--claude-login`, restore Claude aliases, or reintroduce Anthropic-compatible provider blocks unless JB explicitly reverses that policy in the current session.
- Claude subscription OAuth through CAPI is **not a safe default**: Anthropic docs say OAuth is for ordinary use in Claude Code/native Anthropic apps, and developers should use Console/API keys or supported cloud/gateway auth rather than routing Free/Pro/Max credentials through third-party tools. Treat CAPI Claude OAuth as policy/availability-risky even if technically possible. Preferred path for Claude subscription/OAuth work: call the Claude Code harness directly, either interactively or with `-p`, instead of attaching Claude OAuth to CAPI.
- If JB explicitly overrides and wants a Claude OAuth experiment anyway, require hardening first: local-only bind or protected reverse proxy, `remote-management.allow-remote=false`, management control panel disabled, `request-log=false`, auth JSON files `0600`, auth directory not group/world writable, no public model alias until a smoke test passes, and a rollback path that removes Claude auth files from the active auth dir.
- For the session-derived Anthropic removal and xAI OAuth procedure, see `references/provider-policy-anthropic-removal-xai-oauth.md`.

## Output Contract

When reporting CAPI work, include:
- endpoint checked (`local` or `public`) and exact read-only command/script used
- classification of action: read-only diagnostic, model test/quota-consuming, config mutation, service mutation, or auth/account mutation
- verification evidence: response status, model count/sample, script exit code, or relevant log window
- any blocked mutation with the exact approval needed

## Verification Gate

Before claiming CAPI is configured, healthy, or fixed:
1. Verify `/v1/models` against the intended endpoint.
2. If routing/model execution matters, run a minimal model smoke test and capture exit code/output.
3. If service state matters, verify systemd or log evidence on the host that owns the service.
4. If Hermes/Workspace integration matters, verify the consuming UI/API path as well as CAPI itself.


## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CAPI (CLIProxyAPI)                          │
│                   https://llm-proxy.genr8ive.ai                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Anthropic│  │  Google  │  │  OpenAI  │  │   Z.AI   │  + more    │
│  │  Claude  │  │  Gemini  │  │ GPT/Codex│  │   GLM    │            │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│       │             │             │             │                   │
│       └─────────────┴─────────────┴─────────────┘                   │
│                           │                                         │
│              ┌────────────┴────────────┐                            │
│              │   Load Balancing        │                            │
│              │   Multi-account Pool    │                            │
│              │   Auto-retry on 429     │                            │
│              └────────────┬────────────┘                            │
│                           │                                         │
├───────────────────────────┴─────────────────────────────────────────┤
│  Endpoints:                                                         │
│    • POST /v1/chat/completions  (OpenAI-compatible)                │
│    • POST /v1/messages          (Anthropic-native, for thinking)   │
│    • GET  /v1/models            (List all available models)         │
│    • Dashboard: /management.html                                    │
└─────────────────────────────────────────────────────────────────────┘
```

## Endpoints

| Endpoint | URL |
|----------|-----|
| **HTTPS (public)** | `https://llm-proxy.genr8ive.ai` |
| **HTTP (local)** | `http://localhost:8317` |
| **Dashboard** | `https://llm-proxy.genr8ive.ai/management.html` |

## Quick Commands

### Check Status

```bash
# Service status
sudo systemctl status cliproxyapi

# View logs (live)
sudo journalctl -u cliproxyapi -f

# Recent logs
sudo journalctl -u cliproxyapi --since "1 hour ago"
```

### List Available Models

Run from the explicitly selected CAPI package root. The helper uses `CAPI_URL` and private inbound authentication; catalog requests are read-only.

```bash
set -euo pipefail
# All models
bash scripts/capi-models.sh

# Filter by provider
bash scripts/capi-models.sh | grep claude
bash scripts/capi-models.sh | grep gemini
bash scripts/capi-models.sh | grep gpt
bash scripts/capi-models.sh | grep glm
```

### Test a Model

```bash
set -euo pipefail
# Run from the selected CAPI package root; uses configured inbound authentication.
source scripts/capi-common.sh
# Completion requests below consume provider quota.
# Quick test
capi_request /v1/chat/completions -X POST \
  -H "Content-Type: application/json" \
  -d '{"model":"glm-4.7","messages":[{"role":"user","content":"Say hello"}]}'

# With streaming
capi_request /v1/chat/completions -X POST \
  -H "Content-Type: application/json" \
  -d '{"model":"gemini-3-flash-preview","messages":[{"role":"user","content":"Hello"}],"stream":true}'
```

### GPT-image-2 image/reference edits through OAuth

CAPI can also expose OpenAI-compatible image endpoints, including `gpt-image-2`, without requiring a provider API key from the caller. Use the local endpoint with the compatibility header `Authorization: Bearer sk-dummy` and CAPI's OAuth-backed account pool.

Preflight before any batch: verify `gpt-image-2` is currently listed by the intended endpoint's `/v1/models`. If `/v1/images/edits` returns `auth_unavailable: no auth available (providers=codex, model=gpt-image-2)` or the model is absent from `/v1/models`, the image lane needs account/auth repair; re-auth the Codex/OpenAI lane (for example `cli-proxy-api --codex-login`, with JB approval for the account-bound OAuth action), restart/recheck CAPI as needed, then rerun the prepared batch. Do not misdiagnose this as a prompt or multipart-format failure.

Reference-image edits work via multipart `POST /v1/images/edits` with repeated `image` parts — first image as base, additional images as references. See `references/gpt-image-2-reference-edits.md` for probes, decoding, wrapper-script pattern, and pitfalls.

### Restart Service

```bash
sudo systemctl restart cliproxyapi
```

### GPT-image-2 Image Generation + Reference Edits

CAPI also exposes OpenAI-compatible image endpoints on this VPS. Keep this route skill-local: do **not** export `OPENAI_API_KEY` globally for this. Use CAPI's OAuth-backed account pool and the dummy compatibility header.

Preferred helper:

```bash
python3 scripts/capi-gpt-image-2.py generate \
  --prompt 'premium editorial portrait mockup' \
  --size 1024x1536 \
  --quality medium \
  --out /tmp/capi-image.png

python3 scripts/capi-gpt-image-2.py edit \
  --prompt 'Preserve the base layout and use the reference image for identity.' \
  --image base-mockup.png \
  --image reference.png \
  --size 1024x1536 \
  --quality medium \
  --out /tmp/capi-edit.png
```

Raw curl equivalent:

> **GPT Image 2.5 note (2026-09):** JB's official-API/Codex-OAuth OpenAI default is now `gpt-image-2.5-flare` (Sunburst selectable). Prefer 2.5 IDs on CAPI only after a live `/v1/models` check shows them; historical CAPI recipes in this guide remain on `gpt-image-2` while CAPI 2.5 support is unverified.

```bash
# Text-to-image

curl -sS http://127.0.0.1:8317/v1/images/generations \
  -H 'Authorization: Bearer sk-dummy' \
  -H 'Content-Type: application/json' \
  -d '{"model":"gpt-image-2","prompt":"premium editorial portrait mockup","size":"1024x1536","n":1}'

# Reference edit / multi-image edit
curl -sS http://127.0.0.1:8317/v1/images/edits \
  -H 'Authorization: Bearer sk-dummy' \
  -F model='gpt-image-2' \
  -F size='1024x1536' \
  -F quality='medium' \
  -F prompt='Preserve the base layout and use the reference image for identity.' \
  -F image=@base-mockup.png \
  -F image=@reference.png
```

Notes:
- Repeated multipart `image` parts are accepted for base + references.
- Responses return `b64_json`; decode to PNG locally.
- `sk-dummy` is only the CAPI compatibility header; provider auth comes from CAPI's OAuth-backed account pool.
- Do not store direct OpenAI API keys in global env for this path; if a future direct provider key is needed, use a skill-local ignored env file or one-off process env only.
- For MiaFlint reference edits, the historical project wrapper was `/Users/jon/Library/CloudStorage/Dropbox/Projects/hermes-hosting/scripts/capi_gpt_image_reference_edit.py`. That path is outside this package and was not rechecked here; use the contained `scripts/capi-gpt-image-2.py` edit command unless that wrapper is verified present.
- Full reusable workflow and pitfalls: `references/gpt-image-2-reference-edits.md`.

## Authentication / Adding Accounts

CAPI supports configured multi-account pools. Respect provider quotas and backoff; adding accounts is a separately authorized account operation, not automatic 429 recovery.

```bash
cd ~/.cli-proxy-api

# Google Gemini (OAuth)
cli-proxy-api --login

# OpenAI Codex (OAuth)  
cli-proxy-api --codex-login

# xAI / Grok (OAuth, CAPI v7.1.68+)
cli-proxy-api -xai-login -no-browser -oauth-callback-port 8085
```

**Repeat any login to add more accounts** — CAPI auto-balances across all authenticated accounts.

Note: `--claude-login` exists in CAPI, but JB's current CAPI runtime policy is to keep Anthropic/Claude fully removed unless he explicitly asks to restore it.

### OAuth Login from VPS (SSH Tunnel Method)

When running on a VPS, OAuth callbacks commonly go to `localhost:8085`. Use SSH tunnel:

1. **On your laptop**, open tunnel:
   ```bash
   ssh -L 8085:127.0.0.1:8085 dev@5.161.192.198 -p 22
   ```

2. **On VPS**, run the provider login from a PTY when you need to see/copy the URL:
   ```bash
   cd ~/.cli-proxy-api && cli-proxy-api -xai-login -no-browser -oauth-callback-port 8085
   # or: cli-proxy-api --login / --codex-login as appropriate
   ```

3. **Copy the URL** to your laptop browser, authorize, callback will tunnel through. If the provider displays a callback token instead of redirecting cleanly, paste it into the waiting CLI prompt.

Pitfall: non-PTY/background login can appear silent while the callback listener is actually running. Use PTY/tmux for account-bound OAuth flows so the URL and token prompt are visible. xAI-specific details live in `references/provider-policy-anthropic-removal-xai-oauth.md`.

## Historical model catalog (not current availability)

Last verified 2026-07-23 against local `/v1/models` on CAPI v7.2.96: the live catalog exposed 53 models across OpenAI, Antigravity, xAI, Anthropic-labeled compatibility routes, Baseten, and Venice. Always re-check live with `curl -s http://127.0.0.1:8317/v1/models -H 'Authorization: Bearer sk-dummy' | jq -r '.data[].id' | sort` because CAPI's registry changes dynamically. Upstream v7.2.87 added Kimi `kimi-k3` / `kimi-k3[1m]` and renamed Gemini preview IDs to production IDs (`gemini-3-pro`, `gemini-3-flash`, `gemini-3.1-pro`, `gemini-3.1-flash-image`, `gemini-3-pro-image`); v7.2.83 renamed `gemini-3.1-flash-lite-preview` to `gemini-3.1-flash-lite`. These upstream-supported IDs are not necessarily exposed by the live endpoint without healthy provider auth. CAPI v7.2.96 itself added Home credential concurrency support, not a new model family.

### Anthropic / Claude aliases and dated IDs
- `claude-opus-4-8`, `claude-opus-4-7`, `claude-opus-4-6`, `claude-opus-4-5-20251101`, `claude-opus-4-1-20250805`, `claude-opus-4-20250514`
- `claude-sonnet-4-6`, `claude-sonnet-4-5-20250929`, `claude-sonnet-4-20250514`, `claude-3-7-sonnet-20250219`
- `claude-haiku-4-5-20251001`, `claude-3-5-haiku-20241022`
- Short aliases: `opus`, `opus-high`, `opus-low`, `sonnet`, `sonnet-high`, `sonnet-low`, `haiku`

### Google / Gemini aliases and dated IDs
- `gemini-3.1-pro-preview`, `gemini-3.1-flash-lite-preview`, `gemini-3-pro-preview`, `gemini-3-flash-preview`
- `gemini-2.5-pro`, `gemini-2.5-flash-lite`
- Short aliases: `gpro`, `gpro-high`, `gpro-low`, `gflash`, `gflash-high`, `gflash-low`

### OpenAI / Codex / image
- `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.2`
- `gpt-5.3-codex`, `gpt-5.3-codex-spark`, `codex-auto-review`
- `gpt-image-2`

### GLM / Z.AI
- `glm-5`, `glm-5.1`, `glm-5-turbo`
- Namespaced aliases: `zai/glm-5`, `zai/glm-5.1`, `zai/glm-5-turbo`

### Other
- `kimi-k2-thinking`
- `venice-uncensored`, `venice/venice-uncensored`

## Configuration

### Config File: `~/.cli-proxy-api/config.yaml`

```yaml
port: 8317
auth-dir: "/Users/jon/.cli-proxy-api"
debug: true
logging-to-file: true
request-retry: 3

# OpenAI-compatible providers
openai-compatibility:
  - name: "zai"
    base-url: "https://api.z.ai/api/coding/paas/v4"
    api-key-entries:
      - api-key: "YOUR_KEY"
    models:
      - name: "glm-4.7"
        alias: "glm-4.7"
```

### Environment Variables

Historical environment example: use process-scoped settings instead; do not change global shell startup files. Public endpoints require the configured inbound key described in `references/current-diagnostics.md`.

```bash
# Point clients at CAPI
export OPENAI_API_BASE="https://llm-proxy.genr8ive.ai/v1"
export OPENAI_API_KEY="sk-dummy"  # local-only dummy; public CAPI now requires ~/.cli-proxy-api/inbound-api-key

export ANTHROPIC_BASE_URL="https://llm-proxy.genr8ive.ai"
export ANTHROPIC_AUTH_TOKEN="CONFIGURED_INBOUND_KEY"  # public; sk-dummy is loopback-only. Claude proxy stays off unless explicitly reversed.
```

## File Locations

| File | Path |
|------|------|
| Binary | `/usr/local/bin/cli-proxy-api` |
| Config | `~/.cli-proxy-api/config.yaml` |
| Auth tokens | `~/.cli-proxy-api/*.json` |
| Logs | `~/.cli-proxy-api/logs/main.log` |
| Service | `/etc/systemd/system/cliproxyapi.service` |
| Auto-update timer | `/etc/systemd/system/cliproxy-update.timer` |
| Update script | `~/Dropbox/Projects/cliproxy-vps-config/scripts/auto-update-cliproxy.sh` |
| Update log | `~/.cli-proxy-api/logs/auto-update.log` |

## Auto-Update

Weekly updates run via systemd timer (Sundays at midnight):

```bash
# Check timer status
systemctl status cliproxy-update.timer

# View recent update runs
journalctl -u cliproxy-update.service --since "1 week ago"

# Manual update trigger
sudo systemctl start cliproxy-update.service

# Check current version
cli-proxy-api 2>&1 | grep Version
```

### Manual Update

Pitfall: older copies of `auto-update-cliproxy.sh` used `pkill -f "cli-proxy-api"`, which can match and kill the updater's own parent command, leaving the service stopped mid-update. Before relying on that script, verify its stop/start checks use exact process-name matching (`pgrep -x` / `pkill -x`) and keep a binary/config rollback copy.

```bash
# Check latest release
curl -s https://api.github.com/repos/router-for-me/CLIProxyAPI/releases/latest | jq -r '.tag_name'

# Download and install
VERSION="X.X.X"
curl -sLO "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${VERSION}/CLIProxyAPI_${VERSION}_linux_amd64.tar.gz"
tar -xzf "CLIProxyAPI_${VERSION}_linux_amd64.tar.gz"
sudo mv cli-proxy-api /usr/local/bin/
sudo systemctl restart cliproxyapi
```

## Model Validation

Treat model availability as a live check, not a static list. Prefer the bundled read-only model script:

```bash
scripts/capi-models.sh
scripts/capi-models.sh claude
```

If a separate alerting job exists, verify its current path and schedule before relying on it; do not assume old `.claude` validator paths are still active.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Model not found | Check available: `bash scripts/capi-models.sh` from the selected CAPI package root |
| 401 Missing/Invalid API key on **public** `llm-proxy.genr8ive.ai` | Public CAPI requires an inbound key from dest `~/.cli-proxy-api/config.yaml` `api-keys`. `sk-dummy` is 401. Andromeda document-evidence: load `andromeda-document-evidence-capi`. Never paste keys in Discord. |
| 403 Forbidden | Inspect endpoint/proxy/account policy evidence before changing auth; do not automatically run a login. |
| 429 Rate limit | Honor Retry-After/backoff and inspect quota; do not automatically add accounts. |
| Connection refused | Check dest user unit `cli-proxy-api` (`127.0.0.1:8317`), not the disabled system `cliproxyapi`. |
| Slow responses | Check logs for retry patterns |
| Embeddings fail | CAPI doesn't support `/v1/embeddings` — use provider directly |

### Debug Mode

Edit config to enable debug:
```yaml
debug: true
logging-to-file: true
```

Then restart and watch logs:
```bash
sudo systemctl restart cliproxyapi
tail -f ~/.cli-proxy-api/logs/main.log
```

## Integration Notes

### With Hermes Workspace / Dashboard custom providers

CAPI should be represented as a Hermes custom OpenAI-compatible provider, not as native Anthropic/OpenAI auth. For `https://hermes.genr8ive.ai/settings`, add a `custom_providers` row such as `name: capi`, `base_url: https://llm-proxy.genr8ive.ai/v1`, `api_key: CONFIGURED_INBOUND_KEY`, `api_mode: chat_completions`. If the Settings model dropdown does not show the full CAPI catalog, patch Workspace to query the custom provider's own `/models` endpoint instead of only filtering Hermes `/v1/models`; see `references/hermes-workspace-custom-provider.md`.

### With app-level OpenAI-compatible integrations

For self-hosted apps that support OpenAI-compatible providers, CAPI can supply OAuth-backed intelligence using the configured inbound key for public endpoints; a dummy compatibility key is loopback-only. Provider authentication stays in CAPI’s account pool instead of direct app-stored provider keys. For Open Notebook specifically, use `openai_compatible` with `https://llm-proxy.genr8ive.ai/v1`, register language models manually if needed, and provide a separate embedding provider when CAPI does not expose `/v1/embeddings`. See `references/open-notebook-capi-oauth-integration.md`.

### With Hermes native delegation

CAPI is the preferred route when Hermes `delegate_task` needs Gemini 3 Flash as a fast worker but direct `google-gemini-cli` / Code Assist is hitting short-window 429 throttles. Configure Hermes delegation as a custom OpenAI-compatible endpoint. **When Hermes runs on the same VPS as CAPI, prefer the local endpoint** because the public reverse proxy may reject the dummy compatibility key with HTTP 403:

```yaml
delegation:
  model: gemini-3.5-flash-low
  provider: ""
  base_url: http://127.0.0.1:8317/v1
  api_key: CONFIGURED_INBOUND_KEY
  api_mode: chat_completions
```

Use the public endpoint only when its authentication policy has been explicitly verified from the consuming host.

Verify with `/v1/models`, a direct completion, and an actual `delegate_task` smoke test. **Inspect the child session/log metadata to prove the final model remained Gemini**; a correct-looking response is insufficient because Hermes can silently fall back after a 403. Expected child metadata should show the requested Gemini model, `provider=custom`, the intended CAPI base URL, and no `Fallback activated` line. Keep `provider` blank for the direct custom-endpoint path — `provider: google-gemini-cli` routes through Google Code Assist instead.

### With OpenClaw

OpenClaw can use CAPI as a model provider:

```json
{
  "models": {
    "providers": {
      "capi": {
        "baseUrl": "https://llm-proxy.genr8ive.ai/v1",
        "api": "openai-completions",
        "models": [
          {"id": "glm-4.7", "name": "GLM-4.7 (Fast)", "contextWindow": 131000}
        ]
      }
    }
  }
}
```

### Anthropic-Native Features (Thinking, Caching)

If the user restores Claude proxy policy, check the selected CAPI release accepts the helper’s Bearer authentication on `/v1/messages` before using this historical Anthropic-native feature example. It sends a completion request and consumes provider quota. If a different auth header is required, use a private in-process/header-configuration mechanism; never substitute the key into argv.

```bash
set -euo pipefail
# Run from the selected CAPI package root; only if Claude proxy policy is reversed.
source scripts/capi-common.sh
capi_request /v1/messages -X POST \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-5-20251101",
    "max_tokens": 1024,
    "thinking": {"type": "enabled", "budget_tokens": 5000},
    "messages": [{"role": "user", "content": "Explain quantum computing"}]
  }'
```

## Related Files

- Architecture doc: `$HOME/.claude/docs/architecture/cliproxyapi.md` (if present) or project docs under the cliproxy config repo
- VPS config repo: `~/Dropbox/Projects/cliproxy-vps-config/`
- Test scripts: `~/Dropbox/Projects/cliproxy-vps-config/scripts/test-all-models.sh`

## Compatibility

- `cliproxyapi` is now a redirect alias to this canonical skill.
- Legacy cookbook guidance is available under:
  - `cookbook/authentication.md`
  - `cookbook/configuration.md`
  - `cookbook/sdk-integration.md`
  - `cookbook/service-management.md`

## Optional legacy contract runtime (requires an installed host-local runner)

- Canonical workflow: `workflow.yaml`
- Generic adapter: `adapters/generic_tool_loop.py`
- Contract tests: `tests/test_contract.py`
- Package-relative runtime example: `python3 ~/.agents/tools/skill_runtime/run_contract.py --contract workflow.yaml --tool-module-path adapters/generic_tool_loop.py --input-json '{"request":"route this task"}'`. The old `/Users/jon/.hermes/skills/openclaw-imports/capi/` absolute paths are historical and are not in this snapshot.

<!-- curator-umbrella-capi -->
## Curator umbrella consolidation

cliproxyapi is the same provider/proxy domain as CAPI and is retained as a legacy reference.

Absorbed former top-level skills as reference files:
- `cliproxyapi` -> `references/archived-cliproxyapi-source.md`

Use the labeled subsections in this SKILL.md for routing; open the reference files only when session-specific details are needed.

