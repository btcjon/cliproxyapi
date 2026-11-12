# CLIProxyAPI API Reference

This file is a practical usage guide for the live VPS deployment.

Canonical live-system reference:
- `/home/dev/.agents/docs/architecture/cliproxyapi.md`

Use that architecture doc as the source of truth for:
- current version
- current model registry
- current auth topology
- hidden / removed models
- quarantined auth files
- current routing and parity decisions

## Base URLs

- Public: `https://llm-proxy.genr8ive.ai`
- Local: `http://localhost:8317`

## Routes

| Route | Use for |
|------|---------|
| `GET /v1/models` | List exposed models |
| `POST /v1/chat/completions` | GPT, Gemini, GLM, Kimi |
| `POST /v1/responses` | GPT workloads where OpenAI caching matters |
| `POST /v1/messages` | Claude |

## Authentication

Client requests use dummy keys for compatibility:

```bash
Authorization: Bearer sk-dummy
```

For Anthropic-native requests:

```bash
x-api-key: sk-dummy
anthropic-version: 2023-06-01
```

The proxy handles real upstream auth internally through OAuth-backed accounts for Claude, OpenAI, and Gemini.

## Important Routing Rules

- Use `POST /v1/messages` for Claude.
- Use `POST /v1/chat/completions` for Gemini, GPT, GLM, and Kimi.
- Use `POST /v1/responses` for GPT cache-sensitive workloads.
- Do not assume every historically documented model is still exposed. Check `/v1/models`.

## Quick Start

### List models

```bash
curl -s https://llm-proxy.genr8ive.ai/v1/models | jq -r '.data[].id'
```

### Claude

```bash
curl -s https://llm-proxy.genr8ive.ai/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: sk-dummy" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 128,
    "messages": [{"role": "user", "content": "Reply with exactly CLAUDE_OK"}]
  }'
```

### GPT / OpenAI-compatible

```bash
curl -s https://llm-proxy.genr8ive.ai/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{
    "model": "gpt-5.4",
    "messages": [{"role": "user", "content": "Reply with exactly GPT_OK"}]
  }'
```

### Gemini

```bash
curl -s https://llm-proxy.genr8ive.ai/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{
    "model": "gemini-3-flash-preview",
    "messages": [{"role": "user", "content": "Reply with exactly GEMINI_OK"}]
  }'
```

### OpenAI Responses API

```bash
curl -s https://llm-proxy.genr8ive.ai/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{
    "model": "gpt-5.4",
    "prompt_cache_key": "example-cache-key",
    "input": "Reply with exactly RESPONSES_OK"
  }'
```

## SDK Examples

### OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-dummy",
    base_url="https://llm-proxy.genr8ive.ai/v1",
)

resp = client.chat.completions.create(
    model="gpt-5.4",
    messages=[{"role": "user", "content": "Hello"}],
)
print(resp.choices[0].message.content)
```

### Anthropic SDK

```python
import anthropic

client = anthropic.Anthropic(
    api_key="sk-dummy",
    base_url="https://llm-proxy.genr8ive.ai",
)

resp = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=128,
    messages=[{"role": "user", "content": "Hello"}],
)
print(resp.content[0].text)
```

## Notes

- This deployment is intentionally OAuth-first for Claude, OpenAI, and Gemini.
- Obsolete models have been hidden from the live registry.
- Dead or duplicate auth files have been quarantined to improve parity and reduce routing churn.

## Last Refresh

Reconciled against the live VPS deployment on `2026-03-28`.
