# CAPI deployment

Verified on 2026-11-05. This file records the deployment; recheck changing versions, auth, quota and model availability.

- Host: SSH alias dest, user dev.
- User service: cli-proxy-api.
- Managed binary: /home/dev/.local/lib/capi/cli-proxy-api (8.0.57 at verification).
- Service override: ~/.config/systemd/user/cli-proxy-api.service.d/10-managed-binary.conf.
- Live config and OAuth files: ~/.cli-proxy-api; owner-only files. Do not copy config/config.yaml over the live config.
- Bind: 127.0.0.1:8317; public HTTPS https://llm-proxy.genr8ive.ai.
- Dashboard: /management.html (1.27.3 at verification).
- Cursor: spx-cursor 0.1.2, private plugin directory ~/.cli-proxy-api/plugins; live login and Auto completion/cache read verified.
- Client key: ~/.cli-proxy-api/inbound-api-key, mode 0600. Management authentication is separate. Known Hermes and shared CAPI environment values were migrated; already-running clients with old environment values may need to reload them.
- Client keys cannot access management; the management key cannot access model endpoints.

## Caching

Fill-first fallback selection is retained. Session affinity, one-hour binding, parent/subagent affinity, and quota-only rebinding are enabled. Transient failover does not permanently discard the original binding. Venice has support-prompt-cache-key enabled. Other provider-specific options are left to supported native transports; no blanket TTL injection.

Callers must preserve stable system/tool/document prefixes, ordered history and a stable per-conversation session/cache key. This setting does not rewrite client prompts or guarantee upstream caching. Cursor Auto model choice is upstream-owned.

Paired synthetic tests recorded cache reads on Codex GPT-6.1 Sol, Cursor Auto, GLM-5.3 and Venice. Gemini CLI and Antigravity responded but did not expose cache counters. Existing xAI returned 402, Nous route 404, Baseten route 401. These are not repaired by cache settings; no billing/auth expansion or silent model replacement was performed. See maintenance-20261105/cache-probe.json for credential-free test data.

## Updates

Installed updater: ~/.local/libexec/capi-update.py; maintained source: scripts/update-capi.py.
User units: capi-update.service, capi-update.timer.
Schedule: Sunday midnight America/New_York with up to 15 minutes jitter, Persistent=true.
Run --check for read-only version comparison. The updater uses the default Linux release with dynamic-library plugins, verifies the release checksum, preserves config and prior binary, installs atomically, restarts only the user unit, and checks authenticated catalog health and Cursor presence. On failure it restores the old binary. It does not run billable completion tests or overwrite config. Current version is a no-op.
The compatibility auto-update-cliproxy.sh delegates to this updater. Other old build/deploy/OAuth scripts require review before use.

## Recovery

Backups are private under ~/.cli-proxy-api/backups. This maintenance made tune-20261105-185240 and update-20261105-185334 backups. The old /opt binary remains in place. Restore only responsible changes after comparing current hashes, then restart the owning user unit and verify public/local authenticated catalogs. Do not restore old client key privileges or stale source config as an incidental binary rollback.

## Canonical skill

Global Skills page: https://www.notion.so/3e145e4458bf816b88b2e41473b1ee1b .
The page body plus complete bundle/manifest is authoritative. Local maintenance candidates are staging, not publication. The selected package contains operational helpers, provider-cache guidance and optional quota-consuming probes. Skill publication records live under maintenance-20261105.
