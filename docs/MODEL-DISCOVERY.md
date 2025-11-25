# CLIProxyAPI Model Discovery & Refresh Guide

**Last Updated:** November 15, 2025  
**Issue:** Understanding how CLIProxyAPI discovers models from OAuth providers (Codex, Claude, Gemini) and how to get new models like GPT-5.1

---

## Key Finding: How OAuth Providers Work

### The Critical Insight

**CLIProxyAPI queries OAuth providers (Codex CLI, Claude CLI, Gemini CLI) for available models when the service starts.** It does NOT maintain a static list of models.

### How Model Discovery Works

1. **Service Startup:**
   - CLIProxyAPI reads OAuth token files from `~/.cli-proxy-api/*.json`
   - For each OAuth provider (Codex, Claude, Gemini), it queries the CLI tool for available models
   - Models are registered dynamically based on what the CLI reports

2. **OAuth Provider Types:**
   - **Codex (OpenAI)**: Uses `codex` CLI tool - queries OpenAI API for available models
   - **Claude**: Uses Claude CLI - queries Anthropic API for available models  
   - **Gemini**: Uses Gemini CLI - queries Google AI Studio API for available models

3. **Model Registration:**
   - Models are registered in CLIProxyAPI's internal registry at startup
   - The registry is NOT refreshed automatically while the service is running
   - Unknown models are rejected with: `"unknown provider for model <name>"`

---

## Why GPT-5.1 Isn't Showing Up

### Current Situation

- ✅ **Codex CLI** has GPT-5.1 available (you verified this)
- ❌ **CLIProxyAPI** doesn't see GPT-5.1 yet
- ❌ Calling `gpt-5.1` returns: `"unknown provider for model gpt-5.1"`

### Root Cause

CLIProxyAPI last queried Codex CLI when the service started. If:
1. Codex CLI was updated to see GPT-5.1 **after** CLIProxyAPI started, OR
2. OpenAI released GPT-5.1 **after** the service started

Then CLIProxyAPI won't know about it until it re-queries Codex CLI.

---

## Solution: Refresh Model Discovery

### Option 1: Restart Service (Recommended)

**This is the simplest and most reliable method:**

```bash
# On VPS (Note: service name is 'cliproxyapi', not 'cli-proxy-api')
ssh -i ~/.ssh/pai_deploy dev@91.98.43.93 "sudo systemctl restart cliproxyapi"

# Or use alias (if configured)
ssh -i ~/.ssh/pai_deploy dev@91.98.43.93 "cliproxy-restart"

# Wait a few seconds, then check models
ssh -i ~/.ssh/pai_deploy dev@91.98.43.93 "curl -s http://localhost:8317/v1/models | jq -r '.data[].id' | grep '5.1'"
```

**Note:** Service restart may not be sufficient if CLIProxyAPI has hardcoded model lists. See "Important Discovery" section below.

**What happens:**
- Service stops
- Service starts and re-reads OAuth tokens
- CLIProxyAPI queries Codex CLI for available models
- GPT-5.1 should appear if Codex CLI reports it

### Option 2: Re-authenticate Codex OAuth

**If restart doesn't work, re-authenticate to ensure fresh token:**

```bash
# This will stop service, re-authenticate, then restart
./scripts/oauth-renew.sh openai
```

**What happens:**
- Service stops
- OAuth flow runs (may refresh token)
- Service restarts and queries Codex CLI again

### Option 3: Check Codex CLI Directly

**Verify Codex CLI actually sees GPT-5.1:**

```bash
# On VPS (if codex CLI is installed)
ssh -i ~/.ssh/pai_deploy dev@91.98.43.93 "codex models list | grep -i '5.1'"

# Or check Codex CLI version
ssh -i ~/.ssh/pai_deploy dev@91.98.43.93 "codex --version"
```

**If Codex CLI doesn't see GPT-5.1:**
- Update Codex CLI: `npm update -g @openai/codex-cli` (or however you installed it)
- Then restart CLIProxyAPI

---

## Understanding the Architecture

### Model Discovery Flow

```
┌─────────────────┐
│ CLIProxyAPI     │
│ Service Starts  │
└────────┬────────┘
         │
         ├─→ Reads OAuth tokens from ~/.cli-proxy-api/*.json
         │
         ├─→ For Codex: Queries `codex` CLI → OpenAI API
         ├─→ For Claude: Queries Claude CLI → Anthropic API
         └─→ For Gemini: Queries Gemini CLI → Google AI Studio API
         │
         └─→ Registers all reported models in internal registry
```

### Request Flow

```
Client Request → CLIProxyAPI
                      │
                      ├─→ Check: Is model in registry?
                      │   ├─→ YES: Route to OAuth provider
                      │   └─→ NO: Return "unknown provider for model"
```

### Why No Passthrough?

CLIProxyAPI validates models before routing because:
1. **Security**: Prevents unauthorized model access
2. **Error Handling**: Better error messages for invalid models
3. **Provider Mapping**: Maps model names to correct OAuth providers
4. **Load Balancing**: Routes to correct account/project for multi-account setups

---

## Management API (Future Investigation)

### Current Status

CLIProxyAPI has a management interface at:
- **URL**: `http://localhost:8317/management.html` (or `http://5.161.192.198:8317/management.html`)
- **Config**: `remote-management.allow-remote: true` in `config.yaml`

### Potential Features

The management interface may have:
- Model refresh endpoint (needs verification)
- Client status view
- OAuth token status
- Model list view

**To investigate:**
```bash
# Check management API endpoints
ssh -i ~/.ssh/pai_deploy dev@91.98.43.93 "curl -s http://localhost:8317/management.html | grep -i 'refresh\|reload\|model'"

# Or access via browser
# http://5.161.192.43.93:8317/management.html
```

---

## Best Practices

### When New Models Are Released

1. **Verify Provider CLI Sees New Model:**
   ```bash
   # For Codex
   codex models list | grep <new-model>
   
   # For Claude
   claude models list | grep <new-model>
   
   # For Gemini
   gemini models list | grep <new-model>
   ```

2. **Restart CLIProxyAPI:**
   ```bash
   sudo systemctl restart cli-proxy-api
   # Or
   cliproxy-restart
   ```

3. **Verify Model Appears:**
   ```bash
   curl -s http://localhost:8317/v1/models | jq -r '.data[].id' | grep <new-model>
   ```

4. **Test the Model:**
   ```bash
   curl -s http://localhost:8317/v1/chat/completions \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer sk-dummy" \
     -d '{"model": "<new-model>", "messages": [{"role": "user", "content": "test"}]}'
   ```

### Monitoring Model Availability

**Create a script to check for new models:**

```bash
#!/bin/bash
# scripts/check-new-models.sh

echo "Current models in CLIProxyAPI:"
curl -s http://localhost:8317/v1/models | jq -r '.data[].id' | sort

echo ""
echo "Checking Codex CLI directly:"
codex models list 2>/dev/null | grep -i "gpt" || echo "Codex CLI not available"
```

---

## Troubleshooting

### Model Not Appearing After Restart

1. **Check OAuth Token:**
   ```bash
   ls -la ~/.cli-proxy-api/*codex*.json
   cat ~/.cli-proxy-api/*codex*.json | jq '.expired'
   ```

2. **Check Service Logs:**
   ```bash
   sudo journalctl -u cli-proxy-api -n 50 | grep -i "codex\|model\|error"
   ```

3. **Verify Codex CLI Works:**
   ```bash
   codex models list
   ```

4. **Re-authenticate:**
   ```bash
   ./scripts/oauth-renew.sh openai
   ```

### "Unknown Provider" Error

This means the model is not in CLIProxyAPI's registry. Solutions:
1. Restart service (if provider CLI has the model)
2. Update provider CLI (if it's outdated)
3. Check if model name is correct
4. For API-key providers, add to `config.yaml` manually

---

## Summary

### Key Takeaways

1. ✅ **CLIProxyAPI queries OAuth providers at startup** - models are discovered dynamically
2. ✅ **Restart service to refresh model list** - no automatic refresh while running
3. ✅ **No passthrough mode** - all models must be in registry
4. ⚠️ **OAuth providers may need CLIProxyAPI updates** - not all models are automatically discovered
5. ✅ **API-key providers (Z.AI/Baseten) are static** - must be defined in `config.yaml`

### Important Discovery

**CLIProxyAPI may have hardcoded model lists for OAuth providers.** Even if Codex CLI sees GPT-5.1, CLIProxyAPI might not expose it until:
1. CLIProxyAPI source code is updated to include GPT-5.1 in its model registry
2. CLIProxyAPI binary is rebuilt and redeployed

### For GPT-5.1 Specifically

**✅ RESOLVED (Nov 15, 2025):**
- ✅ GPT-5.1 models are now available (12 variants)
- ✅ Solution: Rebuilt CLIProxyAPI from latest source
- ✅ All GPT-5.1 models are functional and tested

**Available GPT-5.1 Models:**
- `gpt-5.1` - Base model
- `gpt-5.1-codex` - Codex variant
- `gpt-5.1-codex-high` - Codex with high reasoning
- `gpt-5.1-codex-low` - Codex with low reasoning
- `gpt-5.1-codex-medium` - Codex with medium reasoning
- `gpt-5.1-codex-mini` - Codex mini variant
- `gpt-5.1-codex-mini-high` - Codex mini with high reasoning
- `gpt-5.1-codex-mini-medium` - Codex mini with medium reasoning
- `gpt-5.1-high` - High reasoning variant
- `gpt-5.1-low` - Low reasoning variant
- `gpt-5.1-medium` - Medium reasoning variant
- `gpt-5.1-none` - No reasoning variant

**Solution Applied:**
1. Updated `scripts/build.sh` with correct repository URL
2. Rebuilt CLIProxyAPI from latest source (includes GPT-5.1 support)
3. Installed new binary and restarted service
4. Verified all 12 GPT-5.1 models are available and functional

**To Get New Models in Future:**
```bash
# Rebuild from latest source
./scripts/build.sh

# Or manually:
ssh -i ~/.ssh/pai_deploy dev@91.98.43.93 "cd ~/CLIProxyAPI && git pull && /usr/local/go/bin/go build -o cli-proxy-api ./cmd/server"
ssh -i ~/.ssh/pai_deploy dev@91.98.43.93 "sudo systemctl stop cliproxyapi && sudo cp ~/CLIProxyAPI/cli-proxy-api /usr/local/bin/ && sudo systemctl start cliproxyapi"
```

---

## References

- [CLIProxyAPI GitHub](https://github.com/router-for-me/CLIProxyAPI)
- [Management API Documentation](https://github.com/router-for-me/CLIProxyAPI/blob/main/MANAGEMENT_API.md) (if exists)
- Local docs: `docs/API-REFERENCE.md`, `docs/OAUTH.md`

