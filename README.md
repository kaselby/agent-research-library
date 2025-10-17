# Agent Research Library

A hierarchical knowledge management system for AI agents that enables context-efficient research through intelligent report generation and querying.

Built for Claude Code, designed to work with any AI agent system.

## Overview

Create comprehensive, validated research reports on complex codebases and query them efficiently using ~97% fewer tokens than traditional approaches.

### Key Features

- **Four specialized agents**: Creator (Sonnet), Finder (Haiku), Librarian (Sonnet), Validator (Opus/Sonnet)
- **Hierarchical structure**: Progressive disclosure with 1-3 abstraction levels
- **Flexible v2.0 schema**: Mix standalone files and directories based on natural complexity
- **Dynamic validation**: Opus catches conceptual errors with configurable depth
- **Token efficient**: Break-even at 2-3 queries, massive savings thereafter
- **Centralized storage**: All reports in `~/.claude/agent_research_library/`

## Quick Install

```bash
git clone https://github.com/kaselby/agent-research-library.git
cd agent-research-library
./install.sh
```

The installer automatically:
- Installs MCP tools for structure validation
- Registers 4 specialized agents
- Prompts for validator model choice (Opus recommended, Sonnet available)
- Configures global CLAUDE.md instructions
- Creates centralized storage directory

**After installation, restart Claude Code.**

## What It Does

### Create Reports
```
> "Create a research report on acme_api using the Agent Research Library"

Claude creates a hierarchical, validated research report:
  1. research-report-finder checks if report exists
  2. report-creator (Sonnet) analyzes codebase
  3. Linter validates structure automatically
  4. User chooses validation depth (Quick/Standard/Thorough/Skip)
  5. report-validator (Opus) catches conceptual errors
  6. Result: High-confidence documentation
```

### Query Reports
```
> "How does acme_api handle OAuth authentication?"

Claude efficiently navigates the report:
  1. research-report-finder locates relevant report (fuzzy search)
  2. research-librarian reads only relevant sections (~1700 tokens)
  3. Returns summary + section recommendations
  4. vs loading entire codebase (~50K tokens)

Result: ~97% token reduction
```

## Architecture

```
Main Claude
  ├─ MCP Tools:
  │  ├─ lint_report (structure validation)
  │  └─ extract_section (partial content loading)
  │
  └─ Subagents:
     ├─ report-creator (Sonnet) → Creates hierarchical reports
     ├─ report-validator (Opus/Sonnet) → Validates conceptual accuracy
     ├─ research-report-finder (Haiku) → Fast fuzzy search with synonyms
     └─ research-librarian (Sonnet) → Queries reports efficiently
```

## Example Report Structure (v2.0)

The v2.0 schema uses a flexible hierarchy where simple topics are standalone files and complex topics are directories:

```
ACME_API/
├── metadata.json                   # Report metadata with section registry
├── _OVERVIEW.md                    # 400-700 word summary
└── sections/
    ├── INSTALLATION.md            # Simple standalone topic (1000-2000 words)
    │
    ├── CORE_ARCHITECTURE/         # Complex topic with subdivisions
    │   ├── _OVERVIEW.md           # Section navigation (200-400 words)
    │   ├── _CONTENT.md            # Core concepts (1500-2500 words, optional)
    │   ├── CLIENT_MODEL.md        # Focused component (800-1500 words)
    │   └── REQUEST_HANDLER.md
    │
    └── AUTHENTICATION/
        ├── _OVERVIEW.md
        ├── _CONTENT.md
        ├── OAUTH.md               # Component (1200 words)
        └── API_KEYS.md
```

**Key Changes in v2.0:**
- `_CONTENT.md` (optional) replaces `_FULL.md` (deprecated)
- Standalone files are first-class citizens (no forced directories)
- Flexible depth: 1-3 levels based on natural complexity
- Section types: "leaf" (standalone file) or "composite" (directory)
- Section markers enable partial loading of large files

## Storage

All reports are stored centrally:

```
~/.claude/agent_research_library/
├── projects/                      # Project-specific reports
│   └── {project_id}/             # Per-project directory (auto-generated ID)
│       ├── index.json            # Project report registry
│       └── {REPORT_ID}/          # Individual reports
└── _global/                       # Global patterns and frameworks
    ├── index.json                # Global report registry
    └── {REPORT_ID}/              # Reusable knowledge
```

**Benefits:**
- No per-project setup required
- Reports persist across projects
- Global reports reusable everywhere
- Easy backup/export of all knowledge

## Validation Depth Levels

Choose validation thoroughness when creating reports:

| Depth | Tokens | Coverage | When to Use |
|-------|--------|----------|-------------|
| **Quick** | ~5K | Overview + 1 critical section | Simple, straightforward reports |
| **Standard** | ~15K | 2-3 critical sections | Most reports (recommended default) |
| **Thorough** | ~30K | 4-5 comprehensive sections | Critical, complex systems |
| **Skip** | 0 | Linter only (no Opus) | Trivial reports (not recommended) |

Validator dynamically selects which sections to validate based on criticality.

## Cost Analysis

| Operation | Model | Relative Cost |
|-----------|-------|---------------|
| Report Creation | Sonnet | 1.0x (baseline) |
| Standard Validation | Opus | +0.7x |
| Report Query | Sonnet + Haiku | ~0.1x |

**Total for validated report**: ~1.7x base cost
**Break-even**: 2-3 queries
**Long-term**: 97% token reduction per query

## Documentation

Complete documentation is available in `docs/`:

- **[INTEGRATION_GUIDE.md](docs/INTEGRATION_GUIDE.md)** - Installation, setup, and troubleshooting
- **[REPORT_SPECIFICATION.md](docs/REPORT_SPECIFICATION.md)** - Complete v2.0 format specification
- **[AGENT_SYSTEM.md](docs/AGENT_SYSTEM.md)** - Agent architecture and workflows
- **[MCP_TOOLS.md](docs/MCP_TOOLS.md)** - Tool reference (lint_report, extract_section)

## Quick Start Guide

### 1. Install

```bash
./install.sh
```

### 2. Restart Claude Code

Required to load agents and MCP tools.

### 3. Create Your First Report

In any project:
```
> "Create a research report on [component name] using the Agent Research Library"
```

Claude will:
- Launch report-creator to analyze codebase
- Create hierarchical report structure
- Validate with linter (automatic)
- Prompt for validation depth
- Validate with report-validator (if not skipped)
- Store in `~/.claude/agent_research_library/projects/{project_id}/`

### 4. Query Your Report

```
> "How does [component] handle [feature]?"
```

Claude will:
- Launch research-report-finder to locate report
- Launch research-librarian to read relevant sections
- Answer your question with efficient context

## Workflows

### Creating a Report
1. User explicitly requests: `"Create a research report on library_name using the Agent Research Library"`
2. research-report-finder checks if report already exists
3. report-creator (Sonnet) analyzes codebase and writes hierarchical report
4. Linter validates structure automatically (self-fixes)
5. User chooses validation depth (Quick/Standard/Thorough/Skip)
6. report-validator (Opus) checks conceptual accuracy of critical sections
7. If critical issues found, report-creator fixes them
8. Final validated report stored in centralized library

### Querying a Report
1. User asks question about documented topic
2. research-report-finder (Haiku) performs fuzzy search with synonym expansion
3. If report found → research-librarian loads overview + relevant sections
4. Librarian returns summary + section recommendations (~1700 tokens)
5. Main Claude answers user with efficient context (vs ~50K tokens for full codebase)

### Report Not Found
1. research-report-finder returns NOT FOUND
2. Main Claude answers question using traditional codebase search
3. Optionally suggests creating a report for future queries

## Requirements

- **Claude Code**: With subagent and MCP support
- **Node.js**: 18+ (for MCP tools)
- **Models**:
  - Sonnet 3.5 (report-creator, research-librarian)
  - Haiku 3.5 (research-report-finder)
  - Opus 3 or Sonnet 3.5 (report-validator)
- **Disk Space**:
  - ~1MB for system files
  - ~1-5MB per research report

## Updating

To update to the latest version:

```bash
cd agent-research-library
git pull
./install.sh
```

Existing reports remain compatible (schema is versioned). The installer preserves all reports in `~/.claude/agent_research_library/`.

## Troubleshooting

### Agents Not Available

**Symptom**: Claude Code doesn't recognize agent names

**Fix**:
```bash
# Verify agents installed
ls ~/.claude/agents/ | grep report

# Re-install if needed
./install.sh
```

### MCP Tools Not Available

**Symptom**: `mcp__research_report_tools__lint_report` not found

**Fix**:
```bash
# Verify registration
claude mcp list

# Re-install if needed
claude mcp remove research-report-tools
claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js
```

### Report Not Found After Creation

**Symptom**: Created report, but finder can't locate it

**Fix**:
```bash
# Check project index exists
ls ~/.claude/agent_research_library/projects/

# Check global index exists
ls ~/.claude/agent_research_library/_global/index.json

# Verify report directory exists
ls ~/.claude/agent_research_library/projects/{project_id}/{REPORT_ID}/
```

For more troubleshooting, see [INTEGRATION_GUIDE.md](docs/INTEGRATION_GUIDE.md#troubleshooting).

## Uninstall

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

# Remove reports (CAUTION: Deletes all research reports!)
rm -rf ~/.claude/agent_research_library/
```

## License

MIT

## Contributing

Contributions welcome! Please ensure:
- Documentation updates accompany code changes
- All examples use v2.0 schema (_CONTENT.md not _FULL.md)
- Tests pass with the linter
- Agent prompts are clear and focused

## Credits

Designed for context-efficient knowledge management with AI agents.

Built for Claude Code, extensible to other agent frameworks.

---

**Ready to use!** Run `./install.sh` to get started.
