#!/bin/bash
set -euo pipefail

PROVIDER=${1:-}

detect_service_name() {
    if systemctl list-unit-files | grep -q '^cliproxyapi\.service'; then
        echo "cliproxyapi"
        return
    fi
    if systemctl list-unit-files | grep -q '^cli-proxy-api\.service'; then
        echo "cli-proxy-api"
        return
    fi
    # Default to the actively used service in this environment.
    echo "cliproxyapi"
}

SERVICE_NAME=$(detect_service_name)

if [ -z "$PROVIDER" ]; then
    echo "Usage: ./oauth-renew.sh [claude|gemini|openai]"
    exit 1
fi

# Function to stop service
stop_service() {
    echo "Stopping ${SERVICE_NAME} service..."
    sudo systemctl stop "$SERVICE_NAME"
    sleep 2
}

# Function to start service
start_service() {
    echo "Starting ${SERVICE_NAME} service..."
    sudo systemctl start "$SERVICE_NAME"
    echo "Service restarted successfully!"
}

# Trap to ensure service is restarted even if script fails
trap start_service EXIT

case "$PROVIDER" in
    claude)
        echo "Renewing Claude OAuth..."
        echo ""
        echo "1. On your Mac, start SSH tunnel:"
        echo "   ssh -L 54546:127.0.0.1:54545 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N"
        echo ""
        stop_service
        echo "2. Run OAuth flow:"
        cli-proxy-api --claude-login --no-browser --config ~/.cli-proxy-api/config.yaml
        ;;
    gemini)
        echo "Renewing Gemini OAuth..."
        echo ""
        echo "1. On your Mac, start SSH tunnel:"
        echo "   ssh -L 8086:127.0.0.1:8085 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N"
        echo ""
        stop_service
        echo "2. Run OAuth flow:"
        cli-proxy-api --login --no-browser --config ~/.cli-proxy-api/config.yaml
        ;;
    openai)
        echo "Renewing OpenAI OAuth..."
        echo ""
        echo "1. On your Mac, start SSH tunnel:"
        echo "   ssh -L 1455:127.0.0.1:1455 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N"
        echo ""
        stop_service
        echo "2. Run OAuth flow:"
        cli-proxy-api --codex-login --no-browser --config ~/.cli-proxy-api/config.yaml
        ;;
    *)
        echo "Unknown provider: $PROVIDER"
        echo "Valid options: claude, gemini, openai"
        exit 1
        ;;
esac
