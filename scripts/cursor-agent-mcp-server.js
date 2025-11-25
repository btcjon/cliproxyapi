#!/usr/bin/env node
/**
 * MCP Server for Cursor Agent
 * Allows Claude Code to invoke Cursor Agent as a structured tool
 */

const { spawn } = require('child_process');
const readline = require('readline');

// MCP Server implementation
class CursorAgentMCPServer {
  constructor() {
    this.tools = [
      {
        name: 'cursor_agent',
        description: 'Execute a coding task using Cursor AI Agent. The agent will analyze the repository, create a plan, and implement the requested changes.',
        inputSchema: {
          type: 'object',
          properties: {
            repo_path: {
              type: 'string',
              description: 'Absolute path to the git repository'
            },
            task: {
              type: 'string',
              description: 'Detailed description of the coding task to perform'
            },
            dry_run: {
              type: 'boolean',
              description: 'If true, show what would be done without making changes',
              default: false
            }
          },
          required: ['repo_path', 'task']
        }
      }
    ];
  }

  async handleToolCall(toolName, args) {
    if (toolName !== 'cursor_agent') {
      throw new Error(`Unknown tool: ${toolName}`);
    }

    const { repo_path, task, dry_run = false } = args;

    return new Promise((resolve, reject) => {
      const cmdArgs = ['-p', '--force'];
      if (dry_run) {
        cmdArgs.push('--dry-run');
      }
      cmdArgs.push(task);

      const cursorAgent = spawn(
        `${process.env.HOME}/.local/bin/cursor-agent`,
        cmdArgs,
        {
          cwd: repo_path,
          env: process.env
        }
      );

      let stdout = '';
      let stderr = '';

      cursorAgent.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      cursorAgent.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      cursorAgent.on('close', (code) => {
        if (code === 0) {
          resolve({
            content: [
              {
                type: 'text',
                text: `Cursor Agent completed successfully:\n\n${stdout}`
              }
            ]
          });
        } else {
          reject(new Error(`Cursor Agent failed with code ${code}:\n${stderr}`));
        }
      });
    });
  }

  async start() {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: false
    });

    rl.on('line', async (line) => {
      try {
        const request = JSON.parse(line);

        if (request.method === 'tools/list') {
          this.sendResponse({
            tools: this.tools
          });
        } else if (request.method === 'tools/call') {
          const result = await this.handleToolCall(
            request.params.name,
            request.params.arguments
          );
          this.sendResponse(result);
        } else if (request.method === 'initialize') {
          this.sendResponse({
            protocolVersion: '0.1.0',
            capabilities: {
              tools: {}
            },
            serverInfo: {
              name: 'cursor-agent-mcp',
              version: '1.0.0'
            }
          });
        }
      } catch (error) {
        this.sendError(error.message);
      }
    });
  }

  sendResponse(data) {
    console.log(JSON.stringify(data));
  }

  sendError(message) {
    console.error(JSON.stringify({ error: message }));
  }
}

// Start the server
const server = new CursorAgentMCPServer();
server.start();

