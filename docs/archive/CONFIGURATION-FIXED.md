# CLIProxyAPI Configuration - Fixed ✓

**Date:** Thu Nov 13, 2025  
**Issue:** 500 errors on Claude API due to conflicting environment variables  
**Status:** RESOLVED on VPS, needs Mac-side fix

---

## What Was Wrong

**The Problem:**
```bash
export ANTHROPIC_DEFAULT_OPUS_MODEL=gpt-5-codex-high
export ANTHROPIC_DEFAULT_SONNET_MODEL=gpt-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=gemini-2.5-flash
```

These variables caused Claude Code to:
1. Request `claude-sonnet` model
2. Get redirected to `gpt-5` 
3. Send request to Claude API endpoint (`/v1/messages`)
4. But `gpt-5` expects OpenAI format → **500 error**

---

## Current Status

### ✅ VPS Side (Fixed)
- Service running properly
- No conflicting variables
- Claude endpoint working
- GPT endpoint working

### ⚠️ Client Side (Needs Your Action)
1. **Remove problematic variables** from your Mac
2. **Renew Gemini OAuth** (expired Nov 9)

---

## Action Required

### 1. Fix Your Mac Configuration

**Run this on your Mac:**
```bash
cd ~/Dropbox/Projects/cliproxy-vps-config
./scripts/fix-claude-config.sh
```

This will:
- Remove `ANTHROPIC_DEFAULT_*` variables
- Set correct API endpoints
- Add helper functions
- Test the connection

### 2. Renew Gemini OAuth

**On your Mac:**
```bash
# Start SSH tunnel
ssh -L 8085:127.0.0.1:8085 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N
```

**In your VPS terminal:**
```bash
cd ~/Dropbox/Projects/cliproxy-vps-config
./scripts/oauth-renew.sh gemini
```

Follow the instructions and open the OAuth URL in your Mac's browser.

---

## Correct Configuration

### Environment Variables (Mac & VPS)

```bash
# Anthropic/Claude API
export ANTHROPIC_API_BASE="http://localhost:8317"
export ANTHROPIC_API_KEY="sk-dummy"

# OpenAI-compatible API (for GPT, Gemini, etc)
export OPENAI_API_BASE="http://localhost:8317/v1"
export OPENAI_API_KEY="sk-dummy"

# Google/Gemini API
export GOOGLE_API_BASE="http://localhost:8317/v1"
export GOOGLE_API_KEY="sk-dummy"

# DO NOT SET THESE (they cause conflicts):
# ❌ ANTHROPIC_DEFAULT_OPUS_MODEL
# ❌ ANTHROPIC_DEFAULT_SONNET_MODEL
# ❌ ANTHROPIC_DEFAULT_HAIKU_MODEL
```

### Model Naming

Use **actual model names** in your requests:

| Model Type | Model Name | Provider |
|-----------|------------|----------|
| Fast AI | `gemini-2.5-flash` | Google (Ultra subscription) |
| Powerful AI | `gemini-2.5-pro` | Google (Ultra subscription) |
| Code | `gpt-5-codex-high` | OpenAI |
| General | `gpt-5` | OpenAI |
| Chat | `claude-sonnet-4-5-20250929` | Anthropic |
| Fast chat | `claude-3-7-sonnet-20250219` | Anthropic |

---

## Verification

### Test Configuration (on VPS)
```bash
cd ~/Dropbox/Projects/cliproxy-vps-config
./scripts/verify-config.sh
```

### Expected Output
```
✓ cli-proxy-api is running
✓ Claude is working
✓ Gemini is working (AI Ultra subscription)
✓ GPT is working
✓ No conflicting ANTHROPIC_DEFAULT_* variables
```

### Test from Mac
```bash
# After running fix-claude-config.sh:
cliproxy-check
```

---

## Benefits After Fix

✅ **No more 500 errors**  
✅ **Models work as expected**  
✅ **Gemini uses your Ultra subscription** (120 req/min, 2,000 req/day)  
✅ **Claude works via OAuth**  
✅ **GPT/Codex available**  
✅ **Proper error messages** instead of silent failures  

---

## Model Usage Guide

### For Code Tasks
- **Best:** `gemini-2.5-flash` (fast, Ultra subscription, free 2000/day)
- **Alternative:** `gpt-5-codex-high` (very capable)
- **Complex:** `claude-sonnet-4-5-20250929` (deep understanding)

### For Chat/Analysis
- **Fast:** `gemini-2.5-flash`
- **Deep:** `claude-sonnet-4-5-20250929`
- **Balanced:** `gpt-5`

### For Reasoning
- **Advanced:** `gemini-2.5-pro`
- **Thinking:** ~~`kimi-k2-thinking`~~ (has tool calling issues with Claude Code)

---

## Files Modified

### VPS
- ✓ `~/.bashrc` - Cleaned (variables already commented out)
- ✓ `~/.cli-proxy-api/` - Removed malformed token

### Mac (After running fix script)
- `~/.zshrc` or `~/.bashrc` - Fixed variables
- `~/.bash_profile` or `~/.zprofile` - Fixed variables

### New Scripts
- `scripts/fix-claude-config.sh` - Mac configuration fix
- `scripts/verify-config.sh` - VPS verification
- `scripts/cursor-agent-mcp-server.js` - Cursor Agent integration

---

## Related Documentation

- [Cursor Setup Guide](docs/CURSOR-SETUP.md)
- [Cursor Agent Integration](docs/CURSOR-AGENT-INTEGRATION.md)
- [OAuth Renewal](docs/OAUTH.md)
- [Main README](README.md)

---

## Support

If you still see 500 errors after following these steps:

1. Check logs: `ssh dev@5.161.192.198 'tail -100 ~/.cli-proxy-api/logs/main.log | grep error'`
2. Verify tunnel: `lsof -i :8317`
3. Test endpoints: `./scripts/verify-config.sh`
4. Restart service: `ssh dev@5.161.192.198 'sudo systemctl restart cli-proxy-api'`

---

**Status:** Ready for client-side fix  
**Next Step:** Run `./scripts/fix-claude-config.sh` on your Mac

