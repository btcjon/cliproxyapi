# CAPI service management

## Owning service and files

Recheck `systemctl --user show cli-proxy-api -p ExecStart` on the owning host. Current recorded layout on `dest`:

- Service: user unit `cli-proxy-api`.
- Config/auth: `~/.cli-proxy-api`; config/key/auth files owner-only.
- Binary: `~/.local/lib/capi/cli-proxy-api`.
- User override: `~/.config/systemd/user/cli-proxy-api.service.d/10-managed-binary.conf`.
- Plugin directory: `~/.cli-proxy-api/plugins`.
- Dashboard: public `/management.html`; authenticated management API `/v8/management`.
- Updater: `~/.local/libexec/capi-update.py`; user units `capi-update.service` and `capi-update.timer`.

The timer checks weekly Sunday midnight America/New_York with up to 15 minutes jitter and catches up after downtime. A current-version check is a no-op.

## Update

Read `~/.local/libexec/capi-update.py --help`; use `--check` for a read-only version comparison. Without `--check`, it downloads the upstream stable Linux build with dynamic-plugin support, verifies the published SHA-256 checksum, preserves the live config and prior binary in a private timestamped backup, atomically installs the binary and restarts only the owning user unit. It does not copy source config over live config or log credentials. The updater requires Python 3 and outbound HTTPS. Its complete maintained source is bundled as `scripts/capi-update.py`; inspect the target paths before authorized installation. Update logs are in the user journal for `capi-update.service` (the logs helper's update mode), not the historical auto-update.log. The original /opt binary is retained as historical recovery material.

Verify public and local authenticated catalogs, required Cursor entries, and user service state. Smoke-test representative models only within authorized quota scope. The updater performs no billable completion tests. It restores the previous binary and checks health if the new binary fails startup/catalog verification.

## Rollback

Inspect the exact updater receipt and current file hashes before rollback. Restore the responsible prior binary from `~/.cli-proxy-api/backups/update-TIMESTAMP/cli-proxy-api` atomically to the actual ExecStart path, then restart the user unit and recheck catalogs. Restore config only if that specific config change is responsible, preserving newer unrelated edits. Do not run an old system updater or remove the Cursor library as incidental recovery.

## Logs

Use the selected package's `scripts/capi-logs.sh` for bounded service/file/update modes. Read logs locally; redact credentials and account identifiers before reporting. Never paste full auth JSON or raw configuration.
