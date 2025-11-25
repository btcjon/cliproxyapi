#!/bin/bash
set -euo pipefail

echo "Deploying CLIProxyAPI configuration..."

# Copy config
echo "Updating config..."
cp config/config.yaml ~/.cli-proxy-api/config.yaml

# Update systemd service
echo "Updating systemd service..."
sudo cp systemd/cli-proxy-api.service /etc/systemd/system/cli-proxy-api.service
sudo systemctl daemon-reload

# Restart service
echo "Restarting service..."
sudo systemctl restart cli-proxy-api

# Check status
sleep 2
if sudo systemctl is-active --quiet cli-proxy-api; then
    echo "✓ Service is running"
    sudo systemctl status cli-proxy-api --no-pager | head -15
else
    echo "✗ Service failed to start"
    sudo journalctl -u cli-proxy-api -n 20 --no-pager
    exit 1
fi
