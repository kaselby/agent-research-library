# Integration Guide

This guide explains how to install and configure the Agent Research Library for Claude Code.

## Overview

The Agent Research Library is a hierarchical knowledge management system that uses:
- **4 Specialized Agents**: report-creator, report-validator, research-librarian, research-report-finder
- **MCP Tools**: lint_report (structure validation), extract_section (partial content loading)
- **Storage System**: `~/.claude/agent_research_library/` for all reports

For detailed information about the agents and system architecture, see [AGENT_SYSTEM.md](AGENT_SYSTEM.md).

For the complete report structure specification, see [REPORT_SPECIFICATION.md](REPORT_SPECIFICATION.md).

## Prerequisites

- Claude Code CLI installed and configured
- Node.js 18+ (for MCP tools)
- Git (optional, for cloning repository)

## Installation

### Automated Installation (Recommended)

The automated installer handles all setup steps:

```bash
git clone <repository-url>
cd agent-research-library
./install.sh
```

The installer will:

1. **Copy system files** to `~/.claude/research_reports/`:
   - Documentation (all docs/ files)
   - MCP tools (mcp_tools/)
   - Report templates (templates/)
   - Agent definitions (agents/)

2. **Install MCP server** via `claude mcp add` command:
   ```bash
   claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js
   ```

3. **Install agents** to `~/.claude/agents/` for auto-discovery:
   - `report-creator.md` (Sonnet)
   - `research-report-finder.md` (Haiku)
   - `research-librarian.md` (Sonnet)
   - `report-validator.md` (Opus or Sonnet)

4. **Prompt for validator model choice**:
   - Opus (recommended for highest accuracy)
   - Sonnet (faster, still effective)

5. **Configure global CLAUDE.md** with system instructions

6. **Create storage directory**: `~/.claude/agent_research_library/`

**After installation, restart Claude Code** to load the new agents and MCP tools.

### Manual Installation

If the automated installer fails, you can manually configure:

#### 1. Copy Files

```bash
mkdir -p ~/.claude/research_reports
cp -r docs/ mcp_tools/ templates/ agents/ ~/.claude/research_reports/
```

#### 2. Install MCP Server

```bash
claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js
```

Verify installation:
```bash
claude mcp list
```

#### 3. Install Agents

```bash
mkdir -p ~/.claude/agents
cp agents/report-creator.md ~/.claude/agents/
cp agents/research-report-finder.md ~/.claude/agents/
cp agents/research-librarian.md ~/.claude/agents/
```

Choose validator model:
```bash
# For Opus (recommended)
cp agents/report-validator-opus.md ~/.claude/agents/report-validator.md

# For Sonnet
cp agents/report-validator-sonnet.md ~/.claude/agents/report-validator.md
```

#### 4. Create Storage Directory

```bash
mkdir -p ~/.claude/agent_research_library/_global
mkdir -p ~/.claude/agent_research_library/projects
```

#### 5. Configure CLAUDE.md (Optional)

Add these instructions to `~/.claude/CLAUDE.md`:

```markdown
# Agent Research Library

When users explicitly request creating a research report (mentioning "Agent Research Library" or "Research Library"), use the report-creator agent to generate comprehensive technical documentation.

When users ask questions about documented topics, use research-report-finder to check for existing reports, then research-librarian to query them efficiently.

Storage: ~/.claude/agent_research_library/
- projects/: Project-specific reports
- _global/: Global patterns and frameworks
```

#### 6. Restart Claude Code

After manual installation, restart Claude Code to load agents and MCP tools.

## Verifying Installation

### Test 1: Check MCP Tools

```bash
# In Claude Code session
# The mcp__research_report_tools__lint_report tool should be available
```

Ask Claude: "Can you list the available MCP tools?"

You should see: `mcp__research_report_tools__lint_report`

### Test 2: Check Agents

```bash
# List installed agents
ls ~/.claude/agents/
```

Expected files:
- `report-creator.md`
- `research-report-finder.md`
- `research-librarian.md`
- `report-validator.md`

### Test 3: Create Test Report

In a small test project:

```
User: "Create a research report on this project using the Agent Research Library"
```

Expected behavior:
1. report-creator agent launches
2. Analyzes project structure
3. Creates hierarchical report in `~/.claude/agent_research_library/projects/{project_slug}/`
4. Validates structure with linter
5. Prompts for validation depth
6. report-validator checks conceptual accuracy (if not skipped)
7. Returns report summary

### Test 4: Query Report

After creating a test report:

```
User: "How does the [component] work?"
```

Expected behavior:
1. research-report-finder launches (fast Haiku search)
2. Finds relevant report
3. research-librarian launches
4. Reads overview + relevant sections
5. Returns summary with section recommendations
6. Main Claude answers question with context

### Test 5: Report Not Found

```
User: "How does [undocumented component] work?"
```

Expected behavior:
1. research-report-finder launches
2. Returns NOT FOUND
3. Main Claude uses traditional codebase search
4. Optionally suggests creating a report

## Configuration Options

### Storage Locations

Reports are stored in `~/.claude/agent_research_library/`:

```
~/.claude/agent_research_library/
├── _global/                    # Global reports (patterns, frameworks)
│   ├── index.json             # Global report registry
│   └── {REPORT_ID}/           # Individual reports
├── projects/                   # Project-specific reports
│   └── {project_slug}/        # Per-project directory
│       ├── index.json         # Project report registry
│       └── {REPORT_ID}/       # Individual reports
```

For details on report structure, see [REPORT_SPECIFICATION.md](REPORT_SPECIFICATION.md).

### Validator Model

You can change the validator model after installation:

**Switch to Opus (more accurate):**
```bash
cp ~/.claude/research_reports/agents/report-validator-opus.md \
   ~/.claude/agents/report-validator.md
```

**Switch to Sonnet (faster):**
```bash
cp ~/.claude/research_reports/agents/report-validator-sonnet.md \
   ~/.claude/agents/report-validator.md
```

Restart Claude Code after changing.

### Validation Depth

When creating reports, you'll be prompted to choose validation depth:

- **Quick** (~5K tokens): Overview + 1 critical section
- **Standard** (~15K tokens): 2-3 critical sections (recommended default)
- **Thorough** (~30K tokens): 4-5 comprehensive sections
- **Skip**: No validation (not recommended)

See [AGENT_SYSTEM.md](AGENT_SYSTEM.md#validation-depth-levels) for detailed comparison.

### Scope Configuration

Reports can be scoped as:
- **Project**: Specific to current project
- **Global**: General patterns/frameworks available everywhere

The system automatically determines scope based on context. See [AGENT_SYSTEM.md](AGENT_SYSTEM.md#scope-management) for details.

## Troubleshooting

### Agents Not Available

**Symptoms**: Claude Code doesn't recognize agent names when launching

**Checks**:
1. Verify agents installed:
   ```bash
   ls ~/.claude/agents/ | grep -E "(report-creator|research-librarian|report-validator|research-report-finder)"
   ```
2. Check agent files are markdown with YAML frontmatter
3. Verify YAML frontmatter has `name:` field matching filename

**Fix**:
```bash
# Re-copy agent files
cp ~/.claude/research_reports/agents/*.md ~/.claude/agents/

# Restart Claude Code
```

### MCP Tools Not Available

**Symptoms**: `mcp__research_report_tools__lint_report` tool not found

**Checks**:
1. Verify MCP server registered:
   ```bash
   claude mcp list
   ```
2. Check Node.js installed and accessible:
   ```bash
   node --version  # Should be 18+
   ```
3. Verify MCP server file exists:
   ```bash
   ls ~/.claude/research_reports/mcp_tools/index.js
   ```

**Fix**:
```bash
# Reinstall MCP server
claude mcp remove research-report-tools
claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js

# Restart Claude Code
```

### Report Not Found After Creation

**Symptoms**: Created report, but research-report-finder can't find it

**Checks**:
1. Verify index.json exists:
   ```bash
   # For project reports
   ls ~/.claude/agent_research_library/projects/{project_slug}/index.json

   # For global reports
   ls ~/.claude/agent_research_library/_global/index.json
   ```

2. Check report ID in index:
   ```bash
   cat ~/.claude/agent_research_library/projects/{project_slug}/index.json | jq '.reports[].id'
   ```

3. Verify report directory exists:
   ```bash
   ls ~/.claude/agent_research_library/projects/{project_slug}/{REPORT_ID}/
   ```

**Fix**:
- If index.json missing: Have report-creator recreate report
- If report ID mismatch: Edit index.json or recreate report
- If directory missing: Recreate report

### Linter Errors During Creation

**Symptoms**: Report creation fails with validation errors

**Common Issues**:

1. **Invalid section keys**:
   ```
   Error: Section key 'SECTION' missing report ID prefix
   ```
   Fix: All keys must start with `REPORT_ID:` (e.g., `MY_REPORT:ARCHITECTURE`)

2. **Orphaned sections**:
   ```
   Error: Section 'MY_REPORT:CHILD' parent 'MY_REPORT:PARENT' not found
   ```
   Fix: Ensure parent sections exist before child sections

3. **Invalid file structure**:
   ```
   Error: File sections/TOPIC.md not found for section key
   ```
   Fix: Ensure file paths match section structure

4. **Schema version mismatch**:
   ```
   Error: Unknown schema version
   ```
   Fix: Use `schema_version: "2.0"` in metadata.json

For more linter details, see [MCP_TOOLS.md](MCP_TOOLS.md#lint_report-tool).

### Permission Errors

**Symptoms**: Cannot write to `~/.claude/agent_research_library/`

**Fix**:
```bash
# Check permissions
ls -la ~/.claude/agent_research_library/

# Fix if needed
chmod 755 ~/.claude/agent_research_library/
chmod 755 ~/.claude/agent_research_library/_global/
chmod 755 ~/.claude/agent_research_library/projects/
```

### Agent Launches But Fails

**Symptoms**: Agent starts but errors during execution

**Checks**:
1. Verify agent has required tools (check agent .md file frontmatter)
2. Check agent has filesystem access
3. Review error messages for missing dependencies

**Debug**:
- Manually launch agent with simple test task
- Check Claude Code logs for detailed errors
- Verify working directory is accessible

### Node.js Version Issues

**Symptoms**: MCP server fails to start

**Check**:
```bash
node --version
```

**Fix**:
- Install Node.js 18 or higher
- Update PATH if Node.js installed but not found
- Use nvm to manage Node.js versions:
  ```bash
  nvm install 18
  nvm use 18
  ```

## Updating the System

To update to a newer version:

```bash
cd agent-research-library
git pull
./install.sh
```

The installer will:
- Overwrite system files in `~/.claude/research_reports/`
- Update agents in `~/.claude/agents/`
- Preserve existing reports in `~/.claude/agent_research_library/`

**Important**: Existing reports are never modified during updates.

## Uninstalling

To completely remove the system:

```bash
# Remove MCP server
claude mcp remove research-report-tools

# Remove agents
rm ~/.claude/agents/report-creator.md
rm ~/.claude/agents/research-report-finder.md
rm ~/.claude/agents/research-librarian.md
rm ~/.claude/agents/report-validator.md

# Remove system files
rm -rf ~/.claude/research_reports/

# Remove reports (CAUTION: This deletes all research reports!)
rm -rf ~/.claude/agent_research_library/

# Remove from global CLAUDE.md (manual edit)
# Remove the "Agent Research Library" section
```

## Next Steps

After successful installation:

1. **Read Documentation**:
   - [REPORT_SPECIFICATION.md](REPORT_SPECIFICATION.md) - Report structure and format
   - [AGENT_SYSTEM.md](AGENT_SYSTEM.md) - Agent workflows and architecture
   - [MCP_TOOLS.md](MCP_TOOLS.md) - Tool reference

2. **Create First Report**:
   ```
   In a project: "Create a research report on [component] using the Agent Research Library"
   ```

3. **Query Report**:
   ```
   "How does [component] handle [feature]?"
   ```

4. **Explore Examples**:
   - See [REPORT_SPECIFICATION.md](REPORT_SPECIFICATION.md#structure-examples) for example structures
   - Review validation output for quality feedback

## Support

For issues or questions:
- Check this troubleshooting section first
- Review [AGENT_SYSTEM.md](AGENT_SYSTEM.md) for workflow details
- Check [REPORT_SPECIFICATION.md](REPORT_SPECIFICATION.md) for structure questions
- Review MCP tool documentation in [MCP_TOOLS.md](MCP_TOOLS.md)

---

**Last Updated**: 2025-10-17
**Version**: 2.0
