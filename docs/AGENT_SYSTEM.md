# Agent Research Library System

This document describes the agent architecture, workflows, and operational characteristics of the Agent Research Library.

## System Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Main Claude                              │
│  ┌──────────────────┐  ┌──────────────────┐                     │
│  │ MCP Tools        │  │ Registry/Linter  │                     │
│  │ (lint, extract)  │  │ (find reports)   │                     │
│  └──────────────────┘  └──────────────────┘                     │
└────┬──────────────────────┬──────────────────────┬──────────────┘
     │                      │                      │
     ▼                      ▼                      ▼
┌──────────────┐   ┌──────────────────┐   ┌─────────────────────┐
│ report-      │   │ report-validator │   │ research-librarian  │
│ creator      │   │ Subagent         │   │ Subagent            │
│ (Sonnet)     │   │ (Opus/Sonnet)    │   │ (Sonnet)            │
│              │   │                  │   │                     │
│ Creates      │   │ Validates        │   │ Queries reports,    │
│ comprehensive│   │ conceptual       │   │ recommends sections │
│ reports      │   │ accuracy         │   │ (efficient)         │
└──────┬───────┘   └────────┬─────────┘   └──────────┬──────────┘
       │                    │                         │
       └────────────────────┴─────────────────────────┘
                            ▼
                ┌────────────────────────────┐
                │   Report Storage           │
                │                            │
                │  ~/.claude/                │
                │  agent_research_library/   │
                └────────────────────────────┘
```

### Additional Component: research-report-finder

The `research-report-finder` (Haiku) is a lightweight search agent that finds existing reports using intelligent fuzzy matching:

```
Main Claude → research-report-finder (Haiku) → Searches indexes → Returns report path
```

**Purpose:** Fast report discovery before launching heavier agents.

### Data Flows

**Report Creation:**
```
User request → Main Claude → report-creator (Sonnet) → Research + Write →
Linter validation → User chooses depth → report-validator (Opus) →
Validation feedback → Fixes if needed → Final report stored
```

**Report Query:**
```
User question → Main Claude → research-report-finder (Haiku) → Report found →
research-librarian (Sonnet) → Reads relevant sections → Returns summary +
section recommendations → Main Claude answers user
```

## Agents

### 1. report-creator (Sonnet)

**Type:** Specialized research agent
**Model:** Claude Sonnet
**Invocation:** ONLY on explicit user request
**Purpose:** Deep-dive codebase analysis and hierarchical report generation

#### When to Use

✅ **Use when:**
- User explicitly says: "Create a research report on {topic}"
- User requests: "Generate documentation for {library/component}"
- User asks: "Build a technical analysis of {system}"

❌ **DO NOT use when:**
- Auto-generating documentation
- User just wants quick information
- Any automatic trigger without explicit user request

#### Capabilities

**Analyzes codebases systematically:**
- Traces execution flows with file:line references
- Identifies architectural patterns and key abstractions
- Documents integration points and data flows
- Creates hierarchical section structure

**Generates v2.0 compliant reports:**
- Flexible depth (1-3 levels based on natural complexity)
- Mixed structures (standalone files + directories)
- Optional `_CONTENT.md` for section-level concepts
- Section markers for partial content loading
- Complete metadata with v2.0 schema

**Self-validates structure:**
- Runs linter automatically before completion
- Fixes structural issues found
- Ensures metadata consistency

#### Report Structure Created

**Hierarchical organization:**
- L1 sections: Major subsystems or top-level topics
- L2 sections: Specific components when needed
- L3 sections: Detailed implementations (rarely needed)

**File types generated:**
- `_OVERVIEW.md`: Section navigation (200-400 words)
- `_CONTENT.md`: Core concepts for section (optional, 1500-2500 words)
- Standalone `.md` files: Complete topics (800-2000 words)

**Metadata tracking:**
- Section keys: `REPORT_ID:L1:L2:L3`
- Section types: "leaf" or "composite"
- Word counts per file
- Markers for partial loading
- Confidence levels per section

#### Process

1. **Analyze scope**: Determine if topic is simple, moderate, or complex
2. **Research**: Read source code, trace flows, identify patterns
3. **Structure**: Plan hierarchy based on natural content divisions
4. **Write**: Generate all files with proper cross-references
5. **Metadata**: Create complete metadata.json with v2.0 schema
6. **Validate**: Run linter, fix structural issues
7. **Store**: Write to `~/.claude/agent_research_library/`

#### Output Format

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

#### Tools Required

- **Read**: Source file reading
- **Glob**: File pattern matching
- **Grep**: Code searching
- **Write**: Report file creation
- **WebFetch**: Documentation research
- **Bash**: Git commands, directory operations

---

### 2. report-validator (Opus or Sonnet)

**Type:** Specialized validation agent
**Model:** Claude Opus (recommended) or Sonnet (users without Opus)
**Invocation:** After report creation, with user-specified depth
**Purpose:** Validate conceptual accuracy and architectural understanding

#### When to Use

✅ **Use when:**
- Report just created by report-creator
- User requests validation of existing report
- Significant code changes warrant re-validation

❌ **DO NOT use when:**
- Report hasn't passed linter validation
- User explicitly skips validation
- Trivial updates (typo fixes)

#### Validation Depth Levels

User specifies depth; validator decides what to check based on:
1. Depth level (quick/standard/thorough)
2. Report complexity (from metadata)
3. Section criticality (architectural importance)

**Quick Validation (~5K tokens):**
- Read report _OVERVIEW.md
- Read all L1 section _OVERVIEW files
- Spot-check 1 critical section
- Focus: High-level coherence

**Standard Validation (~15K tokens, default):**
- Read all _OVERVIEW files (L1 and L2)
- Deep-dive 2-3 critical sections
- Cross-section consistency check
- Focus: Architectural accuracy

**Thorough Validation (~30K tokens):**
- Read all sections completely
- Deep-dive 4-5 sections
- Comprehensive cross-section analysis
- Focus: Complete technical accuracy

#### Criticality Assessment

Validator prioritizes sections based on:

**High Priority:**
- Sections with "CORE" or "ARCHITECTURE" in name
- System integration and data flow descriptions
- Complex interactions (multiple cross-references)
- Bold technical claims

**Indicators:**
- Word count >2000 (complexity)
- Deep nesting (L3 sections)
- Multiple subsections

#### Validation Process

1. **Read metadata**: Understand report structure and complexity
2. **Assess complexity**: Determine validation needs
3. **Select critical sections**: Apply criticality indicators
4. **Validate sections**: Re-read source code, verify claims
5. **Check coherence**: Cross-section consistency
6. **Sense check**: Does architecture work as described?

#### What Validator Checks

✅ **Validates:**
- Fundamental architectural understanding
- Correct causality and data flow
- Technical claims supported by code
- Consistency between sections

❌ **Does NOT check:**
- Formatting (linter handles)
- Word counts or file structure
- Minor stylistic issues

#### Output Format

```markdown
# Validation Report: {REPORT_ID}

**Validation Depth**: {Quick/Standard/Thorough}
**Sections Deep-Dived**: {count} of {total}
**Overall Confidence**: {0-100%}

## Critical Issues

### CRITICAL: {Issue Title}
**Location**: {SECTION:KEY}
**Issue**: {Description of fundamental misunderstanding}
**Evidence**: {Code references showing problem}
**Impact**: {How this affects usability}
**Recommendation**: {How to fix}

## Medium Issues
...

## Sections Validated

**Deep Validation** (re-read source):
- {SECTION:KEY} - {Result}

**Overview Validation** (coherence):
- {SECTION:KEY} - {Result}

## Recommendations
1. **MUST FIX**: {Critical issues}
2. **SHOULD FIX**: {Important improvements}
3. **CONSIDER**: {Nice-to-have}
```

#### Quality Standards

- **CRITICAL**: Fundamental misunderstanding that misleads users
- **MEDIUM**: Technically correct but could be clearer
- **MINOR**: Out of scope (ignored)

#### Tools Required

- **Read**: Report files and source code
- **Glob**: Source file finding
- **Grep**: Pattern searching for validation

---

### 3. research-librarian (Sonnet)

**Type:** Specialized query agent
**Model:** Claude Sonnet
**Invocation:** Automatic when report exists and user asks questions
**Purpose:** Efficient context retrieval and section recommendation

#### When to Use

✅ **Use when:**
- User asks about documented topic
- Need specific information from research report
- Want context-efficient summary
- Need section recommendations for main Claude

❌ **DO NOT use when:**
- No report exists (check with finder first)
- User wants to create new report
- Simple query answerable without research

#### Process

**1. Read Report Overview (always start here):**
- Load `{REPORT_ID}/_OVERVIEW.md` (~500 tokens)
- Understand available sections
- Identify relevant L1 sections

**2. Navigate Hierarchy (contextual):**
- Broad queries: Read L1 _OVERVIEW files
- Specific queries: Navigate to L2/L3
- Deep dives: Read _CONTENT.md or standalone files

**3. Make Decision:**

For **simple queries** (definitions, basic concepts):
- Read relevant sections
- Synthesize answer
- Return: Summary + "No additional context needed"

For **complex queries** (implementations, multi-faceted):
- Read _OVERVIEW files
- Skim relevant sections
- Return: Summary + "Load these sections: [keys]"

**4. Optimize Token Usage:**
- Overviews are cheap (~300-500 words)
- Content files expensive (~1500-2500 words)
- Balance understanding vs. efficiency
- Don't read everything

#### Decision Matrix

| Query Type | Action | Token Cost |
|------------|--------|------------|
| "What is X?" | Read overview + synthesize | Low (~800) |
| "How does X work?" | Read section + summarize | Medium (~1500) |
| "How does X integrate with Y?" | Read overviews + recommend | Low (~1000) |
| "Explain X in detail" | Skim + recommend sections | Medium (~1200) |

#### Output Format

**Simple Query:**
```
**Answer**: {synthesized summary from report}

**Source**: {SECTION_KEY}

**Additional Context**: None needed
```

**Complex Query:**
```
**Summary**: {brief synthesis from overviews}

**Recommended Sections**:
1. {SECTION_KEY_1} - {why relevant}
2. {SECTION_KEY_2} - {why relevant}

**Optional Deep Dive**:
- {SECTION_KEY_3} - {for comprehensive details}

**Reasoning**: {why these sections answer query}
```

#### Quality Standards

- Read minimum necessary
- Provide actionable recommendations
- Include reasoning for choices
- Always cite section keys
- Optimize for parent agent

#### Tools Required

- **Read**: Report file reading
- **Glob**: Section finding
- **Grep**: Search within reports (optional)

---

### 4. research-report-finder (Haiku)

**Type:** Lightweight search agent
**Model:** Claude Haiku
**Invocation:** Before launching librarian or when checking report existence
**Purpose:** Fast report discovery with fuzzy matching

#### When to Use

✅ **Use when:**
- User asks about existing knowledge/documentation
- Need to check if report exists for topic
- Want fast search before expensive operations
- Synonym-aware matching needed

#### Capabilities

**Intelligent fuzzy search:**
- Case-insensitive matching
- Synonym expansion (e.g., "auth" → "authentication", "oauth")
- Partial matches (e.g., "auth" matches "Authentication System")
- Word-level matching
- Typo forgiveness

**Fast operation:**
- Target <500 tokens total
- Only reads index.json files (never report content)
- Returns immediately with result

**Search locations:**
- Project reports: `~/.claude/agent_research_library/projects/*/index.json`
- Global reports: `~/.claude/agent_research_library/_global/index.json`

#### Search Process

1. **Extract search terms**: Keywords + synonyms
2. **List all indexes**: Find all project + global indexes
3. **Match reports**: Exact → Partial → Word matching
4. **Rank results**: Project exact > project partial > global exact > global partial
5. **Return result**: Single match or ranked list

#### Common Synonym Expansion

- **auth**: authentication, authorization, oauth, jwt, tokens, login
- **api**: client, endpoints, rest, http, requests, service
- **task**: job, worker, queue, orchestration, workflow
- **db**: database, storage, persistence, orm, sql
- **test**: testing, spec, unit, integration, e2e

#### Output Format

**Single Match:**
```
FOUND: {topic}
Path: {absolute_path}
Scope: {project|global}
Match: {exact|partial|word}
```

**Multiple Matches:**
```
FOUND: {count} matches

MOST RELEVANT:
1. {topic} - {path} - {scope} - {match_type}
   Reason: {why most relevant}

OTHER MATCHES:
2. {topic} - {path} - {scope}
3. {topic} - {path} - {scope}
```

**Not Found:**
```
NOT FOUND
Searched: {N} projects, {M} global reports
```

#### Tools Required

- **Glob**: Find index files
- **Grep**: Search within indexes
- **Read**: Read index.json files

---

## Workflows

### Workflow 1: Creating and Validating Reports

```
User: "Create research report on {topic}"
  ↓
Main Claude: Recognize explicit request
  ↓
report-creator (Sonnet):
  - Analyze codebase systematically
  - Create v2.0 hierarchical structure
  - Write all files with metadata
  - Run linter, fix issues
  - Return report summary
  ↓
Main Claude: Prompt user for validation depth
  ↓
User: Chooses Quick/Standard/Thorough/Skip
  ↓
report-validator (Opus/Sonnet):
  - Read based on depth level
  - Validate critical sections
  - Check cross-section coherence
  - Generate validation report
  ↓
If CRITICAL issues:
  report-creator: Fix issues, increment version
  ↓
Main Claude: Report complete, {confidence}%
```

**Token Costs:**
- Report creation: 1.0x (baseline)
- Linting: FREE
- Validation: +0.4x (quick) to +1.2x (thorough)

---

### Workflow 2: Querying Reports

```
User: "{Question about topic}"
  ↓
Main Claude: Launch research-report-finder
  ↓
research-report-finder (Haiku):
  - Search indexes with fuzzy matching
  - Return report path if found
  ↓
If found → Main Claude: Launch research-librarian
  ↓
research-librarian (Sonnet):
  - Read _OVERVIEW.md
  - Navigate to relevant sections
  - Read minimal necessary content
  - Synthesize or recommend sections
  ↓
Main Claude: Use summary to answer user
```

**Token Costs:**
- Finder: ~300 tokens
- Librarian: ~800-1700 tokens
- Total: ~1000-2000 tokens (vs ~50K for full codebase)

**Efficiency:** ~97% token reduction

---

### Workflow 3: Report Not Found

```
User: "{Question about topic}"
  ↓
Main Claude: Launch research-report-finder
  ↓
research-report-finder: NOT FOUND
  ↓
Main Claude: Two options:
  A) Answer from codebase (traditional)
  B) Suggest creating report
  ↓
Decision heuristic:
  - One-off query → Answer directly
  - Repeated/complex topic → Suggest report
```

---

## Scope Management

### Scope Types

**Project Scope:**
- Location: `~/.claude/agent_research_library/projects/{project_slug}/`
- Contains: Project-specific technical knowledge
- Examples: Custom architecture, integrations, implementations
- Access: Only within project context

**Global Scope:**
- Location: `~/.claude/agent_research_library/_global/`
- Contains: User-level knowledge applicable everywhere
- Examples: Language patterns, design principles, frameworks
- Access: From any project

### Cross-Reference Rules

| From Scope | Can Reference |
|------------|---------------|
| Project | Same project + global reports |
| Global | Only global reports |

**Enforcement:** report-creator validates cross-references at creation time.

### Project Identification

Projects identified by git repository root:
```python
project_root = get_git_root(cwd)
project_slug = hash(project_root)
storage_path = f"~/.claude/agent_research_library/projects/{project_slug}/"
```

---

## Validation Depth Levels

### Comparison Table

| Depth | Tokens | Sections Validated | Focus | Use Case |
|-------|--------|-------------------|-------|----------|
| **Quick** | ~5K | 1 critical | High-level coherence | Simple reports (<8 sections) |
| **Standard** | ~15K | 2-3 critical | Architectural accuracy | Most reports (default) |
| **Thorough** | ~30K | 4-5 comprehensive | Complete accuracy | Critical/complex systems |
| **Skip** | 0 | 0 | N/A | Not recommended |

### Selection Guidance

**Use Quick when:**
- Report is simple (<8 sections)
- Straightforward topic
- Low complexity

**Use Standard when:**
- Moderate complexity (most cases)
- Good balance of cost/quality
- Default choice

**Use Thorough when:**
- Critical system documentation
- Complex architectures
- High-stakes accuracy needed

**Skip only when:**
- Trivial documentation
- Rapid prototyping
- Will validate separately later

---

## Cost Analysis

### Relative Costs

Operations scaled relative to report creation (baseline = 1.0x):

| Operation | Model | Cost | Notes |
|-----------|-------|------|-------|
| **Report Creation** | Sonnet | 1.0x | Heavy research, writing |
| **Linting** | Script | FREE | Automated validation |
| **Quick Validation** | Opus | +0.4x | Overview + 1 section |
| **Standard Validation** | Opus | +0.7x | Overview + 2-3 sections |
| **Thorough Validation** | Opus | +1.2x | All sections + 4-5 deep |
| **Report Finding** | Haiku | ~0.01x | Fast index search |
| **Report Querying** | Sonnet | ~0.1x | Efficient navigation |

### Cost Factors

Report costs vary by:
1. **Codebase size**: More files = more reading
2. **Report complexity**: More sections = more writing
3. **Validation depth**: Thorough costs 3x quick
4. **Validation findings**: Fixes require rewrites

### Example Scenario

Moderate report (12 sections):
- Creation: 1.0x
- Linting: FREE
- Standard validation: +0.7x
- **Total first time: ~1.7x**
- Each query afterward: ~0.1x

**Break-even: 2-3 queries on same topic**

### Token Efficiency

**Traditional approach:**
- Every query: Load full codebase (~50K tokens)
- Repeated queries: Reload same context

**Research system:**
- One-time: Create report (~1.7x cost)
- Each query: Librarian navigation (~1-2K tokens)
- **Savings: ~97% per query**

**Long-term value:**
- Reports persist across sessions
- Team can reuse
- Massive token savings for repeated queries

---

## Cross-References

### Format

Cross-references use bracket notation:
```markdown
See [REPORT_ID:SECTION:SUBSECTION] for details.
With marker: [REPORT_ID:AUTH:OAUTH#configuration]
```

### Validation

- Linter checks referenced sections exist
- Warns on broken references
- Enforces scope rules (project/global)

### Best Practices

- Reference complete section keys
- Include context for why reference is relevant
- Use markers (`#marker-id`) for specific subsections
- Keep references stable (don't change keys)

---

## Storage Locations

**Project Reports:**
```
~/.claude/agent_research_library/projects/{project_slug}/
├── index.json
├── REPORT_ID/
│   ├── metadata.json
│   ├── _OVERVIEW.md
│   └── sections/...
```

**Global Reports:**
```
~/.claude/agent_research_library/_global/
├── index.json
├── PATTERN_REPORT/
│   ├── metadata.json
│   ├── _OVERVIEW.md
│   └── sections/...
```

**All reports** use the same v2.0 structure regardless of scope.

---

**Document Version:** 1.0
**Last Updated:** 2025-10-17
**Schema Version:** 2.0
