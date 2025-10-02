#!/bin/bash

# version.sh - Utility functions for Agent Research Library version management

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the repository version from VERSION file
get_repo_version() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$script_dir/VERSION" ]; then
        cat "$script_dir/VERSION" | tr -d '[:space:]'
    else
        echo "ERROR: VERSION file not found" >&2
        return 1
    fi
}

# Get the installed version from INSTALLED_VERSION manifest
get_installed_version() {
    local install_dir="$HOME/.claude/agent_research_library"
    local manifest="$install_dir/INSTALLED_VERSION"

    if [ ! -f "$manifest" ]; then
        echo ""  # Not installed
        return 1
    fi

    # Extract version from JSON
    grep -o '"version": *"[^"]*"' "$manifest" | cut -d'"' -f4
}

# Compare two semantic versions
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
compare_versions() {
    local v1=$1
    local v2=$2

    if [ "$v1" == "$v2" ]; then
        return 0
    fi

    local IFS=.
    local i ver1=($v1) ver2=($v2)

    # Fill empty positions with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++)); do
        if [ -z "${ver2[i]}" ]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done

    return 0
}

# Check if version is a major version bump (breaking changes)
is_major_version_bump() {
    local from_version=$1
    local to_version=$2

    local from_major=$(echo "$from_version" | cut -d. -f1)
    local to_major=$(echo "$to_version" | cut -d. -f1)

    [ "$to_major" -gt "$from_major" ]
}

# Get project ID from git root or working directory
get_project_id() {
    local working_dir="${1:-$(pwd)}"

    cd "$working_dir" 2>/dev/null || return 1

    # Try to get git root
    local git_root
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        # Use git root path to generate stable ID
        echo -n "$git_root" | shasum -a 256 | cut -c1-16
        return 0
    fi

    # Fallback: use directory name + path hash
    local dir_name=$(basename "$working_dir")
    echo -n "${dir_name}-${working_dir}" | shasum -a 256 | cut -c1-16
}

# Get project name from git or directory
get_project_name() {
    local working_dir="${1:-$(pwd)}"

    cd "$working_dir" 2>/dev/null || return 1

    # Try git remote first
    local git_remote
    if git_remote=$(git remote get-url origin 2>/dev/null); then
        # Extract repo name from URL
        basename "$git_remote" .git
        return 0
    fi

    # Try git root directory name
    local git_root
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        basename "$git_root"
        return 0
    fi

    # Fallback: current directory name
    basename "$working_dir"
}

# Create timestamped backup of installation
backup_installation() {
    local install_dir="$HOME/.claude/agent_research_library"
    local backup_dir="$install_dir/backups"
    local version=$(get_installed_version)
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="v${version}-${timestamp}"

    if [ ! -d "$install_dir" ]; then
        echo -e "${YELLOW}⚠️  No installation to backup${NC}"
        return 1
    fi

    echo "Creating backup: $backup_name"
    mkdir -p "$backup_dir/$backup_name"

    # Backup critical components
    [ -d "$install_dir/agents" ] && cp -r "$install_dir/agents" "$backup_dir/$backup_name/"
    [ -d "$install_dir/mcp_tools" ] && cp -r "$install_dir/mcp_tools" "$backup_dir/$backup_name/"
    [ -d "$install_dir/templates" ] && cp -r "$install_dir/templates" "$backup_dir/$backup_name/"
    [ -f "$install_dir/INSTALLED_VERSION" ] && cp "$install_dir/INSTALLED_VERSION" "$backup_dir/$backup_name/"

    # Backup CLAUDE.md section if it exists
    if [ -f "$HOME/.claude/CLAUDE.md" ]; then
        extract_arl_section > "$backup_dir/$backup_name/CLAUDE.md.section" 2>/dev/null || true
    fi

    # Backup installed agents from ~/.claude/agents/
    mkdir -p "$backup_dir/$backup_name/installed_agents"
    cp "$HOME/.claude/agents"/report-*.md "$backup_dir/$backup_name/installed_agents/" 2>/dev/null || true
    cp "$HOME/.claude/agents"/research-*.md "$backup_dir/$backup_name/installed_agents/" 2>/dev/null || true

    echo -e "${GREEN}✓ Backup created: $backup_dir/$backup_name${NC}"
}

# Compute SHA256 hash of content
hash_content() {
    echo -n "$1" | shasum -a 256 | cut -d' ' -f1 | cut -c1-12
}

# Extract ARL section from CLAUDE.md
extract_arl_section() {
    local claude_md="$HOME/.claude/CLAUDE.md"

    if [ ! -f "$claude_md" ]; then
        return 1
    fi

    sed -n '/<!-- AGENT_RESEARCH_LIBRARY_START/,/<!-- AGENT_RESEARCH_LIBRARY_END/p' "$claude_md"
}

# Remove ARL section from CLAUDE.md
remove_arl_section() {
    local claude_md="$HOME/.claude/CLAUDE.md"

    if [ ! -f "$claude_md" ]; then
        return 0
    fi

    # Check if markers exist
    if ! grep -q "AGENT_RESEARCH_LIBRARY_START" "$claude_md"; then
        echo -e "${YELLOW}⚠️  No ARL section found in CLAUDE.md${NC}"
        return 0
    fi

    # Create backup
    cp "$claude_md" "$claude_md.backup"

    # Remove section between markers (including markers)
    sed -i.bak '/<!-- AGENT_RESEARCH_LIBRARY_START/,/<!-- AGENT_RESEARCH_LIBRARY_END -->/d' "$claude_md"
    rm -f "$claude_md.bak"

    echo -e "${GREEN}✓ Removed ARL section from CLAUDE.md${NC}"
}

# Replace ARL section in CLAUDE.md
replace_arl_section() {
    local new_content=$1
    local version=$2
    local content_hash=$(hash_content "$new_content")

    local claude_md="$HOME/.claude/CLAUDE.md"

    # Remove old section first
    remove_arl_section

    # Append new section with markers
    echo "" >> "$claude_md"
    echo "<!-- AGENT_RESEARCH_LIBRARY_START:v${version}:hash:${content_hash} -->" >> "$claude_md"
    echo "$new_content" >> "$claude_md"
    echo "<!-- AGENT_RESEARCH_LIBRARY_END:v${version} -->" >> "$claude_md"

    echo -e "${GREEN}✓ Updated ARL section in CLAUDE.md (v${version})${NC}"
}

# Verify ARL section hasn't been manually modified
verify_arl_section() {
    local expected_hash=$1
    local claude_md="$HOME/.claude/CLAUDE.md"

    if [ ! -f "$claude_md" ]; then
        return 1
    fi

    # Extract content between markers (excluding markers)
    local content=$(sed -n '/<!-- AGENT_RESEARCH_LIBRARY_START/,/<!-- AGENT_RESEARCH_LIBRARY_END/{//!p;}' "$claude_md")
    local actual_hash=$(hash_content "$content")

    if [ "$actual_hash" != "$expected_hash" ]; then
        echo -e "${YELLOW}⚠️  Warning: CLAUDE.md ARL section has been manually modified${NC}"
        echo -e "   Expected hash: $expected_hash"
        echo -e "   Actual hash:   $actual_hash"
        return 1
    fi

    return 0
}

# Validate INSTALLED_VERSION manifest
validate_manifest() {
    local install_dir="$HOME/.claude/agent_research_library"
    local manifest="$install_dir/INSTALLED_VERSION"

    if [ ! -f "$manifest" ]; then
        echo -e "${RED}✗ INSTALLED_VERSION manifest not found${NC}"
        return 1
    fi

    # Check required fields
    local required_fields=("version" "installed_date" "install_path" "components")
    local valid=true

    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" "$manifest"; then
            echo -e "${RED}✗ Missing required field: $field${NC}"
            valid=false
        fi
    done

    if [ "$valid" = false ]; then
        return 1
    fi

    echo -e "${GREEN}✓ Manifest is valid${NC}"
    return 0
}

# Check if ARL is installed
is_installed() {
    [ -f "$HOME/.claude/agent_research_library/INSTALLED_VERSION" ]
}

# Print version comparison
print_version_info() {
    local repo_version=$(get_repo_version)
    local installed_version=$(get_installed_version)

    echo "Repository version: $repo_version"

    if [ -z "$installed_version" ]; then
        echo "Installed version:  (not installed)"
    else
        echo "Installed version:  $installed_version"

        compare_versions "$repo_version" "$installed_version"
        local cmp=$?

        if [ $cmp -eq 0 ]; then
            echo -e "${GREEN}Status: Up to date${NC}"
        elif [ $cmp -eq 1 ]; then
            echo -e "${YELLOW}Status: Update available${NC}"
            if is_major_version_bump "$installed_version" "$repo_version"; then
                echo -e "${RED}Warning: Breaking changes in this update${NC}"
            fi
        else
            echo -e "${YELLOW}Status: Installed version is newer than repository${NC}"
        fi
    fi
}
