#!/bin/bash

# Agent Research Library - Installation Script
# Usage: ./install.sh

set -e  # Exit on error

# Detect installation source
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source version utilities
source "$SCRIPT_DIR/version.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Agent Research Library - Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get version from VERSION file
INSTALL_VERSION=$(get_repo_version)
echo "Installing version: $INSTALL_VERSION"
echo ""

# Check if already installed
if is_installed; then
    CURRENT_VERSION=$(get_installed_version)
    echo -e "${YELLOW}⚠️  Agent Research Library is already installed (v$CURRENT_VERSION)${NC}"
    echo ""
    echo "If you want to:"
    echo "  • Update to a new version: run ./update.sh"
    echo "  • Reinstall current version: run ./uninstall.sh first"
    echo ""
    read -p "Continue with installation anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

if [ ! -d "$SCRIPT_DIR/docs" ] || [ ! -d "$SCRIPT_DIR/agents" ]; then
    echo "✗ Error: Invalid installation source"
    echo "  Expected docs/ and agents/ directories in $SCRIPT_DIR"
    exit 1
fi

echo "✓ Running from: $SCRIPT_DIR"

# Set target directory (RENAMED from research_reports)
CLAUDE_DIR="$HOME/.claude"
TARGET_DIR="$CLAUDE_DIR/agent_research_library"

echo ""
echo "Installation target: $TARGET_DIR"
echo ""

# Create directory structure (centralized storage)
echo "Creating directory structure..."
mkdir -p "$TARGET_DIR"/{agents,templates,_global,projects,mcp_tools,docs,migrations,backups}

# Copy documentation
echo "Copying documentation..."
cp "$SCRIPT_DIR/docs/"*.md "$TARGET_DIR/" || {
    echo "✗ Error: Failed to copy documentation files"
    exit 1
}
cp "$SCRIPT_DIR/orchestration/REPORT_CREATION.md" "$TARGET_DIR/" || {
    echo "✗ Error: Failed to copy REPORT_CREATION.md"
    exit 1
}

# Verify critical documentation files (v2.0 docs structure)
if [ ! -f "$TARGET_DIR/README.md" ]; then
    echo "✗ Error: README.md not found after copy"
    exit 1
fi

# Copy templates
echo "Copying templates..."
cp "$SCRIPT_DIR/templates/"* "$TARGET_DIR/templates/" || {
    echo "✗ Error: Failed to copy template files"
    exit 1
}

# Verify critical template files
if [ ! -f "$TARGET_DIR/templates/metadata_template.json" ]; then
    echo "✗ Error: metadata_template.json not found after copy"
    exit 1
fi

# Copy agent definitions (will be done after validator model choice)

# Copy MCP tools
echo "Copying MCP tools..."
cp -r "$SCRIPT_DIR/mcp_tools/"* "$TARGET_DIR/mcp_tools/" || {
    echo "✗ Error: Failed to copy MCP tools"
    exit 1
}

# Verify critical MCP files
if [ ! -f "$TARGET_DIR/mcp_tools/index.js" ]; then
    echo "✗ Error: MCP tools index.js not found after copy"
    exit 1
fi

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
        MCP_REGISTERED=true
    else
        echo -e "${YELLOW}⚠️  Claude CLI not found. You'll need to manually configure MCP tools.${NC}"
        echo "   Run: claude mcp add research-report-tools -- node $TARGET_DIR/mcp_tools/index.js"
        MCP_REGISTERED=false
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
cp "$SCRIPT_DIR/agents/report-creator.md" "$TARGET_DIR/agents/" || {
    echo "✗ Error: Failed to copy report-creator.md"
    exit 1
}
cp "$SCRIPT_DIR/agents/research-report-finder.md" "$TARGET_DIR/agents/" || {
    echo "✗ Error: Failed to copy research-report-finder.md"
    exit 1
}
cp "$SCRIPT_DIR/agents/research-librarian.md" "$TARGET_DIR/agents/" || {
    echo "✗ Error: Failed to copy research-librarian.md"
    exit 1
}
cp "$SCRIPT_DIR/agents/$VALIDATOR_SOURCE" "$TARGET_DIR/agents/report-validator.md" || {
    echo "✗ Error: Failed to copy $VALIDATOR_SOURCE"
    exit 1
}

# Install agents to Claude Code directory for auto-discovery
echo "Installing agents for Claude Code..."
mkdir -p "$CLAUDE_DIR/agents"
cp "$TARGET_DIR/agents/report-creator.md" "$CLAUDE_DIR/agents/" || {
    echo "✗ Error: Failed to install report-creator agent"
    exit 1
}
cp "$TARGET_DIR/agents/research-report-finder.md" "$CLAUDE_DIR/agents/" || {
    echo "✗ Error: Failed to install research-report-finder agent"
    exit 1
}
cp "$TARGET_DIR/agents/research-librarian.md" "$CLAUDE_DIR/agents/" || {
    echo "✗ Error: Failed to install research-librarian agent"
    exit 1
}
cp "$TARGET_DIR/agents/report-validator.md" "$CLAUDE_DIR/agents/" || {
    echo "✗ Error: Failed to install report-validator agent"
    exit 1
}
echo "✓ Agents installed to $CLAUDE_DIR/agents/"

# Handle CLAUDE.md integration with version markers
echo ""
echo "Configuring global CLAUDE.md..."
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

# Read the instructions content
INSTRUCTIONS_CONTENT=$(cat "$SCRIPT_DIR/orchestration/GLOBAL_INSTRUCTIONS.md")
CONTENT_HASH=$(hash_content "$INSTRUCTIONS_CONTENT")

if [ -f "$CLAUDE_MD" ]; then
    # Check if ARL markers already exist
    if grep -q "AGENT_RESEARCH_LIBRARY_START" "$CLAUDE_MD" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Agent Research Library section already exists in CLAUDE.md${NC}"
        echo "   Use update.sh to update the instructions"
        CLAUDE_MD_UPDATED=false
    else
        # File exists, offer to append
        echo ""
        echo "Found existing $CLAUDE_MD"
        read -p "Add Agent Research Library instructions to it? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            # Append with version markers
            echo "" >> "$CLAUDE_MD"
            echo "---" >> "$CLAUDE_MD"
            echo "" >> "$CLAUDE_MD"
            echo "<!-- AGENT_RESEARCH_LIBRARY_START:v${INSTALL_VERSION}:hash:${CONTENT_HASH} -->" >> "$CLAUDE_MD"
            echo "$INSTRUCTIONS_CONTENT" >> "$CLAUDE_MD"
            echo "<!-- AGENT_RESEARCH_LIBRARY_END:v${INSTALL_VERSION} -->" >> "$CLAUDE_MD"
            echo -e "${GREEN}✓ Added Agent Research Library instructions to CLAUDE.md${NC}"
            CLAUDE_MD_UPDATED=true
        else
            echo -e "${YELLOW}⚠️  Skipped CLAUDE.md update. You can manually add:${NC}"
            echo "   $SCRIPT_DIR/orchestration/GLOBAL_INSTRUCTIONS.md"
            CLAUDE_MD_UPDATED=false
        fi
    fi
else
    # No CLAUDE.md exists, create it with markers
    echo "<!-- AGENT_RESEARCH_LIBRARY_START:v${INSTALL_VERSION}:hash:${CONTENT_HASH} -->" > "$CLAUDE_MD"
    echo "$INSTRUCTIONS_CONTENT" >> "$CLAUDE_MD"
    echo "<!-- AGENT_RESEARCH_LIBRARY_END:v${INSTALL_VERSION} -->" >> "$CLAUDE_MD"
    echo -e "${GREEN}✓ Created $CLAUDE_MD with Agent Research Library instructions${NC}"
    CLAUDE_MD_UPDATED=true
fi

# Create INSTALLED_VERSION manifest
echo ""
echo "Creating installation manifest..."
cat > "$TARGET_DIR/INSTALLED_VERSION" <<EOF
{
  "version": "$INSTALL_VERSION",
  "installed_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "install_path": "$TARGET_DIR",
  "components": {
    "mcp_tools": {
      "version": "1.0.0",
      "path": "$TARGET_DIR/mcp_tools",
      "registered": ${MCP_REGISTERED:-false}
    },
    "agents": {
      "report-creator": {
        "version": "$INSTALL_VERSION",
        "path": "$CLAUDE_DIR/agents/report-creator.md",
        "installed": true
      },
      "research-report-finder": {
        "version": "$INSTALL_VERSION",
        "path": "$CLAUDE_DIR/agents/research-report-finder.md",
        "installed": true
      },
      "research-librarian": {
        "version": "$INSTALL_VERSION",
        "path": "$CLAUDE_DIR/agents/research-librarian.md",
        "installed": true
      },
      "report-validator": {
        "version": "$INSTALL_VERSION",
        "model": "$VALIDATOR_MODEL_NAME",
        "path": "$CLAUDE_DIR/agents/report-validator.md",
        "installed": true
      }
    },
    "global_instructions": {
      "enabled": ${CLAUDE_MD_UPDATED:-false},
      "version": "$INSTALL_VERSION",
      "content_hash": "$CONTENT_HASH",
      "path": "$CLAUDE_MD"
    }
  },
  "installation_method": "install.sh",
  "system_info": {
    "os": "$(uname -s | tr '[:upper:]' '[:lower:]')",
    "node_version": "$(node --version 2>/dev/null || echo "not installed")",
    "claude_cli_available": $(command -v claude &> /dev/null && echo "true" || echo "false")
  }
}
EOF

echo "✓ Installation manifest created: $TARGET_DIR/INSTALLED_VERSION"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Version: $INSTALL_VERSION"
echo "Files installed to: $TARGET_DIR"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Verify Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "After restarting Claude Code, verify with these commands:"
echo ""
echo "1. Check MCP tools are registered:"
echo "   claude mcp list | grep research-report-tools"
echo ""
echo "2. Check agents are installed:"
echo "   ls ~/.claude/agents/ | grep -E 'report-creator|research-librarian|research-report-finder|report-validator'"
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
echo "Documentation:"
echo "  • Report format: $TARGET_DIR/REPORT_SPECIFICATION.md"
echo "  • Agents & workflows: $TARGET_DIR/AGENT_SYSTEM.md"
echo "  • Installation & setup: $TARGET_DIR/INTEGRATION_GUIDE.md"
echo "  • MCP tools: $TARGET_DIR/MCP_TOOLS.md"
echo ""
echo "Test the system:"
echo '  > "Create a research report on [your library]"'
echo ""
