#!/bin/bash
# Test external API access to CLIProxyAPI
# This script tests all available models from an external client perspective

VPS_HOST="${1:-5.161.192.198}"
VPS_PORT="${2:-8317}"
BASE_URL="http://${VPS_HOST}:${VPS_PORT}"

echo "========================================"
echo "CLIProxyAPI External API Test"
echo "========================================"
echo "Base URL: $BASE_URL"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASS=0
FAIL=0

test_endpoint() {
    local name="$1"
    local endpoint="$2"
    local data="$3"
    local headers="$4"
    
    echo -n "Testing $name... "
    
    response=$(curl -s -w "\n%{http_code}" $headers "$BASE_URL$endpoint" \
        -H "Content-Type: application/json" \
        -d "$data")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASS=$((PASS + 1))
        # Show first 100 chars of response
        echo "$body" | jq -r '.choices[0].message.content // .content[0].text' 2>/dev/null | head -c 100
        echo "..."
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
        FAIL=$((FAIL + 1))
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
    fi
    echo ""
}

# Test 1: List models
echo "1. Listing Available Models"
echo "----------------------------"
models=$(curl -s "$BASE_URL/v1/models" | jq -r '.data[].id' 2>/dev/null)
if [ -n "$models" ]; then
    echo -e "${GREEN}✓ Successfully retrieved models${NC}"
    echo "$models" | head -5
    model_count=$(echo "$models" | wc -l)
    echo "... ($model_count total models)"
    PASS=$((PASS + 1))
else
    echo -e "${RED}✗ Failed to retrieve models${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# Test 2: Gemini (OpenAI format)
echo "2. Testing Gemini 2.5 Flash (AI Ultra)"
echo "---------------------------------------"
test_endpoint \
    "Gemini 2.5 Flash" \
    "/v1/chat/completions" \
    '{"model":"gemini-2.5-flash","messages":[{"role":"user","content":"Say hello in one word"}],"max_tokens":5}' \
    '-H "Authorization: Bearer sk-dummy"'

# Test 3: GPT (OpenAI format)
echo "3. Testing GPT-5"
echo "----------------"
test_endpoint \
    "GPT-5" \
    "/v1/chat/completions" \
    '{"model":"gpt-5","messages":[{"role":"user","content":"Say hello in one word"}],"max_tokens":5}' \
    '-H "Authorization: Bearer sk-dummy"'

# Test 4: Claude (Anthropic format)
echo "4. Testing Claude Sonnet"
echo "------------------------"
test_endpoint \
    "Claude Sonnet" \
    "/v1/messages" \
    '{"model":"claude-sonnet-4-5-20250929","messages":[{"role":"user","content":"Say hello in one word"}],"max_tokens":5}' \
    '-H "anthropic-version: 2023-06-01" -H "x-api-key: sk-dummy"'

# Test 5: GLM (OpenAI format)
echo "5. Testing Z.AI GLM 4.6"
echo "-----------------------"
test_endpoint \
    "GLM 4.6" \
    "/v1/chat/completions" \
    '{"model":"glm-4.6","messages":[{"role":"user","content":"Say hello in one word"}],"max_tokens":5}' \
    '-H "Authorization: Bearer sk-dummy"'

# Test 6: Streaming
echo "6. Testing Streaming (Gemini)"
echo "-----------------------------"
echo -n "Testing streaming... "
stream_response=$(curl -s "$BASE_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer sk-dummy" \
    -d '{"model":"gemini-2.5-flash","messages":[{"role":"user","content":"Count to 3"}],"stream":true,"max_tokens":20}')

if echo "$stream_response" | grep -q "data:"; then
    echo -e "${GREEN}✓ PASS${NC}"
    echo "Received streaming response (SSE format)"
    PASS=$((PASS + 1))
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "$stream_response"
    FAIL=$((FAIL + 1))
fi
echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo "Total: $((PASS + FAIL))"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Your CLIProxyAPI is working correctly and ready for external use."
    echo "See docs/API-REFERENCE.md for complete usage documentation."
    exit 0
else
    echo -e "${YELLOW}⚠ Some tests failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check service status: ssh dev@$VPS_HOST 'sudo systemctl status cli-proxy-api'"
    echo "2. View logs: ssh dev@$VPS_HOST 'tail -100 ~/.cli-proxy-api/logs/main.log'"
    echo "3. Verify config: ssh dev@$VPS_HOST 'bash -s' < scripts/verify-config.sh"
    exit 1
fi

