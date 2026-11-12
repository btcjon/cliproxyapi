# CAPI operations guide

The live deployment uses `systemctl --user … cli-proxy-api`, `~/.cli-proxy-api/config.yaml`, and the managed user binary `~/.local/lib/capi/cli-proxy-api`. Historical system service commands and repository-to-live configuration copies are not current deployment procedures.

## Read-only checks

Run from the selected package root:

```bash
set -euo pipefail
bash scripts/capi-models.sh
```

Public requests require the configured inbound client key. The management key is only for the dashboard/management API. See [diagnostics](references/current-diagnostics.md) for secure process/key-file selection.

## Quota-consuming work

`scripts/capi-test.sh` sends a completion request and consumes provider quota. Supply an explicit live model ID; there is no default test model. For cache validation, `scripts/capi-cache-probe.py --model MODEL` makes exactly two calls per requested model. See [provider caching](references/provider-caching.md) for interpretation.

## Supported paths

- [Service updates and rollback](cookbook/service-management.md)
- [Cursor installation and login](references/cursor-provider.md)
- [SDK integration](cookbook/sdk-integration.md)
- [Hermes Workspace](references/hermes-workspace-custom-provider.md)
- [Open Notebook](references/open-notebook-capi-oauth-integration.md)
- [Image generation and reference edits](references/gpt-image-2-reference-edits.md)
- [Authentication concepts](cookbook/authentication.md)
- [Configuration concepts](cookbook/configuration.md)

The active provider catalog and credentials determine available routes. Never infer account entitlement from upstream model announcements or static lists. Preserve the direct-Anthropic restriction while treating user-authorized Cursor models as Cursor routes.

The previous comprehensive guide is preserved as [historical reference](references/historical-operations-20261004.md); its service names, IPs, catalogs, dummy-key and update recipes are not current commands.
