#!/usr/bin/env bash
echo "RETIRED historical copy: use scripts/update-capi.py and docs/OPERATIONS.md" >&2
exit 1
# --- original below (not executed) ---
#!/bin/bash
# Auto-update CLIProxyAPI - runs weekly on Sunday at midnight
# Checks GitHub for new releases, updates binary, syncs config, restarts service

# set -euo pipefail

# LOG_FILE="$HOME/.cli-proxy-api/logs/auto-update.log"
# GITHUB_REPO="router-for-me/CLIProxyAPI"
# DOC_FILE="$HOME/Dropbox/Projects/sai/docs/features/tools/cliproxyapi.md"
# CONFIG_FILE="$HOME/.cli-proxy-api/config.yaml"
# CONFIG_REPO="$HOME/Dropbox/Projects/cliproxy-vps-config/config/config.yaml"
# MAX_RETRIES=3
# RETRY_DELAY=5
# CURL_TIMEOUT=30
# GITHUB_TOKEN_VALUE="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

# Ensure log directory exists
# mkdir -p "$(dirname "$LOG_FILE")"

# log() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
# }

# Internal log (file only, no stdout - for use in functions that capture output)
# log_quiet() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
# }

# Retry function with exponential backoff
# NOTE: Uses log_quiet to avoid polluting stdout (for command substitution)
# retry_cmd() {
#     local cmd="$1"
#     local description="$2"
#     local attempt=1
#     local delay=$RETRY_DELAY

#     while [ $attempt -le $MAX_RETRIES ]; do
#         log_quiet "  Attempt $attempt/$MAX_RETRIES: $description"
#         if output=$(eval "$cmd" 2>&1); then
#             echo "$output"
#             return 0
#         fi
#         log_quiet "  Failed (attempt $attempt): ${output:-no output}"
#         if [ $attempt -lt $MAX_RETRIES ]; then
#             log_quiet "  Retrying in ${delay}s..."
#             sleep $delay
#             delay=$((delay * 2))
#         fi
#         attempt=$((attempt + 1))
#     done
#     return 1
# }

# log "=== Starting CLIProxyAPI auto-update check ==="

# 0. Sync config from repo if newer
# if [ -f "$CONFIG_REPO" ]; then
#     if [ ! -f "$CONFIG_FILE" ] || [ "$CONFIG_REPO" -nt "$CONFIG_FILE" ]; then
#         log "Syncing config from repo..."
#         cp "$CONFIG_REPO" "$CONFIG_FILE"
#         log "Config synced: $(stat -c '%y' "$CONFIG_FILE" | cut -d. -f1)"
#     else
#         log "Config up to date"
#     fi
# else
#     log "WARNING: Repo config not found at $CONFIG_REPO"
# fi

# 1. Get current version
# CURRENT_OUTPUT=$(/usr/local/bin/cli-proxy-api --version 2>&1 || /usr/local/bin/cli-proxy-api 2>&1 || true)
# CURRENT=$(echo "$CURRENT_OUTPUT" | grep -oP 'CLIProxyAPI Version: \K[0-9.]+' | head -1)
# if [ -z "$CURRENT" ]; then
#     CURRENT=$(echo "$CURRENT_OUTPUT" | grep -oP 'Version:?\s*\K[0-9.]+' | head -1)
# fi
# if [ -z "$CURRENT" ]; then
#     CURRENT="0.0.0"
#     log "WARNING: Could not detect current version, assuming $CURRENT"
# fi
# log "Current version: v$CURRENT"

# 2. Get latest release from GitHub (with retry and timeout)
# log "Fetching latest release from GitHub..."
# if [ -n "$GITHUB_TOKEN_VALUE" ]; then
#     log "Using authenticated GitHub API request"
#     GITHUB_API_CMD="curl -sL --max-time $CURL_TIMEOUT --retry 2 --retry-delay 3 -H 'Authorization: Bearer $GITHUB_TOKEN_VALUE' -H 'Accept: application/vnd.github+json' 'https://api.github.com/repos/$GITHUB_REPO/releases/latest'"
# else
#     log "Using unauthenticated GitHub API request"
#     GITHUB_API_CMD="curl -sL --max-time $CURL_TIMEOUT --retry 2 --retry-delay 3 'https://api.github.com/repos/$GITHUB_REPO/releases/latest'"
# fi

# GITHUB_RESPONSE=$(retry_cmd \
#     "$GITHUB_API_CMD" \
#     "Fetch GitHub releases API") || {
#     log "ERROR: Failed to fetch latest version from GitHub after $MAX_RETRIES attempts"
#     exit 1
# }

# LATEST=$(echo "$GITHUB_RESPONSE" | jq -r '.tag_name' 2>/dev/null | tr -d 'v')
# if [ -z "$LATEST" ] || [ "$LATEST" = "null" ]; then
#     log "ERROR: Invalid GitHub API response"
#     log "  Response preview: $(echo "$GITHUB_RESPONSE" | head -c 200)"
#     exit 1
# fi
# log "Latest version: v$LATEST"

# 3. Compare versions
# if [ "$CURRENT" = "$LATEST" ]; then
#     log "Already up to date (v$CURRENT). No action needed."
#     exit 0
# fi

# log "Update available: v$CURRENT -> v$LATEST"

# 4. Download new binary (with retry and timeout)
# DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/v$LATEST/CLIProxyAPI_${LATEST}_linux_amd64.tar.gz"
# cd /tmp
# log "Downloading from: $DOWNLOAD_URL"

# retry_cmd \
#     "curl -sL --max-time 120 --retry 2 --retry-delay 3 -o cliproxy_update.tar.gz '$DOWNLOAD_URL' && [ -s cliproxy_update.tar.gz ]" \
#     "Download release archive" || {
#     log "ERROR: Failed to download update after $MAX_RETRIES attempts"
#     rm -f /tmp/cliproxy_update.tar.gz
#     exit 1
# }

# Verify archive integrity before extraction
# if ! tar -tzf cliproxy_update.tar.gz > /dev/null 2>&1; then
#     log "ERROR: Downloaded archive is corrupt or incomplete"
#     log "  File size: $(stat -c%s cliproxy_update.tar.gz 2>/dev/null || echo 'unknown') bytes"
#     rm -f /tmp/cliproxy_update.tar.gz
#     exit 1
# fi

# tar -xzf cliproxy_update.tar.gz
# log "Downloaded and extracted v$LATEST"

# 5. Verify new binary works
# log "Verifying new binary..."
# if [ ! -f /tmp/cli-proxy-api ]; then
#     log "ERROR: Binary not found after extraction"
#     log "  Archive contents: $(tar -tzf cliproxy_update.tar.gz 2>/dev/null | tr '\n' ' ')"
#     rm -f /tmp/cliproxy_update.tar.gz
#     exit 1
# fi

# chmod +x /tmp/cli-proxy-api

# Verify binary is valid
# Method 1: Check ELF header directly (works without 'file' command)
# if head -c 4 /tmp/cli-proxy-api | grep -q "ELF"; then
#     log "Binary verified (ELF header present)"
# else
#     # Method 2: Try 'file' command if available
#     if command -v file &>/dev/null; then
#         FILE_INFO=$(file /tmp/cli-proxy-api 2>/dev/null || echo "unknown")
#         if ! echo "$FILE_INFO" | grep -qE "(ELF|executable)"; then
#             log "ERROR: Binary is not a valid executable"
#             log "  File info: $FILE_INFO"
#             rm -f /tmp/cliproxy_update.tar.gz /tmp/cli-proxy-api
#             exit 1
#         fi
#         log "Binary verified via file command"
#     else
#         # Method 3: Just check it's not empty and is executable
#         if [ -s /tmp/cli-proxy-api ] && [ -x /tmp/cli-proxy-api ]; then
#             log "Binary verified (executable, non-empty)"
#         else
#             log "ERROR: Binary verification failed - file empty or not executable"
#             rm -f /tmp/cliproxy_update.tar.gz /tmp/cli-proxy-api
#             exit 1
#         fi
#     fi
# fi

# Try to get version (may fail without config, that's OK)
# VERIFY_OUTPUT=$(/tmp/cli-proxy-api --version 2>&1 || /tmp/cli-proxy-api 2>&1 || true)
# if echo "$VERIFY_OUTPUT" | grep -qE "(CLIProxyAPI|Version|version)"; then
#     BINARY_VERSION=$(echo "$VERIFY_OUTPUT" | grep -oP 'Version:?\s*\K[0-9.]+' | head -1)
#     log "Binary version: v${BINARY_VERSION:-unknown}"
# fi

# 6. Stop service, update binary
# log "Stopping existing service..."
# sudo systemctl stop cliproxyapi.service 2>/dev/null || true
# pkill -9 -x "cli-proxy-api" 2>/dev/null || true
# sleep 2

# Verify stopped
# if pgrep -x "cli-proxy-api" > /dev/null 2>&1; then
#     log "WARNING: Process still running, forcing kill..."
#     pkill -9 -x "cli-proxy-api" || true
#     sleep 2
# fi

# sudo cp /tmp/cli-proxy-api /usr/local/bin/cli-proxy-api
# sudo chmod +x /usr/local/bin/cli-proxy-api
# log "Binary updated to v$LATEST"

# 7. Restart service via systemd
# log "Starting service..."
# sudo systemctl start cliproxyapi.service
# sleep 5

# Verify service is running
# if ! pgrep -x "cli-proxy-api" > /dev/null; then
#     log "ERROR: Service failed to start after update"
#     log "  systemctl status: $(systemctl status cliproxyapi.service 2>&1 | head -5)"
#     exit 1
# fi
# log "Service restarted successfully"

# 8. Get updated model list
# sleep 2  # Give service time to fully initialize
# MODEL_COUNT=$(curl -s --max-time 10 http://localhost:8317/v1/models | jq '.data | length' 2>/dev/null || echo "0")
# log "Models available: $MODEL_COUNT total"

# Get models by provider for logging
# MODELS_BY_PROVIDER=$(curl -s --max-time 10 http://localhost:8317/v1/models | jq -r '.data | group_by(.owned_by) | .[] | "\(.[0].owned_by): \(length)"' 2>/dev/null || echo "unknown")
# log "Models by provider: $MODELS_BY_PROVIDER"

# 9. Update documentation
# if [ -f "$DOC_FILE" ]; then
#     log "Updating documentation..."

#     # Update version in doc
#     sed -i "s/\*\*Version\*\*: v[0-9.]\+/**Version**: v$LATEST/g" "$DOC_FILE"
#     sed -i "s/\*\*CLIProxyAPI Version\*\*: v[0-9.]\+/**CLIProxyAPI Version**: v$LATEST/g" "$DOC_FILE"

#     # Update date
#     TODAY=$(date '+%Y-%m-%d')
#     sed -i "s/\*\*Last Updated\*\*: [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/**Last Updated**: $TODAY/g" "$DOC_FILE"

#     log "Documentation updated"

#     # 10. Git commit if changes
#     cd ~/Dropbox/Projects/sai
#     if ! git diff --quiet docs/features/tools/cliproxyapi.md 2>/dev/null; then
#         git add docs/features/tools/cliproxyapi.md
#         git commit -m "chore: auto-update CLIProxyAPI docs to v$LATEST

# - Updated version: v$CURRENT -> v$LATEST
# - Models available: $MODEL_COUNT

# [automated]"
#         log "Documentation committed to git"
#     else
#         log "No doc changes to commit"
#     fi
# else
#     log "WARNING: Doc file not found at $DOC_FILE"
# fi

# 11. Cleanup
# rm -f /tmp/cliproxy_update.tar.gz /tmp/cli-proxy-api /tmp/LICENSE /tmp/README.md /tmp/README_CN.md /tmp/config.example.yaml

# log "=== Update complete: v$CURRENT -> v$LATEST (${MODEL_COUNT} models) ==="
