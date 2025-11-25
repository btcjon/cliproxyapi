# Factory CLI Configuration for CLIProxyAPI

**Last Updated:** November 15, 2025

This guide shows how to configure Factory CLI to use your CLIProxyAPI setup, giving you access to all 30+ models (Claude, GPT-5/5.1, Gemini, GLM) through Factory's Droid CLI.

---

## Quick Setup

### 1. Install Factory CLI

If you haven't already, install Factory CLI:
```bash
# Follow the 5-minute quickstart
# https://docs.factory.ai/cli/getting-started/quickstart
```

### 2. Configure Factory CLI

Copy the configuration file to Factory CLI's config directory:

```bash
# On your local machine (Mac)
mkdir -p ~/.factory
cp factory-cli-config.json ~/.factory/config.json
```

**Or manually edit `~/.factory/config.json`:**

The configuration file includes all your CLIProxyAPI models organized by provider type:
- **Anthropic provider** (`anthropic`) - For Claude models
- **OpenAI provider** (`openai`) - For GPT-5 and GPT-5.1 models  
- **Generic provider** (`generic-chat-completion-api`) - For Gemini and GLM models

### 3. Configure Base URL

**For local access (if Factory CLI runs on same machine as CLIProxyAPI):**
- Use `http://localhost:8317` for Anthropic models
- Use `http://localhost:8317/v1` for OpenAI and generic models

**For remote access (if Factory CLI runs on different machine):**
- Use `http://5.161.192.198:8317` for Anthropic models
- Use `http://5.161.192.198:8317/v1` for OpenAI and generic models

**To update the base URL in your config:**

```bash
# Replace localhost with your VPS IP if needed
sed -i '' 's|http://localhost:8317|http://5.161.192.198:8317|g' ~/.factory/config.json
```

### 4. Restart Factory CLI

After making configuration changes, restart Factory CLI:

```bash
# Exit any running Droid sessions
# Then start a new session
droid
```

### 5. Select Your Model

In Factory CLI, use the `/model` command to see all available models. Your CLIProxyAPI models will appear in a "Custom models" section.

---

## Configuration Details

### Provider Types

Factory CLI uses different provider types based on the API format:

| Provider | API Format | Models | Base URL |
|----------|------------|--------|----------|
| `anthropic` | Anthropic Messages API | Claude models | `http://localhost:8317` |
| `openai` | OpenAI Responses API | GPT-5, GPT-5.1 | `http://localhost:8317/v1` |
| `generic-chat-completion-api` | OpenAI Chat Completions | Gemini, GLM | `http://localhost:8317/v1` |

### Model Configuration Fields

Each model in the config has these fields:

- **`model_display_name`**: Name shown in Factory CLI model selector
- **`model`**: Model ID used by CLIProxyAPI (e.g., `gpt-5.1`, `claude-sonnet-4-5-20250929`)
- **`base_url`**: CLIProxyAPI endpoint
- **`api_key`**: Use `sk-dummy` (CLIProxyAPI uses OAuth, so any key works)
- **`provider`**: One of `anthropic`, `openai`, or `generic-chat-completion-api`
- **`max_tokens`**: Maximum output tokens (4096 for Claude, 16384 for GPT, 8192 for others)

---

## Available Models

### Claude Models (7 models)
- Claude Sonnet 4.5
- Claude Opus 4.1
- Claude Haiku 4.5
- Claude Sonnet 4
- Claude Opus 4
- Claude Sonnet 3.7
- Claude Haiku 3.5

### GPT-5.1 Models (12 models)
- GPT-5.1 (base)
- GPT-5.1 Codex
- GPT-5.1 Codex High/Medium/Low
- GPT-5.1 Codex Mini
- GPT-5.1 High/Medium/Low

### GPT-5 Models (12 models)
- GPT-5 (base)
- GPT-5 Codex
- GPT-5 Codex High/Medium/Low
- GPT-5 Codex Mini
- GPT-5 High/Medium/Low/Minimal

### Gemini Models (3 models)
- Gemini 2.5 Flash
- Gemini 2.5 Pro
- Gemini 3 Pro Preview

### GLM Models (2 models)
- GLM 4.6
- GLM 4.5 Air

**Total: 36 models available through Factory CLI**

*Note: The configuration file includes all available models. You can remove any models you don't need from the config.*

---

## Usage Examples

### Switch Models in Factory CLI

```bash
# In Droid CLI
/model

# Select from the list:
# - Factory-provided models (top section)
# - Custom models (bottom section) - your CLIProxyAPI models
```

### Recommended Models for Coding

**Best for complex coding:**
- `GPT-5.1 Codex High (CLIProxyAPI)` - Latest with high reasoning
- `Claude Opus 4.1 (CLIProxyAPI)` - Most capable Claude
- `Gemini 2.5 Pro (CLIProxyAPI)` - Fast with good reasoning

**Best for fast iteration:**
- `GPT-5.1 Codex (CLIProxyAPI)` - Fast code generation
- `Gemini 2.5 Flash (CLIProxyAPI)` - Very fast responses
- `Claude Haiku 4.5 (CLIProxyAPI)` - Fast Claude variant

---

## Troubleshooting

### Models Not Appearing

1. **Check JSON syntax:**
   ```bash
   cat ~/.factory/config.json | jq .
   ```
   If this fails, fix JSON syntax errors.

2. **Verify base URL:**
   - For local: `http://localhost:8317`
   - For remote: `http://5.161.192.198:8317`
   - Make sure CLIProxyAPI is accessible from your machine

3. **Restart Factory CLI:**
   - Exit Droid completely
   - Start a new session: `droid`

### Connection Errors

**"Connection refused" or "Cannot connect":**
- Verify CLIProxyAPI is running: `ssh dev@91.98.43.93 "sudo systemctl status cliproxyapi"`
- Check if you need SSH tunnel for remote access
- Verify base URL matches your setup (localhost vs VPS IP)

**"Invalid provider" error:**
- Provider must be exactly: `anthropic`, `openai`, or `generic-chat-completion-api`
- Check for typos in the config file

### Authentication Errors

**"Invalid API key" or "Unauthorized":**
- CLIProxyAPI uses OAuth, so `sk-dummy` should work
- Verify CLIProxyAPI is running and OAuth tokens are valid
- Check CLIProxyAPI logs: `ssh dev@91.98.43.93 "sudo journalctl -u cliproxyapi -n 50"`

### Model Not Responding

**Model times out or returns errors:**
- Check if model is available: `curl http://localhost:8317/v1/models | jq '.data[].id'`
- Verify OAuth tokens are valid (for Claude/Gemini/GPT)
- Check CLIProxyAPI logs for errors

---

## Advanced Configuration

### Using Remote VPS

If Factory CLI runs on a different machine than CLIProxyAPI:

1. **Option A: Use VPS IP directly**
   ```json
   "base_url": "http://5.161.192.198:8317"
   ```
   Requires CLIProxyAPI to allow remote access (already configured).

2. **Option B: Use SSH tunnel (more secure)**
   ```bash
   # Create SSH tunnel
   ssh -L 8317:localhost:8317 -i ~/.ssh/pai_deploy dev@91.98.43.93 -f -N
   
   # Then use localhost in config
   "base_url": "http://localhost:8317"
   ```

### Customizing Model List

Edit `~/.factory/config.json` to:
- Add/remove models
- Change display names
- Adjust `max_tokens` limits
- Modify base URLs

After changes, restart Factory CLI.

### Prompt Caching

Factory CLI automatically uses prompt caching when available:
- **OpenAI provider**: Supports prompt caching via CLIProxyAPI
- **Anthropic provider**: Supports prompt caching via CLIProxyAPI
- **Generic provider**: Caching depends on CLIProxyAPI implementation

Check caching with `/cost` command in Droid CLI.

---

## References

- [Factory CLI BYOK Documentation](https://docs.factory.ai/cli/byok/overview)
- [CLIProxyAPI API Reference](docs/API-REFERENCE.md)
- [CLIProxyAPI Setup](CLAUDE.md)

---

## Configuration File Location

- **Local config**: `~/.factory/config.json`
- **Template**: `factory-cli-config.json` (in this repo)

To update all models, copy the template:
```bash
cp factory-cli-config.json ~/.factory/config.json
```

