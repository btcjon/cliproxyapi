#!/bin/bash
# Setup Cursor to use CLIProxyAPI on Mac

set -e

echo "=== Cursor + CLIProxyAPI Setup for Mac ==="
echo ""

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bash_profile"
    SHELL_NAME="bash"
else
    echo "Unsupported shell. Please use bash or zsh."
    exit 1
fi

echo "Detected shell: $SHELL_NAME"
echo "Config file: $SHELL_RC"
echo ""

# Ask for setup type
echo "Choose setup method:"
echo "  1) SSH Tunnel (recommended - most secure)"
echo "  2) Direct connection (public IP - less secure)"
read -p "Enter choice [1/2]: " SETUP_TYPE

if [ "$SETUP_TYPE" = "1" ]; then
    BASE_URL="http://localhost:8317"
    TUNNEL_NEEDED=true
    echo ""
    echo "You chose: SSH Tunnel"
elif [ "$SETUP_TYPE" = "2" ]; then
    BASE_URL="http://5.161.192.198:8317"
    TUNNEL_NEEDED=false
    echo ""
    echo "You chose: Direct connection"
    echo "⚠️  Warning: This exposes your proxy publicly"
else
    echo "Invalid choice"
    exit 1
fi

echo ""
echo "=== Adding configuration to $SHELL_RC ==="

# Backup existing config
cp "$SHELL_RC" "$SHELL_RC.backup-$(date +%Y%m%d_%H%M%S)"
echo "✓ Backed up existing config"

# Add CLIProxyAPI configuration
cat >> "$SHELL_RC" << EOF

# === CLIProxyAPI for Cursor ===
# Added $(date)

EOF

if [ "$TUNNEL_NEEDED" = true ]; then
    cat >> "$SHELL_RC" << 'EOF'
# SSH Tunnel alias
alias cliproxy-tunnel='ssh -L 8317:127.0.0.1:8317 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N'
alias cliproxy-tunnel-stop='pkill -f "ssh.*8317"'

EOF
fi

cat >> "$SHELL_RC" << EOF
# OpenAI-compatible endpoint (for Gemini, GPT models)
export OPENAI_API_BASE="$BASE_URL/v1"
export OPENAI_API_KEY="sk-dummy"

# Anthropic endpoint (for Claude models)
export ANTHROPIC_API_BASE="$BASE_URL"
export ANTHROPIC_API_KEY="sk-dummy"

# Google endpoint (for Gemini models)
export GOOGLE_API_BASE="$BASE_URL/v1"
export GOOGLE_API_KEY="sk-dummy"

EOF

echo "✓ Added configuration"

# Source the config
source "$SHELL_RC"
echo "✓ Reloaded shell configuration"

echo ""
echo "=== Setup Complete! ==="
echo ""

if [ "$TUNNEL_NEEDED" = true ]; then
    echo "Next steps:"
    echo "1. Start the SSH tunnel: cliproxy-tunnel"
    echo "2. Test connection: curl $BASE_URL/v1/models"
    echo "3. Open Cursor and start coding!"
    echo ""
    echo "Useful commands:"
    echo "  cliproxy-tunnel       - Start SSH tunnel"
    echo "  cliproxy-tunnel-stop  - Stop SSH tunnel"
    echo "  lsof -i :8317         - Check if tunnel is running"
    echo ""
    echo "Starting tunnel now..."
    cliproxy-tunnel
    sleep 2
    if lsof -i :8317 > /dev/null 2>&1; then
        echo "✓ SSH tunnel is active"
    else
        echo "⚠️  Tunnel failed to start. Try manually: cliproxy-tunnel"
    fi
else
    echo "Configuration complete!"
    echo "Test connection: curl $BASE_URL/v1/models"
    echo "Open Cursor and start coding!"
fi

echo ""
echo "=== Testing Connection ==="
if curl -s "$BASE_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{"model":"gemini-2.5-flash","messages":[{"role":"user","content":"Hello"}],"max_tokens":20}' \
    | grep -q "choices"; then
    echo "✓ Connection successful!"
    echo ""
    echo "Available models:"
    curl -s "$BASE_URL/v1/models" | python3 -c 'import sys, json; data=json.load(sys.stdin); [print(f"  • {m[\"id\"]}") for m in sorted(data["data"], key=lambda x: x["id"])[:10]]; print(f"  ... and {len(data[\"data\"]) - 10} more")'
else
    echo "⚠️  Connection test failed"
    echo "Check CLIProxyAPI service status on VPS"
fi

echo ""
echo "📚 Full documentation: docs/CURSOR-SETUP.md"
echo "🎉 Ready to use Cursor with your AI Ultra subscription!"

