# Using Cursor Agent with Claude Code

This guide shows how to set up Cursor Agent as a tool that Claude Code can invoke for executing coding tasks.

## What This Does

**Claude Code can delegate coding tasks to Cursor Agent**, which will:
- Analyze the repository
- Create an execution plan
- Implement the changes
- Run tests and validation
- Return results to Claude

This creates a powerful workflow where Claude can **plan** and **orchestate**, while Cursor Agent **executes** the actual coding.

## Installation

### 1. Cursor Agent is Already Installed ✓

```bash
~/.local/bin/cursor-agent --version
# 2025.11.06-8fe8a63
```

### 2. Configure MCP Server for Claude

Add to your Claude desktop app config (`~/.config/Claude/claude_desktop_config.json` on Linux/Mac):

```json
{
  "mcpServers": {
    "cursor-agent": {
      "command": "node",
      "args": ["/home/dev/Dropbox/Projects/cliproxy-vps-config/scripts/cursor-agent-mcp-server.js"],
      "env": {
        "PATH": "/home/dev/.local/bin:/usr/local/bin:/usr/bin:/bin"
      }
    }
  }
}
```

## Usage

### From Claude Code

Once configured, Claude Code will see a new tool called `cursor_agent`. You can ask Claude to use it:

**Example prompts:**
```
"Use cursor_agent to refactor the authentication module in /path/to/repo"

"Run cursor_agent to add TypeScript types to all functions in the utils folder"

"Have cursor_agent implement the new API endpoint we discussed"
```

### Tool Parameters

```javascript
{
  repo_path: "/absolute/path/to/repository",
  task: "Detailed description of what to do",
  dry_run: false  // Optional: preview changes without applying
}
```

### Direct Command Line Usage

You can also invoke cursor-agent directly:

```bash
# Navigate to your repository
cd /path/to/your/project

# Run a task
~/.local/bin/cursor-agent -p --force "Add error handling to all API calls"
```

**Flags:**
- `-p` - Print mode (non-interactive)
- `--force` - Apply changes without confirmation
- `--dry-run` - Preview changes only

### Using the Wrapper Script

A convenience wrapper is available at `~/cursor-agent-tool.sh`:

```bash
~/cursor-agent-tool.sh /path/to/repo "Task description"
```

## Example Workflows

### 1. Code Refactoring

**Claude's role:** Analyze codebase, identify refactoring needs, create plan
**Cursor Agent's role:** Execute the refactoring

```
Claude: "I've analyzed the auth module. Let me have cursor_agent refactor it..."
cursor_agent({
  repo_path: "/home/dev/project",
  task: "Refactor auth/login.ts to use async/await and add proper error handling"
})
```

### 2. Feature Implementation

**Claude's role:** Design the feature, break down requirements
**Cursor Agent's role:** Implement the code

```
Claude: "Here's the plan for the new dashboard. I'll have cursor_agent implement it..."
cursor_agent({
  repo_path: "/home/dev/dashboard-app",
  task: "Create a new dashboard component with real-time data display, following the design in SPEC.md"
})
```

### 3. Bug Fixing

**Claude's role:** Understand the bug, identify root cause
**Cursor Agent's role:** Fix the code

```
Claude: "The bug is in the rate limiter. Let me fix it..."
cursor_agent({
  repo_path: "/home/dev/api",
  task: "Fix rate limiter logic in middleware/rateLimiter.ts - should reset counter every hour, not accumulate"
})
```

## Configuration

### Repository Setup

For best results, add an `environment.json` file to your repositories:

```json
{
  "install": "npm install",
  "terminals": [
    {
      "name": "dev",
      "command": "npm run dev"
    },
    {
      "name": "test",
      "command": "npm test"
    }
  ]
}
```

This tells Cursor Agent how to set up and test your project.

### GitHub Integration

Cursor Agent can integrate with GitHub:

1. Link your GitHub account: `cursor-agent auth github`
2. Grant repository access
3. Agent can then clone, edit, and push changes automatically

## Advanced Features

### Multi-Step Tasks

Cursor Agent can handle complex multi-step operations:

```bash
cursor-agent -p --force "
1. Add a new user management API endpoint
2. Create database migrations
3. Add tests for the new endpoint
4. Update API documentation
"
```

### Iterative Refinement

You can refine results by running multiple tasks:

```bash
# First pass
cursor-agent -p --force "Add user authentication"

# Review and refine
cursor-agent -p --force "Add rate limiting to the auth endpoint"

# Polish
cursor-agent -p --force "Add comprehensive error messages and logging"
```

## Troubleshooting

### "cursor-agent: command not found"

Use the full path:
```bash
~/.local/bin/cursor-agent --version
```

Or add to PATH in `~/.bashrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### MCP Server Not Connecting

Check Claude desktop app logs:
- Linux: `~/.config/Claude/logs/`
- Mac: `~/Library/Logs/Claude/`

Verify Node.js is installed:
```bash
node --version  # Should be v14+
```

### Agent Not Making Changes

Ensure you're using the `-p --force` flags:
```bash
cursor-agent -p --force "Your task"
```

Without `--force`, it runs in interactive mode (won't work from Claude).

### Repository Access Issues

Make sure:
- Repository is a valid git repository
- You have write permissions
- No uncommitted changes (or use `--allow-dirty`)

## Performance Tips

1. **Be specific** - Detailed task descriptions get better results
2. **One task at a time** - Break complex changes into steps
3. **Review changes** - Use `dry_run: true` first for big changes
4. **Use context** - Reference existing files/patterns in your task description

## Security Considerations

⚠️ **Important:**
- Cursor Agent has **full access** to the repository it's running on
- Always review changes before committing/pushing
- Use `--dry-run` for untrusted or experimental tasks
- Don't run on repositories with sensitive data unless necessary

## Comparison: Claude Code vs Cursor Agent

| Feature | Claude Code | Cursor Agent |
|---------|-------------|--------------|
| Planning | ✅ Excellent | ❌ Basic |
| Code Analysis | ✅ Deep understanding | ✅ Good |
| Execution | ❌ Needs tools | ✅ Direct code generation |
| Context | ✅ Full conversation | ❌ Task-based |
| Integration | ✅ Web/API | ✅ CLI/MCP |

**Best together:** Claude plans and orchestrates, Cursor Agent executes!

## Related Documentation

- [Cursor CLI Official Docs](https://docs.cursor.com/cli/headless)
- [MCP Server Specification](https://modelcontextprotocol.io/)
- [Claude Code Integration](../CLAUDE.md)

---

**Last Updated**: Thu Nov 13 13:35:00 EST 2025
