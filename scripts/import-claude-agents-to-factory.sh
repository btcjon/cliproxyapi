#!/bin/bash
set -euo pipefail

# Script to import Claude agents from ~/.claude/agents/ to Factory CLI custom commands
# Factory CLI custom commands are stored in ~/.factory/commands/

SOURCE_DIR="$HOME/.claude/agents"
TARGET_DIR="$HOME/.factory/commands"

echo "Importing Claude agents to Factory CLI custom commands..."
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR not found"
    exit 1
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Count agents
AGENT_COUNT=$(find "$SOURCE_DIR" -name "*.md" -type f | wc -l)
echo "Found $AGENT_COUNT agent files"
echo ""

# Copy and convert agents
COPIED=0
for agent_file in "$SOURCE_DIR"/*.md; do
    if [ -f "$agent_file" ]; then
        filename=$(basename "$agent_file")
        target_file="$TARGET_DIR/$filename"
        
        # Copy the file
        cp "$agent_file" "$target_file"
        echo "✓ Imported: $filename"
        COPIED=$((COPIED + 1))
    fi
done

echo ""
echo "✓ Successfully imported $COPIED agents to Factory CLI"
echo ""
echo "Next steps:"
echo "1. Restart Factory CLI (exit and restart 'droid')"
echo "2. Use your agents as custom commands in Factory CLI"
echo ""
echo "Note: Factory CLI custom commands use slash commands (e.g., /researcher)"
echo "The agent name from the frontmatter will be used as the command name"

