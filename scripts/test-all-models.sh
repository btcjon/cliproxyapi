#!/bin/bash
# Test every available model with a simple query
# This ensures all models are accessible via external API

VPS_URL="http://5.161.192.198:8317"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

echo "=========================================="
echo "Testing All CLIProxyAPI Models"
echo "=========================================="
echo ""

test_openai_model() {
    local model="$1"
    local description="$2"
    
    echo -n "Testing $model... "
    
    response=$(curl -s -w "\n%{http_code}" "$VPS_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-dummy" \
        -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"Say hi\"}],\"max_tokens\":10}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        content=$(echo "$body" | jq -r '.choices[0].message.content' 2>/dev/null)
        if [ -n "$content" ] && [ "$content" != "null" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
            echo "  Response: $(echo "$content" | head -c 50)..."
            PASS=$((PASS + 1))
        else
            echo -e "${RED}✗ FAIL${NC} - No content in response"
            FAIL=$((FAIL + 1))
        fi
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
        echo "  Error: $(echo "$body" | jq -r '.error.message // .error // .' 2>/dev/null | head -c 100)"
        FAIL=$((FAIL + 1))
    fi
    echo ""
}

test_claude_model() {
    local model="$1"
    local description="$2"
    
    echo -n "Testing $model... "
    
    response=$(curl -s -w "\n%{http_code}" "$VPS_URL/v1/messages" \
        -H "Content-Type: application/json" \
        -H "anthropic-version: 2023-06-01" \
        -H "x-api-key: sk-dummy" \
        -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"Say hi\"}],\"max_tokens\":10}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        content=$(echo "$body" | jq -r '.content[0].text' 2>/dev/null)
        if [ -n "$content" ] && [ "$content" != "null" ]; then
            echo -e "${GREEN}✓ PASS${NC}"
            echo "  Response: $(echo "$content" | head -c 50)..."
            PASS=$((PASS + 1))
        else
            echo -e "${RED}✗ FAIL${NC} - No content in response"
            FAIL=$((FAIL + 1))
        fi
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
        echo "  Error: $(echo "$body" | jq -r '.error.message // .error // .' 2>/dev/null | head -c 100)"
        FAIL=$((FAIL + 1))
    fi
    echo ""
}

# Test Gemini Models
echo -e "${BLUE}=== GEMINI MODELS (AI Ultra Subscription) ===${NC}"
test_openai_model "gemini-2.5-flash" "Fast, general purpose"
test_openai_model "gemini-2.5-pro" "Advanced reasoning"
test_openai_model "gemini-3-pro-preview-11-2025" "Latest preview"

# Test Claude Models
echo -e "${BLUE}=== CLAUDE MODELS ===${NC}"
test_claude_model "claude-opus-4-20250514" "Opus (May 2025)"
test_claude_model "claude-sonnet-4-20250514" "Sonnet (May 2025)"
test_claude_model "claude-3-5-haiku-20241022" "Haiku 3.5"
test_claude_model "claude-opus-4-1-20250805" "Opus 4.1"
test_claude_model "claude-sonnet-4-5-20250929" "Sonnet 4.5 (Current)"
test_claude_model "claude-3-7-sonnet-20250219" "Sonnet 3.7"
test_claude_model "claude-haiku-4-5-20251001" "Haiku 4.5"

# Test GPT Models
echo -e "${BLUE}=== GPT-5 MODELS ===${NC}"
test_openai_model "gpt-5-minimal" "Minimal tier"
test_openai_model "gpt-5-low" "Low tier"
test_openai_model "gpt-5-medium" "Medium tier"
test_openai_model "gpt-5-high" "High tier"
test_openai_model "gpt-5" "Standard"

# Test GPT Codex Models
echo -e "${BLUE}=== GPT-5 CODEX MODELS ===${NC}"
test_openai_model "gpt-5-codex-mini" "Codex Mini"
test_openai_model "gpt-5-codex-mini-medium" "Codex Mini Medium"
test_openai_model "gpt-5-codex-mini-high" "Codex Mini High"
test_openai_model "gpt-5-codex-low" "Codex Low"
test_openai_model "gpt-5-codex-medium" "Codex Medium"
test_openai_model "gpt-5-codex-high" "Codex High"
test_openai_model "gpt-5-codex" "Codex Standard"

# Test Z.AI GLM Models
echo -e "${BLUE}=== Z.AI GLM MODELS ===${NC}"
test_openai_model "glm-4.6" "GLM 4.6 (Advanced)"
test_openai_model "glm-4.5-air" "GLM 4.5 Air (Fast)"

# Test Baseten Kimi
echo -e "${BLUE}=== BASETEN MODELS ===${NC}"
test_openai_model "kimi-k2-thinking" "Kimi K2 Thinking"

# Summary
echo "=========================================="
echo -e "${BLUE}TEST SUMMARY${NC}"
echo "=========================================="
echo -e "Total Models Tested: $((PASS + FAIL))"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ ALL MODELS WORKING! ✓✓✓${NC}"
    echo ""
    echo "Your CLIProxyAPI is fully operational."
    echo "All 25 models are accessible via external API."
    exit 0
else
    SUCCESS_RATE=$(( (PASS * 100) / (PASS + FAIL) ))
    echo -e "${YELLOW}Success Rate: $SUCCESS_RATE%${NC}"
    echo ""
    echo "Some models failed. This could be due to:"
    echo "  - OAuth tokens expired (run ./scripts/oauth-renew.sh)"
    echo "  - Model temporarily unavailable"
    echo "  - Rate limits hit"
    echo ""
    echo "Check logs: ssh dev@5.161.192.198 'tail -100 ~/.cli-proxy-api/logs/main.log'"
    exit 1
fi

