# Claude Code Integration Guide

This guide explains how to integrate the Research Report System with Claude Code.

## Overview

The Research Report System uses three specialized Claude Code subagents:
1. **report-creator** (Sonnet) - Generates comprehensive research reports
2. **report-validator** (Opus) - Validates conceptual accuracy and catches misunderstandings
3. **research-librarian** (Sonnet) - Queries reports and recommends context

## Creating the Subagents

### Method 1: Via Claude Code UI

If Claude Code has a UI for creating subagents, use the agent descriptions from `RESEARCH_REPORT_SYSTEM.md`:

1. **report-creator agent** (Sonnet):
   - Copy description from: RESEARCH_REPORT_SYSTEM.md → "Claude Code Subagents" → "Subagent 1: report-creator"
   - Tools needed: Read, Glob, Grep, Write, WebFetch, Bash

2. **report-validator agent** (Opus):
   - Copy description from: RESEARCH_REPORT_SYSTEM.md → "Claude Code Subagents" → "Subagent 2: report-validator"
   - Tools needed: Read, Glob, Grep
   - **Important**: Configure to use Opus model (not Sonnet)

3. **research-librarian agent** (Sonnet):
   - Copy description from: RESEARCH_REPORT_SYSTEM.md → "Claude Code Subagents" → "Subagent 3: research-librarian"
   - Tools needed: Read, Glob, Grep

### Method 2: Via Configuration File

If Claude Code uses config files for agents, create entries like:

```yaml
# agents.yml or similar
agents:
  - name: report-creator
    type: specialized
    description: |
      Expert technical researcher specialized in creating comprehensive,
      hierarchical research reports optimized for context efficiency.

      [Full description from RESEARCH_REPORT_SYSTEM.md]
    tools:
      - Read
      - Glob
      - Grep
      - Write
      - WebFetch
      - Bash

  - name: research-librarian
    type: specialized
    description: |
      Knowledgeable research librarian specialized in efficiently navigating
      hierarchical technical reports and recommending optimal context to load.

      [Full description from RESEARCH_REPORT_SYSTEM.md]
    tools:
      - Read
      - Glob
      - Grep
```

## Implementing ReportRegistryTool

The `ReportRegistryTool` is a simple lookup function that should be available to main Claude.

### Python Implementation

```python
import json
import os
from pathlib import Path
from typing import Dict, Optional

class ReportRegistryTool:
    """Check if research report exists for a topic"""

    name: str = "report_registry"
    description: str = """
    Check if a research report exists for a given topic.

    Args:
        topic: Subject to search for (e.g., "acme_api", "taskflow")
        scope: "project", "global", or "auto" (default: "auto")

    Returns dict with report information if found, or exists=false if not found.
    """

    def __init__(self, project_path: Optional[str] = None):
        self.project_path = project_path or os.getcwd()
        self.global_path = Path.home() / ".claude" / "research_reports" / "_global"
        self.project_research_path = Path(self.project_path) / ".claude_research"

    def _run(self, topic: str, scope: str = "auto") -> Dict:
        """
        Search for research report by topic

        Returns:
            {
                "exists": bool,
                "report_id": str,
                "scope": str,
                "path": str,
                "overview_path": str,
                "metadata_path": str,
                "section_count": int,
                "created": str,
                "updated": str,
                "confidence": str
            }
        """
        # Normalize topic to potential report ID
        report_id = topic.upper().replace("-", "_").replace(" ", "_")

        search_scopes = []
        if scope in ["auto", "project"]:
            search_scopes.append(("project", self.project_research_path))
        if scope in ["auto", "global"]:
            search_scopes.append(("global", self.global_path))

        # Search each scope
        for scope_name, base_path in search_scopes:
            index_path = base_path / "index.json"

            if not index_path.exists():
                continue

            with open(index_path, 'r') as f:
                index_data = json.load(f)

            # Search for matching report
            for report in index_data.get("reports", []):
                # Match by ID (exact) or title (fuzzy)
                if (report["id"] == report_id or
                    report_id in report["id"] or
                    topic.lower() in report["title"].lower()):

                    report_path = base_path / report["path"]
                    overview_path = report_path / "_OVERVIEW.md"
                    metadata_path = report_path / "metadata.json"

                    return {
                        "exists": True,
                        "report_id": report["id"],
                        "scope": scope_name,
                        "path": str(report_path),
                        "overview_path": str(overview_path),
                        "metadata_path": str(metadata_path),
                        "section_count": report.get("section_count", 0),
                        "created": report.get("created", ""),
                        "updated": report.get("updated", ""),
                        "confidence": report.get("confidence", "unknown")
                    }

        # Not found
        return {
            "exists": False,
            "searched_scopes": [s[0] for s in search_scopes],
            "suggestion": f"No research report found for '{topic}'. Create one with: 'Create research report on {topic}'"
        }

# Usage in main Claude
registry = ReportRegistryTool(project_path="/path/to/project")
result = registry._run(topic="acme_api", scope="auto")

if result["exists"]:
    print(f"Found report: {result['report_id']} in {result['scope']} scope")
    # Launch research-librarian subagent
else:
    print(result["suggestion"])
```

### JavaScript/TypeScript Implementation

```typescript
interface ReportInfo {
  exists: boolean;
  report_id?: string;
  scope?: string;
  path?: string;
  overview_path?: string;
  metadata_path?: string;
  section_count?: number;
  created?: string;
  updated?: string;
  confidence?: string;
  searched_scopes?: string[];
  suggestion?: string;
}

class ReportRegistryTool {
  name = "report_registry";
  projectPath: string;
  globalPath: string;
  projectResearchPath: string;

  constructor(projectPath?: string) {
    this.projectPath = projectPath || process.cwd();
    this.globalPath = path.join(
      os.homedir(),
      ".claude",
      "research_reports",
      "_global"
    );
    this.projectResearchPath = path.join(this.projectPath, ".claude_research");
  }

  async run(topic: string, scope: string = "auto"): Promise<ReportInfo> {
    // Normalize topic to report ID
    const reportId = topic.toUpperCase().replace(/[-\s]/g, "_");

    const searchScopes: Array<[string, string]> = [];
    if (scope === "auto" || scope === "project") {
      searchScopes.push(["project", this.projectResearchPath]);
    }
    if (scope === "auto" || scope === "global") {
      searchScopes.push(["global", this.globalPath]);
    }

    // Search each scope
    for (const [scopeName, basePath] of searchScopes) {
      const indexPath = path.join(basePath, "index.json");

      if (!fs.existsSync(indexPath)) {
        continue;
      }

      const indexData = JSON.parse(fs.readFileSync(indexPath, "utf-8"));

      // Search for matching report
      for (const report of indexData.reports || []) {
        if (
          report.id === reportId ||
          report.id.includes(reportId) ||
          report.title.toLowerCase().includes(topic.toLowerCase())
        ) {
          const reportPath = path.join(basePath, report.path);
          const overviewPath = path.join(reportPath, "_OVERVIEW.md");
          const metadataPath = path.join(reportPath, "metadata.json");

          return {
            exists: true,
            report_id: report.id,
            scope: scopeName,
            path: reportPath,
            overview_path: overviewPath,
            metadata_path: metadataPath,
            section_count: report.section_count || 0,
            created: report.created || "",
            updated: report.updated || "",
            confidence: report.confidence || "unknown",
          };
        }
      }
    }

    // Not found
    return {
      exists: false,
      searched_scopes: searchScopes.map((s) => s[0]),
      suggestion: `No research report found for '${topic}'. Create one with: 'Create research report on ${topic}'`,
    };
  }
}

// Usage
const registry = new ReportRegistryTool("/path/to/project");
const result = await registry.run("acme_api", "auto");

if (result.exists) {
  console.log(`Found report: ${result.report_id} in ${result.scope} scope`);
  // Launch research-librarian subagent
} else {
  console.log(result.suggestion);
}
```

## Usage Workflows

### Workflow 1: User Requests Report Creation

```
User: "Create a research report on acme_api"

Main Claude:
1. Recognize explicit report creation request
2. Determine scope (project-level based on cwd)
3. Launch report-creator subagent with:
   - Task: "Create comprehensive research report on acme_api library"
   - Working directory: /path/to/project
   - Output location: .claude_research/ACME_API/

report-creator:
- Analyzes codebase
- Creates hierarchical report
- Writes to .claude_research/
- Syncs to ~/.claude/research_reports/projects/

Returns: Report summary
```

### Workflow 2: User Asks Question

```
User: "How does acme_api handle OAuth authentication?"

Main Claude:
1. Use ReportRegistryTool("acme_api")
2. If exists:
   a. Launch research-librarian subagent with:
      - Query: "How does acme_api handle OAuth authentication?"
      - Report path: {from registry}
   b. Librarian returns summary + section recommendations
   c. Optionally load recommended sections
   d. Answer user with context
3. If not exists:
   a. Answer from codebase directly (traditional approach)
   b. Optionally suggest: "Would you like me to create a research report?"
```

### Workflow 3: Checking for Report

```
# In main Claude's decision logic

if user_query_about_documented_topic:
    result = ReportRegistryTool._run(topic=inferred_topic)

    if result["exists"]:
        use_research_librarian(result)
    else:
        use_traditional_approach()
```

## File Locations

### Global Reports
```
~/.claude/research_reports/
├── RESEARCH_REPORT_SYSTEM.md          # System documentation
├── CLAUDE_CODE_INTEGRATION.md         # This file
├── templates/                          # Report templates
└── _global/                            # User-level reports
    └── index.json
```

### Project Reports
```
/path/to/project/
├── .claude_research/                   # Primary storage
│   ├── index.json
│   ├── metadata.json
│   └── {REPORT_ID}/
│       ├── metadata.json
│       ├── _OVERVIEW.md
│       └── sections/
└── .gitignore                          # Should include .claude_research/
```

### Backup Location
```
~/.claude/research_reports/projects/{project_slug}/
└── {REPORT_ID}/                        # Mirror of project reports
```

## Testing the Integration

### Test 1: Create Simple Report

```
User: "Create a research report on the configuration system"

Expected:
- report-creator launches
- Creates CONFIG_SYSTEM report
- Stores in .claude_research/CONFIG_SYSTEM/
- Updates index.json
- Returns summary
```

### Test 2: Query Existing Report

```
# First create report (Test 1)
# Then:

User: "How does the configuration system load YAML files?"

Expected:
- ReportRegistryTool finds CONFIG_SYSTEM
- research-librarian launches
- Reads overview + relevant sections
- Returns summary + section recommendations
- Main Claude uses context to answer
```

### Test 3: Query Non-Existent Report

```
User: "How does the authentication system work?"

Expected:
- ReportRegistryTool returns exists=false
- Main Claude uses traditional codebase search
- Optionally suggests creating report
```

## Troubleshooting

### ReportRegistryTool Not Finding Reports

**Check**:
1. `index.json` exists in search locations
2. Report ID in index matches expected format
3. Scope parameter is correct ("auto", "project", "global")

**Debug**:
```python
registry = ReportRegistryTool()
print(f"Project path: {registry.project_research_path}")
print(f"Global path: {registry.global_path}")
print(f"Index exists: {(registry.project_research_path / 'index.json').exists()}")
```

### Subagent Not Launching

**Check**:
1. Agent registered in Claude Code
2. Agent description matches expected format
3. Required tools are available to agent

**Test**:
```
# Manually launch agent to test
Launch report-creator with test task
Check agent receives task
Verify agent has file system access
```

### Report Creation Fails

**Check**:
1. `.claude_research/` directory exists and writable
2. Sufficient disk space
3. No permission issues
4. Agent has Write tool access

**Fix**:
```bash
# Ensure directory exists
mkdir -p /path/to/project/.claude_research

# Check permissions
ls -la /path/to/project/.claude_research
```

## Advanced Configuration

### Custom Report Locations

Modify `ReportRegistryTool.__init__()` to support custom paths:

```python
def __init__(self, project_path: Optional[str] = None,
             custom_global_path: Optional[str] = None):
    self.project_path = project_path or os.getcwd()
    self.global_path = (Path(custom_global_path) if custom_global_path
                       else Path.home() / ".claude" / "research_reports" / "_global")
    self.project_research_path = Path(self.project_path) / ".claude_research"
```

### Scope-Specific Search

To only search project scope:

```python
result = registry._run(topic="acme_api", scope="project")
```

To only search global scope:

```python
result = registry._run(topic="python_patterns", scope="global")
```

### Custom Report ID Matching

Modify `_run()` method to customize how topics match report IDs:

```python
# Exact match only
if report["id"] == report_id:
    return report_info

# Fuzzy match with threshold
if fuzz.ratio(topic.lower(), report["title"].lower()) > 80:
    return report_info
```

## Next Steps

1. **Register Subagents**: Create report-creator and research-librarian agents in Claude Code
2. **Implement Tool**: Add ReportRegistryTool to main Claude's available tools
3. **Test Integration**: Run the test workflows above
4. **Create First Report**: Ask Claude to create a research report on a project component
5. **Query Report**: Test the research-librarian by asking questions about the documented component

## Reference

- Full system documentation: `RESEARCH_REPORT_SYSTEM.md`
- Report templates: `templates/`
- Example reports: See RESEARCH_REPORT_SYSTEM.md → Examples section

---

**Last Updated**: 2025-10-02
**Version**: 1.0
