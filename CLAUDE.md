# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The Agent Research Library is a hierarchical knowledge management system that enables context-efficient research through intelligent report generation and querying. It uses specialized AI agents to create, validate, and query comprehensive technical documentation.

Built for Claude Code, designed to be extensible to other AI agent systems.

## System Architecture

The system consists of three main components:

1. **MCP Tools** (Node.js): Provide report registry and linting capabilities
2. **Subagents** (Claude Code): Three specialized agents for creation, validation, and querying
3. **Storage System**: Local `.claude_research/` directories and global `~/.claude/research_reports/`

### Key Components

- **report-creator** (Sonnet): Analyzes codebases and generates hierarchical research reports with automatic structure validation
- **research-report-finder** (Haiku): Intelligent fuzzy search to find existing reports using synonyms and related terms
- **research-librarian** (Sonnet): Efficiently queries reports and recommends relevant sections
- **report-validator** (Opus or Sonnet): Validates conceptual accuracy - model chosen during installation
- **MCP Tools**: JavaScript tools for linting report structure (lint_report)

## Installation and Setup

### Automated Installation

```bash
./install.sh
```

The installer automatically:
1. **Copies files** to `~/.claude/research_reports/`:
   - Documentation (RESEARCH_REPORT_SYSTEM.md, CLAUDE_CODE_INTEGRATION.md)
   - MCP tools (in `mcp_tools/`)
   - Report templates (in `templates/`)
2. **Installs MCP server** via `claude mcp add` command
3. **Installs 4 agents** to `~/.claude/agents/` for auto-discovery:
   - `report-creator.md` (Sonnet)
   - `research-report-finder.md` (Haiku)
   - `research-librarian.md` (Sonnet)
   - `report-validator.md` (Opus recommended, or Sonnet)
4. **Prompts for validator model choice** (Opus/Sonnet)
5. **Configures global CLAUDE.md** with system instructions

After installation, **restart Claude Code** to load agents and MCP tools.

### Manual Installation (if needed)

If the automated installer fails, you can manually configure:

**MCP Server:**
```bash
claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js
```

**Agents:**
```bash
cp ~/.claude/research_reports/agents/*.md ~/.claude/agents/
```

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

User explicitly requests: `"Create a research report on [library_name] using the Agent Research Library"`

**IMPORTANT**: Only create reports when the user specifically mentions "Agent Research Library" or "Research Library" by name.

1. Main Claude launches `report-creator` subagent
2. Agent analyzes codebase with Read, Glob, Grep tools
3. Agent creates hierarchical report structure
4. **Agent automatically validates structure with linter and fixes any issues**
5. Main Claude prompts user for validation depth (Quick/Standard/Thorough/Skip)
6. `report-validator` validates conceptual accuracy
7. If critical issues found, `report-creator` fixes them

**Validation Depth Levels:**
- **Quick** (~5K tokens): Overview + 1 critical section
- **Standard** (~15K tokens): 2-3 critical sections (default)
- **Thorough** (~30K tokens): 4-5 comprehensive sections

### Querying a Report

User asks question about documented topic: `"How does [library] handle [feature]?"`

1. Main Claude launches `research-report-finder` agent (Haiku, fast fuzzy search)
2. Finder intelligently searches using synonyms and related terms (e.g., "auth" finds "authentication")
3. If report exists, launch `research-librarian` subagent
4. Librarian reads only relevant sections (~1700 tokens vs ~50K for full codebase)
5. Returns summary + section recommendations
6. Main Claude answers user with efficient context

### When Report Doesn't Exist

1. Finder agent returns `NOT FOUND`
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

- `report-validator` can use **Opus** (recommended, more accurate) or **Sonnet** (faster, users without Opus access)
- Validator model choice is made during `./install.sh` - creates appropriate agent file
- Add `.claude_research/` to project `.gitignore`
- Reports are project-scoped by default (stored in project directory)
- Global reports (patterns, frameworks) go in `~/.claude/research_reports/_global/`
- Section keys are stable - don't change after creation
- Structural validation is automatic (report-creator self-lints before returning)

## Cross-References

Reports can reference other sections:
- Project reports can reference: same project + global scope
- Global reports can reference: only other global reports
- Format: `[SECTION_KEY]` → `[ACME_API:AUTHENTICATION:OAUTH]`

## Documentation Files

- **README.md**: User-facing quick start guide
- **RESEARCH_REPORT_SYSTEM.md**: Complete system specification (~2000 lines)
- **CLAUDE_CODE_INTEGRATION.md**: Technical integration guide
- **orchestration/GLOBAL_INSTRUCTIONS.md**: Brief global Claude Code instructions (~500 tokens, added to ~/.claude/CLAUDE.md)
- **orchestration/REPORT_CREATION.md**: Detailed report creation workflow for main Claude
- **agents/*.md**: Agent definitions with YAML frontmatter
- **agent_prompts/*.txt**: Original prompts used to create agents (for reference)

## Troubleshooting

**Report not found after creation:**
- Check `.claude_research/index.json` exists
- Verify report ID in index
- Check backup: `~/.claude/research_reports/projects/`

**Want to change validator model:**
- Re-run `./install.sh` and choose different model when prompted
- Or manually copy `agents/report-validator-opus.md` or `agents/report-validator-sonnet.md` to `~/.claude/research_reports/agents/report-validator.md`

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
- research-report-finder uses fuzzy matching (no need for exact topic names)
- Finder understands synonyms: "auth" → "authentication", "oauth" → finds AUTHENTICATION report
- Trust librarian recommendations - it reads enough to understand what to load
- Librarian focuses on completeness over token optimization

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
