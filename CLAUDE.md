# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The Claude Research Report System is a hierarchical knowledge management system that enables context-efficient research through intelligent report generation and querying. It uses three specialized Claude Code subagents to create, validate, and query comprehensive technical documentation.

## System Architecture

The system consists of three main components:

1. **MCP Tools** (Node.js): Provide report registry and linting capabilities
2. **Subagents** (Claude Code): Three specialized agents for creation, validation, and querying
3. **Storage System**: Local `.claude_research/` directories and global `~/.claude/research_reports/`

### Key Components

- **report-creator** (Sonnet): Analyzes codebases and generates hierarchical research reports
- **report-validator** (Opus): Validates conceptual accuracy and catches architectural misunderstandings
- **research-librarian** (Sonnet): Efficiently queries reports and recommends relevant sections
- **MCP Tools**: JavaScript tools for checking report existence and validating report structure

## Installation and Setup

### Install Files

```bash
./install.sh
```

This installs files to `~/.claude/research_reports/` including:
- Documentation (RESEARCH_REPORT_SYSTEM.md, CLAUDE_CODE_INTEGRATION.md)
- Agent definitions (in `agents/`)
- MCP tools (in `mcp_tools/`)
- Report templates (in `templates/`)

### Configure MCP Server

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "research-report-tools": {
      "type": "stdio",
      "command": "node",
      "args": ["~/.claude/research_reports/mcp_tools/index.js"]
    }
  }
}
```

Or use CLI: `claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js`

### Install Subagents

Copy agent files to Claude Code's agent directory:

```bash
cp ~/.claude/research_reports/agents/*.md ~/.claude/agents/
```

Or manually create three subagents using the agent definition files in `~/.claude/research_reports/agents/`:
- `report-creator.md` (Sonnet)
- `report-validator.md` (Opus - **must use Opus**)
- `research-librarian.md` (Sonnet)

## Report Structure

Reports are hierarchical with 1-3 abstraction levels:

```
REPORT_ID/
├── metadata.json                 # Report metadata, section registry
├── _OVERVIEW.md                  # 500-word report summary
└── sections/
    ├── L1_SECTION/               # Major subsystem
    │   ├── _FULL.md              # 2000-4000 words
    │   ├── _OVERVIEW.md          # 300-500 word summary
    │   ├── L2_COMPONENT.md       # 600-1000 words
    │   └── L2_COMPONENT2.md
    └── L1_SECTION2/
        └── ...
```

### Section Keys

Format: `REPORT_ID:L1_SECTION:L2_COMPONENT:L3_DETAIL`

Examples:
- `ACME_API:CORE_ARCHITECTURE`
- `ACME_API:AUTHENTICATION:OAUTH`
- `TASKFLOW:ORCHESTRATION:TASK_DELEGATION`

## Storage Locations

- **Project reports**: `{project}/.claude_research/` (add to `.gitignore`)
- **Global patterns**: `~/.claude/research_reports/_global/`
- **Backups**: `~/.claude/research_reports/projects/{project_slug}/`

## Common Workflows

### Creating a Report

User explicitly requests: `"Create a research report on [library_name]"`

1. Main Claude launches `report-creator` subagent
2. Agent analyzes codebase with Read, Glob, Grep tools
3. Agent creates hierarchical report structure
4. Linter validates format (automatic)
5. User chooses validation depth (Quick/Standard/Thorough/Skip)
6. `report-validator` (Opus) validates conceptual accuracy
7. If critical issues found, `report-creator` fixes them

**Validation Depth Levels:**
- **Quick** (~5K tokens): Overview + 1 critical section
- **Standard** (~15K tokens): 2-3 critical sections (default)
- **Thorough** (~30K tokens): 4-5 comprehensive sections

### Querying a Report

User asks question about documented topic: `"How does [library] handle [feature]?"`

1. Main Claude uses `check_report_exists` MCP tool
2. If report exists, launch `research-librarian` subagent
3. Librarian reads only relevant sections (~1700 tokens vs ~50K for full codebase)
4. Returns summary + section recommendations
5. Main Claude answers user with efficient context

### When Report Doesn't Exist

1. MCP tool returns `exists: false`
2. Answer question using traditional codebase search
3. Optionally suggest creating a report for future queries

## Development Commands

### MCP Tools

```bash
# Install dependencies
cd mcp_tools
npm install

# Test MCP server
node index.js

# Lint a report
node index.js lint /path/to/.claude_research/REPORT_ID/
```

### File Operations

```bash
# Install/update system files
./install.sh

# Create agent files from templates
cp agents/*.md ~/.claude/agents/

# View installed documentation
cat ~/.claude/research_reports/RESEARCH_REPORT_SYSTEM.md
```

## Key Design Principles

1. **Context Efficiency**: Load only relevant sections, not entire reports
2. **Hierarchical Organization**: Progressive disclosure through abstraction levels
3. **Explicit Creation**: Reports only created on explicit user request (expensive)
4. **Persistent Knowledge**: Reports survive across sessions
5. **Quality Validation**: Opus validates conceptual accuracy, catches fundamental errors

## Token Efficiency

- **Report creation**: 1.0x base cost (Sonnet research + writing)
- **Validation**: +0.7x (Opus, standard depth)
- **Query**: ~0.1x (Sonnet librarian)
- **Break-even**: 2-3 queries on same topic
- **Long-term savings**: 97% token reduction per query

## Important Notes

- `report-validator` **MUST** use Opus model for accurate validation
- Add `.claude_research/` to project `.gitignore`
- Reports are project-scoped by default (stored in project directory)
- Global reports (patterns, frameworks) go in `~/.claude/research_reports/_global/`
- Section keys are stable - don't change after creation

## Cross-References

Reports can reference other sections:
- Project reports can reference: same project + global scope
- Global reports can reference: only other global reports
- Format: `[SECTION_KEY]` → `[ACME_API:AUTHENTICATION:OAUTH]`

## Documentation Files

- **README.md**: User-facing quick start guide
- **RESEARCH_REPORT_SYSTEM.md**: Complete system specification (~2000 lines)
- **CLAUDE_CODE_INTEGRATION.md**: Technical integration guide
- **agents/*.md**: Agent definitions with YAML frontmatter

## Troubleshooting

**Report not found after creation:**
- Check `.claude_research/index.json` exists
- Verify report ID in index
- Check backup: `~/.claude/research_reports/projects/`

**Validation uses Sonnet instead of Opus:**
- Verify `report-validator` agent configured for Opus model

**MCP tools not available:**
- Restart Claude Code after adding to `~/.claude.json`
- Check Node.js installed: `node --version`
- Verify path: `~/.claude/research_reports/mcp_tools/index.js`

## Cost Optimization

1. Use **Standard** validation for most reports (good balance)
2. Use **Quick** validation for simple/straightforward reports (<8 sections)
3. Use **Thorough** validation for critical/complex systems
4. Skip validation only for trivial reports (not recommended)
5. Linter validation is always free (catches 80% of issues)

## Report Versioning

- Format: `major.minor`
- Major: Structural changes (new sections, reorganization)
- Minor: Content updates (existing sections modified)
- Each section tracks: `last_updated` timestamp
- Update reports when code changes significantly

## Best Practices

### For Report Creation
- Include `file:line` references (e.g., `auth.py:145-203`)
- Target word counts: Overview (300-500), L2 (600-1000), L1 Full (2000-4000)
- Maximum depth: 3 levels (rarely needed)
- Cross-reference related sections with `[SECTION_KEY]`

### For Querying
- Always check `check_report_exists` before traditional search
- Start with _OVERVIEW files (cheapest)
- Navigate hierarchy before reading _FULL sections
- Trust librarian recommendations

## Example Usage

```
# Create a report
> "Create a research report on the authentication system"

# Query the report
> "How does the auth system handle OAuth?"
→ Librarian reads ~1700 tokens, returns summary

# Update existing report
> "Update the authentication report with recent changes"
```
