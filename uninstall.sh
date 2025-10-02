#!/bin/bash

# Agent Research Library - Uninstallation Script
# Usage: ./uninstall.sh

set -e

# Detect script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source version utilities
source "$SCRIPT_DIR/version.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Agent Research Library - Uninstaller"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if installed
if ! is_installed; then
    echo -e "${YELLOW}Agent Research Library is not installed${NC}"
    echo ""
    echo "Nothing to uninstall."
    exit 0
fi

INSTALLED_VERSION=$(get_installed_version)
echo "Installed version: $INSTALLED_VERSION"
echo ""

TARGET_DIR="$HOME/.claude/agent_research_library"
CLAUDE_DIR="$HOME/.claude"

# Ask for confirmation
echo -e "${YELLOW}⚠️  This will remove the Agent Research Library system${NC}"
echo ""
read -p "Continue with uninstallation? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled"
    exit 0
fi

# Optional backup before uninstall
echo ""
read -p "Create backup before uninstalling? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    backup_installation || echo -e "${YELLOW}⚠️  Backup failed, continuing anyway${NC}"
fi

echo ""
echo "Uninstalling Agent Research Library..."
echo ""

# 1. Remove agents from ~/.claude/agents/
echo "Removing agents..."
rm -f "$CLAUDE_DIR/agents/report-creator.md"
rm -f "$CLAUDE_DIR/agents/research-report-finder.md"
rm -f "$CLAUDE_DIR/agents/research-librarian.md"
rm -f "$CLAUDE_DIR/agents/report-validator.md"
echo "✓ Agents removed"

# 2. Remove MCP server
echo "Removing MCP server..."
if command -v claude &> /dev/null; then
    claude mcp remove research-report-tools 2>/dev/null && \
        echo "✓ MCP server removed" || \
        echo "⚠️  MCP server not found or already removed"
else
    echo "⚠️  Claude CLI not found, skipping MCP removal"
    echo "   Manually remove from ~/.claude.json if needed"
fi

# 3. Remove CLAUDE.md section
echo "Removing CLAUDE.md section..."
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    if grep -q "AGENT_RESEARCH_LIBRARY_START" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; then
        remove_arl_section
    else
        echo "⚠️  No ARL section found in CLAUDE.md"
    fi
else
    echo "⚠️  CLAUDE.md not found"
fi

# 4. Show report status
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Your Research Reports"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count reports
PROJECT_REPORTS=0
GLOBAL_REPORTS=0

if [ -d "$TARGET_DIR/projects" ]; then
    PROJECT_REPORTS=$(find "$TARGET_DIR/projects" -type d -maxdepth 2 -mindepth 2 | wc -l | tr -d ' ')
fi

if [ -d "$TARGET_DIR/_global" ]; then
    GLOBAL_REPORTS=$(find "$TARGET_DIR/_global" -type d -maxdepth 1 -mindepth 1 ! -name index.json | wc -l | tr -d ' ')
fi

echo "Found:"
echo "  • Project reports: $PROJECT_REPORTS"
echo "  • Global reports: $GLOBAL_REPORTS"
echo ""

if [ "$PROJECT_REPORTS" -gt 0 ] || [ "$GLOBAL_REPORTS" -gt 0 ]; then
    echo -e "${YELLOW}Your research reports are stored in:${NC}"
    echo "  $TARGET_DIR/projects/"
    echo "  $TARGET_DIR/_global/"
    echo ""
    echo -e "${RED}⚠️  WARNING: Deleting reports cannot be undone!${NC}"
    echo ""
    read -p "Delete ALL research reports? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Delete everything
        rm -rf "$TARGET_DIR"
        echo -e "${GREEN}✓ Complete removal (including all reports)${NC}"
        DELETE_ALL=true
    else
        # Keep reports, remove system files only
        rm -rf "$TARGET_DIR/agents"
        rm -rf "$TARGET_DIR/mcp_tools"
        rm -rf "$TARGET_DIR/templates"
        rm -rf "$TARGET_DIR/docs"
        rm -rf "$TARGET_DIR/migrations"
        rm -rf "$TARGET_DIR/backups"
        rm -f "$TARGET_DIR/INSTALLED_VERSION"
        rm -f "$TARGET_DIR"/*.md
        echo -e "${GREEN}✓ System removed, reports preserved${NC}"
        DELETE_ALL=false
    fi
else
    # No reports, safe to delete everything
    rm -rf "$TARGET_DIR"
    echo -e "${GREEN}✓ Complete removal${NC}"
    DELETE_ALL=true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Uninstallation Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$DELETE_ALL" = true ]; then
    echo "Agent Research Library has been completely removed"
else
    echo "Agent Research Library system has been removed"
    echo ""
    echo "Your research reports are preserved in:"
    echo "  $TARGET_DIR/projects/"
    echo "  $TARGET_DIR/_global/"
    echo ""
    echo "To completely remove everything (including reports):"
    echo "  rm -rf $TARGET_DIR"
fi

echo ""
echo "To reinstall, run: ./install.sh"
echo ""
