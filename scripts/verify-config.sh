#!/bin/bash
# Verify CLIProxyAPI configuration is correct

echo "=== CLIProxyAPI Configuration Verification ==="
echo ""

# Check service status
echo "1. Service Status:"
if sudo systemctl is-active --quiet cli-proxy-api; then
    echo "   ✓ cli-proxy-api is running"
else
    echo "   ✗ cli-proxy-api is not running"
    echo "   Run: sudo systemctl start cli-proxy-api"
    exit 1
fi
echo ""

# Test endpoints
echo "2. Testing Endpoints:"
echo ""

# Test Claude
echo "   Testing Claude..."
CLAUDE_RESULT=$(curl -s http://localhost:8317/v1/messages \
    -H 'Content-Type: application/json' \
    -H 'anthropic-version: 2023-06-01' \
    -d '{"model":"claude-sonnet-4-5-20250929","messages":[{"role":"user","content":"hi"}],"max_tokens":5}')

if echo "$CLAUDE_RESULT" | grep -q '"type":"message"'; then
    echo "   ✓ Claude is working"
else
    echo "   ✗ Claude failed"
    echo "   Response: $CLAUDE_RESULT"
fi
echo ""

# Test Gemini
echo "   Testing Gemini..."
GEMINI_RESULT=$(curl -s http://localhost:8317/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{"model":"gemini-2.5-flash","messages":[{"role":"user","content":"hi"}],"max_tokens":5}')

if echo "$GEMINI_RESULT" | grep -q '"choices"'; then
    echo "   ✓ Gemini is working (AI Ultra subscription)"
else
    echo "   ✗ Gemini failed"
    echo "   Response: $GEMINI_RESULT"
fi
echo ""

# Test GPT
echo "   Testing GPT..."
GPT_RESULT=$(curl -s http://localhost:8317/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{"model":"gpt-5","messages":[{"role":"user","content":"hi"}],"max_tokens":5}')

if echo "$GPT_RESULT" | grep -q '"choices"'; then
    echo "   ✓ GPT is working"
else
    echo "   ✗ GPT failed"
    echo "   Response: $GPT_RESULT"
fi
echo ""

# List active clients
echo "3. Active Clients:"
tail -5 ~/.cli-proxy-api/logs/service.log | grep "clients and configuration" | tail -1 || echo "   Could not determine client count"
echo ""

# Check for problematic config
echo "4. Configuration Check:"
if grep -q "^export ANTHROPIC_DEFAULT" ~/.bashrc ~/.bash_profile 2>/dev/null; then
    echo "   ⚠️  Found ANTHROPIC_DEFAULT_* variables (these cause 500 errors)"
    echo "   These should be commented out or removed"
else
    echo "   ✓ No conflicting ANTHROPIC_DEFAULT_* variables"
fi
echo ""

# Check OAuth tokens
echo "5. OAuth Token Status:"
echo ""

# Claude
if [ -f ~/.cli-proxy-api/claude-anthropic@decentral.email.json ]; then
    CLAUDE_EXPIRY=$(grep -o '"expiry":"[^"]*"' ~/.cli-proxy-api/claude-anthropic@decentral.email.json | cut -d'"' -f4)
    echo "   Claude: $CLAUDE_EXPIRY"
else
    echo "   Claude: NOT CONFIGURED"
fi

# Gemini
GEMINI_COUNT=$(ls ~/.cli-proxy-api/jonebennett@gmail.com-gen-lang-client-*.json 2>/dev/null | wc -l)
echo "   Gemini: $GEMINI_COUNT project(s) configured"

# OpenAI
if [ -f ~/.cli-proxy-api/codex-*.json ]; then
    echo "   OpenAI: Configured"
else
    echo "   OpenAI: NOT CONFIGURED"
fi

echo ""
echo "=== Verification Complete ==="

