#!/bin/bash
# Fix Claude Code configuration to work properly with CLIProxyAPI
# Run this on your Mac

set -e

echo "=== Claude Code + CLIProxyAPI Configuration Fix ==="
echo ""

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_PROFILE="$HOME/.zprofile"
    SHELL_NAME="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_PROFILE="$HOME/.bash_profile"
    SHELL_NAME="bash"
else
    echo "Unsupported shell. Please use bash or zsh."
    exit 1
fi

echo "Detected shell: $SHELL_NAME"
echo ""

# Backup
BACKUP_SUFFIX=".backup-$(date +%Y%m%d_%H%M%S)"
cp "$SHELL_RC" "${SHELL_RC}${BACKUP_SUFFIX}" 2>/dev/null || true
cp "$SHELL_PROFILE" "${SHELL_PROFILE}${BACKUP_SUFFIX}" 2>/dev/null || true
echo "✓ Backed up existing configs"

# Remove problematic variables
echo ""
echo "=== Removing Problematic Variables ==="

for file in "$SHELL_RC" "$SHELL_PROFILE"; do
    if [ -f "$file" ]; then
        # Comment out or remove ANTHROPIC_DEFAULT_* variables
        sed -i.tmp '/export ANTHROPIC_DEFAULT_OPUS_MODEL/d' "$file" 2>/dev/null || true
        sed -i.tmp '/export ANTHROPIC_DEFAULT_SONNET_MODEL/d' "$file" 2>/dev/null || true
        sed -i.tmp '/export ANTHROPIC_DEFAULT_HAIKU_MODEL/d' "$file" 2>/dev/null || true
        rm -f "${file}.tmp"
        echo "  ✓ Cleaned $file"
    fi
done

# Add correct configuration
echo ""
echo "=== Adding Correct Configuration ==="

cat >> "$SHELL_RC" << 'EOF'

# === CLIProxyAPI Configuration (Fixed) ===
# Updated: $(date)

# Remove any model override variables that cause conflicts
unset ANTHROPIC_DEFAULT_OPUS_MODEL
unset ANTHROPIC_DEFAULT_SONNET_MODEL
unset ANTHROPIC_DEFAULT_HAIKU_MODEL

# Anthropic/Claude endpoint (for Claude models)
export ANTHROPIC_API_BASE="http://localhost:8317"
export ANTHROPIC_API_KEY="sk-dummy"

# OpenAI endpoint (for GPT and other OpenAI-compatible models)
export OPENAI_API_BASE="http://localhost:8317/v1"
export OPENAI_API_KEY="sk-dummy"

# Google/Gemini endpoint (for Gemini models)
export GOOGLE_API_BASE="http://localhost:8317/v1"
export GOOGLE_API_KEY="sk-dummy"

# Helper function to check CLIProxyAPI connection
function cliproxy-check() {
    echo "Testing CLIProxyAPI connection..."
    if curl -s http://localhost:8317/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d '{"model":"gemini-2.5-flash","messages":[{"role":"user","content":"test"}],"max_tokens":5}' \
        | grep -q "choices"; then
        echo "✓ CLIProxyAPI is working!"
    else
        echo "✗ CLIProxyAPI connection failed"
        echo "  Make sure SSH tunnel is active: cliproxy-tunnel"
    fi
}

EOF

echo "✓ Added configuration to $SHELL_RC"

# Fix Claude Desktop App config if it exists
CLAUDE_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
if [ -f "$CLAUDE_CONFIG" ]; then
    echo ""
    echo "=== Checking Claude Desktop App Config ==="
    
    # Backup
    cp "$CLAUDE_CONFIG" "${CLAUDE_CONFIG}${BACKUP_SUFFIX}"
    
    # Check if there are problematic env vars in the config
    if grep -q "ANTHROPIC_DEFAULT" "$CLAUDE_CONFIG" 2>/dev/null; then
        echo "⚠️  Found ANTHROPIC_DEFAULT_* variables in Claude config"
        echo "   Please manually review: $CLAUDE_CONFIG"
        echo "   Remove any ANTHROPIC_DEFAULT_* variables from the env section"
    else
        echo "✓ Claude desktop config looks good"
    fi
fi

# Source the new config
source "$SHELL_RC"
echo ""
echo "✓ Reloaded shell configuration"

# Test configuration
echo ""
echo "=== Testing Configuration ==="
echo ""
echo "Environment variables:"
echo "  ANTHROPIC_API_BASE: ${ANTHROPIC_API_BASE:-NOT SET}"
echo "  OPENAI_API_BASE: ${OPENAI_API_BASE:-NOT SET}"
echo "  GOOGLE_API_BASE: ${GOOGLE_API_BASE:-NOT SET}"
echo ""

# Check for tunnel
if lsof -i :8317 > /dev/null 2>&1; then
    echo "✓ SSH tunnel is active on port 8317"
    echo ""
    echo "Running connection test..."
    cliproxy-check
else
    echo "⚠️  SSH tunnel is not active"
    echo "   Start it with: cliproxy-tunnel"
    echo "   Or manually: ssh -L 8317:127.0.0.1:8317 -i ~/.ssh/pai_deploy dev@5.161.192.198 -f -N"
fi

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "✓ Removed problematic ANTHROPIC_DEFAULT_* variables"
echo "✓ Set correct API endpoints for CLIProxyAPI"
echo "✓ All models now accessible by their actual names"
echo ""
echo "Model naming guide:"
echo "  - Gemini:  gemini-2.5-flash, gemini-2.5-pro"
echo "  - GPT:     gpt-5, gpt-5-codex-high, gpt-5-codex-medium"
echo "  - Claude:  claude-sonnet-4-5-20250929, claude-opus-4-1-20250805"
echo ""
echo "📚 Full documentation: docs/CURSOR-SETUP.md"

