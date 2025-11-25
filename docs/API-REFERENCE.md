# CLIProxyAPI - External Usage Guide

**Version:** 1.0  
**Last Updated:** November 13, 2025  
**Base URL:** `http://5.161.192.198:8317`

A unified API gateway providing access to multiple AI models (Gemini, Claude, GPT, GLM, Kimi) through OpenAI and Anthropic-compatible endpoints.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Available Models](#available-models)
- [API Endpoints](#api-endpoints)
- [Authentication](#authentication)
- [Request Formats](#request-formats)
- [Response Formats](#response-formats)
- [Code Examples](#code-examples)
- [Framework Integration](#framework-integration)
- [Error Handling](#error-handling)
- [Rate Limits](#rate-limits)
- [Security](#security)

---

## Quick Start

### 1. Test Connection

```bash
curl http://5.161.192.198:8317/v1/models
```

### 2. Make Your First Request

```bash
curl http://5.161.192.198:8317/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{
    "model": "gemini-2.5-flash",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### 3. Use in Your Code

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-dummy",
    base_url="http://5.161.192.198:8317/v1"
)

response = client.chat.completions.create(
    model="gemini-2.5-flash",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

---

## Available Models

### Google Gemini (AI Ultra Subscription)

**Best for:** Fast responses, coding, general tasks  
**Quota:** 120 req/min, 2,000 req/day (AI Ultra subscription)  
**Endpoint:** `/v1/chat/completions`

| Model | Context | Best Use | Cost |
|-------|---------|----------|------|
| `gemini-2.5-flash` | 1M tokens | Fast, general purpose, coding | Free (Ultra) |
| `gemini-2.5-pro` | 2M tokens | Complex reasoning, deep analysis | Free (Ultra) |
| `gemini-3-pro-preview-11-2025` | 2M tokens | Latest preview features | Free (Ultra) |

**Example:**
```json
{
  "model": "gemini-2.5-flash",
  "messages": [{"role": "user", "content": "Your prompt"}],
  "temperature": 0.7,
  "max_tokens": 2000
}
```

---

### Anthropic Claude

**Best for:** Complex reasoning, writing, code understanding  
**Quota:** OAuth account limits  
**Endpoint:** `/v1/messages`

| Model | Context | Best Use | Notes |
|-------|---------|----------|-------|
| `claude-sonnet-4-5-20250929` | 200K | Balanced performance | Recommended |
| `claude-opus-4-1-20250805` | 200K | Most capable | Slower |
| `claude-3-7-sonnet-20250219` | 200K | Fast responses | Good balance |
| `claude-haiku-4-5-20251001` | 200K | Fast, lightweight | Cost-effective |
| `claude-3-5-haiku-20241022` | 200K | Very fast | Simple tasks |

**Example:**
```json
{
  "model": "claude-sonnet-4-5-20250929",
  "messages": [{"role": "user", "content": "Your prompt"}],
  "max_tokens": 4096,
  "temperature": 1.0
}
```

**Note:** Claude requires additional header:
```
anthropic-version: 2023-06-01
```

---

### OpenAI GPT/Codex

**Best for:** Code generation, general chat  
**Quota:** OAuth account limits  
**Endpoint:** `/v1/chat/completions`

| Model | Best Use |
|-------|----------|
| `gpt-5` | General purpose |
| `gpt-5-minimal` | Fast responses |
| `gpt-5-low` | Basic tasks |
| `gpt-5-medium` | Balanced |
| `gpt-5-high` | Complex tasks |
| `gpt-5-codex` | Code generation |
| `gpt-5-codex-low` | Simple code |
| `gpt-5-codex-medium` | Balanced coding |
| `gpt-5-codex-high` | Complex code |
| `gpt-5-codex-mini` | Fast code snippets |
| `gpt-5-codex-mini-medium` | Medium code |
| `gpt-5-codex-mini-high` | Advanced snippets |

**Example:**
```json
{
  "model": "gpt-5-codex-high",
  "messages": [{"role": "user", "content": "Write a sorting algorithm"}],
  "temperature": 0.2
}
```

---

### Z.AI GLM (Coding Plan)

**Best for:** Code generation, Chinese language  
**Quota:** API key limits  
**Endpoint:** `/v1/chat/completions`

| Model | Best Use |
|-------|----------|
| `glm-4.6` | Advanced coding, reasoning |
| `glm-4.5-air` | Fast responses |

**Example:**
```json
{
  "model": "glm-4.6",
  "messages": [{"role": "user", "content": "Create a REST API"}],
  "temperature": 0.7
}
```

---

### Baseten Kimi K2 Thinking

**Best for:** Deep reasoning, analysis (not coding with tools)  
**Quota:** API key limits  
**Endpoint:** `/v1/chat/completions`

| Model | Context | Best Use | Notes |
|-------|---------|----------|-------|
| `kimi-k2-thinking` | 128K | Reasoning, analysis | Shows thinking process |

**Example:**
```json
{
  "model": "kimi-k2-thinking",
  "messages": [{"role": "user", "content": "Analyze this problem..."}],
  "max_tokens": 1000
}
```

**Note:** Returns thinking process in `<think>` tags. Not suitable for tool-calling applications.

---

## API Endpoints

### 1. List Models

**Endpoint:** `GET /v1/models`

**Response:**
```json
{
  "data": [
    {
      "id": "gemini-2.5-flash",
      "object": "model",
      "created": 1699564800,
      "owned_by": "google"
    }
  ]
}
```

### 2. Chat Completions (OpenAI-compatible)

**Endpoint:** `POST /v1/chat/completions`

**Models:** Gemini, GPT, GLM, Kimi

**Headers:**
```
Content-Type: application/json
Authorization: Bearer sk-dummy
```

**Request Body:**
```json
{
  "model": "gemini-2.5-flash",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant"},
    {"role": "user", "content": "Hello"}
  ],
  "temperature": 0.7,
  "max_tokens": 2000,
  "stream": false
}
```

**Response:**
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1699564800,
  "model": "gemini-2.5-flash",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! How can I help you today?"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 9,
    "total_tokens": 19
  }
}
```

### 3. Messages (Claude/Anthropic)

**Endpoint:** `POST /v1/messages`

**Models:** Claude only

**Headers:**
```
Content-Type: application/json
anthropic-version: 2023-06-01
```

**Request Body:**
```json
{
  "model": "claude-sonnet-4-5-20250929",
  "messages": [
    {"role": "user", "content": "Hello"}
  ],
  "max_tokens": 1024
}
```

**Response:**
```json
{
  "id": "msg_01ABC",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "Hello! How can I assist you today?"
    }
  ],
  "model": "claude-sonnet-4-5-20250929",
  "stop_reason": "end_turn",
  "usage": {
    "input_tokens": 10,
    "output_tokens": 25
  }
}
```

---

## Authentication

**API Key:** Any value works (e.g., `sk-dummy`)

The proxy handles authentication to the underlying services via OAuth tokens. Your requests only need a dummy key for compatibility with OpenAI/Anthropic clients.

**Examples:**
```bash
# Header format
Authorization: Bearer sk-dummy

# Or via SDK
api_key="sk-dummy"
```

---

## Request Formats

### Standard Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | string | **required** | Model identifier |
| `messages` | array | **required** | Conversation history |
| `temperature` | float | 1.0 | Randomness (0.0-2.0) |
| `max_tokens` | integer | varies | Max response length |
| `top_p` | float | 1.0 | Nucleus sampling |
| `stream` | boolean | false | Stream responses |
| `stop` | string/array | null | Stop sequences |

### Message Format

```json
{
  "role": "system|user|assistant",
  "content": "Message text"
}
```

**Roles:**
- `system`: System instructions (optional)
- `user`: User messages
- `assistant`: AI responses (for multi-turn)

### Streaming

**Enable streaming:**
```json
{
  "model": "gemini-2.5-flash",
  "messages": [...],
  "stream": true
}
```

**Response format:** Server-Sent Events (SSE)
```
data: {"choices":[{"delta":{"content":"Hello"}}]}

data: {"choices":[{"delta":{"content":" there"}}]}

data: [DONE]
```

---

## Response Formats

### Success Response

**OpenAI Format:**
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1699564800,
  "model": "gemini-2.5-flash",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Response text"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  }
}
```

**Finish Reasons:**
- `stop`: Natural completion
- `length`: Max tokens reached
- `content_filter`: Content filtered
- `tool_calls`: Function calling (if enabled)

---

## Code Examples

### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-dummy",
    base_url="http://5.161.192.198:8317/v1"
)

# Basic completion
response = client.chat.completions.create(
    model="gemini-2.5-flash",
    messages=[
        {"role": "system", "content": "You are a helpful coding assistant"},
        {"role": "user", "content": "Write a Python hello world"}
    ],
    temperature=0.7,
    max_tokens=500
)

print(response.choices[0].message.content)

# Streaming
stream = client.chat.completions.create(
    model="gemini-2.5-flash",
    messages=[{"role": "user", "content": "Count to 10"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

### Python (Anthropic SDK)

```python
from anthropic import Anthropic

client = Anthropic(
    api_key="sk-dummy",
    base_url="http://5.161.192.198:8317"
)

response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Explain quantum computing"}
    ]
)

print(response.content[0].text)
```

### JavaScript/TypeScript

```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  apiKey: 'sk-dummy',
  baseURL: 'http://5.161.192.198:8317/v1'
});

async function main() {
  const completion = await client.chat.completions.create({
    model: 'gemini-2.5-flash',
    messages: [
      { role: 'user', content: 'Write a TypeScript function' }
    ]
  });

  console.log(completion.choices[0].message.content);
}

main();
```

### cURL

```bash
# OpenAI-compatible models
curl http://5.161.192.198:8317/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-dummy" \
  -d '{
    "model": "gemini-2.5-flash",
    "messages": [
      {"role": "user", "content": "Hello"}
    ],
    "max_tokens": 100
  }'

# Claude models
curl http://5.161.192.198:8317/v1/messages \
  -H "Content-Type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -H "x-api-key: sk-dummy" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "messages": [
      {"role": "user", "content": "Hello"}
    ],
    "max_tokens": 100
  }'
```

### Go

```go
package main

import (
    "context"
    "fmt"
    openai "github.com/sashabaranov/go-openai"
)

func main() {
    config := openai.DefaultConfig("sk-dummy")
    config.BaseURL = "http://5.161.192.198:8317/v1"
    client := openai.NewClientWithConfig(config)

    resp, err := client.CreateChatCompletion(
        context.Background(),
        openai.ChatCompletionRequest{
            Model: "gemini-2.5-flash",
            Messages: []openai.ChatCompletionMessage{
                {
                    Role:    openai.ChatMessageRoleUser,
                    Content: "Write a Go function",
                },
            },
        },
    )

    if err != nil {
        fmt.Printf("Error: %v\n", err)
        return
    }

    fmt.Println(resp.Choices[0].Message.Content)
}
```

### Rust

```rust
use reqwest;
use serde_json::json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    
    let res = client
        .post("http://5.161.192.198:8317/v1/chat/completions")
        .header("Content-Type", "application/json")
        .header("Authorization", "Bearer sk-dummy")
        .json(&json!({
            "model": "gemini-2.5-flash",
            "messages": [
                {"role": "user", "content": "Write a Rust function"}
            ]
        }))
        .send()
        .await?
        .json::<serde_json::Value>()
        .await?;

    println!("{}", res["choices"][0]["message"]["content"]);
    Ok(())
}
```

---

## Framework Integration

### LangChain (Python)

```python
from langchain.chat_models import ChatOpenAI
from langchain.schema import HumanMessage, SystemMessage

llm = ChatOpenAI(
    model_name="gemini-2.5-flash",
    openai_api_base="http://5.161.192.198:8317/v1",
    openai_api_key="sk-dummy",
    temperature=0.7
)

messages = [
    SystemMessage(content="You are a coding assistant"),
    HumanMessage(content="Write a Python class for a user")
]

response = llm(messages)
print(response.content)
```

### LangChain (JavaScript)

```javascript
import { ChatOpenAI } from "langchain/chat_models/openai";
import { HumanMessage, SystemMessage } from "langchain/schema";

const model = new ChatOpenAI({
  modelName: "gemini-2.5-flash",
  openAIApiKey: "sk-dummy",
  configuration: {
    basePath: "http://5.161.192.198:8317/v1"
  }
});

const messages = [
  new SystemMessage("You are a helpful assistant"),
  new HumanMessage("Hello!")
];

const response = await model.call(messages);
console.log(response.content);
```

### LlamaIndex

```python
from llama_index.llms import OpenAI
from llama_index import ServiceContext, VectorStoreIndex

llm = OpenAI(
    model="gemini-2.5-flash",
    api_base="http://5.161.192.198:8317/v1",
    api_key="sk-dummy"
)

service_context = ServiceContext.from_defaults(llm=llm)

# Use in your index
index = VectorStoreIndex.from_documents(
    documents,
    service_context=service_context
)
```

### Semantic Kernel

```csharp
using Microsoft.SemanticKernel;

var kernel = Kernel.Builder
    .WithOpenAIChatCompletionService(
        modelId: "gemini-2.5-flash",
        apiKey: "sk-dummy",
        endpoint: new Uri("http://5.161.192.198:8317/v1")
    )
    .Build();

var result = await kernel.InvokeSemanticFunctionAsync(
    "Write a C# function",
    maxTokens: 500
);

Console.WriteLine(result);
```

### Haystack

```python
from haystack.nodes import PromptNode

prompt_node = PromptNode(
    model_name_or_path="gemini-2.5-flash",
    api_key="sk-dummy",
    model_kwargs={
        "api_base": "http://5.161.192.198:8317/v1"
    }
)

result = prompt_node("Write a Python function")
print(result[0])
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 400 | Bad request | Check request format |
| 401 | Unauthorized | Check API key (should work with any value) |
| 429 | Rate limited | Wait and retry |
| 500 | Server error | Retry with backoff |
| 502 | Bad gateway | Service temporarily down |
| 503 | Service unavailable | Retry later |

### Error Response Format

```json
{
  "error": {
    "message": "Invalid request",
    "type": "invalid_request_error",
    "code": "invalid_model"
  }
}
```

### Common Errors

**Model not found:**
```json
{
  "error": {
    "message": "unknown provider for model xyz",
    "type": "invalid_request_error"
  }
}
```
**Solution:** Check model name spelling

**Rate limit exceeded:**
```json
{
  "error": {
    "message": "Rate limit exceeded",
    "type": "rate_limit_error"
  }
}
```
**Solution:** Implement exponential backoff

**Token quota exceeded:**
```json
{
  "error": {
    "message": "Token quota exceeded",
    "type": "quota_exceeded"
  }
}
```
**Solution:** Reduce max_tokens or wait for quota reset

### Retry Strategy

```python
import time
from openai import OpenAI

def make_request_with_retry(client, model, messages, max_retries=3):
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model=model,
                messages=messages
            )
            return response
        except Exception as e:
            if attempt < max_retries - 1:
                wait_time = (2 ** attempt) + 1  # Exponential backoff
                print(f"Retry {attempt + 1} after {wait_time}s...")
                time.sleep(wait_time)
            else:
                raise e
```

---

## Rate Limits

### By Provider

| Provider | Rate Limit | Daily Limit | Notes |
|----------|------------|-------------|-------|
| **Gemini** | 120 req/min | 2,000 req/day | AI Ultra subscription |
| **Claude** | Varies | Varies | Based on OAuth account |
| **GPT** | Varies | Varies | Based on OAuth account |
| **GLM** | Varies | Varies | Based on API key |
| **Kimi** | Varies | Varies | Based on API key |

### Best Practices

1. **Implement rate limiting** in your client
2. **Use exponential backoff** on errors
3. **Cache responses** when possible
4. **Batch requests** for efficiency
5. **Monitor usage** via proxy logs

### Example Rate Limiter

```python
import time
from threading import Lock

class RateLimiter:
    def __init__(self, requests_per_minute):
        self.requests_per_minute = requests_per_minute
        self.min_interval = 60.0 / requests_per_minute
        self.last_request = 0
        self.lock = Lock()
    
    def wait_if_needed(self):
        with self.lock:
            elapsed = time.time() - self.last_request
            if elapsed < self.min_interval:
                time.sleep(self.min_interval - elapsed)
            self.last_request = time.time()

# Usage
limiter = RateLimiter(requests_per_minute=100)

for prompt in prompts:
    limiter.wait_if_needed()
    response = client.chat.completions.create(...)
```

---

## Security

### Current Setup

- ✅ OAuth tokens stored securely on VPS
- ⚠️ Port 8317 is **publicly accessible**
- ⚠️ No authentication required (dummy key accepted)

### Recommendations

#### 1. Use SSH Tunnel (Recommended)

**On your local machine:**
```bash
ssh -L 8317:127.0.0.1:8317 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N
```

**Then connect to:**
```
http://localhost:8317/v1/...
```

**Benefits:**
- ✅ Encrypted connection
- ✅ Not publicly accessible
- ✅ SSH authentication required

#### 2. IP Whitelist (VPS Firewall)

```bash
# On VPS
sudo ufw allow from YOUR_IP to any port 8317
sudo ufw deny 8317
```

#### 3. Reverse Proxy with Auth (Advanced)

```nginx
# nginx config
location /v1/ {
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://localhost:8317;
}
```

### Data Privacy

- ✅ Requests are proxied through your VPS
- ✅ OAuth tokens never leave your VPS
- ⚠️ Traffic between client and VPS is unencrypted (HTTP)
- 💡 Consider setting up HTTPS with Let's Encrypt

---

## Additional Resources

- **Main Documentation:** [README.md](../README.md)
- **OAuth Setup:** [OAUTH.md](OAUTH.md)
- **Cursor Integration:** [CURSOR-SETUP.md](CURSOR-SETUP.md)
- **Troubleshooting:** [CONFIGURATION-FIXED.md](../CONFIGURATION-FIXED.md)

---

## Support & Contact

**Repository:** `cliproxy-vps-config`  
**VPS Host:** 5.161.192.198  
**Service Port:** 8317

**Quick Help:**
```bash
# Check service status
ssh dev@5.161.192.198 'sudo systemctl status cli-proxy-api'

# View logs
ssh dev@5.161.192.198 'tail -100 ~/.cli-proxy-api/logs/main.log'

# Verify configuration
ssh dev@5.161.192.198 'bash -s' < scripts/verify-config.sh
```

---

**Version 1.0** - November 13, 2025

