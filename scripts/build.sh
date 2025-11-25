#!/bin/bash
set -euo pipefail

echo "Building CLIProxyAPI from source..."

# Check if source exists
if [ ! -d ~/CLIProxyAPI ]; then
    echo "Cloning CLIProxyAPI repository..."
    cd ~
    git clone https://github.com/router-for-me/CLIProxyAPI.git
    cd CLIProxyAPI
else
    echo "Updating CLIProxyAPI source..."
    cd ~/CLIProxyAPI
    git pull
fi

# Build
echo "Building binary..."
# Use full path to Go if not in PATH
if command -v go &> /dev/null; then
    go build -o cli-proxy-api ./cmd/server
else
    /usr/local/go/bin/go build -o cli-proxy-api ./cmd/server
fi

# Install to /usr/local/bin
echo "Installing to /usr/local/bin..."
# Stop service if running to allow binary replacement
if systemctl is-active --quiet cliproxyapi; then
    echo "Stopping cliproxyapi service..."
    sudo systemctl stop cliproxyapi
    sleep 2
fi

sudo cp cli-proxy-api /usr/local/bin/
sudo chmod +x /usr/local/bin/cli-proxy-api

# Restart service if it was running
if systemctl is-enabled --quiet cliproxyapi; then
    echo "Starting cliproxyapi service..."
    sudo systemctl start cliproxyapi
fi

echo "✓ Build complete and service restarted"
