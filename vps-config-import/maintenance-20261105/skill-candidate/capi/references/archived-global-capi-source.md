> Archived historical skill text. Not an active procedure and not a current model catalog. "Available Models (Current)" below is old snapshot wording. Use live `/v1/models` and `references/current-diagnostics.md`. System unit `cliproxyapi` examples are not the destination user unit.

---

archived-skill-name: capi
description: "CLIProxyAPI — multi-provider LLM proxy for unified model access and management. USE WHEN: \"CAPI\", \"LLM proxy\", \"multi-provider\", \"OpenAI compatible\", \"Claude proxy\", \"Gemini proxy\", \"model routing\", \"LLM gateway\", \"proxy API\", \"unified LLM\""
---
# CLIProxyAPI (CAPI)

Multi-provider LLM proxy that unifies access to Claude, Gemini, GPT, GLM, Kimi and more behind OpenAI-compatible and Anthropic-native endpoints.

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

```bash
# All models
curl -s https://llm-proxy.genr8ive.ai/v1/models | jq -r '.data[].id'

# Filter by provider
curl -s https://llm-proxy.genr8ive.ai/v1/models | jq -r '.data[].id' | grep claude
curl -s https://llm-proxy.genr8ive.ai/v1/models | jq -r '.data[].id' | grep gemini
curl -s https://llm-proxy.genr8ive.ai/v1/models | jq -r '.data[].id' | grep gpt
curl -s https://llm-proxy.genr8ive.ai/v1/models | jq -r '.data[].id' | grep glm
```

### Test a Model

```bash
# Quick test
curl -X POST https://llm-proxy.genr8ive.ai/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"glm-4.7","messages":[{"role":"user","content":"Say hello"}]}'

# With streaming
curl -X POST https://llm-proxy.genr8ive.ai/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemini-3-flash-preview","messages":[{"role":"user","content":"Hello"}],"stream":true}'
```

### Restart Service

```bash
sudo systemctl restart cliproxyapi
```

## Authentication / Adding Accounts

CAPI supports multi-account pools with automatic load balancing. Add accounts to increase rate limits.

```bash
cd ~/.cli-proxy-api

# Google Gemini (OAuth)
cli-proxy-api --login

# OpenAI Codex (OAuth)  
cli-proxy-api --codex-login

# Anthropic Claude (API key)
cli-proxy-api --claude-login
```

**Repeat any login to add more accounts** — CAPI auto-balances across all authenticated accounts.

### OAuth Login from VPS (SSH Tunnel Method)

When running on a VPS, OAuth callbacks go to `localhost:8085`. Use SSH tunnel:

1. **On your laptop**, open tunnel:
   ```bash
   ssh -L 8085:127.0.0.1:8085 dev@5.161.192.198 -p 22
   ```

2. **On VPS**, run login:
   ```bash
   cd ~/.cli-proxy-api && cli-proxy-api --login
   ```

3. **Copy the URL** to your laptop browser, authorize, callback will tunnel through.

## Available Models (Current)

### Anthropic (Claude)
- `claude-opus-4-5-20251101` - Best reasoning
- `claude-sonnet-4-5-20250929` - Fast + capable
- `claude-haiku-4-5-20251001` - Fastest

### Google (Gemini)
- `gemini-3-pro-preview` - Highest capability
- `gemini-3-flash-preview` - Fast + cheap
- `gemini-2.5-pro` - Previous gen pro
- `gemini-2.5-flash` - Previous gen flash

### OpenAI
- `gpt-5.4` - Latest GPT
- `gpt-5.3-codex-spark` - Fast Codex variant
- `gpt-5.2-codex` - Stable Codex model

### Z.AI (GLM)
- `glm-4.7` - Fast coding model (~1000 tps via Cerebras)
- `glm-4.5-air` - Lighter variant

### Other
- `kimi-k2-thinking` - Moonshot reasoning model

## Configuration

### Config File: `~/.cli-proxy-api/config.yaml`

```yaml
port: 8317
auth-dir: "/home/dev/.cli-proxy-api"
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

Set in `~/.bashrc` or `~/.zshrc`:

```bash
# Point clients at CAPI
export OPENAI_API_BASE="https://llm-proxy.genr8ive.ai/v1"
export OPENAI_API_KEY="sk-dummy"  # CAPI doesn't check this

export ANTHROPIC_BASE_URL="https://llm-proxy.genr8ive.ai"
export ANTHROPIC_AUTH_TOKEN="sk-dummy"
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

Daily cron validates model availability:

```bash
# Manual validation
~/.claude/scripts/validate-model-tokens.sh

# View validation log
cat ~/.claude/logs/model-validator.log
```

Alerts via Discord on failures, weekly summary on Mondays.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Model not found | Check available: `curl -s https://llm-proxy.genr8ive.ai/v1/models \| jq -r '.data[].id'` |
| 403 Forbidden | Re-authenticate: `cli-proxy-api --login` |
| 429 Rate limit | Add more accounts (repeat login) |
| Connection refused | Check service: `sudo systemctl status cliproxyapi` |
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

For Claude models with `thinking` or prompt caching, use the Anthropic-native endpoint:

```bash
curl -X POST https://llm-proxy.genr8ive.ai/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: sk-dummy" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-opus-4-5-20251101",
    "max_tokens": 1024,
    "thinking": {"type": "enabled", "budget_tokens": 5000},
    "messages": [{"role": "user", "content": "Explain quantum computing"}]
  }'
```

## Related Files

- Architecture doc: `/home/dev/.claude/docs/architecture/cliproxyapi.md`
- VPS config repo: `~/Dropbox/Projects/cliproxy-vps-config/`
- Test scripts: `~/Dropbox/Projects/cliproxy-vps-config/scripts/test-all-models.sh`

## Compatibility

- `cliproxyapi` is now a redirect alias to this canonical skill.
- Legacy cookbook guidance is available under:
  - `cookbook/authentication.md`
  - `cookbook/configuration.md`
  - `cookbook/sdk-integration.md`
  - `cookbook/service-management.md`

## Contract-First Runtime

- Canonical workflow: `workflow.yaml`
- Generic adapter: `adapters/generic_tool_loop.py`
- Contract tests: `tests/test_contract.py`
- Runtime entrypoint: `python3 ~/.agents/tools/skill_runtime/run_contract.py --contract ~/.agents/skills/capi/workflow.yaml --tool-module-path ~/.agents/skills/capi/adapters/generic_tool_loop.py --input-json '{"request":"route this task"}'`
