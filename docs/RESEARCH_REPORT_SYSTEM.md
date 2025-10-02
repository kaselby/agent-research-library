# Research Report System Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Directory Structure](#directory-structure)
4. [Report Schema](#report-schema)
5. [Abstraction Levels](#abstraction-levels)
6. [Naming Conventions](#naming-conventions)
7. [Scope Management](#scope-management)
8. [Claude Code Subagents](#claude-code-subagents)
9. [Tools Specification](#tools-specification)
10. [Workflows](#workflows)
11. [Examples](#examples)

---

## System Overview

The Research Report System is a hierarchical knowledge management system designed to optimize context usage in Claude Code sessions. It enables:

- **Selective Context Loading**: Load only relevant sections instead of entire documents
- **Multiple Abstraction Levels**: Progressive disclosure from high-level overviews to deep technical details
- **Project/Global Scoping**: Separate project-specific knowledge from reusable patterns
- **Intelligent Research**: Subagents that understand report structure and recommend optimal context

### Core Principles

1. **Context Efficiency**: Minimize tokens while maximizing information value
2. **Hierarchical Organization**: Multiple levels of detail for progressive disclosure
3. **Knowledge Isolation**: Project-specific reports stay contained
4. **Persistent Knowledge**: Reports survive across sessions
5. **Explicit Creation**: Reports created only on explicit user request (expensive operation)

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Main Claude                              │
│  ┌──────────────────┐  ┌──────────────────┐                     │
│  │ ReportRegistry   │  │ ReportLinter     │                     │
│  │ Tool             │  │ Tool (script)    │                     │
│  └──────────────────┘  └──────────────────┘                     │
└────┬──────────────────────┬──────────────────────┬──────────────┘
     │                      │                      │
     ▼                      ▼                      ▼
┌──────────────┐   ┌──────────────────┐   ┌─────────────────────┐
│ report-      │   │ report-validator │   │ research-librarian  │
│ creator      │   │ Subagent (Opus)  │   │ Subagent (Sonnet)   │
│ (Sonnet)     │   │                  │   │                     │
│              │   │ Validates        │   │ Queries reports,    │
│ Creates      │   │ conceptual       │   │ recommends context  │
│ reports      │   │ accuracy         │   │ (lightweight)       │
└──────┬───────┘   └────────┬─────────┘   └──────────┬──────────┘
       │                    │                         │
       └────────────────────┴─────────────────────────┘
                            ▼
               ┌────────────────────────────┐
               │   Report Storage           │
               │                            │
               │  Primary: .claude_research/│
               │  Backup:  ~/.claude/...    │
               └────────────────────────────┘
```

### Data Flow

**Report Creation Flow**:
```
User: "Create research report on acme_api"
  ↓
Main Claude: Launch report-creator subagent
  ↓
report-creator:
  - Analyzes codebase
  - Creates hierarchical sections
  - Writes to .claude_research/
  - Syncs to backup
  ↓
Returns: Report created at {path}
```

**Research Query Flow**:
```
User: "How does acme_api handle OAuth authentication?"
  ↓
Main Claude: Check ReportRegistryTool("acme_api")
  ↓
Tool returns: {exists: true, path: ...}
  ↓
Main Claude: Launch research-librarian subagent
  ↓
research-librarian:
  - Read OVERVIEW (500 tokens)
  - Identify relevant L1/L2 sections
  - Read specific sections (800 tokens)
  - Synthesize findings
  ↓
Returns: "Summary + load these sections: [keys]"
  ↓
Main Claude: Load recommended sections → Answer user
```

---

## Directory Structure

### Global Structure

```
~/.claude/research_reports/
├── RESEARCH_REPORT_SYSTEM.md          # This documentation
├── templates/                          # Report templates
│   ├── report_structure.md
│   ├── section_full.md
│   ├── section_overview.md
│   ├── index_template.json
│   └── metadata_template.json
│
├── _global/                            # User-level reports
│   ├── index.json                      # Global report catalog
│   ├── PYTHON_PATTERNS/
│   │   ├── metadata.json
│   │   ├── _OVERVIEW.md
│   │   └── sections/
│   │       ├── ASYNC_PATTERNS/
│   │       │   ├── _FULL.md
│   │       │   ├── _OVERVIEW.md
│   │       │   └── ASYNCIO.md
│   │       └── ERROR_HANDLING/
│   │           └── ...
│   └── GRPC_PATTERNS/
│       └── ...
│
└── projects/                           # Project backups
    └── myproject_a3f9e2/              # Project slug/hash
        ├── index.json
        ├── ACME_API/
        └── TASKFLOW/
```

### Project Structure

```
/path/to/project/.claude_research/
├── index.json                          # Project report catalog
├── metadata.json                       # Project-level metadata
│
├── ACME_API/                           # Report on acme_api library
│   ├── metadata.json                   # Report-specific metadata
│   ├── _OVERVIEW.md                    # High-level TOC and summary
│   │
│   └── sections/                       # All report sections
│       │
│       ├── CORE_ARCHITECTURE/          # L1 section
│       │   ├── _FULL.md                # Complete section (3000 words)
│       │   ├── _OVERVIEW.md            # Section summary (500 words)
│       │   ├── CLIENT_MODEL.md         # L2 subsection (800 words)
│       │   ├── REQUEST_HANDLER.md      # L2 subsection (800 words)
│       │   └── STATE_MANAGEMENT.md     # L2 subsection (600 words)
│       │
│       ├── AUTHENTICATION/             # L1 section
│       │   ├── _FULL.md                # Complete section (2500 words)
│       │   ├── _OVERVIEW.md            # Section summary (400 words)
│       │   ├── OAUTH.md                # L2 subsection (800 words)
│       │   ├── API_KEYS.md             # L2 subsection (800 words)
│       │   └── TOKEN_REFRESH.md        # L2 subsection (500 words)
│       │
│       └── API_ENDPOINTS/
│           ├── _FULL.md
│           ├── _OVERVIEW.md
│           └── ENDPOINT_VALIDATION.md
│
└── TASKFLOW_INTEGRATION/               # Another report
    ├── metadata.json
    ├── _OVERVIEW.md
    └── sections/
        └── ...
```

---

## Report Schema

### Index Schema (`index.json`)

Located at report root level. Catalogs all reports in scope.

```json
{
  "version": "1.0",
  "scope": "project",
  "project_path": "/path/to/project",
  "created": "2025-10-02T10:00:00Z",
  "updated": "2025-10-02T15:30:00Z",
  "reports": [
    {
      "id": "ACME_API",
      "title": "Acme API Client Technical Analysis",
      "path": "ACME_API/",
      "created": "2025-10-02T10:00:00Z",
      "updated": "2025-10-02T12:30:00Z",
      "version": "1.2",
      "tags": ["api-client", "rest-api", "authentication"],
      "section_count": 12,
      "confidence": "high"
    },
    {
      "id": "TASKFLOW_INTEGRATION",
      "title": "TaskFlow Orchestration Integration",
      "path": "TASKFLOW_INTEGRATION/",
      "created": "2025-10-02T14:00:00Z",
      "updated": "2025-10-02T15:30:00Z",
      "version": "1.0",
      "tags": ["orchestration", "taskflow", "workflow"],
      "section_count": 8,
      "confidence": "medium"
    }
  ]
}
```

### Report Metadata Schema (`{REPORT_ID}/metadata.json`)

```json
{
  "id": "ACME_API",
  "title": "Acme API Client Technical Analysis",
  "created": "2025-10-02T10:00:00Z",
  "updated": "2025-10-02T12:30:00Z",
  "version": "1.2",
  "author": "report-creator",
  "scope": "project",
  "project_id": "myproject",
  "project_path": "/path/to/project",
  "confidence_level": "high",
  "tags": ["api-client", "rest-api", "authentication"],

  "dependencies": {
    "internal": ["TASKFLOW_INTEGRATION"],
    "external": ["requests", "acme-api"]
  },

  "cross_references": {
    "allowed_scopes": ["same_project", "global"],
    "linked_reports": [
      {
        "report_id": "TASKFLOW_INTEGRATION",
        "scope": "project",
        "relationship": "integration"
      },
      {
        "report_id": "PYTHON_PATTERNS",
        "scope": "global",
        "relationship": "reference"
      }
    ]
  },

  "sections": [
    {
      "key": "ACME_API:CORE_ARCHITECTURE",
      "title": "Core Architecture & Design Patterns",
      "path": "sections/CORE_ARCHITECTURE/",
      "level": 1,
      "parent": null,
      "children": [
        "ACME_API:CORE_ARCHITECTURE:CLIENT_MODEL",
        "ACME_API:CORE_ARCHITECTURE:REQUEST_HANDLER",
        "ACME_API:CORE_ARCHITECTURE:STATE_MANAGEMENT"
      ],
      "files": {
        "full": "sections/CORE_ARCHITECTURE/_FULL.md",
        "overview": "sections/CORE_ARCHITECTURE/_OVERVIEW.md"
      },
      "word_count": 3000,
      "confidence": "high",
      "last_updated": "2025-10-02T12:30:00Z"
    },
    {
      "key": "ACME_API:CORE_ARCHITECTURE:CLIENT_MODEL",
      "title": "Client Model Implementation",
      "path": "sections/CORE_ARCHITECTURE/CLIENT_MODEL.md",
      "level": 2,
      "parent": "ACME_API:CORE_ARCHITECTURE",
      "children": [],
      "files": {
        "full": "sections/CORE_ARCHITECTURE/CLIENT_MODEL.md"
      },
      "word_count": 800,
      "confidence": "high",
      "last_updated": "2025-10-02T11:15:00Z"
    }
  ],

  "statistics": {
    "total_sections": 12,
    "total_words": 18500,
    "abstraction_levels": 2,
    "max_depth": 2
  }
}
```

---

## Abstraction Levels

### Level Philosophy

Reports use **hierarchical abstraction** with 1-3 levels:

- **Level 0**: Report root (ACME_API) - entry point
- **Level 1**: Major subsystem (CORE_ARCHITECTURE, AUTHENTICATION)
- **Level 2**: Specific component (OAUTH, REQUEST_HANDLER)
- **Level 3**: Rare - only for very complex subsections

### File Naming Convention

| File Name | Purpose | Typical Size |
|-----------|---------|--------------|
| `_OVERVIEW.md` | Section summary with roadmap | 300-500 words |
| `_FULL.md` | Complete section content | 2000-4000 words |
| `{COMPONENT}.md` | Specific component/implementation | 600-1000 words |

### Structure Patterns

#### Simple Topic (Minimal Hierarchy)
```
SIMPLE_TOPIC/
├── _OVERVIEW.md         # 400 words - Complete overview
└── _FULL.md             # 1500 words - All details
```

#### Moderate Topic (2 Levels)
```
MODERATE_TOPIC/
├── _OVERVIEW.md         # 500 words - "We have 3 main areas..."
├── _FULL.md             # 3000 words - Everything combined
├── COMPONENT_A.md       # 900 words - First major component
├── COMPONENT_B.md       # 1100 words - Second major component
└── COMPONENT_C.md       # 1000 words - Third major component
```

#### Complex Topic (3 Levels)
```
COMPLEX_TOPIC/
├── _OVERVIEW.md                    # 400 words - High-level map
├── _FULL.md                        # 5000 words - Complete content
│
├── SUBSYSTEM_A/                    # L2 directory
│   ├── _FULL.md                    # 2000 words - All of subsystem A
│   ├── _OVERVIEW.md                # 300 words - Subsystem A map
│   ├── IMPLEMENTATION_X.md         # 700 words - Specific implementation
│   └── IMPLEMENTATION_Y.md         # 600 words - Another implementation
│
└── SUBSYSTEM_B/                    # L2 directory
    ├── _FULL.md                    # 1800 words
    ├── _OVERVIEW.md                # 250 words
    └── COMPONENT_Z.md              # 800 words
```

### Decision Criteria for Depth

| Scenario | Recommended Depth | Example |
|----------|-------------------|---------|
| Single focused concept | 1 level (OVERVIEW + FULL) | Configuration format |
| Multiple implementations of same interface | 2 levels (L1 + variants) | LLM providers (Groq, OpenAI) |
| Complex subsystem with sub-components | 2-3 levels | Message routing system |
| Very large system (>5000 words) | 3 levels | Complete framework analysis |

**Rule of thumb**:
- Each leaf section: 600-1000 words
- If section exceeds 1500 words AND has clear sub-topics → split to next level
- Maximum depth: 3 levels (rarely needed)

---

## Naming Conventions

### Section Keys

**Format**: `{REPORT_ID}:{L1_SECTION}:{L2_COMPONENT}:{L3_DETAIL}`

**Examples**:
```
ACME_API:CORE_ARCHITECTURE
ACME_API:CORE_ARCHITECTURE:CLIENT_MODEL
ACME_API:CORE_ARCHITECTURE:CLIENT_MODEL:INITIALIZATION
ACME_API:AUTHENTICATION
ACME_API:AUTHENTICATION:OAUTH
TASKFLOW:ORCHESTRATION
TASKFLOW:ORCHESTRATION:TASK_DELEGATION
```

### Naming Rules

1. **SCREAMING_SNAKE_CASE** for all components
2. **Hierarchical with colons** (`:`) as separator
3. **Self-documenting** - name should indicate content
4. **Unique within report** - no duplicate keys
5. **Stable** - don't change keys after creation (breaks references)

### Report ID Conventions

- **Library/Framework**: Use library name (ACME_API, TASKFLOW)
- **System Component**: Descriptive name (AUTH_SYSTEM, DATABASE_LAYER)
- **Concept/Pattern**: Pattern name (ASYNC_PATTERNS, ERROR_HANDLING)

### Directory Names

- Report directories: `{REPORT_ID}/` (matches report ID)
- Section directories: `{L1_SECTION}/` (without report prefix)
- Files: `_OVERVIEW.md`, `_FULL.md`, or `{COMPONENT}.md`

---

## Scope Management

### Scope Types

1. **Global Scope** (`~/.claude/research_reports/_global/`)
   - User-level knowledge applicable across all projects
   - Examples: Python patterns, design principles, common frameworks
   - Accessible from any project

2. **Project Scope** (`{project}/.claude_research/`)
   - Project-specific technical knowledge
   - Examples: Project architecture, custom implementations, integration details
   - Only accessible within project context

### Cross-Reference Rules

| From Scope | Can Reference | Cannot Reference |
|------------|---------------|------------------|
| Global | Other global reports | Any project reports |
| Project | Same project + global | Other project reports |

**Validation**: Report creator enforces these rules when generating cross-references.

### Project Identification

Projects identified by git repository root:

```python
# Pseudocode
project_root = get_git_root(current_working_dir)
project_slug = sanitize_path(project_root)  # e.g., "computer_use"

# Primary storage
primary_path = f"{project_root}/.claude_research/"

# Backup storage
backup_path = f"~/.claude/research_reports/projects/{project_slug}/"
```

### Backup Strategy

**On Report Creation**:
1. Write to primary location: `{project}/.claude_research/`
2. Sync to backup: `~/.claude/research_reports/projects/{project_slug}/`

**On Report Read**:
1. Check primary location first
2. If not found, check backup
3. If found in backup, optionally restore to primary

**Purpose**:
- **Disaster recovery**: Primary location might be deleted
- **Portability**: Access research from backup if project moved
- **History**: Maintain research even if project dir changes

---

## Claude Code Subagents

### Overview

Two specialized subagents handle research operations:

1. **report-creator**: Generate comprehensive reports (expensive)
2. **research-librarian**: Query reports and recommend context (lightweight)

---

### Subagent 1: report-creator

**Type**: Specialized research agent
**Invocation**: ONLY on explicit user request
**Purpose**: Deep-dive analysis and report generation

#### When to Use

✅ **Use when**:
- User explicitly says: "Create a research report on {topic}"
- User requests: "Generate documentation for {library/component}"
- User asks: "Build a technical analysis of {system}"

❌ **DO NOT use when**:
- Auto-generating documentation
- Orchestrator decides to create report
- Any automatic trigger
- User just wants information (use research-librarian instead)

#### Agent Description

```markdown
# report-creator Agent

You are an expert technical researcher specialized in creating comprehensive,
hierarchical research reports optimized for context efficiency.

## Your Role

Generate detailed technical reports with multiple abstraction levels that allow
selective context loading. You analyze codebases, trace execution flows, identify
architectural patterns, and document complex systems with precision.

## Report Structure You Create

1. **Hierarchical Organization**:
   - L1 sections: Major subsystems (2000-4000 words each)
   - L2 sections: Specific components (600-1000 words each)
   - L3 sections: Detailed implementations (only when necessary)

2. **Files Per Section**:
   - `_OVERVIEW.md`: Section summary with roadmap (300-500 words)
   - `_FULL.md`: Complete section content
   - Component files: Specific implementations

3. **Unique Keys**: Every section has hierarchical key
   - Format: `REPORT_ID:L1_SECTION:L2_COMPONENT`
   - Example: `ACME_API:AUTHENTICATION:OAUTH`

## Your Process

1. **Analyze Scope**:
   - Determine if topic is simple, moderate, or complex
   - Identify natural conceptual divisions
   - Plan abstraction levels (1-3 levels max)

2. **Research**:
   - Read source code (use Read, Glob, Grep tools)
   - Trace execution flows with file:line references
   - Identify key patterns and architectural decisions
   - Web search for official documentation

3. **Structure Report**:
   - Create hierarchical section structure
   - Generate unique keys for each section
   - Write _OVERVIEW for each major section
   - Write detailed content for leaf sections

4. **Document Code References**:
   - Include file paths with line numbers
   - Example: `browser_agent.py:145-203`
   - Link related sections with cross-references

5. **Generate Metadata**:
   - Create index.json and metadata.json
   - Track section hierarchy and relationships
   - Note confidence levels and word counts

6. **Store Report**:
   - Write to `.claude_research/` in project
   - Sync to `~/.claude/research_reports/projects/{project}/`

## Output Format

Return structured summary:
```
Report Created: {REPORT_ID}
Location: {path}
Sections: {count}
Abstraction Levels: {levels}
Total Words: {word_count}

Key Sections:
- {SECTION_KEY_1}: {brief description}
- {SECTION_KEY_2}: {brief description}
...
```

## Quality Standards

- Each leaf section: 600-1000 words (target)
- Overviews: 300-500 words
- Include code references with file:line format
- Cross-reference related sections
- Clear, technical, comprehensive
- Optimized for selective loading
```

#### Tools Required

- **Read**: Read source files
- **Glob**: Find files by pattern
- **Grep**: Search code for patterns
- **Write**: Create report files
- **WebFetch**: Research documentation
- **Bash**: Execute git commands, directory operations

#### Example Invocation

```
User: "Create a research report on the acme_api library"

Claude (main): [Launches report-creator subagent]

Prompt to subagent:
"Create a comprehensive research report on the acme_api library in this project.
Analyze the library architecture, authentication mechanisms, API endpoints, and request
handling. Use hierarchical structure with appropriate abstraction levels.
Store in .claude_research/ACME_API/"

Subagent: [Executes research and report generation]

Returns:
"Report Created: ACME_API
Location: /path/to/project/.claude_research/ACME_API/
Sections: 12
Abstraction Levels: 2
Total Words: 18500

Key Sections:
- ACME_API:CORE_ARCHITECTURE: Client-server-API interaction model
- ACME_API:AUTHENTICATION: Multi-method auth support (OAuth, API Keys, Token Refresh)
- ACME_API:API_ENDPOINTS: Endpoint validation and execution system
..."
```

---

### Subagent 2: report-validator

**Type**: Specialized validation agent (uses Opus)
**Invocation**: Automatic after report creation (with user depth prompt)
**Purpose**: Validate conceptual accuracy and architectural understanding

#### When to Use

✅ **Use when**:
- Report has just been created by report-creator
- User requests validation of existing report
- Significant code changes warrant re-validation

❌ **DO NOT use when**:
- Report hasn't passed linter validation yet
- User explicitly skips validation
- Trivial report updates (typo fixes, etc.)

#### Agent Description

```markdown
# report-validator Agent (Opus)

You are an expert technical reviewer specialized in validating research reports
for conceptual accuracy and architectural understanding.

## Your Role

Verify that research reports have **correct fundamental understanding** of the
systems they document. You are the quality gate that catches:
- Architectural misunderstandings
- Incorrect causality or data flow
- Conceptual contradictions between sections
- Misidentified patterns or anti-patterns
- Unsupported technical claims

## Validation Depth Levels

The user specifies validation depth. You dynamically decide HOW to validate
based on:
1. **Depth level specified** (quick/standard/thorough)
2. **Report complexity** (simple/moderate/complex from metadata)
3. **Section criticality** (which sections are architecturally important?)

### Quick Validation (~5K tokens input)
- Read report _OVERVIEW.md
- Read all L1 section _OVERVIEW files
- Spot-check 1 critical section (re-read source)
- Focus: High-level coherence, obvious contradictions

### Standard Validation (~15K tokens input, default)
- Read report _OVERVIEW.md
- Read all section _OVERVIEW files (L1 and L2)
- Deep-dive 2-3 critical sections (re-read source code)
- Cross-section consistency check
- Focus: Architectural accuracy, key patterns correct

### Thorough Validation (~30K+ tokens input)
- Read entire report (all _FULL.md files)
- Deep-dive 4-5 sections with source verification
- Comprehensive cross-section analysis
- Edge case and error handling verification
- Focus: Complete technical accuracy

## Dynamic Section Selection

You decide which sections need deep validation based on:

**Criticality Indicators**:
- Sections with "CORE" or "ARCHITECTURE" in name (high priority)
- Sections describing system integration or data flow
- Sections with complex interactions (multiple cross-references)
- Sections making bold technical claims

**Complexity Indicators**:
- High word count (>2000 words suggests complexity)
- Deep nesting (L3 sections suggest intricate topic)
- Multiple subsections (indicates branching logic)

**Example Decision**:
```
Report: ACME_API (12 sections, 2 levels)
Depth: Standard
Decision:
  - MUST validate: CORE_ARCHITECTURE (critical, complex)
  - MUST validate: AUTHENTICATION:OAUTH (integration point)
  - SHOULD validate: API_ENDPOINTS (data flow)
  - SKIP: Individual endpoint implementations (leaf nodes)
```

## Validation Process

1. **Read Report Metadata**:
   - Understand report scope and structure
   - Identify abstraction levels and section count
   - Note confidence levels from report-creator

2. **Assess Complexity**:
   - Simple report (<8 sections, 1-2 levels): Less deep-dive needed
   - Complex report (>15 sections, 3 levels): More validation needed

3. **Select Critical Sections**:
   - Apply criticality indicators
   - Choose N sections based on depth level
   - Prioritize architectural and integration sections

4. **Validate Each Critical Section**:
   - Re-read the actual source code referenced
   - Verify technical claims are supported by code
   - Check for fundamental misunderstandings
   - Look for unsupported assumptions

5. **Cross-Section Coherence**:
   - Do sections contradict each other?
   - Are relationships described consistently?
   - Is terminology used consistently?

6. **Architectural Sense Check**:
   - Does the overall design make sense?
   - Are the stated patterns actually present?
   - Would this architecture work as described?

## What You're NOT Checking

❌ Formatting (linter handles this)
❌ Word counts or file structure
❌ Minor stylistic issues
❌ Trivial inconsistencies

Focus ONLY on **conceptual correctness**.

## Output Format

```markdown
# Validation Report: {REPORT_ID}

**Validation Depth**: {Quick/Standard/Thorough}
**Sections Deep-Dived**: {count} of {total}
**Overall Confidence**: {0-100%}

## Critical Issues

### CRITICAL: {Issue Title}
**Location**: {SECTION:KEY}
**Issue**: {Clear description of fundamental misunderstanding}
**Evidence**:
- {Specific code reference showing the problem}
- {What the report claims vs what code shows}
**Impact**: {How this affects report usability}
**Recommendation**: {How to fix}

## Medium Issues

### MEDIUM: {Issue Title}
**Location**: {SECTION:KEY}
**Issue**: {Description of misleading or unclear content}
**Recommendation**: {Suggested improvement}

## Cross-Section Analysis

✅ {What's consistent and correct}
❌ {What contradicts between sections}
⚠️ {What's unclear or ambiguous}

## Sections Validated

**Deep Validation** (re-read source):
- {SECTION:KEY} - {Why validated} - {Result}

**Overview Validation** (coherence only):
- {SECTION:KEY} - {Result}

**Not Validated** (out of scope for depth level):
- {SECTION:KEY} - {Reason skipped}

## Recommendations

1. **MUST FIX**: {Critical issues that must be addressed}
2. **SHOULD FIX**: {Important improvements}
3. **CONSIDER**: {Nice-to-have enhancements}

## Validation Rationale

{Explain why you chose to deep-dive these specific sections}
{Explain what depth level meant for this particular report}
```

## Quality Standards

- **CRITICAL** = Fundamental misunderstanding that would mislead users
- **MEDIUM** = Technically correct but could be clearer or more accurate
- **MINOR** = Out of scope for validation (ignore)

## Success Criteria

After your validation:
- User knows confidence level of report (0-100%)
- User knows which sections are verified accurate
- User knows what issues exist and their severity
- report-creator can fix critical issues if needed
```

#### Tools Required

- **Read**: Read report files and source code
- **Glob**: Find source files for verification
- **Grep**: Search code for patterns during validation

#### Example Invocation

```
report-creator: "Report created: ACME_API"
  ↓
Main Claude: Prompts user for validation depth
  ↓
User: "Standard validation"
  ↓
Main Claude: [Launches report-validator subagent]

Prompt to subagent:
"Validate the ACME_API research report at /path/.claude_research/ACME_API/
Validation depth: Standard
Focus on conceptual accuracy and architectural understanding."

Subagent workflow:
1. Reads metadata.json (12 sections, moderate complexity)
2. Reads report _OVERVIEW + all section overviews (~4K tokens)
3. Identifies critical sections: CORE_ARCHITECTURE, AUTHENTICATION:OAUTH
4. Re-reads source code for those sections
5. Validates technical claims
6. Generates validation report

Returns:
"Validation Report: ACME_API
Overall Confidence: 85%

CRITICAL: OAuth flow misunderstood
- Report claims authorization code flow
- Code actually implements device code flow
- Recommendation: Rewrite AUTHENTICATION:OAUTH section

MEDIUM: Request handler relationship unclear
- States 'parallel paths' but code shows delegation
- Recommendation: Clarify in CORE_ARCHITECTURE overview

Sections Deep-Dived: 2 of 12
- CORE_ARCHITECTURE:REQUEST_HANDLER ✓
- AUTHENTICATION:OAUTH ✗ (critical issue found)"
```

---

### Subagent 3: research-librarian

**Type**: Specialized query agent
**Invocation**: Automatic when report exists and information needed
**Purpose**: Efficient context retrieval and recommendation

#### When to Use

✅ **Use when**:
- User asks question about documented topic
- Main Claude needs information from research report
- Need to understand specific aspect of analyzed system
- Want context-efficient summary + section recommendations

❌ **DO NOT use when**:
- No report exists (check with ReportRegistryTool first)
- User wants to create new report (use report-creator)
- Simple query answerable without research

#### Agent Description

```markdown
# research-librarian Agent

You are a knowledgeable research librarian specialized in efficiently navigating
hierarchical technical reports and recommending optimal context to load.

## Your Role

Query existing research reports, understand their structure, and provide either:
1. Synthesized summaries for simple queries, OR
2. Section recommendations for complex queries

Your goal: **Minimize token usage while maximizing information value**.

## Available Reports Structure

Reports are organized hierarchically:
```
{REPORT_ID}/
├── _OVERVIEW.md                     # Report entry point
└── sections/
    ├── {L1_SECTION}/
    │   ├── _OVERVIEW.md             # Section roadmap
    │   ├── _FULL.md                 # Complete section
    │   └── {L2_COMPONENT}.md        # Specific components
    └── ...
```

## Your Process

1. **Read Report Overview** (always start here):
   - Load `{REPORT_ID}/_OVERVIEW.md` (~500 tokens)
   - Understand report structure and available sections
   - Identify relevant L1 sections for query

2. **Navigate Hierarchy** (contextual decision):
   - For broad queries: Read L1 _OVERVIEW files
   - For specific queries: Navigate to L2 components
   - For deep dives: Read _FULL content

3. **Make Decision**:

   **For Simple Queries** (definition, basic concept):
   - Read relevant section(s)
   - Synthesize answer
   - Return: Summary + "No additional context needed"

   **For Complex Queries** (implementation details, multi-faceted):
   - Read _OVERVIEW to understand scope
   - Skim relevant sections
   - Return: Brief summary + "Load these sections: [keys]"

4. **Optimize Token Usage**:
   - Don't read everything - be selective
   - Overviews are cheap (~300-500 words)
   - Full sections are expensive (~1000-4000 words)
   - Balance understanding vs. efficiency

## Decision Matrix

| Query Type | Your Action | Token Cost |
|------------|-------------|------------|
| "What is X?" | Read overview + synthesize | Low (~800) |
| "How does X work?" | Read L1 section + summarize | Medium (~1500) |
| "How does X integrate with Y?" | Read overviews + recommend sections | Low (~1000) |
| "Explain X implementation in detail" | Skim + recommend _FULL sections | Medium (~1200) |

## Output Format

### For Simple Queries
```
**Answer**: {synthesized summary based on report content}

**Source**: {SECTION_KEY}

**Additional Context**: None needed
```

### For Complex Queries
```
**Summary**: {brief synthesis from overviews}

**Recommended Sections**:
1. {SECTION_KEY_1} - {why relevant}
2. {SECTION_KEY_2} - {why relevant}

**Optional Deep Dive**:
- {SECTION_KEY_3:_FULL} - {for comprehensive details}

**Reasoning**: {why these sections answer the query}
```

## Example Behavior

Query: "How does acme_api handle OAuth authentication?"

Your workflow:
1. Read ACME_API/_OVERVIEW.md (500 tokens)
   → See section: AUTHENTICATION
2. Read ACME_API:AUTHENTICATION/_OVERVIEW.md (400 tokens)
   → See subsections: OAUTH, API_KEYS, TOKEN_REFRESH
3. Read ACME_API:AUTHENTICATION/OAUTH.md (800 tokens)
   → Contains OAuth-specific implementation

Return:
```
**Summary**: acme_api supports multiple authentication methods through a provider
pattern. OAuth integration uses standard OAuth 2.0 flow with PKCE support.
Token management is handled through a refresh token rotation mechanism.

**Recommended Sections**:
1. ACME_API:AUTHENTICATION:OAUTH - Complete OAuth implementation details

**Source Files Referenced**:
- acme_api/src/auth/oauth_handler.py:145-230

**Additional Context**: If you need token refresh details, also load
ACME_API:AUTHENTICATION:TOKEN_REFRESH
```

## Quality Standards

- Read minimum necessary to answer query
- Provide actionable recommendations
- Include reasoning for section choices
- Synthesize when appropriate
- Always cite section keys
- Optimize for parent agent's next steps
```

#### Tools Required

- **Read**: Read report files
- **Glob**: Find sections by pattern
- **Grep**: Search within reports (optional)

#### Example Invocation

```
User: "How does the API client handle OAuth authentication?"

Claude (main):
1. [Uses ReportRegistryTool("acme_api")]
2. Tool returns: {exists: true, path: ".claude_research/ACME_API/"}
3. [Launches research-librarian subagent]

Prompt to subagent:
"Query the ACME_API research report to answer: 'How does the API client
handle OAuth authentication?' Provide summary and/or section recommendations."

Subagent workflow:
1. Read ACME_API/_OVERVIEW.md
2. Identify: AUTHENTICATION section relevant
3. Read AUTHENTICATION/_OVERVIEW.md
4. See: OAUTH subsection
5. Read AUTHENTICATION:OAUTH.md

Returns:
"**Summary**: API client uses OAuth 2.0 with PKCE flow for secure authentication.
Tokens are managed with automatic refresh and secure storage via keyring.

**Recommended Sections**:
1. ACME_API:AUTHENTICATION:OAUTH - Complete OAuth implementation
2. ACME_API:CORE_ARCHITECTURE:STATE_MANAGEMENT - Token persistence

**Source**: api_client.py:89-145

**Additional Context**: For credential security details, see GLOBAL:PYTHON_PATTERNS:SECRETS_MANAGEMENT"
```

---

## Tools Specification

### ReportRegistryTool

**Type**: Synchronous lookup tool (not a subagent)
**Available to**: Main Claude
**Purpose**: Check if research report exists

---

### ReportLinterTool

**Type**: Automated validation script (not an LLM)
**Available to**: Main Claude, report-creator
**Purpose**: Validate report structure and formatting

#### Tool Interface

```python
class ReportLinterTool:
    """Validates report structure and cross-references"""

    name: str = "report_linter"

    def validate(self, report_path: str) -> dict:
        """
        Validates report structure for formatting and schema compliance.

        Args:
            report_path: Absolute path to report directory

        Returns:
            {
                "valid": bool,
                "errors": [
                    {
                        "type": "missing_file" | "invalid_json" | "broken_ref" | "duplicate_key",
                        "severity": "error" | "warning",
                        "message": str,
                        "location": str,  # File or section where error occurred
                        "auto_fixable": bool
                    }
                ],
                "warnings": [...],  # Same structure as errors
                "auto_fixes_applied": [str],  # List of fixes that were automatically applied
                "stats": {
                    "total_sections": int,
                    "total_words": int,
                    "cross_references": int,
                    "broken_references": int
                }
            }
        """
```

#### Validation Checks

**Errors (blocking)**:
- ✅ `metadata.json` exists and is valid JSON
- ✅ All sections in metadata have corresponding files
- ✅ Required structure files exist (`_OVERVIEW.md`, `sections/`)
- ✅ No duplicate section keys
- ✅ JSON schema compliance (required fields present)

**Warnings (non-blocking)**:
- ⚠️ Broken cross-references `[SECTION:KEY]` (section doesn't exist)
- ⚠️ Word counts outside recommended ranges
- ⚠️ Missing optional fields in metadata
- ⚠️ Inconsistent naming patterns

**Auto-Fixes**:
- Fix JSON formatting (pretty-print)
- Standardize file permissions
- Update word counts in metadata
- Generate missing index entries

#### Usage Example

```python
linter = ReportLinterTool()
result = linter.validate("/path/to/project/.claude_research/ACME_API/")

if not result["valid"]:
    print(f"Found {len(result['errors'])} errors")
    for error in result["errors"]:
        print(f"  [{error['severity']}] {error['message']} at {error['location']}")

if result["auto_fixes_applied"]:
    print(f"Auto-fixed: {', '.join(result['auto_fixes_applied'])}")
```

---

### ReportRegistryTool (continued)

#### Tool Interface

```python
class ReportRegistryTool:
    """Check if research report exists for a topic"""

    name: str = "report_registry"
    description: str = """
    Check if a research report exists for a given topic.

    Args:
        topic: Subject to search for (e.g., "acme_api", "taskflow", "auth_system")
        scope: "project", "global", or "auto" (default: "auto" - search both)

    Returns:
        {
            "exists": bool,
            "report_id": str,              # e.g., "ACME_API"
            "scope": str,                  # "project" or "global"
            "path": str,                   # Full path to report directory
            "overview_path": str,          # Path to _OVERVIEW.md
            "metadata_path": str,          # Path to metadata.json
            "section_count": int,
            "created": str,                # ISO timestamp
            "updated": str,                # ISO timestamp
            "confidence": str              # "high", "medium", "low"
        }

        # If not found:
        {
            "exists": false,
            "searched_scopes": ["project", "global"],
            "suggestion": str              # Closest match or creation suggestion
        }
    """

    def _run(self, topic: str, scope: str = "auto") -> dict:
        """
        Implementation:
        1. Normalize topic to potential report ID
        2. Search project scope: {project}/.claude_research/index.json
        3. Search global scope: ~/.claude/research_reports/_global/index.json
        4. Check backup: ~/.claude/research_reports/projects/{project}/index.json
        5. Return result
        """
```

#### Usage Example

```python
# In main Claude flow
result = ReportRegistryTool._run(topic="acme_api", scope="auto")

if result["exists"]:
    # Launch research-librarian with report_id
    launch_subagent("research-librarian", {
        "query": user_query,
        "report_path": result["path"]
    })
else:
    # Inform user - ask if they want to create report
    respond(f"No research report found for '{topic}'. Would you like me to create one?")
```

---

## Workflows

### Workflow 1: Creating and Validating a Research Report

```
┌─────────────────────────────────────────────────────────────┐
│ User: "Create a research report on acme_api library"       │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude:                                                │
│ 1. Recognize explicit report creation request               │
│ 2. Determine scope (project-level based on cwd)             │
│ 3. Launch report-creator subagent                           │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ report-creator Subagent (Sonnet):                           │
│                                                             │
│ 1. Analyze acme_api library:                               │
│    - Glob for main files: **/*api*.py                      │
│    - Read key files: api_client.py, auth_handler.py, etc.  │
│    - Grep for patterns: class definitions, key methods     │
│                                                             │
│ 2. Identify structure:                                     │
│    - Major subsystems: Core, Auth, Endpoints, Validation   │
│    - Decision: 2 abstraction levels (moderate complexity)  │
│                                                             │
│ 3. Create hierarchy:                                       │
│    ACME_API/                                               │
│    ├── _OVERVIEW.md                                        │
│    └── sections/                                           │
│        ├── CORE_ARCHITECTURE/                              │
│        │   ├── _FULL.md                                    │
│        │   ├── _OVERVIEW.md                                │
│        │   ├── CLIENT_MODEL.md                             │
│        │   └── REQUEST_HANDLER.md                          │
│        └── AUTHENTICATION/                                 │
│            ├── _FULL.md                                    │
│            ├── _OVERVIEW.md                                │
│            ├── OAUTH.md                                    │
│            └── API_KEYS.md                                 │
│                                                             │
│ 4. Write content & generate metadata                       │
│ 5. Store report (primary + backup)                         │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude: Run ReportLinterTool                           │
│                                                             │
│ Linter checks:                                              │
│ ✓ All files exist                                           │
│ ✓ JSON is valid                                             │
│ ✓ Cross-references resolve                                  │
│ ✓ Structure matches schema                                  │
│                                                             │
│ Result: 2 warnings (non-blocking)                           │
│ - Word count slightly low on one section                    │
│ - Minor naming inconsistency                                │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude → User:                                         │
│ "Report created: ACME_API (12 sections, 18500 words)        │
│                                                             │
│  How thorough should the validation be?                     │
│  - Quick (~5 sec, overview coherence only)                  │
│  - Standard (~15 sec, validates 2-3 key sections)           │
│  - Thorough (~30 sec, validates 4-5 sections)               │
│  - Skip (not recommended)                                   │
│                                                             │
│  [Default: Standard]"                                       │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ User: "Standard" (or just presses enter for default)       │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude: Launch report-validator subagent               │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ report-validator Subagent (Opus):                           │
│                                                             │
│ 1. Read metadata (12 sections, moderate complexity)         │
│ 2. Read all _OVERVIEW files (~4K tokens)                    │
│ 3. Identify critical sections:                              │
│    - CORE_ARCHITECTURE (architectural, complex)             │
│    - AUTHENTICATION:OAUTH (integration point)               │
│ 4. Deep-dive selected sections:                             │
│    - Re-read source code for CORE_ARCHITECTURE              │
│    - Re-read source code for AUTHENTICATION:OAUTH           │
│    - Validate technical claims                              │
│ 5. Cross-section coherence check                            │
│ 6. Generate validation report                               │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Validator returns:                                          │
│ "Validation Report: ACME_API                                │
│  Overall Confidence: 85%                                    │
│                                                             │
│  ✓ CORE_ARCHITECTURE validated - accurate                   │
│  ✗ AUTHENTICATION:OAUTH - CRITICAL issue found              │
│    (Claims authorization code flow, actually device flow)   │
│                                                             │
│  Sections validated: 2 of 12 (Standard depth)               │
│  Issues: 1 CRITICAL, 1 MEDIUM"                              │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude: Critical issues found                          │
│ 1. Pass validation report to report-creator                 │
│ 2. request fixes for CRITICAL issues                        │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ report-creator: Fix AUTHENTICATION:OAUTH section            │
│ - Re-researches OAuth implementation                        │
│ - Rewrites section with correct device flow                 │
│ - Updates version 1.0 → 1.1                                 │
│ - Updates metadata timestamps                               │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude → User:                                         │
│ "✓ Report created and validated: ACME_API                   │
│                                                             │
│  Overall Confidence: 85%                                    │
│  Status: 1 critical issue found and fixed                   │
│  Version: 1.1                                               │
│                                                             │
│  Note: 1 medium issue noted in validation report:          │
│  - Request handler relationship could be clearer            │
│                                                             │
│  You can now query this report for context."                │
└─────────────────────────────────────────────────────────────┘
```

---

### Workflow 2: Querying a Research Report

```
┌─────────────────────────────────────────────────────────────┐
│ User: "How does acme_api handle OAuth authentication?"     │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude:                                                │
│ 1. Use ReportRegistryTool(topic="acme_api")                 │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ ReportRegistryTool:                                         │
│ {                                                           │
│   "exists": true,                                           │
│   "report_id": "ACME_API",                                  │
│   "scope": "project",                                       │
│   "path": "/path/.claude_research/ACME_API/",               │
│   "overview_path": "/path/.../ACME_API/_OVERVIEW.md",       │
│   "section_count": 12                                       │
│ }                                                           │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude:                                                │
│ 2. Launch research-librarian subagent with:                 │
│    - Query: "How does acme_api handle OAuth authentication?"│
│    - Report path: "/path/.claude_research/ACME_API/"        │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ research-librarian Subagent:                                │
│                                                             │
│ 1. Read ACME_API/_OVERVIEW.md (500 tokens)                  │
│    → "Report covers: Core Architecture, Authentication..."  │
│    → Identify: AUTHENTICATION section relevant              │
│                                                             │
│ 2. Read AUTHENTICATION/_OVERVIEW.md (400 tokens)            │
│    → "Supports OAuth, API Keys, Token Refresh"              │
│    → See subsections: OAUTH.md, API_KEYS.md, etc.          │
│                                                             │
│ 3. Read AUTHENTICATION/OAUTH.md (800 tokens)                │
│    → Full OAuth implementation details                      │
│    → Code references: oauth_handler.py:145-230              │
│                                                             │
│ 4. Decision: Query is moderately complex                    │
│    → Have enough info to summarize                          │
│    → Recommend section for detailed implementation          │
│                                                             │
│ Total tokens used: ~1700 (vs ~18500 for full report)       │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Returns to Main Claude:                                     │
│                                                             │
│ "**Summary**: acme_api implements OAuth 2.0 with PKCE flow  │
│  for secure authentication. Tokens are automatically        │
│  refreshed and stored securely via system keyring.          │
│                                                             │
│  **Recommended Sections**:                                  │
│  1. ACME_API:AUTHENTICATION:OAUTH - Complete OAuth impl     │
│                                                             │
│  **Source Files**:                                          │
│  - oauth_handler.py:145-230 (OAuth flow)                    │
│  - token_manager.py:89-156 (Token refresh)                  │
│                                                             │
│  **Additional Context**: For token storage, see             │
│  ACME_API:AUTHENTICATION:TOKEN_REFRESH"                     │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude:                                                │
│ 3. Decide if need to load recommended section               │
│    - For this query: Summary sufficient                     │
│    - Skip loading full section (save tokens)                │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude → User:                                         │
│ "acme_api implements OAuth 2.0 authentication with PKCE     │
│  flow for enhanced security. The system automatically       │
│  refreshes tokens and stores them securely via keyring.     │
│                                                             │
│  Implementation details in oauth_handler.py:145-230 and     │
│  token_manager.py:89-156."                                  │
└─────────────────────────────────────────────────────────────┘
```

**Token Efficiency**:
- Without research system: Load entire codebase (~50,000 tokens)
- With research system: Librarian query (~1,700 tokens) + answer
- Savings: ~97% reduction in context usage

---

### Workflow 3: Report Not Found

```
┌─────────────────────────────────────────────────────────────┐
│ User: "How does the authentication system work?"            │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude:                                                │
│ 1. Use ReportRegistryTool(topic="authentication")           │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ ReportRegistryTool:                                         │
│ {                                                           │
│   "exists": false,                                          │
│   "searched_scopes": ["project", "global"],                 │
│   "suggestion": "No research report found. Create one?"     │
│ }                                                           │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude:                                                │
│ 2. Options:                                                 │
│    A) Answer from codebase directly (traditional approach)  │
│    B) Ask user if they want report created                  │
│                                                             │
│ Decision: For one-off query → Answer directly               │
│           For repeated queries → Suggest report creation    │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Main Claude → User:                                         │
│ "I don't have a research report on authentication yet.      │
│  Let me search the codebase...                              │
│                                                             │
│  [Provides answer from code search]                         │
│                                                             │
│  Note: If you'd like detailed documentation on              │
│  authentication for future queries, I can create a          │
│  research report. Just say 'Create research report on       │
│  authentication'."                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Examples

### Example 1: Simple Report Structure

**Topic**: Configuration file format (simple, focused)

```
CONFIG_FORMAT/
├── metadata.json
├── _OVERVIEW.md                # 400 words - Complete overview
└── sections/
    ├── YAML_SCHEMA/
    │   └── _FULL.md            # 1200 words - Schema details
    └── VALIDATION/
        └── _FULL.md            # 900 words - Validation rules
```

**Key sections**:
- `CONFIG_FORMAT:YAML_SCHEMA`
- `CONFIG_FORMAT:VALIDATION`

---

### Example 2: Moderate Report Structure

**Topic**: API client library (moderate complexity)

```
ACME_API/
├── metadata.json
├── _OVERVIEW.md                        # 500 words - System overview
└── sections/
    ├── CORE_ARCHITECTURE/
    │   ├── _FULL.md                    # 3000 words - Complete architecture
    │   ├── _OVERVIEW.md                # 400 words - Architecture map
    │   ├── CLIENT_MODEL.md             # 800 words - Client implementation
    │   ├── REQUEST_HANDLER.md          # 900 words - Request flow
    │   └── STATE_MANAGEMENT.md         # 700 words - State handling
    │
    ├── AUTHENTICATION/
    │   ├── _FULL.md                    # 2500 words - All auth methods
    │   ├── _OVERVIEW.md                # 400 words - Auth overview
    │   ├── OAUTH.md                    # 800 words - OAuth-specific
    │   ├── API_KEYS.md                 # 800 words - API key auth
    │   └── TOKEN_REFRESH.md            # 500 words - Token management
    │
    └── API_ENDPOINTS/
        ├── _FULL.md                    # 2200 words
        ├── _OVERVIEW.md                # 350 words
        ├── ENDPOINT_VALIDATION.md      # 900 words
        └── ENDPOINT_EXECUTION.md       # 950 words
```

**Key sections** (12 total):
- L1: `ACME_API:CORE_ARCHITECTURE`
- L1: `ACME_API:AUTHENTICATION`
- L1: `ACME_API:API_ENDPOINTS`
- L2: `ACME_API:CORE_ARCHITECTURE:CLIENT_MODEL`
- L2: `ACME_API:AUTHENTICATION:OAUTH`
- ... etc

---

### Example 3: Complex Report Structure

**Topic**: Complete orchestration framework (high complexity)

```
TASKFLOW_FRAMEWORK/
├── metadata.json
├── _OVERVIEW.md                        # 600 words - Framework overview
└── sections/
    ├── WORKFLOW_SYSTEM/
    │   ├── _FULL.md                    # 4000 words
    │   ├── _OVERVIEW.md                # 500 words
    │   ├── WORKFLOW_LIFECYCLE.md       # 1000 words
    │   ├── STEP_INTEGRATION.md         # 900 words
    │   └── STATE_MANAGEMENT.md         # 800 words
    │
    ├── TASK_ORCHESTRATION/
    │   ├── _FULL.md                    # 3500 words
    │   ├── _OVERVIEW.md                # 450 words
    │   │
    │   ├── SEQUENTIAL_TASKS/           # L3 subsection
    │   │   ├── _FULL.md                # 1500 words
    │   │   ├── TASK_DELEGATION.md      # 700 words
    │   │   └── RESULT_AGGREGATION.md   # 600 words
    │   │
    │   └── PARALLEL_TASKS/             # L3 subsection
    │       ├── _FULL.md                # 1200 words
    │       └── SYNCHRONIZATION.md      # 800 words
    │
    └── EXECUTION_BACKEND/
        ├── _FULL.md                    # 2800 words
        ├── _OVERVIEW.md                # 400 words
        ├── EXECUTOR_ADAPTERS.md        # 1100 words
        └── SCHEDULING.md               # 900 words
```

**Key sections** (includes L3):
- L1: `TASKFLOW_FRAMEWORK:TASK_ORCHESTRATION`
- L2: `TASKFLOW_FRAMEWORK:TASK_ORCHESTRATION:SEQUENTIAL_TASKS`
- L3: `TASKFLOW_FRAMEWORK:TASK_ORCHESTRATION:SEQUENTIAL_TASKS:TASK_DELEGATION`

**Note**: L3 depth used because TASK_ORCHESTRATION is very large (3500 words) with clear sub-divisions.

---

### Example 4: Cross-References

**In Project Report** (`ACME_API/_OVERVIEW.md`):

```markdown
# Acme API Client Technical Analysis

## Integration with TaskFlow

The API client integrates with TaskFlow's orchestration system.
See [`TASKFLOW_INTEGRATION:API_ORCHESTRATION`] for details on how TaskFlow jobs
are converted to API call sequences.

## Authentication Patterns

Uses standard Python async patterns for auth token management. For general async
best practices, see [`GLOBAL:PYTHON_PATTERNS:ASYNC_PATTERNS`].
```

**Cross-reference validation**:
- ✅ `TASKFLOW_INTEGRATION:API_ORCHESTRATION` - Same project scope
- ✅ `GLOBAL:PYTHON_PATTERNS:ASYNC_PATTERNS` - Global scope allowed
- ❌ `OTHER_PROJECT:SOMETHING` - Would be rejected (cross-project not allowed)

---

### Example 5: Section Content Format

**File**: `ACME_API/sections/AUTHENTICATION/OAUTH.md`

```markdown
# ACME_API:AUTHENTICATION:OAUTH

**Version**: 1.0
**Confidence**: High
**Last Updated**: 2025-10-02
**Parent Section**: [`ACME_API:AUTHENTICATION`]

## Overview

OAuth integration for acme_api implements OAuth 2.0 authorization code flow with PKCE
for enhanced security. The implementation handles token acquisition, refresh, and
secure storage via system keyring.

## Implementation Architecture

### Auth Manager Integration

The OAuth provider is registered in the auth manager at initialization:

**File**: `acme_api/src/auth/auth_manager.py:89-156`

```python
def get_auth_handler(self, provider: str, config: dict):
    if provider == "oauth":
        return OAuthHandler(
            client_id=config.get("client_id"),
            auth_url=config.get("auth_url", "https://api.acme.com/oauth"),
            use_pkce=config.get("use_pkce", True)
        )
```

### PKCE Flow Implementation

OAuth flow uses PKCE (Proof Key for Code Exchange) for security:

1. **Code Verifier**: Random string generated for each auth request
2. **Code Challenge**: SHA256 hash of verifier sent to auth server

**File**: `acme_api/src/auth/oauth_handler.py:708-736`

The handler implements:
- Code verifier generation with cryptographically secure random
- Code challenge creation using SHA256
- Token exchange with verifier validation

### Token Management

**File**: `acme_api/src/auth/oauth_handler.py:729-736`

```python
token_data = {
    "access_token": response["access_token"],
    "refresh_token": response["refresh_token"],
    "expires_at": time.time() + response["expires_in"],
    "token_type": response.get("token_type", "Bearer")
}
```

**Token Storage**: Tokens are stored securely in system keyring.
See [`ACME_API:AUTHENTICATION:TOKEN_REFRESH`] for refresh mechanism details.

## Configuration

### Required Settings

**File**: `config/auth_config.yml:1-8`

```yaml
auth_config:
  provider: "oauth"
  client_id: "your_client_id"
  use_pkce: true

api_config:
  auth_provider: "oauth"
  scopes: ["read", "write"]
```

### Connection Parameters

- **auth_url**: OAuth authorization endpoint
- **client_id**: OAuth client identifier
- **use_pkce**: Enable PKCE flow (recommended: true)

## Error Handling

Error handling follows standard auth adapter pattern. See [`ACME_API:AUTHENTICATION:ERROR_HANDLING`] for details.

## Related Sections

- [`ACME_API:AUTHENTICATION:API_KEYS`] - API key auth comparison
- [`ACME_API:CORE_ARCHITECTURE:REQUEST_HANDLER`] - How auth integrates with requests
- [`GLOBAL:PYTHON_PATTERNS:ADAPTER_PATTERN`] - Adapter pattern implementation

## References

1. OAuth 2.0 Specification: RFC 6749
2. PKCE Extension: RFC 7636
3. Implementation Guide: `/docs/auth/oauth-implementation.md`
```

---

## Cost Estimates

### Relative Cost Analysis

The system uses different models for different tasks to optimize cost/quality tradeoffs:

**Component Costs** (relative scale, not absolute prices):

| Operation | Model | Relative Cost | Notes |
|-----------|-------|---------------|-------|
| Report Creation | Sonnet 3.5 | 1x (baseline) | Heavy research, many file reads, large output |
| Format Linting | Script | FREE | Automated validation, no LLM |
| Quick Validation | Opus | ~0.4x | Read overviews only, 1 deep-dive |
| Standard Validation | Opus | ~0.7x | Read overviews, 2-3 deep-dives (default) |
| Thorough Validation | Opus | ~1.2x | Read all sections, 4-5 deep-dives |
| Report Querying | Sonnet 3.5 | ~0.1x | Lightweight librarian reads |

**Example Cost Scenario** (moderate report, 12 sections):
- Report creation: **1.0x** (baseline)
- Linting: **FREE**
- Standard validation: **+0.7x**
- **Total: ~1.7x the base cost**

### Cost Factors

Report costs vary based on:
1. **Codebase size**: More files = more reading
2. **Report complexity**: More sections = more writing
3. **Validation depth**: Thorough costs ~2x quick
4. **Validation findings**: Fixes require re-writing sections

### Cost Optimization Tips

1. **Skip validation only for trivial reports** (not recommended for production use)
2. **Use Quick validation for simple reports** (<8 sections, straightforward)
3. **Use Standard validation for most cases** (good balance)
4. **Use Thorough validation for critical/complex reports** (worth the cost)
5. **Linter is always free** - catches 80% of issues at no cost

### Token Efficiency

**Traditional approach** (no research system):
- Every query: Load entire codebase (~50K tokens)
- Repeated queries: Reload same context each time

**Research system approach**:
- One-time: Create validated report (~1.7x base cost)
- Each query: Librarian navigates report (~5-10% of base cost)
- **Break-even: ~2-3 queries** on same codebase

**Long-term value**: Reports persist across sessions, team can reuse, 97% token reduction per query.

---

## Best Practices

### For Report Creators

1. **Start with Overview**: Always create `_OVERVIEW.md` first to plan structure
2. **Progressive Detail**: Write overviews → full sections → components
3. **File:Line References**: Always include code locations (e.g., `file.py:145-203`)
4. **Cross-Reference**: Link related sections with `[SECTION_KEY]` syntax
5. **Confidence Levels**: Mark sections as high/medium/low confidence
6. **Word Count Targets**:
   - Overview: 300-500 words
   - L2 component: 600-1000 words
   - L1 _FULL: 2000-4000 words

### For Report Consumers (research-librarian)

1. **Always Start with Overview**: Cheapest way to understand structure
2. **Navigate Hierarchy**: Don't jump to _FULL immediately
3. **Balance Tokens**: Read enough to guide, not everything
4. **Recommend, Don't Load**: Let parent agent decide what to load
5. **Provide Context**: Explain why sections are relevant
6. **Cite Sources**: Always reference section keys and file paths

### For Main Claude

1. **Check Registry First**: Use `ReportRegistryTool` before querying
2. **Explicit Creation**: Only create reports on explicit user request
3. **Trust Librarian**: Use librarian's recommendations
4. **Selective Loading**: Don't load all recommended sections unless needed
5. **Update Reports**: Suggest updates if code changed significantly

---

## Maintenance

### Updating Reports

When code changes significantly:

1. User requests: "Update acme_api report"
2. Launch report-creator with update flag
3. Creator compares existing metadata timestamps with code file modifications
4. Updates changed sections, preserves keys
5. Increments version number
6. Updates metadata timestamps

### Report Versioning

- **Version format**: `major.minor`
- **Major increment**: Structural changes (new sections, reorganization)
- **Minor increment**: Content updates (existing sections modified)
- **Metadata tracks**: Per-section and per-report timestamps

### Cleanup

Old reports can accumulate. Consider cleanup when:
- Project deleted but backup remains
- Reports for removed dependencies
- Very outdated reports (>6 months with no updates)

Manual cleanup: Remove report directory + update index.json

---

## Technical Implementation Notes

### Storage Format

- **Files**: Markdown (`.md`) for human readability
- **Metadata**: JSON for machine processing
- **Encoding**: UTF-8
- **Line Endings**: LF (Unix-style)

### Git Integration

**Project Reports** (`.claude_research/`):
- Recommend adding to `.gitignore` (user choice)
- Reports can be large, project-specific to machine
- Alternative: Commit if team wants shared knowledge base

**Backup Reports** (`~/.claude/research_reports/`):
- User-local, never committed
- Personal knowledge cache

### Performance Considerations

- **Index lookup**: O(n) scan of reports array (acceptable for <100 reports)
- **Section lookup**: O(n) scan of sections array (acceptable for <50 sections/report)
- **File reads**: Cached by OS, prioritize small files (overviews)
- **Token costs**: Overviews ~500 tokens, sections ~1000 tokens, full reports ~20000 tokens

### Future Enhancements

Potential improvements:
1. **Vector search**: Semantic search across report content
2. **Auto-update triggers**: Detect code changes, suggest report updates
3. **Report templates**: Domain-specific templates (API docs, architecture, etc.)
4. **Diff visualization**: Show what changed between report versions
5. **Export formats**: Generate PDF, HTML from markdown reports

---

## Troubleshooting

### Report Not Found Despite Creation

**Symptoms**: ReportRegistryTool returns `exists: false` after creation

**Solutions**:
1. Check primary location: `{project}/.claude_research/index.json`
2. Verify index.json contains report entry
3. Check backup location: `~/.claude/research_reports/projects/{project}/`
4. Regenerate index if corrupted

### Librarian Returns "No Relevant Sections"

**Symptoms**: research-librarian can't find relevant content

**Solutions**:
1. Check if query matches report domain
2. Verify _OVERVIEW.md has clear section descriptions
3. Update metadata.json section summaries
4. Query might need different report

### Cross-Reference Errors

**Symptoms**: Links to `[SECTION_KEY]` not resolving

**Solutions**:
1. Verify section key exists in metadata.json
2. Check scope rules (project can't reference other projects)
3. Validate key format: `REPORT_ID:L1:L2`
4. Update cross-reference after report restructuring

### Token Usage Higher Than Expected

**Symptoms**: Librarian using too many tokens

**Solutions**:
1. Start with _OVERVIEW only
2. Read L1 _OVERVIEW before reading L2 sections
3. Avoid reading _FULL unless necessary
4. Recommend sections instead of synthesizing from _FULL

---

## Appendix

### Complete File Structure Example

See [Example 2: Moderate Report Structure](#example-2-moderate-report-structure) for full `ACME_API` report layout.

### Schema Files

Templates available in `~/.claude/research_reports/templates/`:
- `index_template.json`
- `metadata_template.json`
- `report_structure.md`
- `section_full.md`
- `section_overview.md`

### Tool Integration

For implementing `ReportRegistryTool` in your Claude Code setup, see [Tools Specification](#tools-specification).

---

## Glossary

- **Abstraction Level**: Hierarchical depth (L1=major, L2=component, L3=detail)
- **Section Key**: Unique hierarchical identifier (e.g., `REPORT:SECTION:COMPONENT`)
- **Scope**: Visibility boundary (project vs. global)
- **_OVERVIEW**: High-level section summary file
- **_FULL**: Complete section content file
- **Cross-Reference**: Link between related sections using `[KEY]` syntax
- **Report Registry**: Index of all available research reports
- **Librarian**: Subagent that queries reports efficiently
- **Creator**: Subagent that generates comprehensive reports

---

**Document Version**: 1.0
**Last Updated**: 2025-10-02
**Maintained By**: Research Report System

For questions or suggestions, update this documentation or create a feedback report.
