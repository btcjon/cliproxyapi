# CLIProxyAPI Setup Complete ✓

## Service Status
- **Service**: cli-proxy-api
- **Status**: Running and enabled for auto-start
- **Port**: 8317 (localhost and public)
- **Config**: ~/.cli-proxy-api/config.yaml

## OAuth Authentication ✓
Successfully authenticated with:
- **Claude/Anthropic** (expires: check ~/.cli-proxy-api/claude-anthropic@decentral.email.json)
- **Google/Gemini** (2 projects for load balancing, check ~/.cli-proxy-api/jonebennett@gmail.com-gen-lang-client-*.json)
  - **Uses AI Ultra subscription benefits** via Code Assist API (120 req/min, 2,000 req/day)
- **OpenAI/Codex** (existing token still valid)

## Environment Variables ✓

Added to ~/.bash_profile (loaded on SSH login):

```bash
# Proxy URLs
CLIPROXY_URL="http://localhost:8317"
CLIPROXY_URL_PUBLIC="http://5.161.192.198:8317"

# OpenAI-compatible routes
OPENAI_BASE_URL="http://localhost:8317"
OPENAI_API_BASE="http://localhost:8317/v1"
OPENAI_API_KEY="sk-dummy"

# Anthropic Claude routes
ANTHROPIC_BASE_URL="http://localhost:8317"
ANTHROPIC_API_BASE="http://localhost:8317"
ANTHROPIC_API_KEY="sk-dummy"

# Google/Gemini routes
GOOGLE_API_BASE="http://localhost:8317/v1"
GOOGLE_AI_BASE_URL="http://localhost:8317"
GOOGLE_API_KEY="sk-dummy"
```

## Convenience Aliases (in ~/.bashrc for interactive shells)

```bash
cliproxy-status    # Check service status
cliproxy-logs      # Tail service logs
cliproxy-errors    # Tail error logs
cliproxy-restart   # Restart service
cliproxy-test      # Test API endpoint
cliproxy-health    # Check health endpoint
```

## Usage

### For tools running on VPS (use localhost)
```bash
export OPENAI_API_BASE="http://localhost:8317/v1"
```

### For external access (from Mac or other servers)
```bash
export OPENAI_API_BASE="http://5.161.192.198:8317/v1"
```

### Service Management
```bash
sudo systemctl status cli-proxy-api   # Check status
sudo systemctl restart cli-proxy-api  # Restart
sudo systemctl stop cli-proxy-api     # Stop
journalctl -u cli-proxy-api -f        # View systemd logs
```

### Check Logs
```bash
tail -f ~/.cli-proxy-api/logs/service.log        # Service output
tail -f ~/.cli-proxy-api/logs/service-error.log  # Errors
```

### Test Endpoints
```bash
curl http://localhost:8317/              # Root endpoint
curl http://localhost:8317/health         # Health check
curl http://localhost:8317/v1/models      # List available models
```

## OAuth Re-authentication (when tokens expire)

### Claude
```bash
# On Mac, start SSH tunnel first:
ssh -L 54546:127.0.0.1:54545 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N

# On VPS:
cli-proxy-api --claude-login --no-browser --config ~/.cli-proxy-api/config.yaml

# In browser on Mac: open the URL, change port from :54545 to :54546 in callback URL
```

### Google/Gemini
```bash
# On Mac, start SSH tunnel first:
ssh -L 8085:127.0.0.1:8085 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N

# On VPS (script automatically stops/restarts service):
./scripts/oauth-renew.sh gemini

# Follow the instructions and open the OAuth URL in your browser
```

## Backup Files Created
- ~/.bash_profile.backup-* (bash_profile backups)
- ~/.bashrc.backup-* (bashrc backups)

## Configuration Files
- **Service**: /etc/systemd/system/cli-proxy-api.service
- **Config**: ~/.cli-proxy-api/config.yaml
- **Shell**: ~/.bash_profile (environment variables)
- **Shell**: ~/.bashrc (aliases and interactive config)

---

Setup completed on: Thu Nov 13 05:44:56 EST 2025
VPS: 5.161.192.198
User: dev
