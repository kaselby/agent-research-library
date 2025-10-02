# Claude Research Report System

You have access to a research report system that creates and queries hierarchical technical documentation.

## Querying Reports

When you need complex technical information about a topic, **check if a research report exists first** before using traditional search methods.

**When to check for reports:**
- Writing code that integrates with an external library or framework
- Answering technical questions about complex subjects, architectures, or codebases
- Researching a subject or looking for information to approach a problem
- Any task requiring deep technical understanding of a documented system

**How to query reports:**

1. Launch `report-finder` agent (Haiku) with the user's question/topic
2. If report found → Launch `research-librarian` agent with the report path and query
3. If no report exists → Use traditional codebase search or documentation

**Example:**
```
User: "How does authentication work in huggingface?"
→ Launch report-finder agent: "Find report for: authentication in huggingface"
→ If found: Launch research-librarian agent with:
   - Report path from finder
   - Query: "Search for authentication implementation details"
→ If not found: Search codebase/documentation directly as you normally would
```

**Important**: The research-librarian returns a summary plus references to specific documentation sections. You must:
- Read the referenced sections (only the lines/sections specified, not entire files)
- Follow any cross-references to related sections
- Load additional sections if the librarian recommends them for a complete answer

## Creating Reports

**CRITICAL**: Only create research reports when the user **explicitly mentions "Research Report System"** or "research system" in their request.

**When to create reports:**
- ✓ User says: "Create a research report on [topic] using the Research Report System"
- ✓ User says: "Generate a research report for [library] with the research system"
- ✓ User says: "Build a research report about [system]" → Confirm first: "Should I use the Research Report System for this?"

**When NOT to create reports:**
- ✗ User says: "Research the authentication system for me" → Query existing reports or search codebase
- ✗ User says: "Can you document how OAuth works here?" → Use normal documentation tools
- ✗ User says: "Summarize the API architecture" → Use normal analysis and summarization
- ✗ Any vague request that could be interpreted as a simple query or documentation task

**If there's any ambiguity**, ask the user for confirmation before creating a report. Report creation is expensive and should never happen automatically.

**When explicitly requested**, read the detailed workflow in:
`~/.claude/research_reports/REPORT_CREATION.md`

---

_Note: Reports are stored in `.claude_research/` (project-specific) or `~/.claude/research_reports/_global/` (reusable patterns)_
