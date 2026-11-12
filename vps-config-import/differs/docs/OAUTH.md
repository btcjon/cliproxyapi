# CLIProxyAPI OAuth Guide

This guide covers the OAuth-backed providers used by the live deployment.

Canonical live-system reference:
- `/home/dev/.agents/docs/architecture/cliproxyapi.md`

That architecture doc is the source of truth for:
- which providers are OAuth-backed
- which auth files are live
- which auth files were quarantined
- current routing and parity decisions

## Current OAuth-backed Providers

- Claude
- OpenAI / Codex
- Gemini

This deployment is intentionally OAuth-first for those expensive providers. Do not replace them with direct paid API-key lanes just for convenience.

## Live Auth Directory

```bash
ls -1 ~/.cli-proxy-api/*.json
```

Quarantined files live in:

```bash
ls -1 ~/.cli-proxy-api/disabled-auth/
```

## Re-authentication

### Claude

```bash
cd ~/.cli-proxy-api
cli-proxy-api --claude-login --config ~/.cli-proxy-api/config.yaml
```

### Gemini

```bash
cd /home/dev/Dropbox/Projects/cliproxy-vps-config
./scripts/oauth-renew.sh gemini
```

### OpenAI / Codex

```bash
cd /home/dev/Dropbox/Projects/cliproxy-vps-config
./scripts/oauth-renew.sh openai
```

## VPS OAuth Callback

When the OAuth flow uses `localhost` callbacks on a VPS, create an SSH tunnel from your laptop first:

```bash
ssh -L 8085:127.0.0.1:8085 dev@5.161.192.198 -p 22
```

Use the provider-specific port your login flow prints if it differs.

## Service Commands

```bash
sudo systemctl status cliproxyapi
sudo systemctl restart cliproxyapi
sudo journalctl -u cliproxyapi -f
```

## Notes

- The service name is `cliproxyapi`.
- The live config is `~/.cli-proxy-api/config.yaml`.
- The public endpoint is `https://llm-proxy.genr8ive.ai`.
- The updater and routing cleanup done on `2026-03-28` are documented in the canonical architecture doc.

## Last Refresh

Reconciled against the live VPS deployment on `2026-03-28`.
