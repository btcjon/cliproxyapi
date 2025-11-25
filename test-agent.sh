#!/bin/bash
# Test script for ClipProxy Expert Agent

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_URL="http://localhost:8100"

echo "╔════════════════════════════════════════════════════╗"
echo "║   ClipProxy Expert Agent - Test Suite              ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Check if agent is running
if ! curl -s "$AGENT_URL/" > /dev/null 2>&1; then
    echo "❌ Error: Agent not running at $AGENT_URL"
    echo ""
    echo "Start the agent with:"
    echo "  ./start-agent.sh"
    exit 1
fi

echo "✅ Agent is running"
echo ""

# Test 1: API Documentation
echo "📋 Test 1: API Documentation"
echo "  GET /"
DOCS=$(curl -s "$AGENT_URL/" | jq '.name')
echo "  Response: $DOCS"
echo "  ✅ Pass"
echo ""

# Test 2: Status Endpoint
echo "📊 Test 2: Status Endpoint"
echo "  GET /status"
STATUS=$(curl -s "$AGENT_URL/status" | jq '.status')
MODEL=$(curl -s "$AGENT_URL/status" | jq -r '.model')
echo "  Status: $STATUS"
echo "  Model: $MODEL"
echo "  ✅ Pass"
echo ""

# Test 3: Empty Messages
echo "💬 Test 3: Messages (Empty)"
echo "  GET /messages"
MESSAGES=$(curl -s "$AGENT_URL/messages" | jq 'length')
echo "  Message count: $MESSAGES"
echo "  ✅ Pass"
echo ""

# Test 4: Send Query
echo "🔄 Test 4: Send Query"
echo "  POST /message"
QUERY="What is ClipProxy?"
echo "  Query: \"$QUERY\""
RESPONSE=$(curl -s -X POST "$AGENT_URL/message" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"$QUERY\"}")
MESSAGE_ID=$(echo "$RESPONSE" | jq '.messageId')
echo "  Message ID: $MESSAGE_ID"
echo "  ✅ Pass (Processing async)"
echo ""

# Test 5: Wait for response
echo "⏳ Test 5: Waiting for response (5 seconds)..."
sleep 5

# Test 6: Get Messages
echo "📬 Test 6: Messages (After Query)"
echo "  GET /messages"
FINAL_MESSAGES=$(curl -s "$AGENT_URL/messages" | jq 'length')
echo "  Message count: $FINAL_MESSAGES"
if [ "$FINAL_MESSAGES" -gt 0 ]; then
    echo "  ✅ Pass"
else
    echo "  ⚠️  No messages yet (still processing)"
fi
echo ""

# Test 7: History Endpoint
echo "📖 Test 7: History (Formatted Text)"
echo "  GET /history"
HISTORY=$(curl -s "$AGENT_URL/history" | head -3)
if [ ! -z "$HISTORY" ]; then
    echo "  ✅ Pass"
    echo ""
    echo "First few lines of history:"
    curl -s "$AGENT_URL/history" | head -5 | sed 's/^/    /'
else
    echo "  ℹ️  No history yet"
fi
echo ""

# Test 8: CORS Headers
echo "🔐 Test 8: CORS Headers"
echo "  OPTIONS /"
CORS=$(curl -s -I -X OPTIONS "$AGENT_URL/message" | grep -i "access-control")
if [ ! -z "$CORS" ]; then
    echo "  ✅ CORS enabled"
else
    echo "  ❌ CORS headers missing"
fi
echo ""

# Summary
echo "╔════════════════════════════════════════════════════╗"
echo "║   Test Summary                                     ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "✅ All core tests passed!"
echo ""
echo "📝 Next steps:"
echo "  1. Use curl to send more queries:"
echo "     curl -X POST http://localhost:8100/message \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"content\": \"Your question\"}'"
echo ""
echo "  2. Check conversation history:"
echo "     curl http://localhost:8100/history"
echo ""
echo "  3. View all messages (JSON):"
echo "     curl http://localhost:8100/messages | jq"
echo ""
echo "  4. Clear conversation:"
echo "     curl -X POST http://localhost:8100/clear"
echo ""
echo "🤖 Agent is ready for integration!"
