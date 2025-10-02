# Research Report MCP Tools

Custom MCP tools for the Claude Research Report System.

## Tools Included

### 1. check_report_exists
Check if a research report exists for a given topic.

**Parameters:**
- `topic` (string, required): The topic or library name to search for
- `working_directory` (string, optional): Current working directory

**Returns:**
- `exists` (boolean): Whether the report exists
- `scope` (string): "project" or "global" if found
- `report_path` (string): Absolute path to the report directory
- `topic` (string): The matched topic name
- `created` (string): ISO timestamp of creation
- `updated` (string): ISO timestamp of last update
- `message` (string): Human-readable status message

### 2. lint_report
Validate the structure and formatting of a research report.

**Parameters:**
- `report_path` (string, required): Absolute path to report directory

**Returns:**
- `valid` (boolean): Whether the report structure is valid
- `errors` (array): List of errors that must be fixed
- `warnings` (array): List of warnings (non-critical issues)
- `fixes` (array): Suggested fixes
- `message` (string): Human-readable summary

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

After installation, restart Claude Code. The tools should appear with names:
- `mcp__research-report-tools__check_report_exists`
- `mcp__research-report-tools__lint_report`

You can verify by asking Claude: "What MCP tools do you have available?"

## Usage Examples

### Check if a report exists
```
User: "Do we have a research report on acme_api?"
Claude: [Uses mcp__research-report-tools__check_report_exists]
```

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
