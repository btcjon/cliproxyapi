#!/bin/bash

# Install systemd service for cliproxy expert agent

SERVICE_FILE="$(dirname "$0")/cliproxy-expert.service"
SYSTEMD_DIR="/etc/systemd/system"

echo "📦 Installing ClipProxy Expert Agent systemd service..."

# Copy service file
sudo cp "$SERVICE_FILE" "$SYSTEMD_DIR/cliproxy-expert.service"

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable cliproxy-expert

echo "✅ Service installed and enabled"
echo ""
echo "Commands:"
echo "  Start:   sudo systemctl start cliproxy-expert"
echo "  Stop:    sudo systemctl stop cliproxy-expert"
echo "  Status:  sudo systemctl status cliproxy-expert"
echo "  Logs:    journalctl -u cliproxy-expert -f"
echo ""
echo "To start now: sudo systemctl start cliproxy-expert"
