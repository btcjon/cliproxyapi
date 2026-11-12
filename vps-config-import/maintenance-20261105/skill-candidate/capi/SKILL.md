---
name: capi
description: Operate CLIProxyAPI/CAPI for provider login, models, prompt caching, authenticated diagnostics, client integration, updates and recovery.
metadata:
  version: 1.3.0
---

# CAPI operations

Resolve the owning host, configured endpoint, binary and service before acting. The recorded deployment is on SSH host `dest`, user service `cli-proxy-api`, loopback port 8317, public HTTPS endpoint `https://llm-proxy.genr8ive.ai`. Recheck changing state. The user-owned managed binary is `~/.local/lib/capi/cli-proxy-api`; old `/opt` and system-service examples are historical.

## Choose the operation

- Read-only diagnostics: `scripts/capi-status.sh`, `scripts/capi-models.sh [filter]`, `scripts/capi-logs.sh [lines] [service|file|update|follow]`. Use [authentication and diagnostics](references/current-diagnostics.md).
- Execution: require an explicit current model ID with `scripts/capi-test.sh MODEL [prompt]`. HTTP success and catalog presence do not prove model execution.
- Caching: read [provider caching](references/provider-caching.md). The opt-in `scripts/capi-cache-probe.py --model MODEL` sends two quota-consuming requests per model and reports provider cache usage.
- Plugin registration: `python3 scripts/capi-plugins.py` reads allowlisted status using a separate management key.
- Cursor: read [Cursor provider](references/cursor-provider.md) for the plugin, browser/API-key login, discovery and tool continuations.
- Updates/recovery: read [service management](cookbook/service-management.md). The user updater verifies release checksums, preserves live config and plugins, and restores the old binary if catalog health fails.
- Client setup: [SDK integration](cookbook/sdk-integration.md), [Hermes Workspace](references/hermes-workspace-custom-provider.md), [Open Notebook](references/open-notebook-capi-oauth-integration.md).
- Images: [image/reference edits](references/gpt-image-2-reference-edits.md). Discover current image IDs first; do not silently substitute a model. The existing helper defaults to `gpt-image-2` for compatibility and accepts an explicit model.

## Operational boundaries

Carry forward the user's authorization for its actual scope. Diagnostics, quota-consuming tests, configuration/service changes and account login are different actions. Existing approval to perform a change does not require another confirmation. Keep credentials out of argv, logs, receipts and skill packages. The raw logs helper is for local operators; in agent tools pipe it locally into `python3 scripts/capi-log-summary.py` so raw lines never enter tool output. Save deeper diagnostic material privately and extract only the needed redacted facts. Client API keys and management keys are separate privileges; do not reuse one value for both.

The historical restriction concerns adding/restoring direct Anthropic subscription credentials and direct Claude proxy routes. The user explicitly installed and authenticated Cursor in November 2026; `cursor/claude-…` models are Cursor routes, not authority to restore direct Anthropic OAuth. Keep the Hermes xAI OAuth lane direct; existing CAPI xAI credentials are separate and are not a reason to change Hermes routing.

Honor 429/backoff and reconcile uncertain mutations before retrying. A 401/403 is authentication evidence, 402 may require provider credit/account action, and 404 may indicate a stale model mapping. Do not solve these by adding accounts or spending money.

## Completion evidence

Report the endpoint and action class, actual command/API status, model count or execution output, and remaining limits. Cache affinity is not a cache hit: use upstream read/write token fields and preserve missing/estimated counters as unknown. A successful warm-cache probe is evidence for that route at that time, not every model or future request.

Run `python3 -m unittest discover -s tests -q` for helper changes. Optional legacy contract tests skip with a clear reason when the external `tools.skill_runtime` runtime is unavailable; ordinary diagnostics do not depend on it. PyYAML is needed for strict YAML validation; Pillow is needed only for image decoding. Preserve the route-only adapter: it does not execute API calls.

See [operations guide](./guide.md) for the current layout. Historical examples are retained in [archived operations](references/historical-operations-20261004.md), not active recipes.
