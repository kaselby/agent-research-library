# Claude Research Report System

A hierarchical knowledge management system for Claude Code that enables context-efficient research through intelligent report generation and querying.

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
git clone https://github.com/yourusername/claude-research-system.git
cd claude-research-system
./install.sh
```

Then create three subagents in Claude Code (see [Setup](#setup) below).

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
  │  ├─ check_report_exists (checks if report exists)
  │  └─ lint_report (format validation)
  │
  └─ Subagents:
     ├─ report-creator (Sonnet) → Creates reports
     ├─ report-validator (Opus) → Validates accuracy
     └─ research-librarian (Sonnet) → Queries efficiently
```

## Setup

### 1. Install Files

```bash
./install.sh
```

This copies files to `~/.claude/research_reports/` and installs MCP tools.

### 2. Configure MCP Tools

See `~/.claude/research_reports/mcp_tools/README.md` for full instructions.

**Quick setup** (user-level, available in all projects):

```bash
claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js
```

Or manually add to `~/.claude.json`:

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

Restart Claude Code after configuration.

### 3. Install Subagents

**Option A: Automatic (File-based discovery)**

Copy agent files to Claude Code's agent directory:

```bash
cp ~/.claude/research_reports/agents/*.md ~/.claude/agents/
```

Restart Claude Code. The agents will be auto-discovered.

**Option B: Manual (via Claude Code UI)**

Create three subagents manually in Claude Code. The agent definition files contain YAML frontmatter with all configuration:

- `~/.claude/research_reports/agents/report-creator.md`
- `~/.claude/research_reports/agents/report-validator.md`
- `~/.claude/research_reports/agents/research-librarian.md`

Copy the entire file contents (including YAML frontmatter) as the agent description.

**⚠️ Important:** `report-validator` MUST use Opus model, not Sonnet.

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
    ├── CORE_ARCHITECTURE/
    │   ├── _FULL.md               # Complete (3000 words)
    │   ├── _OVERVIEW.md           # Summary (400 words)
    │   ├── CLIENT_MODEL.md        # Component (800 words)
    │   └── REQUEST_HANDLER.md
    │
    └── AUTHENTICATION/
        ├── _FULL.md
        ├── _OVERVIEW.md
        ├── OAUTH.md               # Component (800 words)
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

Add to your project's `.gitignore`:
```
.claude_research/
```

Reports are stored per-project in `.claude_research/` (not version controlled).

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
2. Main Claude checks if report exists
3. research-librarian reads only relevant sections
4. Returns summary + section recommendations
5. Main Claude answers user with efficient context

## Storage

- **Per-project**: `{project}/.claude_research/` (primary, gitignored)
- **Global patterns**: `~/.claude/research_reports/_global/` (optional)
- **Backups**: `~/.claude/research_reports/projects/` (optional)

## Updating

```bash
cd ~/Git/claude-research-system
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
→ Check `.claude_research/index.json` in your project directory

## Requirements

- Claude Code with subagent support
- Sonnet 3.5 and Opus model access
- ~1MB disk space for system files
- ~1-5MB per research report

## Uninstall

```bash
rm -rf ~/.claude/research_reports/
# Delete the three subagents from Claude Code
# Optionally delete .claude_research/ from projects
```

## License

MIT

## Credits

Designed for context-efficient knowledge management with Claude Code.
