# CLIProxyAPI Model Discovery

This file explains how the current deployment gets models into `/v1/models`.

Canonical live-system reference:
- `/home/dev/.agents/docs/architecture/cliproxyapi.md`

Use that architecture doc as the source of truth for the current exposed registry.

## How Discovery Works

CLIProxyAPI builds its registry from two sources:

1. OAuth-backed auth files in `~/.cli-proxy-api/*.json`
2. static config-defined API-key lanes in `~/.cli-proxy-api/config.yaml`

In the current deployment:

- Claude models come from the Claude OAuth account
- GPT / Codex models come from the OpenAI / Codex OAuth account
- Gemini models come from the Gemini OAuth accounts
- GLM models come from static config
- Kimi comes from static config

## Refresh Behavior

The registry updates when:

- the service starts
- the config file changes
- auth files are added, removed, or renamed in `~/.cli-proxy-api/`

That means a full service restart is not always required. Incremental auth-file changes are picked up live.

## Current Operational Pattern

We intentionally keep the registry curated rather than exposing every technically available model.

Examples from the current live system:

- `gemini-2.5-flash` is hidden
- `glm-4.7` and `zai/glm-4.7` are hidden
- dead OpenAI auth files were removed from the live pool
- a duplicate Gemini auth file for the same project was removed from the live pool

## Where the Registry Comes From

### OAuth-backed providers

- live auth dir: `~/.cli-proxy-api/`
- quarantined auth dir: `~/.cli-proxy-api/disabled-auth/`

If an OAuth auth file is removed or renamed, CLIProxyAPI unregisters that client and decrements the models it contributed.

### Static config providers

- live config: `~/.cli-proxy-api/config.yaml`
- repo config: `/home/dev/Dropbox/Projects/cliproxy-vps-config/config/config.yaml`

If a model is removed from config, it disappears from `/v1/models` after the config reload.

## Best Practices

- Check `/v1/models` instead of assuming a model is exposed.
- Prefer curating the registry over leaving stale models visible.
- Remove broken or duplicate auth files from the live pool instead of relying on runtime failures.
- Keep `fill-first` routing when cache locality and parity matter more than spreading traffic evenly.

## Useful Commands

### List live models

```bash
curl -s http://localhost:8317/v1/models | jq -r '.data[].id' | sort
```

### Inspect live auth files

```bash
ls -1 ~/.cli-proxy-api/*.json
ls -1 ~/.cli-proxy-api/disabled-auth/
```

### Watch live reload behavior

```bash
tail -f ~/.cli-proxy-api/logs/main.log
```

## Last Refresh

Reconciled against the live VPS deployment on `2026-03-28`.
