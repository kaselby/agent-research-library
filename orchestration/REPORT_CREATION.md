# Research Report Creation Workflow

This document provides detailed instructions for creating research reports using the Claude Research Report System.

## When to Create Reports

Users will explicitly request report creation with phrases like:
- "Create a research report on [topic]"
- "Generate documentation for [library/component]"
- "Build a research report about [system]"

**Never create reports automatically** - they are expensive and intentional.

## Creation Workflow

### Step 1: Launch report-creator Agent

Launch the `report-creator` agent with:
- Clear description of what to document
- Scope (project-specific or global/reusable)
- Any specific focus areas mentioned by the user

Example:
```
Launch report-creator agent:
"Create a comprehensive research report on the authentication system,
focusing on OAuth implementation, token refresh, and session management.
Project scope."
```

The report-creator will:
- Research the codebase thoroughly
- Create hierarchical documentation with multiple abstraction levels
- Generate metadata and cross-references
- **Automatically validate structure using the linter**
- **Fix any structural issues before returning**
- Return a completion summary (structure already validated)

### Step 2: Prompt User for Validation Depth

**Always offer validation options.** Present them clearly:

```
Report created: {REPORT_ID} ({section_count} sections, {word_count} words)

How thorough should the validation be?

1. **Quick** (~5 seconds, ~0.4x base cost)
   - Validates report overview and 1 critical section
   - Checks for obvious contradictions
   - Best for: Simple reports, low-risk documentation

2. **Standard** (~15 seconds, ~0.7x base cost) ← RECOMMENDED
   - Validates overview and 2-3 critical sections
   - Verifies architectural accuracy
   - Best for: Most reports

3. **Thorough** (~30 seconds, ~1.2x base cost)
   - Validates 4-5 sections comprehensively
   - Complete accuracy verification
   - Best for: Critical systems, complex architecture

4. **Skip validation** (not recommended)
   - Report will not be verified for accuracy
   - Use only for trivial documentation

Which would you like? [Default: Standard if user just presses enter]
```

### Step 3: Launch report-validator Agent (if not skipped)

Based on user choice, launch the `report-validator` agent with:

```
Launch report-validator agent:
"Validate the {REPORT_ID} report at {report_path}
Validation depth: {quick|standard|thorough}
Focus on conceptual accuracy and architectural understanding."
```

The validator will:
- Read the report structure
- Verify accuracy against source code
- Check for contradictions and misunderstandings
- Return a validation report with confidence level and any issues

### Step 4: Handle Validation Results

**If CRITICAL issues found:**

```
The validator found critical issues that need to be fixed:

{List critical issues from validation report}

I'll have the report-creator address these issues.
```

Launch report-creator again with:
```
"Fix the following critical issues in {REPORT_ID} report:
{Paste validation report's critical issues section}

Update the affected sections and increment the version number."
```

After fixes, optionally re-run validator with "quick" depth to verify fixes.

**If only MEDIUM issues found:**

```
✓ Report validation complete! Overall confidence: {percentage}%

The validator noted some medium-priority improvements:
{List medium issues}

The report is usable as-is. Would you like me to:
1. Use it now (recommended)
2. Have the creator refine the medium issues
```

**If no issues found:**

```
✓ Report validation complete! Overall confidence: {percentage}%

Report is ready to use. You can now query it efficiently using the
research-librarian agent.
```

## Important Guidelines

### DO:
- ✓ Always offer validation options (don't skip without asking)
- ✓ Default to "Standard" validation if user doesn't specify
- ✓ Fix critical issues before marking reports as ready
- ✓ Explain the token efficiency benefits when suggesting reports

### DON'T:
- ✗ Create reports automatically without explicit user request
- ✗ Skip validation without user approval (default to Standard)
- ✗ Mark reports as "ready" if critical issues exist

## Cost Context

When appropriate, explain to users:

```
"Creating a research report costs ~1.7x a single comprehensive analysis
(base research + validation). But it breaks even after 2-3 queries and
provides ~97% token reduction on all future queries about this topic."
```

## Example Complete Workflow

```
User: "Create a research report on our task orchestration system"

You:
1. Launch report-creator:
   "Create comprehensive research report on the task orchestration
   system. Analyze workflow management, task delegation, scheduling,
   error handling. Project scope."

2. Wait for completion
   → "Report Created: TASK_ORCHESTRATION (15 sections, 22,000 words)"
   → "Structure Validation: ✓ Passed (linter)"
   (The creator automatically validated and fixed any structural issues)

3. Prompt user:
   "Report created! How thorough should validation be?
   1. Quick 2. Standard 3. Thorough 4. Skip [Default: Standard]"

4. User selects "Standard" (or presses enter)

5. Launch report-validator:
   "Validate TASK_ORCHESTRATION report. Depth: standard"

6. Validator returns: 1 CRITICAL issue in SCHEDULING section

7. Inform user:
   "Validation found a critical issue:
   [describe issue from validation report]

   I'll have the creator fix this."

8. Launch report-creator with fix instructions

9. Report fixed and validated → Ready to use
```

## Report Storage

Reports are automatically stored by the agents:

- **Project reports**: `{project}/.claude_research/REPORT_ID/`
- **Global patterns**: `~/.claude/research_reports/_global/REPORT_ID/`
- **Backups**: `~/.claude/research_reports/projects/{project_slug}/`

You don't need to manage storage - the agents handle this.

## Error Handling

**If report-creator fails:**
```
Inform user: "Report creation failed: {error}
Would you like me to try again with different parameters?"
```

**If validator finds issues but creator can't fix:**
```
Present validation report to user:
"The report has some accuracy concerns. Would you like to:
1. Use it with these caveats noted
2. Manual review and fixes
3. Abandon this report and use traditional search"
```

**If lint_report tool is not available:**
```
The report-creator will note this but proceed anyway.
Structural validation is strongly recommended but not strictly required.
```

## Summary

The workflow is:
1. **Create** (report-creator agent - includes automatic structural validation)
2. **Prompt** (ask user for validation depth)
3. **Validate** (report-validator agent for conceptual accuracy)
4. **Fix if needed** (report-creator again)
5. **Confirm ready**

This ensures high-quality, validated documentation that can be efficiently queried hundreds of times.
