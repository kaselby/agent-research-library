# MCP Tools Reference

This document provides complete reference documentation for the Model Context Protocol (MCP) tools used in the Agent Research Library.

## Overview

The Agent Research Library provides two MCP tools:

1. **lint_report** - Validates report structure and formatting (v2.0 schema)
2. **extract_section** - Extracts specific sections from markdown files using markers

**Note**: Report searching and discovery is handled by the `research-report-finder` agent (Haiku), not an MCP tool. The agent provides intelligent fuzzy search with synonym support. See [AGENT_SYSTEM.md](AGENT_SYSTEM.md#4-research-report-finder-haiku) for details.

## lint_report Tool

Validates the complete structure and formatting of a research report against the v2.0 schema specification.

### Tool Name

When invoked by Claude Code: `mcp__research_report_tools__lint_report`

### Description

Comprehensive validation of report structure including:
- Required files (_OVERVIEW.md, metadata.json, sections/)
- Proper naming conventions (UPPERCASE_WITH_UNDERSCORES)
- v2.0 metadata schema compliance
- Section key format validation
- Cross-reference integrity
- File existence checks
- Word count guidelines
- Section type validation (leaf vs composite)
- Section marker validation

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `report_path` | string | Yes | Absolute path to report directory to validate |

### Return Format

Returns a JSON object with:

```json
{
  "valid": boolean,
  "errors": [
    "Error message 1",
    "Error message 2"
  ],
  "warnings": [
    "Warning message 1"
  ],
  "fixes": [
    "Suggested fix 1"
  ],
  "statistics": {
    "overview_word_count": number,
    "metadata_sections": number,
    "actual_files": number,
    "cross_references": number
  },
  "message": "Human-readable summary"
}
```

**Fields:**
- `valid` - Boolean indicating if report has no structural errors
- `errors` - Array of critical issues that must be fixed (structural problems)
- `warnings` - Array of non-critical issues (style/quality recommendations)
- `fixes` - Array of suggested fixes for the issues found
- `statistics` - Object with report statistics
- `message` - Human-readable summary of validation results

### Validation Features

#### Structural Checks (Errors)

These are critical issues that will cause `valid: false`:

1. **Required Files**:
   - `_OVERVIEW.md` must exist in report root
   - `metadata.json` must exist with valid JSON
   - `sections/` directory must exist

2. **Metadata Schema (v2.0)**:
   - `id` - Report ID (required)
   - `topic` - Human-readable topic (required)
   - `topic_normalized` - Normalized topic for search (required)
   - `scope` - "project" or "global" (required)
   - `created` - ISO timestamp (required)
   - `schema_version` - Should be "2.0" (warning if missing/wrong)
   - `sections` - Array of section metadata (required)

3. **Section Metadata (v2.0)**:
   - `key` - Section key in format `REPORT_ID:L1[:L2[:L3]]`
   - `type` - Must be "leaf" or "composite" (required in v2.0)
   - `title` - Human-readable title
   - `files` - Object mapping file roles to paths
     - Use `content` field (not deprecated `full`)
   - `markers` - Array of lowercase section marker IDs (optional)
   - `word_count` - Number (leaf) or object with overview/content (composite)

4. **Section Keys**:
   - Must start with report ID: `REPORT_ID:...`
   - Must have 2-4 parts (report ID + 1-3 section levels)
   - Each part must use UPPERCASE_WITH_UNDERSCORES
   - Example valid keys:
     - `MY_REPORT:ARCHITECTURE`
     - `MY_REPORT:CORE_SYSTEM:AUTHENTICATION`
     - `MY_REPORT:API:ENDPOINTS:REST_API`

5. **Section Types (v2.0)**:
   - `leaf` - Standalone markdown file (e.g., `TOPIC.md`)
   - `composite` - Directory with children (has `_OVERVIEW.md`, optional `_CONTENT.md`)

6. **Section Markers (v2.0)**:
   - If present in metadata, must be array of strings
   - Each marker must be lowercase with hyphens
   - Examples: `"overview"`, `"core-concepts"`, `"implementation"`

7. **Cross-References**:
   - All `[SECTION_KEY]` references must point to existing sections
   - References extracted from all markdown files
   - Checked against metadata.json section registry

8. **File Existence**:
   - All files listed in metadata.json must exist on disk
   - All actual files should be registered in metadata.json (warning if orphaned)

9. **Naming Conventions**:
   - Section directories: UPPERCASE_WITH_UNDERSCORES
   - Reserved files: `_OVERVIEW.md`, `_CONTENT.md`
   - Standalone sections: UPPERCASE_WITH_UNDERSCORES.md

#### Quality Checks (Warnings)

These are non-critical recommendations that won't cause validation failure:

1. **Word Count Guidelines**:
   - Report `_OVERVIEW.md`: 400-700 words (typical), 1000 max
   - Section `_OVERVIEW.md`: 200-400 words (typical), 600 max
   - Section `_CONTENT.md`: 1500-2500 words (typical), 3500 max
   - Standalone section files: 1000-2000 words (typical), 2500 max
   - Subsection component files: 800-1500 words (typical)
   - Files >2000 words should consider using section markers

2. **Schema Version**:
   - Warning if missing `schema_version` field
   - Warning if using v1.0 schema (recommend migration)

3. **Deprecated Fields**:
   - Warning if using `files.full` instead of `files.content`
   - Warning if `_FULL.md` files exist (should be renamed to `_CONTENT.md`)

4. **Orphaned Sections**:
   - Files exist in sections/ but not registered in metadata.json

5. **Content Quality**:
   - Files should have heading structure
   - Files should have minimum content length

### Examples

#### Example 1: Validate a Report

```
User: "Lint the ACME_API research report"

Claude uses: mcp__research_report_tools__lint_report
Parameters: {
  "report_path": "~/.claude/agent_research_library/projects/abc123/ACME_API"
}

Returns: {
  "valid": true,
  "errors": [],
  "warnings": [
    "Section \"AUTHENTICATION\"/_CONTENT.md has 2800 words (typical: 1500-2500, max: 3500)"
  ],
  "fixes": [],
  "statistics": {
    "overview_word_count": 487,
    "metadata_sections": 12,
    "actual_files": 12,
    "cross_references": 5
  },
  "message": "Report structure is valid. 1 warning(s)."
}
```

#### Example 2: Report with Errors

```
Returns: {
  "valid": false,
  "errors": [
    "Section \"AUTH:OAUTH\" must start with report ID \"ACME_API\"",
    "Section \"ACME_API:API_LAYER\" missing required \"type\" field (must be \"leaf\" or \"composite\")",
    "Cross-reference [ACME_API:NONEXISTENT] points to non-existent section"
  ],
  "warnings": [
    "metadata.json uses deprecated \"files.full\" field - should be \"files.content\" in v2.0"
  ],
  "fixes": [
    "Update section key to \"ACME_API:AUTH:OAUTH\"",
    "Add \"type\": \"composite\" to section metadata",
    "Remove cross-reference or create missing section"
  ],
  "message": "Report structure has 3 error(s) and 1 warning(s)."
}
```

### Common Errors and Fixes

#### 1. Missing Report ID Prefix

**Error**: `Section key "AUTHENTICATION" must start with report ID "ACME_API"`

**Fix**: Update section key in metadata.json:
```json
{
  "key": "ACME_API:AUTHENTICATION",  // ✓ Correct
  // not "AUTHENTICATION"           // ✗ Wrong
}
```

#### 2. Missing Type Field

**Error**: `Section "ACME_API:CORE" missing required "type" field`

**Fix**: Add type field to section in metadata.json:
```json
{
  "key": "ACME_API:CORE",
  "type": "composite",  // or "leaf" for standalone files
  "title": "Core System"
}
```

#### 3. Invalid Section Markers

**Error**: `Section "ACME_API:AUTH" has invalid marker "Core_Concepts"`

**Fix**: Use lowercase with hyphens:
```json
{
  "markers": [
    "core-concepts",  // ✓ Correct
    // not "Core_Concepts"  // ✗ Wrong
  ]
}
```

#### 4. Broken Cross-Reference

**Error**: `Cross-reference [ACME_API:MISSING_SECTION] points to non-existent section`

**Fix**: Either:
- Create the referenced section, or
- Update/remove the cross-reference in markdown files

#### 5. Deprecated File Field

**Warning**: `Section "ACME_API:CORE" uses deprecated "files.full" field`

**Fix**: Rename field in metadata.json:
```json
{
  "files": {
    "overview": "sections/CORE/_OVERVIEW.md",
    "content": "sections/CORE/_CONTENT.md",  // ✓ v2.0
    // not "full": "sections/CORE/_FULL.md"  // ✗ v1.0 (deprecated)
  }
}
```

And rename the actual file:
```bash
mv sections/CORE/_FULL.md sections/CORE/_CONTENT.md
```

---

## extract_section Tool

Extracts a specific section from a markdown file using HTML comment markers.

### Tool Name

When invoked by Claude Code: `mcp__research_report_tools__extract_section`

### Description

Enables partial content loading from large markdown files by extracting content between section markers. If markers are not found and the file is small (<1500 words), returns the entire file content.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file_path` | string | Yes | Absolute path to markdown file |
| `section_id` | string | Yes | Section marker ID to extract (e.g., "overview", "implementation") |

### Return Format

Returns a JSON object with:

#### Success (Marker Found)

```json
{
  "success": true,
  "section_found": true,
  "section_id": "overview",
  "file_path": "/path/to/file.md",
  "extracted_content": "Content between markers...",
  "word_count": 450,
  "message": "Successfully extracted section \"overview\" (450 words)"
}
```

#### Fallback (No Markers, Small File)

```json
{
  "success": true,
  "section_found": false,
  "fallback": "full_file",
  "message": "Section markers not found. File is 800 words - returning entire content.",
  "extracted_content": "Full file content...",
  "word_count": 800
}
```

#### Error (No Markers, Large File)

```json
{
  "success": false,
  "section_found": false,
  "message": "Section marker \"overview\" not found in file. File is 3500 words - too large to return without markers.",
  "available_markers": ["core-concepts", "architecture", "implementation"],
  "suggestion": "Use one of the available section markers listed above, or read the full file directly."
}
```

#### Error (Malformed Markers)

```json
{
  "success": false,
  "section_found": true,
  "message": "Start marker found but end marker \"<!-- /section:overview -->\" is missing. Malformed section markers.",
  "suggestion": "Fix the section markers in the file."
}
```

### Section Marker Format

Section markers are HTML comments that wrap logical content units:

```markdown
<!-- section:overview -->
## Overview
This component handles authentication for all API requests...
(content continues for 200-500 words)
<!-- /section:overview -->

<!-- section:core-architecture -->
## Core Architecture
The architecture consists of three main layers...
(content continues)
<!-- /section:core-architecture -->
```

**Guidelines:**
- Use lowercase, hyphenated IDs (e.g., `core-concepts`, `api-reference`)
- Place markers around logical content units (200-500 words each)
- Small files (<1500 words) don't need markers - always loaded fully
- Markers recommended for files >2000 words
- Markers are optional but enable efficient partial loading

**Valid marker IDs:**
- `overview` ✓
- `core-concepts` ✓
- `implementation-details` ✓
- `api-reference` ✓

**Invalid marker IDs:**
- `Core_Concepts` ✗ (uppercase, underscore)
- `API Reference` ✗ (spaces)
- `impl.details` ✗ (periods)

### Examples

#### Example 1: Extract Specific Section

```
User: "Show me just the overview section of ACME_API:AUTHENTICATION"

Claude uses: mcp__research_report_tools__extract_section
Parameters: {
  "file_path": "~/.claude/agent_research_library/projects/abc123/ACME_API/sections/AUTHENTICATION/_CONTENT.md",
  "section_id": "overview"
}

Returns: {
  "success": true,
  "section_found": true,
  "section_id": "overview",
  "extracted_content": "## Overview\n\nThe authentication system provides...",
  "word_count": 420,
  "message": "Successfully extracted section \"overview\" (420 words)"
}
```

#### Example 2: Small File Without Markers

```
Parameters: {
  "file_path": "~/.claude/agent_research_library/projects/abc123/ACME_API/sections/SIMPLE_TOPIC.md",
  "section_id": "overview"
}

Returns: {
  "success": true,
  "section_found": false,
  "fallback": "full_file",
  "message": "Section markers not found. File is 1200 words - returning entire content.",
  "extracted_content": "# Simple Topic\n\n(full content)",
  "word_count": 1200
}
```

#### Example 3: Wrong Marker ID

```
Parameters: {
  "file_path": "~/.claude/agent_research_library/projects/abc123/ACME_API/sections/AUTH/_CONTENT.md",
  "section_id": "nonexistent"
}

Returns: {
  "success": false,
  "section_found": false,
  "message": "Section marker \"nonexistent\" not found in file. File is 2800 words - too large to return without markers.",
  "available_markers": ["overview", "oauth-flow", "jwt-tokens", "session-management"],
  "suggestion": "Use one of the available section markers listed above, or read the full file directly."
}
```

### Use Cases

1. **Efficient Context Loading**: Load only relevant portions of large documents
2. **Progressive Disclosure**: Start with overview, drill down to specific sections as needed
3. **Token Optimization**: Avoid loading entire 3000-word file when you need 400-word overview
4. **research-librarian Integration**: Agent uses this tool to load recommended sections efficiently

---

## Installation

The MCP tools are installed automatically via `install.sh`. See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) for details.

### Manual Installation

If automatic installation fails, register manually:

```bash
claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js
```

### Verify Installation

```bash
# List MCP servers
claude mcp list

# Should show:
# research-report-tools
```

In a Claude Code session, ask: "What MCP tools do you have available?"

You should see:
- `mcp__research_report_tools__lint_report`
- `mcp__research_report_tools__extract_section`

## Requirements

- Node.js 18 or higher
- Claude Code with MCP support
- npm packages (auto-installed):
  - `@modelcontextprotocol/sdk`
  - `zod`

## Troubleshooting

### Tools Not Available

**Symptoms**: Claude Code doesn't see the MCP tools

**Checks**:
1. Verify MCP server registered:
   ```bash
   claude mcp list
   ```
2. Check Node.js version:
   ```bash
   node --version  # Should be 18+
   ```
3. Verify file exists:
   ```bash
   ls ~/.claude/research_reports/mcp_tools/index.js
   ```

**Fix**:
```bash
# Reinstall MCP server
claude mcp remove research-report-tools
claude mcp add research-report-tools -- node ~/.claude/research_reports/mcp_tools/index.js

# Restart Claude Code
```

### Permission Errors

**Symptoms**: "Permission denied" when running MCP server

**Fix**:
```bash
chmod +x ~/.claude/research_reports/mcp_tools/index.js
```

### Module Errors

**Symptoms**: "Cannot find module" errors

**Fix**:
```bash
cd ~/.claude/research_reports/mcp_tools
npm install
```

### lint_report Returns All Warnings

**This is normal!** Word count warnings are recommendations, not errors. The report is still `valid: true` if there are only warnings.

To get a clean validation with no warnings, ensure:
- Overview: 400-700 words
- Section overviews: 200-400 words
- Section content: 1500-2500 words
- Standalone sections: 1000-2000 words
- All metadata fields use v2.0 format (no deprecated fields)

### extract_section Returns Full File

**This is expected behavior** for small files (<1500 words). Section markers are optional for small files since the entire content can be loaded efficiently.

For files >1500 words, add section markers to enable partial loading.

## Development

### Testing Tools Locally

```bash
cd mcp_tools

# Test lint_report
node index.js <<EOF
{
  "method": "tools/call",
  "params": {
    "name": "lint_report",
    "arguments": {
      "report_path": "~/.claude/agent_research_library/projects/abc123/TEST_REPORT"
    }
  }
}
EOF

# Test extract_section
node index.js <<EOF
{
  "method": "tools/call",
  "params": {
    "name": "extract_section",
    "arguments": {
      "file_path": "/path/to/file.md",
      "section_id": "overview"
    }
  }
}
EOF
```

### Debugging

Add console logging to `mcp_tools/index.js`:

```javascript
console.error(`[DEBUG] Validating report at: ${report_path}`);
```

MCP server stderr output appears in Claude Code logs.

## See Also

- [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - Installation and setup
- [REPORT_SPECIFICATION.md](REPORT_SPECIFICATION.md) - Report structure specification
- [AGENT_SYSTEM.md](AGENT_SYSTEM.md) - Agent workflows and architecture

---

**Last Updated**: 2025-10-17
**Version**: 2.0
