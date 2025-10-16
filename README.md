# Agent Research Library

A hierarchical knowledge management system for AI agents that enables context-efficient research through intelligent report generation and querying.

Built for Claude Code, designed to work with any AI agent system.

## Overview

Create comprehensive, validated research reports on complex codebases and query them efficiently using ~97% fewer tokens than traditional approaches.

### Key Features

- **Three specialized agents**: Creator (Sonnet), Validator (Opus), Librarian (Sonnet)
- **Hierarchical structure**: Progressive disclosure with 1-3 abstraction levels
- **Dynamic validation**: Opus catches conceptual errors with configurable depth
- **Token efficient**: Break-even at 2-3 queries, massive savings thereafter
- **Portable**: Easy export/import across machines

## Quick Install

```bash
git clone https://github.com/kaselby/agent-research-library.git
cd agent-research-library
./install.sh
```

The installer will automatically set up agents and prompt for configuration options.

## What It Does

### Create Reports
```
> "Create a research report on acme_api"

Claude creates a hierarchical, validated research report:
  - report-creator (Sonnet) analyzes codebase
  - Linter validates structure
  - report-validator (Opus) catches conceptual errors
  - Result: High-confidence documentation
```

### Query Reports
```
> "How does acme_api handle OAuth authentication?"

research-librarian navigates the report:
  - Reads only relevant sections (~1700 tokens)
  - Returns summary + section recommendations
  - vs loading entire codebase (~50K tokens)
```

## Architecture

```
Main Claude
  ├─ MCP Tools:
  │  └─ lint_report (format validation)
  │
  └─ Subagents:
     ├─ report-creator (Sonnet) → Creates reports
     ├─ report-validator (Opus) → Validates accuracy
     ├─ research-report-finder (Haiku) → Finds existing reports
     └─ research-librarian (Sonnet) → Queries efficiently
```

## Setup

### 1. Run Installation

```bash
./install.sh
```

The installer will:
- Copy files to `~/.claude/research_reports/`
- Install Node.js dependencies for MCP tools
- Automatically configure MCP server using Claude CLI
- Install 4 specialized agents to `~/.claude/agents/`
- Prompt for validator model choice (Opus recommended, Sonnet available)
- Configure global CLAUDE.md instructions

### 2. Restart Claude Code

After installation completes, restart Claude Code to load the new configuration.

### 3. Verify Installation

Check that the following are available:

**MCP Tools:**
- Run `/mcp` in Claude Code to verify `research-report-tools` is listed

**Agents:**
- **report-creator** (Sonnet)
- **report-validator** (Opus or Sonnet)
- **research-librarian** (Sonnet)
- **research-report-finder** (Haiku)

### 4. Test

```
> "Create a research report on [some library in your project]"
```

## Documentation

- **[docs/README.md](docs/README.md)** - Quick reference guide
- **[docs/RESEARCH_REPORT_SYSTEM.md](docs/RESEARCH_REPORT_SYSTEM.md)** - Complete specification
- **[docs/CLAUDE_CODE_INTEGRATION.md](docs/CLAUDE_CODE_INTEGRATION.md)** - Integration details

## Example Report Structure

```
ACME_API/
├── metadata.json
├── _OVERVIEW.md                    # 500 word summary
└── sections/
    ├── INSTALLATION.md            # Simple standalone topic (1200 words)
    │
    ├── CORE_ARCHITECTURE/
    │   ├── _OVERVIEW.md           # Section navigation (400 words)
    │   ├── _CONTENT.md            # Core concepts (2000 words)
    │   ├── CLIENT_MODEL.md        # Component (800 words)
    │   └── REQUEST_HANDLER.md
    │
    └── AUTHENTICATION/
        ├── _OVERVIEW.md
        ├── OAUTH.md               # Component (1200 words)
        └── API_KEYS.md
```

## Cost Analysis

| Operation | Model | Relative Cost |
|-----------|-------|---------------|
| Report Creation | Sonnet | 1.0x (baseline) |
| Standard Validation | Opus | +0.7x |
| Report Query | Sonnet | ~0.1x |

**Total for validated report**: ~1.7x base cost
**Break-even**: 2-3 queries
**Long-term**: 97% token reduction per query

## Validation Depth Levels

Choose validation thoroughness when creating reports:

- **Quick** (~5K tokens): Overview coherence, 1 critical section
- **Standard** (~15K tokens): 2-3 critical sections ← Default
- **Thorough** (~30K tokens): 4-5 sections comprehensive

Opus dynamically selects which sections to validate based on criticality.

## Project Setup

No project-specific setup required. All reports are stored centrally in `~/.claude/agent_research_library/`.

## Workflow

### Creating a Report
1. User: `"Create a research report on library_name"`
2. report-creator analyzes codebase, writes hierarchical report
3. Linter validates structure (auto-fixes)
4. User chooses validation depth (Quick/Standard/Thorough/Skip)
5. report-validator (Opus) checks conceptual accuracy
6. If critical issues found, report-creator fixes them
7. Final validated report ready

### Querying a Report
1. User asks question about documented library
2. Main Claude launches research-report-finder agent (Haiku)
3. If report found → launch research-librarian to read relevant sections
4. Librarian returns summary + section recommendations
5. Main Claude answers user with efficient context

## Storage

- **Centralized**: `~/.claude/agent_research_library/`
- **Project reports**: `~/.claude/agent_research_library/projects/{project_id}/`
- **Global patterns**: `~/.claude/agent_research_library/_global/`

## Updating

```bash
cd ~/Git/agent-research-library
git pull
./install.sh  # Re-install with updates
```

Existing reports remain compatible (schema is versioned).

## Troubleshooting

**"Agent not found" error**
→ Create the three subagents in Claude Code (see Setup above)

**Validation uses Sonnet instead of Opus**
→ Check report-validator agent is configured for Opus model

**Report not found**
→ Check `~/.claude/agent_research_library/projects/{project_slug}/index.json` or `~/.claude/agent_research_library/_global/index.json`

## Requirements

- Claude Code with subagent support
- Sonnet 3.5 and Opus model access
- ~1MB disk space for system files
- ~1-5MB per research report

## Uninstall

```bash
rm -rf ~/.claude/agent_research_library/
# Delete the subagents from ~/.claude/agents/
rm ~/.claude/agents/report-creator.md
rm ~/.claude/agents/research-report-finder.md
rm ~/.claude/agents/research-librarian.md
rm ~/.claude/agents/report-validator.md
```

## License

MIT

## Credits

Designed for context-efficient knowledge management with AI agents.

Built for Claude Code, extensible to other agent frameworks.
