#!/bin/bash

# Claude Research Report System - Installation Script
# Usage: ./install.sh

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Research Report System - Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect installation source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$SCRIPT_DIR/docs" ] || [ ! -d "$SCRIPT_DIR/agents" ]; then
    echo "✗ Error: Invalid installation source"
    echo "  Expected docs/ and agents/ directories in $SCRIPT_DIR"
    exit 1
fi

echo "✓ Running from: $SCRIPT_DIR"

# Set target directory
CLAUDE_DIR="$HOME/.claude"
TARGET_DIR="$CLAUDE_DIR/research_reports"

echo ""
echo "Installation target: $TARGET_DIR"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$TARGET_DIR"/{agents,templates,_global,projects,mcp_tools}

# Copy documentation
echo "Copying documentation..."
cp "$SCRIPT_DIR/docs/"*.md "$TARGET_DIR/"
cp "$SCRIPT_DIR/orchestration/REPORT_CREATION.md" "$TARGET_DIR/"

# Copy templates
echo "Copying templates..."
cp "$SCRIPT_DIR/templates/"* "$TARGET_DIR/templates/"

# Copy agent definitions (will be done after validator model choice)

# Copy MCP tools
echo "Copying MCP tools..."
cp -r "$SCRIPT_DIR/mcp_tools/"* "$TARGET_DIR/mcp_tools/"

# Install MCP tool dependencies
if command -v node &> /dev/null; then
    echo "Installing MCP tool dependencies..."
    cd "$TARGET_DIR/mcp_tools"
    npm install --silent
    chmod +x index.js
    cd - > /dev/null

    # Configure MCP server using Claude CLI
    if command -v claude &> /dev/null; then
        echo "Configuring MCP server..."
        claude mcp add research-report-tools -- node "$TARGET_DIR/mcp_tools/index.js" 2>/dev/null && \
            echo "✓ MCP server configured" || \
            echo "✓ MCP server already configured or manually add later"
    else
        echo "⚠️  Claude CLI not found. You'll need to manually configure MCP tools."
        echo "   Run: claude mcp add research-report-tools -- node $TARGET_DIR/mcp_tools/index.js"
    fi
else
    echo "⚠️  Node.js not found. MCP tools will need manual setup."
    echo "   Install Node.js, then run: cd $TARGET_DIR/mcp_tools && npm install"
fi

# Initialize global index if it doesn't exist
if [ ! -f "$TARGET_DIR/_global/index.json" ]; then
    echo "Initializing global index..."
    cat > "$TARGET_DIR/_global/index.json" <<'EOF'
{
  "version": "1.0",
  "scope": "global",
  "project_path": null,
  "created": "2025-10-02T00:00:00Z",
  "updated": "2025-10-02T00:00:00Z",
  "reports": []
}
EOF
fi

# Prompt for validator model choice
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Validator Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The report-validator agent checks conceptual accuracy of reports."
echo ""
echo "Which model should it use?"
echo "  1) Opus (recommended) - More accurate, catches subtle errors"
echo "  2) Sonnet - Faster and cheaper, good for most cases"
echo ""
read -p "Choose [1/2] (default: 1): " -n 1 -r VALIDATOR_MODEL
echo ""

if [[ $VALIDATOR_MODEL == "2" ]]; then
    VALIDATOR_MODEL_NAME="sonnet"
    VALIDATOR_SOURCE="report-validator-sonnet.md"
    echo "✓ Configured validator to use Sonnet"
else
    VALIDATOR_MODEL_NAME="opus"
    VALIDATOR_SOURCE="report-validator-opus.md"
    echo "✓ Configured validator to use Opus (recommended)"
fi

# Copy agent definitions with the chosen validator to staging
echo "Copying agent definitions..."
cp "$SCRIPT_DIR/agents/report-creator.md" "$TARGET_DIR/agents/"
cp "$SCRIPT_DIR/agents/report-finder.md" "$TARGET_DIR/agents/"
cp "$SCRIPT_DIR/agents/research-librarian.md" "$TARGET_DIR/agents/"
cp "$SCRIPT_DIR/agents/$VALIDATOR_SOURCE" "$TARGET_DIR/agents/report-validator.md"

# Install agents to Claude Code directory for auto-discovery
echo "Installing agents for Claude Code..."
mkdir -p "$CLAUDE_DIR/agents"
cp "$TARGET_DIR/agents/report-creator.md" "$CLAUDE_DIR/agents/"
cp "$TARGET_DIR/agents/report-finder.md" "$CLAUDE_DIR/agents/research-report-finder.md"
cp "$TARGET_DIR/agents/research-librarian.md" "$CLAUDE_DIR/agents/"
cp "$TARGET_DIR/agents/report-validator.md" "$CLAUDE_DIR/agents/"
echo "✓ Agents installed to $CLAUDE_DIR/agents/"

# Handle CLAUDE.md integration
echo ""
echo "Configuring global CLAUDE.md..."
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

if [ -f "$CLAUDE_MD" ]; then
    # Check if already added
    if grep -q "Claude Research Report System" "$CLAUDE_MD" 2>/dev/null; then
        echo "✓ Research Report System already configured in CLAUDE.md"
    else
        # File exists, offer to append
        echo ""
        echo "Found existing $CLAUDE_MD"
        read -p "Add Research Report System instructions to it? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            echo "" >> "$CLAUDE_MD"
            echo "---" >> "$CLAUDE_MD"
            echo "" >> "$CLAUDE_MD"
            cat "$SCRIPT_DIR/orchestration/GLOBAL_INSTRUCTIONS.md" >> "$CLAUDE_MD"
            echo "✓ Added Research Report System instructions to CLAUDE.md"
        else
            echo "⚠️  Skipped CLAUDE.md update. You can manually add:"
            echo "   $SCRIPT_DIR/orchestration/GLOBAL_INSTRUCTIONS.md"
        fi
    fi
else
    # No CLAUDE.md exists, create it
    cat "$SCRIPT_DIR/orchestration/GLOBAL_INSTRUCTIONS.md" > "$CLAUDE_MD"
    echo "✓ Created $CLAUDE_MD with Research Report System instructions"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Files installed to: $TARGET_DIR"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Restart Claude Code"
echo "   The system is fully configured with:"
echo "   • MCP tools (research-report-tools)"
echo "   • 4 specialized agents:"
echo "     - report-creator (Sonnet)"
echo "     - report-validator ($VALIDATOR_MODEL_NAME)"
echo "     - research-librarian (Sonnet)"
echo "     - research-report-finder (Haiku)"
echo ""
echo "2. Test the system"
echo "   Try creating a research report:"
echo "   > \"Create a research report on [your library]\""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Documentation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Quick start: $TARGET_DIR/README.md"
echo "Full system: $TARGET_DIR/RESEARCH_REPORT_SYSTEM.md"
echo "Integration: $TARGET_DIR/CLAUDE_CODE_INTEGRATION.md"
echo ""
echo "Test the system:"
echo '  > "Create a research report on [your library]"'
echo ""
