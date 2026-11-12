# CAPI deployment project

Read /home/dev/.agents/AGENTS.md for the shared contract. Current deployment reference: docs/OPERATIONS.md. Verify the host, service and live configuration before changing runtime state.

This project owns CAPI/CLIProxyAPI service maintenance and documentation. The live service is the user unit cli-proxy-api, not the historical system unit cliproxyapi. Its binary is ~/.local/lib/capi/cli-proxy-api and config is ~/.cli-proxy-api/config.yaml. Public access is authenticated HTTPS; do not use dummy keys remotely or expose port 8317.

Use scripts/update-capi.py (installed at ~/.local/libexec/capi-update.py) for updates. The compatibility auto-update-cliproxy.sh delegates to it. Do not run old build/deploy/OAuth scripts without reviewing their target paths and service. Never copy stale source config over the live config.

Keep secrets out of command arguments, output, documentation and source files. Read only required keys, never source a credential environment file. Keep client and management privileges separate. Auth/key/config files are owner-only.

Preserve configured account scope. The user authorized Cursor and its model routes; this does not authorize restoring direct Anthropic subscription OAuth or changing Hermes' separate direct xAI lane. Diagnose 401/402/404/429 distinctly. Do not spend money, add accounts, or replace models as incidental repair.

Maintain stable session/account affinity and cache keys, but only apply documented provider controls. A catalog entry or affinity setting is not an execution/cache-hit proof. Report upstream cached/read usage and missing/estimated counters honestly.

Use focused offline tests for executable changes, authenticated catalogs for deployment health, and small representative completions only when authorized. No automatic exhaustive all-model tests. The updater is a no-op on the current version and must preserve plugins/config and support rollback.

Global Skills in Notion is authoritative for the capi skill. Publish complete body/bundle/manifest through guarded source workflows and verify fresh selection; do not edit immutable snapshots or exported consumer packages.
