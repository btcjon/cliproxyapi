#!/usr/bin/env bash
echo "RETIRED historical copy: use scripts/update-capi.py and docs/OPERATIONS.md" >&2
exit 1
# --- original below (not executed) ---
#!/bin/sh
# Compatibility entrypoint: the user service owns CAPI; never sync a source config.
# exec /home/dev/.local/libexec/capi-update.py "$@"
