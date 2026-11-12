## Project Overview

This repository manages the configuration and deployment of `CLIProxyAPI` on a VPS. The CLIProxyAPI acts as a unified AI API proxy that routes requests to **25+ AI models** across multiple providers (Anthropic Claude, Google Gemini, OpenAI, Cerebras, Z.AI, Baseten) using OAuth authentication.

**Architecture Flow:**
```
Client Tools → Environment Variables → CLIProxyAPI (port 8317) → OAuth Tokens → AI APIs
External Apps → VPS IP:8317 → CLIProxyAPI → OAuth Tokens → AI APIs
```

**Key Capabilities:**
- 🔐 OAuth-based authentication (no API keys needed for Claude/Gemini)
- 🌐 External API access from any application/device
- 🎯 OpenAI-compatible endpoints for all models
- 💎 Gemini Ultra subscription benefits (120 req/min, 2,000 req/day)
- ⚖️ Load balancing across multiple Gemini projects
- 🧪 Comprehensive testing and verification scripts

## Common Commands

### Building and Deployment
```bash
# Build CLIProxyAPI from source (clones repo, builds Go binary, installs to /usr/local/bin)
./scripts/build.sh

# Deploy configuration and restart service
./scripts/deploy.sh

# Renew OAuth tokens for specific provider (script auto-stops/starts service)
./scripts/oauth-renew.sh [claude|gemini|openai]
```

### Testing and Verification
```bash
# Comprehensive configuration health check
./scripts/verify-config.sh

# Test all 25+ models with live API calls
./scripts/test-all-models.sh

# Test external API access (for remote clients)
./scripts/test-external-api.sh
```

### Service Management
```bash
# Check service status
sudo systemctl status cliproxyapi  # Note: service name is 'cliproxyapi'

# View live logs
sudo journalctl -u cliproxyapi -f

# Restart service
sudo systemctl restart cliproxyapi

# Reload systemd after service file changes
sudo systemctl daemon-reload
```

### Convenience Aliases (defined in ~/.bashrc)
```bash
cliproxy-status    # Check service status
cliproxy-logs      # View live logs
cliproxy-restart   # Restart service
cliproxy-test      # Test API endpoint
cliproxy-health    # Health check
```

## Repository Structure

- **config/** - `config.yaml` for CLIProxyAPI (port, auth-dir, remote management, OpenAI compatibility mappings)
- **systemd/** - Service definition for systemd (`cli-proxy-api.service`)
- **scripts/** - Automation scripts for build, deploy, OAuth renewal, testing, and verification
- **docs/** - Comprehensive documentation:
  - `OAUTH.md` - OAuth setup and renewal guide
  - `API-REFERENCE.md` - Developer guide for external API usage (all 25+ models)
  - `MODEL-DISCOVERY.md` - How CLIProxyAPI discovers models from OAuth providers
  - `CURSOR-AGENT-INTEGRATION.md` - Cursor IDE integration with MCP server
  - `CURSOR-SETUP.md` - Cursor configuration for Mac clients

## Key Configuration

### Main Config Location
- **Deployed config**: `~/.cli-proxy-api/config.yaml`
- **Source config**: `config/config.yaml`
- **OAuth tokens**: `~/.cli-proxy-api/` (managed by CLIProxyAPI)
- **Service logs**: `~/.cli-proxy-api/logs/`

### Environment Variables (in ~/.bashrc)
```bash
# Primary API endpoints (use with dummy keys for OAuth models)
export ANTHROPIC_API_BASE="http://localhost:8317"
export OPENAI_API_BASE="http://localhost:8317/v1"
export GOOGLE_API_BASE="http://localhost:8317/v1"

# Dummy keys for OAuth-authenticated models (Claude, Gemini)
export ANTHROPIC_API_KEY="sk-dummy"
export OPENAI_API_KEY="sk-dummy"
export GOOGLE_API_KEY="sk-dummy"

# Actual API keys for key-based providers
export BASETEN_API_KEY="<your-key>"  # For Kimi K2 Thinking model

# External access (replace localhost with VPS IP for remote clients)
# Example: export ANTHROPIC_API_BASE="http://5.161.192.198:8317"
```

**Note**: Codex CLI has a wrapper at `~/bin/codex` that automatically unsets these proxy variables, allowing Codex to connect directly to OpenAI. The wrapper is automatically used when you run `codex` (PATH is configured in `~/.bashrc`).

## Architecture Details

### OAuth Flow
The CLIProxyAPI uses OAuth tokens to authenticate with AI providers. Token renewal requires:
1. **Start provider login**: `cd ~/.cli-proxy-api && /usr/local/bin/cli-proxy-api -claude-login` (Claude) or `-login` (Gemini). The binary will listen on a local callback port (Claude uses `54545`, Gemini uses `8085`).
2. **Open SSH tunnel from your laptop** while the login command is waiting:
   ```bash
   # Claude
   ssh -L 54545:127.0.0.1:54545 dev@5.161.192.198 -p 22

   # Gemini
   ssh -L 8085:127.0.0.1:8085 dev@5.161.192.198 -p 22
   ```
   Keep this tunnel running until the CLI reports the token was saved.
3. **Paste the OAuth URL** shown in the CLI output into your laptop browser. Because of the tunnel, the redirect to `http://localhost:<port>/callback` reaches the waiting CLI process on the VPS.
4. **Confirm success** in the CLI, then close the tunnel. Tokens are written to `~/.cli-proxy-api/auth/` (one file per provider/project).

**Gemini Benefits**: OAuth authenticates through Code Assist API, which provides access to AI Ultra subscription benefits (120 req/min, 2,000 req/day). Multiple Gemini projects can be configured for load balancing.

### OpenAI Compatibility Layer
The config.yaml defines OpenAI-compatible endpoints for all AI services:
- **OAuth-based**: Claude (3 models), Gemini (11 models via 2 projects)
- **Key-based**: OpenAI (4 models), Cerebras (1 model), Z.AI (6 models), Baseten (1 model)

This allows any tool expecting OpenAI format to work with all 25+ models. See `docs/API-REFERENCE.md` for complete usage examples.

### Service Management
The CLIProxyAPI runs as a systemd service under the `dev` user, automatically restarts on failure, and logs to `~/.cli-proxy-api/logs/`.

### External API Access
CLIProxyAPI can be accessed from **any device/application** via the VPS IP address:

**Example: Using Claude from external Python script**
```python
import anthropic
client = anthropic.Anthropic(
    api_key="sk-dummy",
    base_url="http://5.161.192.198:8317"
)
response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello!"}]
)
```

**Supported Endpoints:**
- Anthropic: `http://5.161.192.198:8317` (Claude models)
- OpenAI: `http://5.161.192.198:8317/v1` (All non-Claude models)
- Remote Management: `http://5.161.192.198:8317/management.html`

See `docs/API-REFERENCE.md` for examples in Python, Node.js, cURL, Go, Ruby, and PHP.

## Available Models (25+)

**Claude** (OAuth): `claude-sonnet-4-5-20250929`, `claude-4-5-sonnet-20250514`, `claude-4-haiku-20250514`

**Gemini** (OAuth, 2 projects for load balancing): `gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-3-flash`, `gemini-3-pro`, `gemini-2-flash-thinking`, `gemini-2-pro-exp`, `gemini-1.5-pro`, `gemini-1.5-flash`

**OpenAI** (API Key): `gpt-5-turbo`, `gpt-5-codex`, `gpt-5o`, `gpt-5o-mini`

**Cerebras** (API Key): `llama-4.3-70b`

**Z.AI** (API Key): `glm-4.6`, `glm-4.5-air`, `glm-4.5-turbo`, `glm-4-plus`, `glm-4-flashx`, `glm-4-flash`

**Baseten** (API Key): `kimi-k2-thinking` (Moonshot AI reasoning model)

Run `./scripts/test-all-models.sh` to test all models or see `docs/API-REFERENCE.md` for complete usage.

## Development Workflow

1. **Modify configuration**: Edit `config/config.yaml`
2. **Deploy changes**: Run `./scripts/deploy.sh` (copies config, reloads systemd, restarts service)
3. **Verify configuration**: Run `./scripts/verify-config.sh` (comprehensive health check)
4. **Update CLIProxyAPI binary**: Run `./scripts/build.sh` (pulls latest source, rebuilds, installs)
5. **Monitor**: Use `cliproxy-logs` or `sudo journalctl -u cli-proxy-api -f`

## Security Notes

- Never commit OAuth tokens or API keys
- `.gitignore` excludes sensitive files
- Service runs with `NoNewPrivileges=true` and `PrivateTmp=true`
- Remote management secret key is in config (keep secure)

## Dropbox import snapshot

`vps-config-import/` holds unique files folded from `~/Dropbox/Projects/cliproxy-vps-config` (LAUN-44). Differing Dropbox copies live under `vps-config-import/differs/`; live secrets were not imported (see `vps-config-import/IMPORT-MANIFEST.md`).
