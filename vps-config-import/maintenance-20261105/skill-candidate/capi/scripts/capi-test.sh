#!/bin/bash
# CAPI Test - Quick model test. This consumes provider quota.
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
MODEL="${1:-${CAPI_MODEL:-}}"
if [[ -z "$MODEL" ]]; then
    echo "Usage: capi-test.sh MODEL [prompt]; choose an exact live catalog ID" >&2
    exit 2
fi
PROMPT="${2:-Say hello in exactly 5 words}"
MAX_TOKENS="${CAPI_MAX_TOKENS:-100}"

payload=$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    --argjson max_tokens "$MAX_TOKENS" \
    '{model:$model,messages:[{role:"user",content:$prompt}],max_tokens:$max_tokens}')

echo "Testing model: $MODEL"
echo "Prompt: $PROMPT"
echo "---"

response=$(capi_request /v1/chat/completions -X POST \
    -H "Content-Type: application/json" \
    -d "$payload")

echo "$response" | jq -er '.choices[0].message.content | select(type == "string" and length > 0)'
echo ""
echo "Usage: $(echo "$response" | jq -c '.usage // "N/A"')"
