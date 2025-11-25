#!/usr/bin/env bun
import Anthropic from '@anthropic-ai/sdk';
import { readFileSync } from 'fs';
import { join } from 'path';

const PORT = 8100;
const PROJECT_DIR = '/home/dev/Dropbox/Projects/cliproxy-vps-config';

// Configure Anthropic client with CLIProxyAPI
const anthropic = new Anthropic({
  apiKey: 'sk-dummy', // OAuth proxy requires dummy key
  baseURL: 'http://5.161.192.198:8317'
});

// Load project-specific expert personality from CLAUDE.md
let systemPrompt = '';
try {
  const claudeMdPath = join(PROJECT_DIR, '.claude', 'CLAUDE.md');
  const claudeContent = readFileSync(claudeMdPath, 'utf-8');

  systemPrompt = `You are the ClipProxy VPS Configuration Expert Agent.

You have deep knowledge of the cliproxy-vps-config codebase and can answer questions about:
- CLIProxyAPI authentication and credential rotation
- Nginx reverse proxy configuration
- VPS deployment and management
- Proxy provider integrations (Claude, Gemini, OpenAI, Cerebras, Z.AI, Baseten)
- System monitoring and health checks
- OAuth flow and token management
- Configuration YAML structure and best practices

PROJECT CONTEXT (from CLAUDE.md):
${claudeContent}

INSTRUCTIONS FOR RESPONSES:
1. Provide specific code examples from actual project files when relevant
2. Reference file paths and line numbers
3. Explain architectural decisions and trade-offs
4. Highlight important gotchas or considerations
5. For configuration questions, reference the config.yaml structure
6. For deployment questions, reference the scripts/ directory
7. For OAuth issues, explain the token renewal process
8. Always be concise but thorough, with working code examples when needed
9. Suggest relevant commands from the Common Commands section
10. Reference appropriate documentation files (OAUTH.md, API-REFERENCE.md, etc.)`;
} catch (error) {
  console.warn('Warning: Could not load CLAUDE.md, using fallback prompt');
  systemPrompt = `You are the ClipProxy VPS Configuration Expert Agent.

You have deep knowledge of the cliproxy-vps-config codebase and can answer questions about:
- CLIProxyAPI authentication and credential rotation
- Nginx reverse proxy configuration
- VPS deployment and management
- Proxy provider integrations
- System monitoring and health checks

When answering:
1. Provide specific code examples from actual project files
2. Reference file paths and line numbers
3. Explain architectural decisions
4. Highlight important gotchas or considerations

Always be concise but thorough, with working code examples.`;
}

// Conversation state
interface Message {
  role: 'user' | 'assistant';
  content: string;
}

let messages: Message[] = [];
let isProcessing = false;
let lastResponse = '';
let processingError = '';

const server = Bun.serve({
  port: PORT,

  async fetch(req) {
    const url = new URL(req.url);

    // CORS headers
    const headers = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Content-Type': 'application/json'
    };

    if (req.method === 'OPTIONS') {
      return new Response(null, { headers });
    }

    // Health/Status endpoint
    if (url.pathname === '/status') {
      return Response.json({
        status: isProcessing ? 'running' : 'stable',
        project: 'cliproxy-vps-config',
        model: 'claude-sonnet-4-5-20250929',
        endpoint: 'CLIProxyAPI',
        uptime: process.uptime(),
        messageCount: messages.length,
        lastResponse: lastResponse.substring(0, 100) + (lastResponse.length > 100 ? '...' : ''),
        error: processingError || null
      }, { headers });
    }

    // Get all messages
    if (url.pathname === '/messages') {
      return Response.json(
        messages.map((msg, idx) => ({
          type: msg.role,
          content: msg.content,
          index: idx,
          timestamp: new Date().toISOString()
        })),
        { headers }
      );
    }

    // Get conversation history (formatted)
    if (url.pathname === '/history') {
      const history = messages
        .map((msg, idx) => `[${idx}] ${msg.role.toUpperCase()}: ${msg.content}`)
        .join('\n\n');

      return new Response(history || 'No messages yet', {
        headers: { ...headers, 'Content-Type': 'text/plain' }
      });
    }

    // Send message to expert
    if (url.pathname === '/message' && req.method === 'POST') {
      try {
        const body = await req.json();
        const userMessage = body.content || body.message;

        if (!userMessage) {
          return Response.json(
            { error: 'Missing content or message field' },
            { status: 400, headers }
          );
        }

        // Add user message to history
        messages.push({ role: 'user', content: userMessage });
        processingError = '';

        // Start processing (async)
        isProcessing = true;

        // Query Claude via CLIProxyAPI
        (async () => {
          try {
            console.log(`[${new Date().toISOString()}] Processing query: ${userMessage.substring(0, 50)}...`);

            const response = await anthropic.messages.create({
              model: 'claude-sonnet-4-5-20250929',
              max_tokens: 4096,
              system: systemPrompt,
              messages: messages.map(m => ({
                role: m.role,
                content: m.content
              }))
            });

            const assistantMessage = response.content[0]?.type === 'text'
              ? response.content[0].text
              : 'No response generated';

            lastResponse = assistantMessage;
            messages.push({ role: 'assistant', content: assistantMessage });

            console.log(`[${new Date().toISOString()}] Response generated: ${assistantMessage.substring(0, 50)}...`);

          } catch (error) {
            const errorMsg = error instanceof Error ? error.message : String(error);
            console.error(`[${new Date().toISOString()}] Error querying CLIProxyAPI:`, errorMsg);
            processingError = errorMsg;

            const fallbackMsg = `Error: Unable to reach CLIProxyAPI - ${errorMsg}. Please check that the API endpoint is running at http://5.161.192.198:8317`;
            messages.push({ role: 'assistant', content: fallbackMsg });
          } finally {
            isProcessing = false;
          }
        })();

        return Response.json({
          success: true,
          messageId: messages.length - 1,
          status: 'processing'
        }, { headers });

      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        return Response.json(
          { error: errorMsg },
          { status: 500, headers }
        );
      }
    }

    // Clear conversation history
    if (url.pathname === '/clear' && req.method === 'POST') {
      messages = [];
      lastResponse = '';
      processingError = '';
      return Response.json({ success: true, message: 'Conversation cleared' }, { headers });
    }

    // Root endpoint - API documentation
    if (url.pathname === '/') {
      return Response.json({
        name: 'ClipProxy Expert Agent',
        version: '1.0.0',
        project: 'cliproxy-vps-config',
        model: 'claude-sonnet-4-5-20250929',
        baseUrl: 'http://5.161.192.198:8317',
        endpoints: {
          GET: {
            '/': 'This documentation',
            '/status': 'Agent status and uptime',
            '/messages': 'Get conversation history (JSON)',
            '/history': 'Get conversation history (formatted text)'
          },
          POST: {
            '/message': 'Send question to expert (body: {content: string})',
            '/clear': 'Clear conversation history'
          }
        },
        examples: {
          sendMessage: {
            method: 'POST',
            url: '/message',
            body: { content: 'How do I configure OAuth for Gemini?' }
          },
          getStatus: {
            method: 'GET',
            url: '/status'
          }
        }
      }, { headers });
    }

    return Response.json(
      { error: 'Not found', available: ['/', '/status', '/messages', '/history', '/message', '/clear'] },
      { status: 404, headers }
    );
  }
});

console.log(`🤖 ClipProxy Expert Agent running on http://localhost:${PORT}`);
console.log(`📁 Project: ${PROJECT_DIR}`);
console.log(`🧠 Model: claude-sonnet-4-5-20250929 via CLIProxyAPI`);
console.log(`🌐 Proxy: http://5.161.192.198:8317`);
console.log(`\n📡 Endpoints:`);
console.log(`  GET  /             - API documentation`);
console.log(`  GET  /status       - Agent status`);
console.log(`  GET  /messages     - Conversation history (JSON)`);
console.log(`  GET  /history      - Conversation history (text)`);
console.log(`  POST /message      - Send question to expert`);
console.log(`  POST /clear        - Clear conversation history`);
console.log(`\n✨ Ready for queries. Open http://localhost:${PORT}/ for more info.`);
