> Compatibility examples, not a live health claim. `sk-dummy` is loopback-only. Public `llm-proxy.genr8ive.ai` requires the configured inbound key. Re-check `/v1/models` before using any model id.

# SDK Integration

Default to the public HTTPS CAPI endpoint unless the task explicitly needs local-only access. Re-check `/v1/models` before choosing model IDs; CAPI's catalog changes often. Do not put the inbound key in a shared file or command line.

## Python SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://llm-proxy.genr8ive.ai/v1",
    api_key="CONFIGURED_INBOUND_KEY",  # public endpoint; loopback may use sk-dummy
)

response = client.chat.completions.create(
    model="glm-5",
    messages=[{"role": "user", "content": "Hello"}],
)
```

Local equivalent:

```python
client = OpenAI(base_url="http://127.0.0.1:8317/v1", api_key="sk-dummy")
```

## TypeScript SDK

```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'https://llm-proxy.genr8ive.ai/v1',
  apiKey: 'CONFIGURED_INBOUND_KEY', // public endpoint; loopback may use sk-dummy
});

const response = await client.chat.completions.create({
  model: 'glm-5',
  messages: [{ role: 'user', content: 'Hello' }],
});
```

## Environment Variables

```bash
# OpenAI-compatible clients
export OPENAI_API_BASE="https://llm-proxy.genr8ive.ai/v1"
export OPENAI_API_KEY="CONFIGURED_INBOUND_KEY"  # public; do not use sk-dummy off loopback

# Anthropic-native clients when using CAPI /v1/messages
export ANTHROPIC_BASE_URL="https://llm-proxy.genr8ive.ai"
export ANTHROPIC_AUTH_TOKEN="CONFIGURED_INBOUND_KEY"  # public; Claude proxy remains policy-off unless explicitly reversed
```

Avoid setting global shell environment variables unless the user asked for a persistent routing change. Prefer per-command env vars for tests.

## Query Models by Provider

Run from the explicitly selected CAPI package root. These are read-only catalog requests; completion SDK calls above consume provider quota. Set `CAPI_URL` to the selected endpoint and load `CAPI_API_KEY` or `CAPI_API_KEY_FILE` privately; public endpoints require the configured inbound key. The helper sends authentication through curl's stdin configuration.

```bash
set -euo pipefail
source scripts/capi-common.sh
# All model IDs
bash scripts/capi-models.sh

# Owner metadata requires raw catalog JSON, not ID-only helper output.
capi_request /v1/models \
  | jq -r '.data | group_by(.owned_by // "unknown") | .[] | "\(.[0].owned_by // "unknown"): \(length) models"'

# Preserve the substring filter on model IDs.
capi_request /v1/models \
  | jq -r '.data[] | select(.id | contains("opus")) | .id'
```
