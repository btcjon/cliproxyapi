#!/bin/bash
# Source from CAPI wrappers. Authentication travels via stdin, not curl argv.
set +x
CAPI_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
API_URL="${CAPI_URL:-https://llm-proxy.genr8ive.ai}"
API_URL="${API_URL%/}"
API_URL="${API_URL%/v1}"
capi_request() {
    local path="$1" config
    shift
    config=$(python3 "$CAPI_SCRIPT_DIR/capi_auth.py" "$API_URL") || return
    printf '%s\n' "$config" | curl -q --config - --silent --show-error --fail \
      --connect-timeout 10 --max-time "${CAPI_TIMEOUT_SECONDS:-60}" "$API_URL$path" "$@"
}
capi_service_args() {
    case "${CAPI_SERVICE_SCOPE:-user}" in
      user) CAPI_SERVICE_ARGS=(--user); CAPI_SERVICE_UNIT="${CAPI_SERVICE:-cli-proxy-api}" ;;
      system) CAPI_SERVICE_ARGS=(); CAPI_SERVICE_UNIT="${CAPI_SERVICE:-cliproxyapi}" ;;
      *) echo 'CAPI_SERVICE_SCOPE must be user or system' >&2; return 2 ;;
    esac
}
