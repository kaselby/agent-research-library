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
mkdir -p "$TARGET_DIR"/{agents,templates,_global,projects}

# Copy documentation
echo "Copying documentation..."
cp "$SCRIPT_DIR/docs/"*.md "$TARGET_DIR/"

# Copy templates
echo "Copying templates..."
cp "$SCRIPT_DIR/templates/"* "$TARGET_DIR/templates/"

# Copy agent definitions
echo "Copying agent definitions..."
cp "$SCRIPT_DIR/agents/"*.md "$TARGET_DIR/agents/"

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

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Files installed to: $TARGET_DIR"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next Steps: Create Claude Code Subagents"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "You must manually create 3 subagents in Claude Code:"
echo ""
echo "1. report-creator (Sonnet)"
echo "   Description: $TARGET_DIR/agents/report-creator.md"
echo "   Tools: Read, Glob, Grep, Write, WebFetch, Bash"
echo ""
echo "2. report-validator (Opus) ⚠️  MUST USE OPUS"
echo "   Description: $TARGET_DIR/agents/report-validator.md"
echo "   Tools: Read, Glob, Grep"
echo ""
echo "3. research-librarian (Sonnet)"
echo "   Description: $TARGET_DIR/agents/research-librarian.md"
echo "   Tools: Read, Glob, Grep"
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
