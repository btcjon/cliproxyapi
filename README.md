# CLIProxyAPI VPS Configuration

Version-controlled configuration and deployment scripts for CLIProxyAPI on VPS (5.161.192.198).

## What This Repo Contains

- **config/** - CLIProxyAPI configuration files (secrets excluded)
- **systemd/** - Systemd service definitions
- **scripts/** - Build, deployment, and OAuth renewal scripts
- **docs/** - Setup and OAuth documentation

## Quick Start

### VPS Management
```bash
# Deploy updated configuration
./scripts/deploy.sh

# Renew OAuth tokens
./scripts/oauth-renew.sh claude
./scripts/oauth-renew.sh gemini
./scripts/oauth-renew.sh openai

# Rebuild from source
./scripts/build.sh
```

### Cursor Setup (Mac) ⭐ NEW
```bash
# Automated setup
./scripts/setup-cursor-mac.sh

# Or manual setup
export OPENAI_API_BASE="http://localhost:8317/v1"
export OPENAI_API_KEY="sk-dummy"

# Start SSH tunnel
ssh -L 8317:127.0.0.1:8317 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N

# See full guide: docs/CURSOR-SETUP.md
```

## Service Management

```bash
# Check status
sudo systemctl status cli-proxy-api
cliproxy-status  # alias

# View logs
sudo journalctl -u cli-proxy-api -f
cliproxy-logs    # alias

# Restart service
sudo systemctl restart cli-proxy-api
cliproxy-restart # alias
```

## Environment Variables

CLIProxyAPI routing is configured in `~/.bash_profile`:

```bash
ANTHROPIC_BASE_URL=http://localhost:8317
OPENAI_BASE_URL=http://localhost:8317
GOOGLE_AI_BASE_URL=http://localhost:8317
```

## Security Notes

**NEVER commit:**
- OAuth token files (`*.json`)
- Credentials or API keys
- Logs containing sensitive data

See `.gitignore` for full exclusion list.

## Architecture

```
Client Tools → Environment Variables → CLIProxyAPI (port 8317) → OAuth Tokens → AI APIs
```
## List Models Available
`curl localhost:8317/v1/models | jq`

## Endpoints

- **Local**: `http://localhost:8317`
- **Public**: `http://5.161.192.198:8317`
- **Health**: `http://localhost:8317/health`
- **Models**: `http://localhost:8317/v1/models`

## OAuth Token Locations

- Claude: `~/.cli-proxy-api/claude-anthropic@decentral.email.json`
- Gemini: `~/.cli-proxy-api/jonebennett@gmail.com-gen-lang-client-*.json` (2 projects for load balancing)
- OpenAI: `~/.cli-proxy-api/codex-gpt2652@hinedigitals.store.json`

**Note**: Gemini uses **Code Assist API** which provides access to your **AI Ultra subscription benefits** (120 req/min, 2,000 req/day) through CLIProxyAPI.

## Available Models

**OpenAI/Codex (OAuth):** GPT-5, GPT-5.1, and all variants (12 GPT-5.1 models including codex variants with different reasoning levels)

**OpenAI-Compatible Providers:**
- **Cerebras GLM 4.6** - Fast inference
- **Z.AI GLM Coding** - GLM 4.6 and 4.5-air models
- **Baseten Kimi K2 Thinking** (`kimi-k2-thinking`) - Advanced reasoning model from Moonshot AI

**See all models:** `curl localhost:8317/v1/models | jq -r '.data[].id'`

## Documentation

### For Developers
- **[API Reference](docs/API-REFERENCE.md)** ⭐ **NEW** - Complete external API usage guide
  - All available models
  - Request/response formats
  - Code examples in 6+ languages
  - Framework integration (LangChain, LlamaIndex, etc)
- **[Test Results](TEST-RESULTS.md)** ✅ **88% Success** - All 25 models tested
  - 22 working models confirmed
  - Performance benchmarks
  - Recommended models by use case

### Setup & Configuration
- [OAuth Setup & Renewal](docs/OAUTH.md) - Initial setup and token renewal
- [Using Cursor with CLIProxyAPI](docs/CURSOR-SETUP.md) - Cursor integration guide
- [Factory CLI Setup](docs/FACTORY-CLI-SETUP.md) ⭐ **NEW** - Configure Factory CLI to use CLIProxyAPI (36 models)
- [Cursor Agent Integration](docs/CURSOR-AGENT-INTEGRATION.md) - Claude Code + Cursor Agent

### Troubleshooting
- [Configuration Fix Guide](CONFIGURATION-FIXED.md) - Fixing 500 errors & env var conflicts
- [Gemini OAuth Fix](GEMINI-OAUTH-FIX.md) - Custom OAuth client setup
- **Codex CLI 404 Errors** - See below

## Repository Structure

```
cliproxy-vps-config/
├── .gitignore                      # Security-critical exclusions
├── README.md                       # This file
├── CLAUDE.md                       # Claude Code guidance
├── CONFIGURATION-FIXED.md          # Troubleshooting: 500 errors
├── GEMINI-OAUTH-FIX.md            # Troubleshooting: OAuth setup
├── config/
│   └── config.yaml                # CLIProxyAPI config
├── systemd/
│   └── cli-proxy-api.service      # Systemd service definition
├── scripts/
│   ├── build.sh                   # Build from source
│   ├── deploy.sh                  # Deploy config changes
│   ├── oauth-renew.sh             # Renew OAuth tokens
│   ├── verify-config.sh           # Verify setup
│   ├── fix-claude-config.sh       # Fix Mac configuration
│   ├── setup-cursor-mac.sh        # Cursor setup (Mac)
│   ├── setup-gemini-oauth.sh      # Custom OAuth setup
│   └── cursor-agent-mcp-server.js # MCP server for Cursor Agent
└── docs/
    ├── API-REFERENCE.md           # External API usage guide
    ├── OAUTH.md                   # OAuth setup & renewal
    ├── CURSOR-SETUP.md            # Cursor integration
    └── CURSOR-AGENT-INTEGRATION.md # Cursor Agent + Claude Code
```

## Troubleshooting: Codex CLI 404 Errors

**Problem**: Codex CLI gets `404 Not Found` errors when trying to connect.

**Root Cause**: Codex CLI needs to connect directly to OpenAI's servers, but CLIProxyAPI environment variables (`OPENAI_BASE_URL`, `OPENAI_API_BASE`, etc.) redirect it to `localhost:8317`.

**Solution**: A wrapper script at `~/bin/codex` automatically unsets proxy environment variables before calling Codex.

**Setup** (already configured):
- Wrapper script: `~/bin/codex` (unsets proxy vars, calls npm-global codex)
- PATH configured: `~/bin` is prepended to PATH in `~/.bashrc`
- Auto-updates: When Codex is updated via `npm update -g @openai/codex`, wrapper automatically uses new version

**Verification**:
```bash
which codex  # Should show: /home/dev/bin/codex
codex --version  # Should work without 404 errors
```

**If wrapper isn't working**:
1. Check PATH: `echo $PATH | tr ':' '\n' | head -5` (should start with `/home/dev/bin`)
2. Reload shell: `source ~/.bashrc` or open new terminal
3. Verify wrapper exists: `ls -la ~/bin/codex`

## Last Updated

Thu Nov 15 10:45:00 EST 2025 - Added Codex CLI wrapper for proxy bypass

## VPS Details

- **Host**: 5.161.192.198
- **User**: dev
- **Location**: Hetzner US
- **OS**: Debian/Ubuntu
