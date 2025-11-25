# ClipProxy Expert Agent

HTTP server providing expert knowledge about ClipProxy VPS configuration and deployment.

## Features

- **Expert Knowledge**: Answers questions about ClipProxy architecture, configuration, and deployment
- **Conversation Memory**: Maintains context across multiple queries
- **Real-time Processing**: Async query handling with status tracking
- **RESTful API**: Simple HTTP endpoints for integration
- **OAuth-Authenticated**: Uses CLIProxyAPI for secure Claude access

## Quick Start

### Option 1: Using the startup script (recommended)

```bash
cd /home/dev/Dropbox/Projects/cliproxy-vps-config
./start-agent.sh
```

### Option 2: Direct with bun

```bash
cd /home/dev/Dropbox/Projects/cliproxy-vps-config
bun install
bun expert-agent-server.ts
```

The server starts on **http://localhost:8100**

## API Endpoints

### GET `/`
API documentation and endpoint reference.

```bash
curl http://localhost:8100/
```

### GET `/status`
Check agent status, model, uptime, and last response.

```bash
curl http://localhost:8100/status
```

Response:
```json
{
  "status": "stable",
  "project": "cliproxy-vps-config",
  "model": "claude-sonnet-4-5-20250929",
  "endpoint": "CLIProxyAPI",
  "uptime": 123.45,
  "messageCount": 5,
  "lastResponse": "For authentication...",
  "error": null
}
```

### GET `/messages`
Get all messages in conversation history (JSON format).

```bash
curl http://localhost:8100/messages
```

Response:
```json
[
  {
    "type": "user",
    "content": "How do I configure OAuth for Gemini?",
    "index": 0,
    "timestamp": "2025-11-14T14:23:49.998Z"
  },
  {
    "type": "assistant",
    "content": "To configure OAuth for Gemini...",
    "index": 1,
    "timestamp": "2025-11-14T14:23:52.123Z"
  }
]
```

### GET `/history`
Get conversation history as formatted text.

```bash
curl http://localhost:8100/history
```

Response:
```
[0] USER: How do I configure OAuth for Gemini?

[1] ASSISTANT: To configure OAuth for Gemini, you need to run the renewal script...
```

### POST `/message`
Send a query to the expert agent.

```bash
curl -X POST http://localhost:8100/message \
  -H "Content-Type: application/json" \
  -d '{"content": "How do I configure OAuth for Gemini?"}'
```

The endpoint accepts either `content` or `message` field:

```bash
# Alternative syntax
curl -X POST http://localhost:8100/message \
  -H "Content-Type: application/json" \
  -d '{"message": "How do I deploy CLIProxyAPI?"}'
```

Response (immediate, processing happens async):
```json
{
  "success": true,
  "messageId": 2,
  "status": "processing"
}
```

Check status with `/status` endpoint or wait a moment then fetch `/messages`.

### POST `/clear`
Clear all conversation history and reset state.

```bash
curl -X POST http://localhost:8100/clear
```

Response:
```json
{
  "success": true,
  "message": "Conversation cleared"
}
```

## Example Queries

### OAuth Configuration
```bash
curl -X POST http://localhost:8100/message \
  -H "Content-Type: application/json" \
  -d '{"content": "How do I renew OAuth tokens for Claude?"}'
```

### Nginx Configuration
```bash
curl -X POST http://localhost:8100/message \
  -H "Content-Type: application/json" \
  -d '{"content": "Explain the Nginx reverse proxy configuration"}'
```

### Deployment Issues
```bash
curl -X POST http://localhost:8100/message \
  -H "Content-Type: application/json" \
  -d '{"content": "The service failed to start. What should I check?"}'
```

### Model Information
```bash
curl -X POST http://localhost:8100/message \
  -H "Content-Type: application/json" \
  -d '{"content": "Which AI models are available through CLIProxyAPI?"}'
```

## Integration Examples

### Python

```python
import requests
import json

BASE_URL = "http://localhost:8100"

# Send query
response = requests.post(
    f"{BASE_URL}/message",
    json={"content": "How do I configure OAuth for Gemini?"}
)
print(f"Query sent: {response.json()}")

# Get history
history = requests.get(f"{BASE_URL}/messages").json()
for msg in history:
    print(f"{msg['type'].upper()}: {msg['content']}")

# Check status
status = requests.get(f"{BASE_URL}/status").json()
print(f"Agent status: {status['status']}")
```

### JavaScript/Node.js

```javascript
const BASE_URL = "http://localhost:8100";

// Send query
const response = await fetch(`${BASE_URL}/message`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ content: "How do I deploy CLIProxyAPI?" })
});
console.log(await response.json());

// Get history
const history = await fetch(`${BASE_URL}/messages`).then(r => r.json());
history.forEach(msg => {
  console.log(`${msg.type.toUpperCase()}: ${msg.content}`);
});

// Check status
const status = await fetch(`${BASE_URL}/status`).then(r => r.json());
console.log(`Uptime: ${status.uptime}s`);
```

### Bash

```bash
# Function to ask the expert
ask_expert() {
  curl -X POST http://localhost:8100/message \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"$1\"}" \
    --silent | jq '.messageId'

  sleep 1  # Wait for processing

  curl http://localhost:8100/messages \
    --silent | jq '.[-1].content'
}

# Usage
ask_expert "How do I renew OAuth tokens?"
```

## Expert Knowledge Areas

The agent has knowledge about:

- **OAuth Configuration**: Token setup and renewal for Claude, Gemini, OpenAI
- **CLIProxyAPI Architecture**: How the proxy works and handles requests
- **Nginx Configuration**: Reverse proxy setup and optimization
- **VPS Deployment**: Service configuration, systemd management
- **Provider Integration**: Gemini, Claude, OpenAI, Cerebras, Z.AI, Baseten
- **Configuration YAML**: Structure, options, and best practices
- **Troubleshooting**: Common issues and solutions
- **Monitoring**: Health checks and logging

## Technical Details

### Architecture

```
Client Tools
    ↓
CLIProxyAPI (localhost:8317)
    ↓
Claude Sonnet 4.5 (via OAuth)
    ↓
Expert Agent Response
```

### Configuration

- **Port**: 8100
- **Model**: claude-sonnet-4-5-20250929
- **Proxy**: CLIProxyAPI at http://5.161.192.198:8317
- **Base URL**: http://5.161.192.198:8317
- **System Prompt**: Loaded from CLAUDE.md project context

### Processing

- Queries are processed asynchronously
- Responses are stored in memory
- Full conversation history is maintained
- Status endpoint shows processing progress

## Monitoring

### View Logs

```bash
# Follow agent startup
tail -f /tmp/agent.log

# Or check in terminal where server is running
```

### Check Agent Health

```bash
curl http://localhost:8100/status | jq .
```

### View Conversation

```bash
curl http://localhost:8100/history
```

## Performance

- **Response Time**: ~2-5 seconds depending on query complexity
- **Concurrent Queries**: Sequential processing (one at a time)
- **Memory**: ~150-200 MB base + query overhead
- **Uptime**: Runs continuously while server is active

## Troubleshooting

### "Connection refused" error

**Issue**: Agent not running or port 8100 not accessible

```bash
# Check if server is running
lsof -i :8100

# Check CLIProxyAPI connectivity
curl http://5.161.192.198:8317/status
```

### "Empty response from agent"

**Issue**: Query may still be processing

```bash
# Wait a moment
sleep 2

# Check status
curl http://localhost:8100/status

# Get latest message
curl http://localhost:8100/messages | jq '.[-1]'
```

### "API error from CLIProxyAPI"

**Issue**: Proxy endpoint unavailable or credentials expired

```bash
# Verify proxy is running
curl http://5.161.192.198:8317

# Check logs on VPS
ssh dev@5.161.192.198
systemctl status cli-proxy-api
```

## Files

- `expert-agent-server.ts` - Main server implementation
- `package.json` - Node.js/Bun dependencies
- `start-agent.sh` - Startup script with installation
- `CLAUDE.md` - Project context for expert knowledge
- `EXPERT-AGENT.md` - This documentation

## Development

### Watch mode with auto-reload

```bash
bun --watch expert-agent-server.ts
```

### Test syntax

```bash
bun --check expert-agent-server.ts
```

### Update dependencies

```bash
bun update
```

## License

MIT - Part of the ClipProxy VPS Config project
