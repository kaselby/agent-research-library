# Agent Specifications for Prompt Generation

This directory contains detailed specifications for each of the 4 agents in the Agent Research Library system. These specifications are designed to be passed to a prompt generator to create the actual agent prompt files.

## Agent Overview

| Agent | Model | Role | Token Budget |
|-------|-------|------|--------------|
| **report-creator** | Sonnet 3.5 | Creates hierarchical research reports from codebases | ~20-40K tokens |
| **report-validator** | Opus 3 or Sonnet 3.5 | Validates conceptual accuracy of reports | ~5-30K tokens (depth-dependent) |
| **research-librarian** | Sonnet 3.5 | Queries reports efficiently, returns summaries | ~1-4K tokens |
| **research-report-finder** | Haiku 3.5 | Fast fuzzy search to locate existing reports | ~500-1K tokens |

## Specification Files

### 1. report-creator-spec.md

**Purpose**: Generate prompts for the report-creator agent

**Key Sections**:
- Complete workflow (6 phases: scope, analyze, structure, metadata, validate, index)
- Required documentation references (REPORT_SPECIFICATION.md, templates)
- Self-validation with lint_report tool (MUST use before completion)
- Output format for returning results to main Claude
- Design principles (natural structure, optional _CONTENT.md, progressive disclosure)
- Common pitfalls to avoid

**Critical Requirements**:
- Agent MUST read REPORT_SPECIFICATION.md (687 lines) for complete v2.0 schema
- Agent MUST use lint_report tool and fix all errors before returning
- Agent MUST only be invoked on explicit user request
- Agent MUST use v2.0 terminology (_CONTENT.md not _FULL.md)

### 2. report-validator-spec.md

**Purpose**: Generate prompts for the report-validator agent (Opus or Sonnet variant)

**Key Sections**:
- Validation workflow (4 phases: understand, validate, categorize, report)
- Validation depth levels (Quick/Standard/Thorough)
- Issue severity classification (CRITICAL/MAJOR/MINOR)
- Critical section selection strategy
- Output format with evidence-based findings

**Critical Requirements**:
- Agent MUST cite evidence (code references) for all findings
- Agent MUST classify issues by severity properly
- Agent MUST provide actionable recommendations
- Agent does NOT have Write access (reports findings only)
- Two versions needed: report-validator-opus.md and report-validator-sonnet.md

### 3. research-librarian-spec.md

**Purpose**: Generate prompts for the research-librarian agent

**Key Sections**:
- Progressive disclosure navigation strategy
- Query classification (simple/complex/exploratory/troubleshooting)
- Token optimization techniques (use overviews, section markers, metadata-driven)
- Output format with summary + recommendations
- Decision matrix for different query types

**Critical Requirements**:
- Agent MUST start with overviews, drill down progressively
- Agent MUST use extract_section tool for large files with markers
- Agent MUST return token usage comparison (~2K vs ~50K)
- Agent MUST recommend further reading sections
- Agent does NOT have access to source code (only reads reports)

### 4. research-report-finder-spec.md

**Purpose**: Generate prompts for the research-report-finder agent

**Key Sections**:
- Fuzzy matching algorithm with scoring
- Synonym expansion rules (auth→authentication, db→database, etc.)
- Search workflow (project scope first, then global)
- Response formats (FOUND/NOT FOUND/MULTIPLE MATCHES)
- Edge case handling (no index, empty index, ambiguous query)

**Critical Requirements**:
- Agent MUST use Haiku 3.5 (speed over reasoning)
- Agent MUST search both project and global scopes
- Agent MUST provide confidence levels (high/medium/low)
- Agent MUST complete in <2 seconds
- Agent MUST explain match reason (exact/synonym/partial)

## How to Use These Specifications

### For Each Agent:

1. **Read the specification file completely**
   - Understand the agent's role and responsibilities
   - Note the required documentation references
   - Review the workflow and key principles

2. **Extract key sections for the prompt**:
   - Role overview → becomes agent description
   - Required documentation → becomes "Read these files first" instructions
   - Workflow → becomes step-by-step instructions
   - Output format → becomes response template
   - Key principles → becomes guiding principles
   - Common pitfalls → becomes warning section

3. **Generate the agent prompt file** (YAML frontmatter + markdown):
   ```yaml
   ---
   name: {agent-name}
   model: {model-name}
   description: {brief-description}
   tools:
     - Read
     - Glob
     - Grep
     - {other-tools}
   ---

   # Agent Instructions

   {Generated from specification}
   ```

4. **Include document references**:
   - Specify exact file paths to documentation
   - Note which sections to read (e.g., "lines ~370-380")
   - Emphasize CRITICAL vs HELPFUL docs

5. **Test the generated prompt**:
   - Verify agent can complete its task
   - Check that it follows the workflow
   - Ensure it produces expected output format
   - Validate error handling

## Documentation References

All agents need access to documentation in `~/.claude/agent_research_library/`:

### Primary Documentation (All Agents)

- **REPORT_SPECIFICATION.md** (687 lines)
  - Complete v2.0 schema definition
  - File types, section types, naming conventions
  - Section keys format, markers, word counts
  - Validation rules and structure examples

### Agent-Specific Documentation

**report-creator**:
- `templates/metadata_template.json`
- `templates/section_overview.md`
- `templates/section_content.md`
- `templates/section_standalone.md`
- `REPORT_CREATION.md` (orchestration workflow)

**report-validator**:
- `AGENT_SYSTEM.md` (Validation Depth Levels section)

**research-librarian**:
- `AGENT_SYSTEM.md` (research-librarian section, lines ~223-281)

**research-report-finder**:
- `AGENT_SYSTEM.md` (research-report-finder section, lines ~283-327)

## Model Selection Notes

### report-creator: Sonnet 3.5
- **Why**: Balance of speed, cost, and quality for research/writing
- **Alternative**: Could use Opus for higher quality, but much more expensive
- **Token budget**: 20-40K tokens per report

### report-validator: Opus 3 (recommended) or Sonnet 3.5
- **Why Opus**: Highest accuracy for catching subtle conceptual errors
- **Why Sonnet**: Faster and cheaper, still effective
- **Decision**: Made during installation by user
- **Token budget**: 5K (Quick) to 30K (Thorough)

### research-librarian: Sonnet 3.5
- **Why**: Needs reasoning to navigate hierarchy and synthesize answers
- **Alternative**: Opus would be overkill; Haiku not smart enough
- **Token budget**: 1-4K tokens per query

### research-report-finder: Haiku 3.5
- **Why**: Simple search task, speed is critical
- **Alternative**: Sonnet would work but costs 5x more for same result
- **Token budget**: 500-1K tokens per search

## Success Criteria for Generated Prompts

A well-generated agent prompt should:

✅ **Clear Role**: Agent understands its specific responsibility
✅ **Required Reading**: Agent knows which docs to read and why
✅ **Step-by-Step**: Agent has clear workflow to follow
✅ **Tool Usage**: Agent knows which tools to use when
✅ **Output Format**: Agent knows exactly what to return
✅ **Error Handling**: Agent knows what to do when things go wrong
✅ **Boundaries**: Agent knows what NOT to do
✅ **Quality Checks**: Agent knows how to validate its own work

## Version Notes

- **Schema Version**: 2.0 (use _CONTENT.md not _FULL.md)
- **Specification Date**: 2025-10-17
- **Status**: Ready for prompt generation

All specifications reflect the completed documentation refactor (Phase 1-6, 100% complete).

## Next Steps

1. Pass each specification to your prompt generator
2. Generate YAML frontmatter + markdown agent files
3. Review generated prompts for completeness
4. Test each agent with sample tasks
5. Install agents to `~/.claude/agents/`
6. Test the complete system end-to-end

---

**Created**: 2025-10-17
**Documentation Version**: 2.0
**Purpose**: Comprehensive specifications for AI agent prompt generation
