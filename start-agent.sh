#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT=8100

echo "╔════════════════════════════════════════════════════╗"
echo "║   ClipProxy Expert Agent Startup                   ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "📁 Project: $PROJECT_DIR"
echo "🔌 Port: $PORT"
echo "🤖 Model: claude-sonnet-4-5-20250929"
echo "🌐 Proxy: http://5.161.192.198:8317"
echo ""

cd "$PROJECT_DIR"

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo "❌ Error: bun is not installed"
    echo "   Install bun from https://bun.sh"
    exit 1
fi

echo "📦 Installing dependencies..."
bun install

echo ""
echo "✅ Dependencies installed"
echo ""
echo "🚀 Starting ClipProxy Expert Agent..."
echo "   Access at: http://localhost:$PORT"
echo "   Docs at:   http://localhost:$PORT/"
echo ""
echo "Press Ctrl+C to stop"
echo ""

bun expert-agent-server.ts
