# Cursor provider

The user authorized installing and authenticating the third-party [Cursor plugin](https://github.com/spancerxing/cliproxyapi-cursor-plugin) in November 2026. The deployed version then was 0.1.2. Recheck upstream and live registration before upgrades.

## Installation

CAPI must support C ABI v1 dynamic libraries. On Linux, choose the default upstream release, not the no-plugin build. The reviewed source checkout is `/home/dev/.local/src/capi-plugins/cursor-20261105`; its initial installed commit was `7bfcc888fd61c662c428387eec0f63f87747a6e1`. Use a native matching Go 1.23+ and C compiler; compile `CGO_ENABLED=1 go build -buildmode=c-shared -o dist/spx-cursor.so .`. Run the plugin's Go tests before installation.

Install into the configured private plugin directory. Enable `plugins.enabled`, configure its absolute `dir`, and set `plugins.configs.spx-cursor.enabled: true`. Preserve other plugins. Back up config, restart the owning user service, then use `python3 scripts/capi-plugins.py` to verify `/v8/management/plugins` reports registered/effectively enabled and `oauth_provider: cursor`.

## Login and discovery

Refresh the dashboard and choose OAuth Login → Cursor. The browser login belongs to the user; never export tokens into chat. The plugin's API-key form is `/v0/resource/plugins/spx-cursor/login`; it requires the management key and a Cursor API key. Browser and API credentials are different routes.

An active credential is not proof of models or execution. After login, query authenticated `/v1/models` for `cursor/` IDs. This deployment initially required a user-service restart to register a newly added credential; recheck registration and bounded logs first, then use a restart within authorized repair scope. Do not repeat login merely because the catalog is empty.

Model IDs include `cursor/auto`, `cursor/composer-2.5` and model/context variants discovered live. Keep exact IDs. Auto may select different underlying models over time, so choose an explicit model when stable model selection is required; never silently replace the user's Auto choice.

## Caching and limits

Preserve a stable per-conversation `prompt_cache_key` or recognized session metadata and the same first user message/history. The plugin derives its upstream conversation identity from the account, session and initial user message. Changing these changes the identity. It forwards Chat Completions natively and supports images/tools. The upstream owns cache behavior; the plugin reports read/write tokens where available and can mark usage estimated. Do not claim synthetic zero counters establish cache absence.

The November 2026 deployment verified real browser auth, 64 model/context entries and `cursor/auto` execution with a positive second-call cache read. Those are dated observations, not permanent account entitlement. Browser renewal was added in 0.1.2; rejected/unusable renewal stops renewal and can require user sign-in. Per-account proxy overrides remain unsupported.
