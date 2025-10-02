# Research Report MCP Tools

Custom MCP tools for the Claude Research Report System.

## Active Tools

### lint_report
Validate the structure and formatting of a research report.

This is the only MCP tool currently active. Report searching is handled by the `research-report-finder` agent, which provides intelligent fuzzy search with synonym support.

**Parameters:**
- `report_path` (string, required): Absolute path to report directory

**Returns:**
- `valid` (boolean): Whether the report structure is valid
- `errors` (array): List of errors that must be fixed
- `warnings` (array): List of warnings (non-critical issues)
- `fixes` (array): Suggested fixes
- `statistics` (object): Report statistics including word counts and file counts
- `message` (string): Human-readable summary

**Validation Features:**

**Structural Checks (Errors):**
- Required files exist (_OVERVIEW.md, metadata.json, sections/)
- Section directories use UPPERCASE_WITH_UNDERSCORES naming
- Each L1 section has _OVERVIEW.md and _FULL.md
- metadata.json has all required fields (id, topic, scope, created, sections)
- Section keys follow format: REPORT_ID:L1[:L2[:L3]]
- Cross-references point to existing sections
- Files listed in metadata.json actually exist on disk

**Quality Checks (Warnings):**
- Word count ranges:
  - Report _OVERVIEW.md: 300-700 words (max 1000)
  - Section _OVERVIEW.md: 300-600 words (max 800)
  - Section _FULL.md: 2000-5000 words (max 6000)
  - L2 component files: 600-1200 words (max 1500)
- Files exist on disk but not registered in metadata.json (orphaned sections)
- Content structure issues (missing headings, too short)

## Installation

### Option 1: User-level (Available in all projects)

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "research-report-tools": {
      "type": "stdio",
      "command": "node",
      "args": ["/Users/YOUR_USERNAME/.claude/research_reports/mcp_tools/index.js"]
    }
  }
}
```

**Replace `YOUR_USERNAME` with your actual username!**

### Option 2: Project-level (Specific project only)

Create `.mcp.json` in your project root:

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

### Option 3: Using Claude CLI

```bash
# User-level
claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js

# Project-level
cd /path/to/your/project
claude mcp add --scope project research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js
```

## Verifying Installation

After installation, restart Claude Code. The tool should appear as:
- `mcp__research-report-tools__lint_report`

You can verify by asking Claude: "What MCP tools do you have available?"

**Note:** Report searching is handled by the `research-report-finder` agent (Haiku), which provides intelligent fuzzy search with synonym support.

## Usage Examples

### Validate a report
```
User: "Lint the acme_api research report"
Claude: [Uses mcp__research-report-tools__lint_report]
```

## Troubleshooting

**Tools not appearing**
- Restart Claude Code after configuration changes
- Verify the path in your MCP config matches your username
- Check `claude mcp list` to see registered servers

**Permission errors**
- Ensure `index.js` is executable: `chmod +x ~/.claude/research_reports/mcp_tools/index.js`
- Check Node.js is installed: `node --version`

**Module errors**
- Reinstall dependencies: `cd ~/.claude/research_reports/mcp_tools && npm install`

## Requirements

- Node.js 18+
- Claude Code with MCP support
- npm packages (installed automatically):
  - `@modelcontextprotocol/sdk`
  - `zod`
