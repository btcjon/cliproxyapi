# Using Cursor with CLIProxyAPI

This guide shows how to configure Cursor (or any OpenAI-compatible client) to use your CLIProxyAPI instance.

Canonical live-system reference:
- `/home/dev/.agents/docs/architecture/cliproxyapi.md`

Check `/v1/models` before choosing a model. Some historically documented models have been intentionally hidden from the live registry.

## Benefits

- ✅ Use your **Gemini AI Ultra subscription** through Cursor (120 req/min, 2,000 req/day)
- ✅ Access to **Claude, GPT-5, and other models** through one endpoint
- ✅ **Load balancing** across multiple Gemini projects
- ✅ **No API keys needed** - OAuth handled by CLIProxyAPI

## Quick Setup (Mac)

### Option 1: SSH Tunnel (Recommended - Most Secure)

**Step 1: Create SSH Tunnel**
```bash
# Add to ~/.zshrc or ~/.bash_profile for persistence
alias cliproxy-tunnel='ssh -L 8317:127.0.0.1:8317 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N'

# Then run it
cliproxy-tunnel
```

**Step 2: Configure Environment**
```bash
# Add to ~/.zshrc or ~/.bash_profile
export OPENAI_API_BASE="http://localhost:8317/v1"
export OPENAI_API_KEY="sk-dummy"  # Any value works

# For Claude models
export ANTHROPIC_API_BASE="http://localhost:8317"
export ANTHROPIC_API_KEY="sk-dummy"

# Reload shell
source ~/.zshrc  # or source ~/.bash_profile
```

**Step 3: Use in Cursor**
- Cursor will automatically use these environment variables
- Select models from the current `/v1/models` output, for example `gemini-3.1-pro-preview  # PKG2: was Flash; Flash OAuth killed`, `gpt-5.4`, or `claude-sonnet-4-5-20250929`.

### Option 2: Direct Connection (Public IP)

**Configure Environment**
```bash
# Add to ~/.zshrc or ~/.bash_profile
export OPENAI_API_BASE="http://5.161.192.198:8317/v1"
export OPENAI_API_KEY="sk-dummy"

export ANTHROPIC_API_BASE="http://5.161.192.198:8317"
export ANTHROPIC_API_KEY="sk-dummy"
```

⚠️ **Note**: This exposes your proxy publicly. Consider using the SSH tunnel method for better security.

## Testing the Connection

**Test with curl:**
```bash
# List available models
curl http://localhost:8317/v1/models | jq '.data[] | .id'

# Test chat completion
curl http://localhost:8317/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-3.1-pro-preview  # PKG2: was Flash; Flash OAuth killed",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 20
  }'
```

**Test with Python:**
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-dummy",
    base_url="http://localhost:8317/v1"
)

response = client.chat.completions.create(
    model="gemini-3.1-pro-preview  # PKG2: was Flash; Flash OAuth killed",
    messages=[{"role": "user", "content": "Hello from Cursor!"}]
)

print(response.choices[0].message.content)
```

## Available Models for Cursor

### ⭐ Recommended for Coding

**Gemini**
- `gemini-3.1-pro-preview  # PKG2: was Flash; Flash OAuth killed` - Fast, strong default
- `gemini-2.5-pro` - More capable, deeper reasoning

**Claude (OAuth)**
- `claude-sonnet-4-5-20250929` - Excellent for coding
- `claude-3-7-sonnet-20250219` - Fast and capable
- `claude-opus-4-1-20250805` - Most powerful

**OpenAI GPT / Codex (OAuth)**
- `gpt-5.4` - Strong current default
- `gpt-5-codex` - Code generation
- `gpt-5.3-codex-spark` - Faster coding lane

### Not Recommended for Cursor

❌ `kimi-k2-thinking` - Reasoning model without proper tool support (use for analysis only)

## Troubleshooting

### "Connection refused"
```bash
# Check if tunnel is running
lsof -i :8317

# Restart tunnel
pkill -f "ssh.*8317" ; cliproxy-tunnel
```

### "404 Not Found"
Ensure you're using `/v1` in the base URL:
- ✅ `http://localhost:8317/v1`
- ❌ `http://localhost:8317`

### "Invalid API Key"
CLIProxyAPI doesn't validate API keys - any value works:
```bash
export OPENAI_API_KEY="sk-dummy"
```

### Check Service Status (on VPS)
```bash
ssh -i ~/.ssh/pai_deploy dev@5.161.192.198
sudo systemctl status cliproxyapi
cliproxy-logs  # View live logs
```

## Advanced Configuration

### Multiple Endpoints for Different Models

```bash
# Gemini models via Google endpoint
export GOOGLE_API_BASE="http://localhost:8317/v1"
export GOOGLE_API_KEY="sk-dummy"

# Claude models via Anthropic endpoint
export ANTHROPIC_API_BASE="http://localhost:8317"
export ANTHROPIC_API_KEY="sk-dummy"

# OpenAI models via OpenAI endpoint
export OPENAI_API_BASE="http://localhost:8317/v1"
export OPENAI_API_KEY="sk-dummy"
```

### Cursor-Specific Configuration

If Cursor has a settings file (e.g., `~/.cursor/config.json`):
```json
{
  "openai": {
    "apiBase": "http://localhost:8317/v1",
    "apiKey": "sk-dummy"
  },
  "anthropic": {
    "apiBase": "http://localhost:8317",
    "apiKey": "sk-dummy"
  }
}
```

## Usage Examples

### In Cursor Chat
```
Use model: gemini-3.1-pro-preview  # PKG2: was Flash; Flash OAuth killed
Prompt: "Refactor this function to use async/await"
```

### In Terminal (via Cursor Agent)
```bash
cursor agent --model gemini-3.1-pro-preview  # PKG2: was Flash; Flash OAuth killed "Add error handling to all API calls"
```

### Via Python Script
```python
from openai import OpenAI

# Automatically uses environment variables
client = OpenAI()

response = client.chat.completions.create(
    model="gemini-3.1-pro-preview  # PKG2: was Flash; Flash OAuth killed",
    messages=[{
        "role": "user",
        "content": "Generate a React component for a login form"
    }],
    temperature=0.7,
    max_tokens=2000
)

print(response.choices[0].message.content)
```

## Performance Tips

1. **Use Gemini 3 Flash Preview for most tasks** - fast and broadly reliable in this setup
2. **Use Claude Sonnet for complex coding** - better at long-context reasoning via `/v1/messages`
3. **Use GPT-5.4 or Codex variants for code-heavy work** - strong OpenAI OAuth lane
4. **Enable streaming** - Add `stream=True` for faster perceived response times

## Security Best Practices

1. ✅ Use SSH tunnel instead of public IP when possible
2. ✅ Keep CLIProxyAPI remote management secret secure
3. ✅ Don't commit OAuth tokens to git (already in `.gitignore`)
4. ✅ Regularly rotate OAuth tokens via `./scripts/oauth-renew.sh`

## Related Documentation

- [OAuth Renewal](OAUTH.md) - How to renew expired tokens
- [Main README](../README.md) - Full CLIProxyAPI documentation
- [Service Management](SETUP.md) - VPS service configuration

---

**Last Updated**: Thu Nov 13 13:15:00 EST 2025
