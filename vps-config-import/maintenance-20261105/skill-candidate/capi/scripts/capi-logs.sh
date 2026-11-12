#!/bin/bash
# CAPI Logs - View recent logs
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/capi-common.sh"
capi_service_args

usage() {
    echo "Usage: capi-logs.sh [lines] [service|file|update|follow]" >&2
}

LINES="${1:-50}"
MODE="${2:-service}"

if ! [[ "$LINES" =~ ^[1-9][0-9]*$ ]]; then
    echo "lines must be a positive integer" >&2
    usage
    exit 2
fi

case "$MODE" in
    service|s)
        command -v journalctl >/dev/null 2>&1 || { echo "Missing required command: journalctl" >&2; exit 127; }
        echo "=== Service Logs (last $LINES lines) ==="
        journalctl "${CAPI_SERVICE_ARGS[@]}" -u "$CAPI_SERVICE_UNIT" --no-pager -n "$LINES"
        ;;
    file|f)
        log_file="$HOME/.cli-proxy-api/logs/main.log"
        [[ -r "$log_file" ]] || { echo "Log file not readable: $log_file" >&2; exit 1; }
        echo "=== File Logs (last $LINES lines) ==="
        tail -n "$LINES" "$log_file"
        ;;
    update|u)
        if [[ -n "${CAPI_UPDATE_LOG_FILE:-}" || "${CAPI_SERVICE_SCOPE:-user}" == system ]]; then
            log_file="${CAPI_UPDATE_LOG_FILE:-$HOME/.cli-proxy-api/logs/auto-update.log}"
            [[ -r "$log_file" ]] || { echo "Log file not readable: $log_file" >&2; exit 1; }
            tail -n "$LINES" "$log_file"
        else
            command -v journalctl >/dev/null 2>&1 || { echo "Missing required command: journalctl" >&2; exit 127; }
            journalctl --user -u "${CAPI_UPDATE_SERVICE:-capi-update}" --no-pager -n "$LINES"
        fi
        ;;
    follow|live)
        command -v journalctl >/dev/null 2>&1 || { echo "Missing required command: journalctl" >&2; exit 127; }
        echo "=== Following Service Logs (Ctrl+C to stop) ==="
        journalctl "${CAPI_SERVICE_ARGS[@]}" -u "$CAPI_SERVICE_UNIT" -f
        ;;
    *)
        usage
        exit 2
        ;;
esac
