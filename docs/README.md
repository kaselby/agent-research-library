# Research Report System

A hierarchical knowledge management system for Claude Code that enables context-efficient research through multi-level abstraction and intelligent report querying.

## Quick Start

### For Users

**Create a research report**:
```
"Create a research report on acme_api"
```

**Query a report**:
```
"How does acme_api handle authentication?"
```

Claude will automatically:
1. Check if a report exists
2. Use the research-librarian subagent to find relevant information
3. Load only necessary sections
4. Provide an informed answer

### For Developers

1. **Read the documentation**:
   - `RESEARCH_REPORT_SYSTEM.md` - Complete system specification
   - `CLAUDE_CODE_INTEGRATION.md` - Integration guide

2. **Set up subagents**:
   - Create `report-creator` agent (see integration guide)
   - Create `research-librarian` agent (see integration guide)

3. **Implement ReportRegistryTool**:
   - Code examples in `CLAUDE_CODE_INTEGRATION.md`

## Directory Structure

```
~/.claude/research_reports/
├── README.md                           # This file
├── RESEARCH_REPORT_SYSTEM.md          # Complete documentation
├── CLAUDE_CODE_INTEGRATION.md         # Integration guide
│
├── templates/                          # Report templates
│   ├── index_template.json
│   ├── metadata_template.json
│   ├── report_structure.md
│   ├── section_overview.md
│   └── section_full.md
│
├── _global/                            # User-level reports
│   └── index.json
│
└── projects/                           # Project backups
    └── {project_slug}/
        └── {REPORT_ID}/
```

## Key Concepts

### Hierarchical Abstraction
Reports have multiple levels of detail:
- **L1**: Major subsystems (2000-4000 words)
- **L2**: Specific components (600-1000 words)
- **L3**: Detailed implementations (rare, only when needed)

Each level has:
- `_OVERVIEW.md` - Summary and navigation (300-500 words)
- `_FULL.md` - Complete content
- Component files - Specific implementations

### Project vs Global Scope
- **Project reports**: Stored in `{project}/.claude_research/`
  - Project-specific technical details
  - Can reference same project + global reports
- **Global reports**: Stored in `~/.claude/research_reports/_global/`
  - User-level knowledge (patterns, best practices)
  - Reusable across all projects

### Context Efficiency
Traditional approach: Load entire codebase (~50,000 tokens)

Research report approach:
1. Librarian reads overview (~500 tokens)
2. Identifies relevant sections
3. Reads specific sections (~800-1500 tokens)
4. Returns summary + recommendations

**Result**: ~97% reduction in context usage

## Components

### 1. report-creator Subagent (Sonnet)
- **Purpose**: Generate comprehensive research reports
- **Invocation**: ONLY on explicit user request
- **Output**: Hierarchical report with keyed sections

### 2. report-validator Subagent (Opus)
- **Purpose**: Validate conceptual accuracy and catch misunderstandings
- **Invocation**: After report creation (user chooses depth)
- **Output**: Validation report with confidence score and issues found

### 3. research-librarian Subagent (Sonnet)
- **Purpose**: Query reports and recommend context
- **Invocation**: Automatic when report exists and user asks questions
- **Output**: Summary + section recommendations

### 4. ReportRegistryTool
- **Purpose**: Check if report exists
- **Type**: Simple lookup tool (not a subagent)
- **Returns**: Report metadata or exists=false

### 5. ReportLinterTool
- **Purpose**: Automated structure and formatting validation
- **Type**: Script-based validator (not an LLM)
- **Returns**: Errors, warnings, and auto-fixes

## Example Report Structure

```
ACME_API/
├── metadata.json
├── _OVERVIEW.md                        # Report overview
└── sections/
    ├── CORE_ARCHITECTURE/
    │   ├── _FULL.md                    # Complete architecture
    │   ├── _OVERVIEW.md                # Architecture summary
    │   ├── REQUEST_HANDLER.md          # L2 component
    │   └── RESPONSE_BUILDER.md         # L2 component
    │
    └── AUTHENTICATION/
        ├── _FULL.md
        ├── _OVERVIEW.md
        ├── OAUTH.md                    # L2 component
        └── API_KEYS.md                 # L2 component
```

## Workflows

### Create Report (with Validation)
```
User: "Create research report on acme_api"
  ↓
Claude: Launch report-creator (Sonnet)
  ↓
report-creator: Analyze → Structure → Write → Store
  ↓
Claude: Run linter (auto-fixes formatting)
  ↓
Claude: Prompt user for validation depth
  ↓
User: "Standard" (or Quick/Thorough/Skip)
  ↓
Claude: Launch report-validator (Opus)
  ↓
report-validator: Read → Identify critical sections → Deep-dive → Validate
  ↓
Result: Validation report (confidence %, issues found)
  ↓
If CRITICAL issues: report-creator fixes them
  ↓
Final: Report in .claude_research/ACME_API/ (validated ✓)
```

### Query Report
```
User: "How does acme_api handle OAuth?"
  ↓
Claude: Check ReportRegistryTool
  ↓
Found: Launch research-librarian (Sonnet)
  ↓
librarian: Read overview → Navigate sections → Synthesize
  ↓
Result: Summary + section recommendations
  ↓
Claude: Load recommended sections → Answer user
```

## Benefits

1. **Token Efficiency**: Load only relevant context
2. **Persistent Knowledge**: Reports survive across sessions
3. **Progressive Disclosure**: Multiple abstraction levels
4. **Project Isolation**: Scoped knowledge management
5. **Intelligent Querying**: Subagent understands report structure
6. **Reusable Patterns**: Global reports for cross-project knowledge

## File Locations

### System Files
- Documentation: `~/.claude/research_reports/*.md`
- Templates: `~/.claude/research_reports/templates/`
- Global reports: `~/.claude/research_reports/_global/`

### Project Files
- Primary storage: `{project}/.claude_research/`
- Backup storage: `~/.claude/research_reports/projects/{project_slug}/`
- Git ignore: Add `.claude_research/` to `.gitignore`

## Best Practices

### Creating Reports
1. Only create on explicit user request
2. Start with overview to plan structure
3. Use 1-3 abstraction levels
4. Include file:line code references
5. Cross-reference related sections
6. Target 600-1000 words per leaf section

### Querying Reports
1. Start with overview (cheapest)
2. Navigate hierarchy progressively
3. Read minimum necessary
4. Recommend sections to parent agent
5. Synthesize for simple queries

## Next Steps

1. ✅ Directory structure created
2. ✅ Documentation written
3. ✅ Templates created
4. ✅ Schema files initialized
5. ⏭️ Set up Claude Code subagents (see CLAUDE_CODE_INTEGRATION.md)
6. ⏭️ Implement ReportRegistryTool
7. ⏭️ Create first research report
8. ⏭️ Test query workflow

## Documentation

- **System Specification**: `RESEARCH_REPORT_SYSTEM.md` (23,000 words)
  - Architecture
  - Schemas
  - Subagent descriptions
  - Workflows
  - Examples

- **Integration Guide**: `CLAUDE_CODE_INTEGRATION.md`
  - How to create subagents
  - ReportRegistryTool implementation
  - Usage workflows
  - Troubleshooting

- **Templates**: `templates/`
  - Report structure examples
  - Section templates
  - Schema templates

## Version

- **System Version**: 1.0
- **Created**: 2025-10-02
- **Status**: Ready for integration

## Support

For questions or issues:
1. Review `RESEARCH_REPORT_SYSTEM.md` for detailed specifications
2. Check `CLAUDE_CODE_INTEGRATION.md` for integration help
3. Examine templates for examples

---

**Ready to use!** Follow the integration guide to set up subagents and start creating research reports.
