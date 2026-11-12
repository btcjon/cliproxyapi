#!/bin/bash
# CAPI Status - Quick health check
set -euo pipefail

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 127
    }
}

require_cmd curl
require_cmd jq

source "$(dirname -- "${BASH_SOURCE[0]}")/capi-common.sh"

api_get_models() {
    capi_request /v1/models
}

echo "=== CAPI Status ==="
echo ""

# Check service on this host; API endpoint may be remote.
capi_service_args
if command -v systemctl >/dev/null 2>&1 && systemctl "${CAPI_SERVICE_ARGS[@]}" is-active --quiet "$CAPI_SERVICE_UNIT" 2>/dev/null; then
    echo "📗 Host service: Running ($CAPI_SERVICE_UNIT, ${CAPI_SERVICE_SCOPE:-user})"
else
    echo "📙 Service: Not local, not systemd-visible, or not running"
fi

# Check API health
echo ""
echo "API Endpoint: $API_URL"
if models_json=$(api_get_models); then
    echo "📗 API: Responsive"
else
    echo "📕 API: Not responding"
    exit 1
fi

# Count model ownership as reported by the registry, including Cursor routes.
echo ""
echo "Available Models by owning provider:"
printf '%s\n' "$models_json" | jq -r '.data | group_by(.owned_by // "unknown")[] | "  \(.[0].owned_by // "unknown"): \(length)"'
printf '  Total: %s\n' "$(printf '%s\n' "$models_json" | jq '.data | length')"

# Credential summaries only; filenames can contain personal account identifiers.
echo ""
echo "Credential files (not a provider-auth health check):"
python3 - <<'PY'
import collections,json
from pathlib import Path
counts=collections.Counter()
for p in (Path.home()/".cli-proxy-api").glob("*.json"):
    try:
        x=json.loads(p.read_text())
        counts[(str(x.get("type","unknown")),bool(x.get("disabled",False)))]+=1
    except (OSError,ValueError):
        continue
for (provider,disabled),count in sorted(counts.items()):
    print("  %s: %s (%s)"%(provider,count,"disabled" if disabled else "enabled"))
PY
