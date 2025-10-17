# Documentation Reorganization Plan

**Started**: 2025-10-17
**Status**: In Progress

## Overview
Reorganizing documentation from scattered 2030-line files into focused, well-scoped documents.

## Target Structure

```
docs/
├── REPORT_SPECIFICATION.md    (~400-500 lines) - Complete v2.0 format spec
├── AGENT_SYSTEM.md             (~600-700 lines) - Agent architecture & workflows
├── INTEGRATION_GUIDE.md        (~300-400 lines) - Installation & setup
└── MCP_TOOLS.md                (~200-250 lines) - Tool reference

README.md                       (~150-200 lines) - Single user quick start

templates/                      - Only actual content templates (no docs)
├── section_content.md
├── section_overview.md
├── section_standalone.md
├── metadata_template.json
└── index_template.json
```

## Detailed Workflow

### Phase 1: Create New Core Documents

#### Task 1.1: Create REPORT_SPECIFICATION.md ✅
**Status**: Completed
**Location**: docs/REPORT_SPECIFICATION.md
**Actual Size**: 687 lines

**Content Sources**:
- [x] Extract Report Schema from RESEARCH_REPORT_SYSTEM.md (lines ~186-306)
- [x] Extract Abstraction Levels from RESEARCH_REPORT_SYSTEM.md (lines ~310-400)
- [x] Extract Naming Conventions from RESEARCH_REPORT_SYSTEM.md (lines ~403-440)
- [x] Extract File Types table from RESEARCH_REPORT_SYSTEM.md (line ~325-331)
- [x] Absorb ALL of section_markers.md (143 lines)
- [x] Absorb ALL of templates/report_structure.md (204 lines)
- [x] Extract Example Structures from RESEARCH_REPORT_SYSTEM.md (lines ~1549-1653)

**New Content to Add**:
- [x] Clear v2.0 schema definition (ensure all examples use _CONTENT.md)
- [x] Decision criteria for when to use directories vs standalone files
- [x] Validation rules for report structure

**Sections**:
1. Overview
2. Schema Version 2.0
3. Directory Structure Patterns
4. File Types and Naming
5. Section Keys
6. Section Markers
7. Word Count Guidelines
8. Structure Examples (3-4 comprehensive examples)
9. Metadata Schema
10. Validation Rules

---

#### Task 1.2: Create AGENT_SYSTEM.md ✅
**Status**: Completed
**Location**: docs/AGENT_SYSTEM.md
**Actual Size**: 744 lines

**Content Sources**:
- [x] Extract Architecture section from RESEARCH_REPORT_SYSTEM.md (lines ~39-109)
- [x] Extract report-creator description from RESEARCH_REPORT_SYSTEM.md (lines ~510-654)
- [x] Extract report-validator description from RESEARCH_REPORT_SYSTEM.md (lines ~657-907)
- [x] Extract research-librarian description from RESEARCH_REPORT_SYSTEM.md (lines ~910-1100)
- [x] Add research-report-finder agent description (from agents/research-report-finder.md)
- [x] Extract Workflows 1-3 from RESEARCH_REPORT_SYSTEM.md (lines ~1264-1546)
- [x] Extract Scope Management from RESEARCH_REPORT_SYSTEM.md (lines ~442-496)
- [x] Extract Cost Estimates from RESEARCH_REPORT_SYSTEM.md (lines ~1790-1841)

**Updates Needed**:
- [x] Update all agent descriptions to v2.0 (change _FULL.md to _CONTENT.md)
- [x] Update workflows for v2.0 structure
- [x] Modernize cost analysis

**Sections**:
1. System Architecture
2. Agent Descriptions
   - report-creator (Sonnet)
   - report-validator (Opus or Sonnet)
   - research-librarian (Sonnet)
   - research-report-finder (Haiku)
3. Workflows
   - Creating and Validating Reports
   - Querying Reports
   - Report Not Found
4. Scope Management (project vs global)
5. Cross-References
6. Validation Depth Levels
7. Cost Analysis
8. Token Efficiency

---

#### Task 1.3: Streamline INTEGRATION_GUIDE.md ✅
**Status**: Completed
**Location**: docs/INTEGRATION_GUIDE.md (rename from CLAUDE_CODE_INTEGRATION.md)
**Actual Size**: 489 lines

**Content Sources**:
- [x] Start with docs/CLAUDE_CODE_INTEGRATION.md (520 lines)
- [x] Keep: Installation instructions
- [x] Keep: Agent registration process
- [x] Keep: Testing the integration
- [x] Keep: Troubleshooting section

**Content to Remove** (now in other docs):
- [x] Remove: Detailed report structure examples (→ REPORT_SPECIFICATION.md)
- [x] Remove: Agent descriptions (→ AGENT_SYSTEM.md)
- [x] Remove: Detailed workflows (→ AGENT_SYSTEM.md)
- [x] Remove: ReportRegistryTool implementation (move to MCP_TOOLS.md)

**Updates Needed**:
- [x] Add links to other docs for details
- [x] Streamline and focus on integration only
- [x] Update for v2.0

**Sections**:
1. Overview
2. Installation
3. Agent Registration
4. MCP Server Setup (brief)
5. Testing Integration
6. Configuration Options
7. Troubleshooting
8. Links to Other Docs

---

#### Task 1.4: Create MCP_TOOLS.md ✅
**Status**: Completed
**Location**: docs/MCP_TOOLS.md
**Actual Size**: 617 lines

**Content Sources**:
- [x] Extract from mcp_tools/README.md (keep original file)
- [x] Absorb extract_section tool details from mcp_tools/index.js
- [x] Note: EXTRACT_SECTION_TOOL.md doesn't exist
- [x] Note: ReportRegistryTool is example code, not actual MCP tool (superseded by research-report-finder agent)

**Sections**:
1. Overview
2. lint_report Tool
   - Parameters
   - Return format
   - Validation features
   - Examples
3. extract_section Tool
   - Parameters
   - Return format
   - Section marker format
   - Examples
4. Installation & Usage
5. Troubleshooting

---

#### Task 1.5: Merge READMEs ✅
**Status**: Completed
**Location**: README.md (root)
**Actual Size**: 338 lines (reduced from 494 total)

**Content Sources**:
- [x] Use root README.md as base (229 lines)
- [x] Extract unique content from docs/README.md (265 lines)
- [x] Remove overlap between the two

**Updates Needed**:
- [x] Keep user-focused, quick start oriented
- [x] Remove details now in other docs
- [x] Add clear links to docs/ for more information
- [x] Update for v2.0

**Sections**:
1. Overview
2. Quick Install
3. Quick Start
4. Architecture (brief)
5. Example Report Structure
6. Storage Locations
7. Documentation Links
8. Requirements

---

### Phase 2: Clean Up templates/

#### Task 2.1: Remove non-template from templates/ ✅
**Status**: Completed

**Actions**:
- [x] Delete templates/report_structure.md (content moved to REPORT_SPECIFICATION.md)
- [x] Verify remaining files are actual templates:
  - section_content.md ✓
  - section_overview.md ✓
  - section_standalone.md ✓
  - metadata_template.json ✓
  - index_template.json ✓
  - INSTALLED_VERSION_template.json ✓

---

### Phase 3: Update References

#### Task 3.1: Update CLAUDE.md references ✅
**Status**: Completed

- [x] Check CLAUDE.md for doc references
- [x] Update any paths that changed
  - Updated installer documentation list
  - Updated "Documentation Files" section with new structure
  - Updated "View installed documentation" commands

#### Task 3.2: Update orchestration/ references ✅
**Status**: Completed

- [x] Check orchestration/GLOBAL_INSTRUCTIONS.md for doc references
- [x] Check orchestration/REPORT_CREATION.md for doc references
- [x] No updates needed - references are still valid

#### Task 3.3: Update install.sh references ✅
**Status**: Completed

- [x] Check install.sh for hardcoded doc paths
- [x] Update any paths that changed
  - Updated verification check from RESEARCH_REPORT_SYSTEM.md to README.md
  - Updated documentation section to reference all 4 new docs

#### Task 3.4: Update cross-references in new docs ⏳
**Status**: Not Started

- [ ] Ensure all internal links in REPORT_SPECIFICATION.md work
- [ ] Ensure all internal links in AGENT_SYSTEM.md work
- [ ] Ensure all internal links in INTEGRATION_GUIDE.md work
- [ ] Ensure all internal links in MCP_TOOLS.md work
- [ ] Ensure all internal links in README.md work

---

### Phase 4: Delete Old Files

#### Task 4.1: Delete obsolete documentation files ⏳
**Status**: Not Started

**Files to Delete**:
- [ ] docs/README.md (content merged into root README.md)
- [ ] docs/RESEARCH_REPORT_SYSTEM.md (split into multiple focused docs)
- [ ] docs/CLAUDE_CODE_INTEGRATION.md (renamed/streamlined to INTEGRATION_GUIDE.md)
- [ ] docs/section_markers.md (absorbed into REPORT_SPECIFICATION.md)
- [ ] docs/EXTRACT_SECTION_TOOL.md (absorbed into MCP_TOOLS.md)
- [ ] templates/report_structure.md (absorbed into REPORT_SPECIFICATION.md)

---

### Phase 5: Fix v2.0 References

#### Task 5.1: Fix _FULL.md → _CONTENT.md references ⏳
**Status**: Not Started

**Files to Check**:
- [ ] REPORT_SPECIFICATION.md - ensure all examples use _CONTENT.md
- [ ] AGENT_SYSTEM.md - update agent descriptions for v2.0
- [ ] INTEGRATION_GUIDE.md - ensure v2.0 terminology
- [ ] MCP_TOOLS.md - ensure lint_report docs reflect v2.0

---

### Phase 6: Final Verification

#### Task 6.1: Verify documentation completeness ⏳
**Status**: Not Started

- [ ] Read through REPORT_SPECIFICATION.md - verify it's a complete spec
- [ ] Read through AGENT_SYSTEM.md - verify all agents covered
- [ ] Read through INTEGRATION_GUIDE.md - verify installation works
- [ ] Read through MCP_TOOLS.md - verify all tools documented
- [ ] Read through README.md - verify good user experience

#### Task 6.2: Check for orphaned content ⏳
**Status**: Not Started

- [ ] Search for any important content from old files that wasn't migrated
- [ ] Verify examples are comprehensive
- [ ] Verify no critical information was lost

#### Task 6.3: Test documentation ⏳
**Status**: Not Started

- [ ] Verify all markdown renders correctly
- [ ] Verify all internal links work
- [ ] Verify code blocks are properly formatted
- [ ] Check file line counts match estimates

---

## Progress Tracker

**Phase 1**: 5/5 tasks complete (100%) ✅
**Phase 2**: 1/1 tasks complete (100%) ✅
**Phase 3**: 0/4 tasks complete (0%)
**Phase 4**: 0/1 tasks complete (0%)
**Phase 5**: 0/1 tasks complete (0%)
**Phase 6**: 0/3 tasks complete (0%)

**Overall**: 6/15 tasks complete (40%)

---

## Notes

- Keep STRUCTURE_REFACTOR_REPORT.md untouched
- Keep orchestration/ files as-is (only update references if needed)
- Keep mcp_tools/README.md as-is (reference from MCP_TOOLS.md)
- All new docs should use v2.0 terminology (_CONTENT.md not _FULL.md)

---

**Last Updated**: 2025-10-17
