#!/bin/bash

# Agent Research Library - Update Script
# Usage: ./update.sh

set -e

# Detect script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source version utilities
source "$SCRIPT_DIR/version.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Agent Research Library - Update"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Check if installed
if ! is_installed; then
    echo -e "${RED}✗ Agent Research Library is not installed${NC}"
    echo ""
    echo "Run ./install.sh to install it first"
    exit 1
fi

# TODO: Get versions
CURRENT_VERSION=$(get_installed_version)
NEW_VERSION=$(get_repo_version)

echo "Current version: $CURRENT_VERSION"
echo "New version:     $NEW_VERSION"
echo ""

# TODO: Compare versions
compare_versions "$NEW_VERSION" "$CURRENT_VERSION"
VERSION_CMP=$?

if [ $VERSION_CMP -eq 0 ]; then
    echo -e "${GREEN}✓ Already up to date${NC}"
    exit 0
elif [ $VERSION_CMP -eq 2 ]; then
    echo -e "${YELLOW}⚠️  Installed version is newer than repository${NC}"
    echo ""
    read -p "Downgrade to repository version? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update cancelled"
        exit 0
    fi
fi

# TODO: Check for breaking changes
if is_major_version_bump "$CURRENT_VERSION" "$NEW_VERSION"; then
    echo -e "${RED}⚠️  WARNING: This is a MAJOR version update with breaking changes${NC}"
    echo ""
    echo "Breaking changes may affect:"
    echo "  • Report schema format"
    echo "  • Storage locations"
    echo "  • Agent interfaces"
    echo ""
    read -p "Continue with update? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update cancelled"
        exit 0
    fi
fi

echo ""
echo "Starting update process..."
echo ""

# ============================================================================
# PHASE 1: BACKUP
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 1: Backup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Create backup of current installation
# - Call backup_installation() from version.sh
# - Store in ~/.claude/agent_research_library/backups/v${CURRENT_VERSION}-${TIMESTAMP}/
# - Backup: agents, mcp_tools, templates, INSTALLED_VERSION, CLAUDE.md section

echo "TODO: backup_installation"

# ============================================================================
# PHASE 2: MIGRATIONS (if needed)
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 2: Migrations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Check if migrations are needed
# - Look for migration scripts: migrations/v${CURRENT_VERSION}-to-v${NEW_VERSION}.sh
# - If found, execute them
# - Migrations should update:
#   • Report metadata schema
#   • Storage locations (if needed)
#   • Index formats

echo "TODO: run_migrations"

# ============================================================================
# PHASE 3: UPDATE MCP TOOLS
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 3: Update MCP Tools"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Update MCP tools
# - Copy new mcp_tools/ files
# - Run npm install in mcp_tools directory
# - MCP server registration should persist (no need to re-add)
# - Note: MCP tools will auto-reload when Claude Code restarts

TARGET_DIR="$HOME/.claude/agent_research_library"

echo "TODO: Copy mcp_tools files"
echo "TODO: npm install in $TARGET_DIR/mcp_tools"

# ============================================================================
# PHASE 4: UPDATE AGENTS
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 4: Update Agents"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Update agent files
# - Remove old agent files from ~/.claude/agents/
#   • report-creator.md
#   • research-report-finder.md
#   • research-librarian.md
#   • report-validator.md
# - Copy new agent files from repo
# - Preserve validator model choice (opus vs sonnet)

CLAUDE_DIR="$HOME/.claude"

echo "TODO: Remove old agents"
echo "TODO: Copy new agents"
echo "TODO: Handle validator model selection"

# ============================================================================
# PHASE 5: UPDATE GLOBAL CLAUDE.MD
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 5: Update Global Instructions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Update CLAUDE.md section using markers
# - Read new GLOBAL_INSTRUCTIONS.md
# - Compute new content hash
# - Use replace_arl_section() from version.sh
# - If markers are missing or hash mismatch detected:
#   • Warn user about manual edits
#   • Ask if they want to:
#     a) Replace anyway (loses manual edits)
#     b) Skip CLAUDE.md update
#     c) Show diff and let them decide

echo "TODO: replace_arl_section with new content"

# ============================================================================
# PHASE 6: UPDATE TEMPLATES AND DOCS
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 6: Update Templates & Documentation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Update templates and documentation
# - Copy new templates/
# - Copy new docs/
# - These are reference files, safe to overwrite

echo "TODO: Update templates"
echo "TODO: Update documentation"

# ============================================================================
# PHASE 7: UPDATE INSTALLED_VERSION MANIFEST
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 7: Update Installation Manifest"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Update INSTALLED_VERSION manifest
# - Update version number
# - Update component versions
# - Update updated_date timestamp
# - Preserve original installed_date

echo "TODO: Update INSTALLED_VERSION"

# ============================================================================
# PHASE 8: VERIFICATION
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Phase 8: Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TODO: Verify update success
# - Check INSTALLED_VERSION matches NEW_VERSION
# - Check all agents exist
# - Check MCP tools directory intact
# - Validate manifest structure

echo "TODO: verify installation"

# ============================================================================
# COMPLETE
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Update Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Updated: $CURRENT_VERSION → $NEW_VERSION"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code to load updated agents and MCP tools"
echo "  2. Verify with: ls ~/.claude/agents/ | grep -E 'report|research'"
echo ""

# TODO: Display changelog if available
# - Look for CHANGELOG.md
# - Extract relevant section for this version
# - Show what changed

echo "TODO: Show changelog for this version"
echo ""
