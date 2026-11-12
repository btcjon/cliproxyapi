#!/bin/bash
# CAPI Models - List available models with optional filtering
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
FILTER="${1:-}"

models=$(capi_request /v1/models | jq -r '.data[].id' | sort)

if [[ -n "$FILTER" ]]; then
    echo "$models" | grep -i -- "$FILTER"
else
    echo "$models"
fi
