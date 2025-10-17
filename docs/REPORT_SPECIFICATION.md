# Research Report Specification v2.0

This document defines the complete technical specification for Agent Research Library reports.

## Overview

Research reports use a flexible hierarchical structure that enables efficient context loading through progressive disclosure. Reports consist of markdown files organized in directories, with metadata tracking the complete section tree.

**Key Characteristics:**
- Flexible depth (1-3 levels based on natural complexity)
- Mixed structures (simple topics as files, complex as directories)
- Independent file loading (every file is self-contained)
- Section markers for partial content extraction
- Hierarchical section keys for precise referencing

## Schema Version

**Current Version:** 2.0

**Breaking Changes from 1.0:**
- `_FULL.md` deprecated → replaced by `_CONTENT.md`
- Standalone files are first-class citizens (not subdirectories)
- Optional `_CONTENT.md` (can be omitted if section fully decomposed)
- `type` field added to metadata ("leaf" vs "composite")
- `markers` array added for section-based loading

## Directory Structure Patterns

### Basic Report Structure

```
{REPORT_ID}/
├── metadata.json                 # Section registry and report metadata
├── _OVERVIEW.md                  # Report-level summary (300-500 words)
└── sections/                     # All report content
    ├── TOPIC_A.md               # Standalone file (leaf node)
    ├── TOPIC_B/                 # Directory with children (composite)
    │   ├── _OVERVIEW.md         # Section navigation (200-400 words)
    │   ├── _CONTENT.md          # Core concepts (optional, 1500-2500 words)
    │   ├── SUBTOPIC_1.md        # Child section (800-1500 words)
    │   └── SUBTOPIC_2.md        # Child section
    └── TOPIC_C/                 # Complex nested structure
        ├── _OVERVIEW.md
        ├── SUBSECTION_A/
        │   ├── _OVERVIEW.md
        │   ├── DETAIL_1.md
        │   └── DETAIL_2.md
        └── SUBSECTION_B.md
```

### Structure Types

#### Flat Report
All content as standalone files, no nesting:

```
SIMPLE_LIBRARY/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── INSTALLATION.md          # 1000 words
    ├── CORE_CONCEPTS.md         # 1500 words
    └── API_REFERENCE.md         # 1800 words
```

#### Mixed-Depth Report
Natural hierarchy with varying depths:

```
WEB_FRAMEWORK/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── GETTING_STARTED.md       # Standalone file
    │
    ├── CORE_SYSTEM/             # Complex directory
    │   ├── _OVERVIEW.md
    │   ├── _CONTENT.md          # Core system concepts
    │   ├── ROUTING.md
    │   └── MIDDLEWARE.md
    │
    └── DEPLOYMENT.md            # Standalone file
```

#### Deep Hierarchy
Three levels, used sparingly:

```
ENTERPRISE_PLATFORM/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── ARCHITECTURE.md          # Level 1 standalone
    │
    └── MICROSERVICES/           # Level 1 directory
        ├── _OVERVIEW.md
        ├── _CONTENT.md
        │
        ├── API_GATEWAY/         # Level 2 directory
        │   ├── _OVERVIEW.md
        │   ├── ROUTING.md       # Level 3 leaf
        │   └── AUTH.md          # Level 3 leaf
        │
        └── SERVICE_MESH.md      # Level 2 standalone
```

## File Types and Naming

### Reserved Filenames

| Filename | Location | Purpose | Size Range |
|----------|----------|---------|------------|
| `_OVERVIEW.md` | Report root | Report summary and navigation | 300-500 words |
| `_OVERVIEW.md` | Section directories | Section summary and child navigation | 200-400 words |
| `_CONTENT.md` | Section directories | Core concepts for this section (optional) | 1500-2500 words |

### Custom Filenames

| Pattern | Usage | Size Range |
|---------|-------|------------|
| `{TOPIC}.md` | Standalone topics (leaf nodes) | 800-1500 words (L2-L3) |
| `{TOPIC}.md` | Standalone topics (top-level) | 1000-2000 words (L1) |
| `{TOPIC}/` | Section directories (composite nodes) | Contains multiple files |

**Naming Convention:** All custom names use `SCREAMING_SNAKE_CASE`

Examples: `AUTHENTICATION.md`, `CORE_ARCHITECTURE/`, `REQUEST_HANDLER.md`

### File Type Semantics

**Report _OVERVIEW.md:**
- Entry point for entire report
- Lists major sections with brief descriptions
- Provides executive summary
- May include cross-references to related reports

**Section _OVERVIEW.md:**
- Navigation aid for section children
- Explains section scope and purpose
- Lists and describes child sections
- Preview of key concepts covered

**Section _CONTENT.md:**
- Core concepts that apply to entire section
- Content NOT duplicated in children
- Optional - omit if section fully decomposed
- Focus on section-level patterns and integration

**Standalone Files:**
- Complete coverage of single topic
- Self-contained (can be read independently)
- May include section markers for partial loading
- Can appear at any hierarchy level

## Section Keys

### Format

Section keys use hierarchical colon-separated format:

```
{REPORT_ID}:{L1_SECTION}:{L2_COMPONENT}:{L3_DETAIL}
```

### Examples

```
ACME_API:AUTHENTICATION
ACME_API:AUTHENTICATION:OAUTH
ACME_API:CORE_ARCHITECTURE:CLIENT_MODEL
TASKFLOW:ORCHESTRATION:TASK_DELEGATION:RESULT_AGGREGATION
```

### Key Rules

1. **SCREAMING_SNAKE_CASE** for all components
2. **Hierarchical** with colon `:` separators
3. **Unique within report** - no duplicates
4. **Stable** - never change after creation (breaks references)
5. **Self-documenting** - name indicates content
6. **Report prefix** - always starts with REPORT_ID

### Key Construction

- Standalone file `sections/TOPIC.md` → `REPORT_ID:TOPIC`
- Directory `sections/TOPIC/` → `REPORT_ID:TOPIC`
- Nested file `sections/L1/L2.md` → `REPORT_ID:L1:L2`
- Deep nested `sections/L1/L2/L3.md` → `REPORT_ID:L1:L2:L3`

## Section Markers

Section markers enable partial content loading from larger files using HTML comments.

### Marker Syntax

```markdown
<!-- section:marker-id -->
## Section Heading
Content for this marked section...
<!-- /section:marker-id -->
```

### Marker ID Format

- **lowercase-hyphenated:** e.g., `overview`, `core-architecture`, `api-reference`
- **Descriptive:** Indicates conceptual content, not necessarily matching heading
- **Unique:** Within file
- **Consistent:** Same ID pattern throughout report

### When to Use Markers

| File Size | Markers Required |
|-----------|------------------|
| <1000 words | Not needed (always loaded fully) |
| 1000-1500 words | Optional |
| 1500-2000 words | Recommended |
| >2000 words | Required |

### Marker Guidelines

- Each marked section: 200-500 words
- Create markers at logical conceptual boundaries
- Don't over-segment (<100 word sections)
- Markers can nest if needed (dot notation: `api.auth`, `api.tokens`)
- Document available markers in section _OVERVIEW.md

### Marker Examples

#### Basic Markers

```markdown
# Authentication System

<!-- section:overview -->
## Overview
High-level description of authentication architecture and approach.
Multiple paragraphs covering the essential concepts...
<!-- /section:overview -->

<!-- section:architecture -->
## Core Architecture
Technical details about the three-tier authentication system including
token management, provider abstraction, and session handling...
<!-- /section:architecture -->

<!-- section:configuration -->
## Configuration
Environment variables, config files, and runtime options for
customizing authentication behavior...
<!-- /section:configuration -->
```

#### Nested Markers

```markdown
<!-- section:api -->
## API Reference

<!-- section:api.auth -->
### Authentication Endpoints
POST /auth/login - User authentication
POST /auth/logout - Session termination
<!-- /section:api.auth -->

<!-- section:api.tokens -->
### Token Management
POST /auth/refresh - Token refresh
GET /auth/validate - Token validation
<!-- /section:api.tokens -->

<!-- /section:api -->
```

### Marker References

Markers can be referenced in section keys using `#` notation:

```
REPORT_ID:SECTION:SUBSECTION#marker-id
REPORT_ID:AUTHENTICATION:OAUTH#architecture
WEB_FRAMEWORK:CORE_SYSTEM:ROUTING#middleware
```

### Metadata Storage

Markers are tracked in metadata.json for efficient lookup:

```json
{
  "key": "REPORT_ID:AUTHENTICATION",
  "path": "sections/AUTHENTICATION.md",
  "type": "leaf",
  "markers": ["overview", "architecture", "configuration"],
  "word_count": 1800
}
```

## Word Count Guidelines

### Target Ranges

| File Type | Minimum | Target | Maximum | Notes |
|-----------|---------|--------|---------|-------|
| Report _OVERVIEW.md | 300 | 400 | 500 | Concise entry point |
| Section _OVERVIEW.md | 200 | 300 | 400 | Navigation focused |
| Section _CONTENT.md | 1500 | 2000 | 2500 | Core concepts only |
| L1 Standalone File | 1000 | 1500 | 2000 | Top-level topics |
| L2-L3 Standalone File | 800 | 1200 | 1500 | Focused components |

### Decision Criteria

| Content Scope | Recommended Structure |
|---------------|----------------------|
| <1000 words total | Single standalone file |
| 1000-2000 words | Single file OR split if natural divisions exist |
| 2000-3000 words | Directory with _OVERVIEW.md, _CONTENT.md, and children |
| >3000 words | Must split - directory with multiple children |

### Validation

Word counts are guidelines, not strict limits. Validation tools warn when counts significantly exceed ranges but don't block creation.

## Structure Examples

### Example 1: Flat Structure (Simple Library)

```
CONFIG_FORMAT/
├── metadata.json
├── _OVERVIEW.md                 # 400 words
└── sections/
    ├── YAML_SCHEMA.md           # 1200 words
    └── VALIDATION.md            # 900 words
```

**Section Keys:**
- `CONFIG_FORMAT:YAML_SCHEMA`
- `CONFIG_FORMAT:VALIDATION`

**Characteristics:** Simple, focused topic with clear divisions

---

### Example 2: Mixed Depth (API Client)

```
ACME_API/
├── metadata.json
├── _OVERVIEW.md                 # 500 words
└── sections/
    ├── CORE_ARCHITECTURE/
    │   ├── _OVERVIEW.md         # 400 words
    │   ├── _CONTENT.md          # 2200 words - Core patterns
    │   ├── CLIENT_MODEL.md      # 800 words
    │   ├── REQUEST_HANDLER.md   # 900 words
    │   └── STATE_MANAGEMENT.md  # 700 words
    │
    ├── AUTHENTICATION/
    │   ├── _OVERVIEW.md         # 350 words
    │   ├── OAUTH.md             # 1200 words
    │   ├── API_KEYS.md          # 800 words
    │   └── TOKEN_REFRESH.md     # 600 words
    │
    └── CONFIGURATION.md         # 1000 words - Standalone
```

**Section Keys (12 total):**
- L1: `ACME_API:CORE_ARCHITECTURE`, `ACME_API:AUTHENTICATION`, `ACME_API:CONFIGURATION`
- L2: `ACME_API:CORE_ARCHITECTURE:CLIENT_MODEL`, `ACME_API:AUTHENTICATION:OAUTH`, etc.

**Characteristics:** Moderate complexity, mixed standalone/directory structure

---

### Example 3: Deep Hierarchy (Complex Framework)

```
TASKFLOW_FRAMEWORK/
├── metadata.json
├── _OVERVIEW.md                 # 600 words
└── sections/
    ├── WORKFLOW_SYSTEM/
    │   ├── _OVERVIEW.md         # 450 words
    │   ├── _CONTENT.md          # 2400 words
    │   ├── WORKFLOW_LIFECYCLE.md # 1000 words
    │   └── STEP_INTEGRATION.md  # 900 words
    │
    ├── TASK_ORCHESTRATION/
    │   ├── _OVERVIEW.md         # 400 words
    │   ├── _CONTENT.md          # 1800 words
    │   │
    │   ├── SEQUENTIAL_TASKS/    # L2 directory
    │   │   ├── _OVERVIEW.md     # 250 words
    │   │   ├── DELEGATION.md    # 700 words - L3
    │   │   └── AGGREGATION.md   # 600 words - L3
    │   │
    │   └── PARALLEL_TASKS/
    │       ├── _OVERVIEW.md     # 200 words
    │       └── SYNC.md          # 800 words - L3
    │
    └── EXECUTION_BACKEND/
        ├── _OVERVIEW.md         # 350 words
        ├── ADAPTERS.md          # 1100 words
        └── SCHEDULING.md        # 900 words
```

**Section Keys (includes L3):**
- L1: `TASKFLOW_FRAMEWORK:TASK_ORCHESTRATION`
- L2: `TASKFLOW_FRAMEWORK:TASK_ORCHESTRATION:SEQUENTIAL_TASKS`
- L3: `TASKFLOW_FRAMEWORK:TASK_ORCHESTRATION:SEQUENTIAL_TASKS:DELEGATION`

**Characteristics:** High complexity, uses maximum depth where necessary

## Metadata Schema

### Index Schema (index.json)

Located at storage root (`~/.claude/agent_research_library/projects/{project}/index.json` or `~/.claude/agent_research_library/_global/index.json`).

```json
{
  "version": "1.0",
  "scope": "project" | "global",
  "project_path": "/absolute/path/to/project",
  "created": "2025-10-17T10:00:00Z",
  "updated": "2025-10-17T15:30:00Z",
  "reports": [
    {
      "id": "REPORT_ID",
      "title": "Human Readable Report Title",
      "path": "REPORT_ID/",
      "created": "2025-10-17T10:00:00Z",
      "updated": "2025-10-17T12:30:00Z",
      "version": "1.2",
      "tags": ["tag1", "tag2"],
      "section_count": 12,
      "confidence": "high" | "medium" | "low"
    }
  ]
}
```

### Report Metadata Schema (metadata.json)

Located at report root (`{REPORT_ID}/metadata.json`).

```json
{
  "id": "REPORT_ID",
  "title": "Report Title",
  "created": "2025-10-17T10:00:00Z",
  "updated": "2025-10-17T12:30:00Z",
  "version": "1.0",
  "schema_version": "2.0",
  "created_by_arl_version": "0.2.0",
  "compatible_with": ["2.0"],
  "author": "report-creator",
  "scope": "project" | "global",
  "project_id": "project-slug",
  "project_name": "Project Name",
  "project_path": "/absolute/path/to/project",
  "confidence_level": "high" | "medium" | "low",
  "tags": ["tag1", "tag2"],

  "dependencies": {
    "internal": ["OTHER_REPORT_ID"],
    "external": ["library-name", "framework"]
  },

  "cross_references": {
    "allowed_scopes": ["same_project", "global"],
    "linked_reports": [
      {
        "report_id": "RELATED_REPORT",
        "scope": "project" | "global",
        "relationship": "integration" | "reference" | "dependency"
      }
    ]
  },

  "sections": [
    {
      "key": "REPORT_ID:SIMPLE_TOPIC",
      "title": "Simple Topic Title",
      "type": "leaf",
      "path": "sections/SIMPLE_TOPIC.md",
      "level": 1,
      "parent": null,
      "word_count": 1500,
      "markers": ["overview", "implementation"],
      "confidence": "high",
      "last_updated": "2025-10-17T10:00:00Z"
    },
    {
      "key": "REPORT_ID:COMPLEX_TOPIC",
      "title": "Complex Topic with Children",
      "type": "composite",
      "path": "sections/COMPLEX_TOPIC/",
      "level": 1,
      "parent": null,
      "files": {
        "overview": "_OVERVIEW.md",
        "content": "_CONTENT.md"
      },
      "word_count": {
        "overview": 300,
        "content": 2000
      },
      "children": [
        "REPORT_ID:COMPLEX_TOPIC:SUBTOPIC_A",
        "REPORT_ID:COMPLEX_TOPIC:SUBTOPIC_B"
      ],
      "confidence": "high",
      "last_updated": "2025-10-17T10:00:00Z"
    }
  ],

  "statistics": {
    "total_sections": 8,
    "total_words": 12350,
    "depth_distribution": {
      "1": 3,
      "2": 4,
      "3": 1
    },
    "max_depth": 3,
    "leaf_sections": 5,
    "composite_sections": 3
  }
}
```

### Section Entry Schema

**Leaf Section (type: "leaf"):**
```json
{
  "key": "REPORT_ID:SECTION:SUBSECTION",
  "title": "Human Readable Title",
  "type": "leaf",
  "path": "sections/SECTION/SUBSECTION.md",
  "level": 2,
  "parent": "REPORT_ID:SECTION",
  "word_count": 1200,
  "markers": ["overview", "architecture", "examples"],
  "confidence": "high" | "medium" | "low",
  "last_updated": "2025-10-17T10:00:00Z"
}
```

**Composite Section (type: "composite"):**
```json
{
  "key": "REPORT_ID:SECTION",
  "title": "Section Title",
  "type": "composite",
  "path": "sections/SECTION/",
  "level": 1,
  "parent": null,
  "files": {
    "overview": "_OVERVIEW.md",
    "content": "_CONTENT.md"
  },
  "word_count": {
    "overview": 300,
    "content": 2000
  },
  "children": [
    "REPORT_ID:SECTION:CHILD_A",
    "REPORT_ID:SECTION:CHILD_B"
  ],
  "confidence": "high",
  "last_updated": "2025-10-17T10:00:00Z"
}
```

**Notes:**
- `content` in `files` is optional for composite sections
- `word_count` for composite is object when `content` exists, otherwise just `overview`
- `children` array lists child section keys
- `markers` array only for leaf sections with markers

## Validation Rules

### Structural Requirements

**Required Files:**
- `metadata.json` (valid JSON)
- `_OVERVIEW.md` (at report root)
- `sections/` (directory)

**Section Files:**
- Leaf sections: Must have corresponding `.md` file at `path`
- Composite sections: Must have `_OVERVIEW.md` at `path`
- Composite sections: `_CONTENT.md` is optional

**Naming:**
- All directories: `SCREAMING_SNAKE_CASE`
- All files: `SCREAMING_SNAKE_CASE.md` or reserved names
- Section keys: Match directory/file structure

### Metadata Requirements

**Required Fields (metadata.json):**
- `id`, `title`, `created`, `updated`, `version`
- `schema_version` (must be "2.0")
- `author`, `scope`, `confidence_level`
- `sections` (array, non-empty)
- `statistics` (object with required counts)

**Section Fields:**
- `key`, `title`, `type`, `path`, `level`, `parent`
- `word_count`, `confidence`, `last_updated`
- Leaf: `markers` array (can be empty)
- Composite: `children` array (can be empty), `files` object

### Consistency Rules

**Section Registry:**
- All sections in metadata must have corresponding files
- All section keys must be unique
- Parent-child relationships must be valid
- Level numbers must be sequential (1, 2, 3)

**Cross-References:**
- Project reports can reference: same project + global
- Global reports can reference: only global
- Referenced sections must exist in metadata

**Word Counts:**
- Must be positive integers
- Tracked per file for accuracy
- Warnings if outside recommended ranges

## Versioning

### Report Versions

Format: `major.minor`

**Major Increment:** Structural changes
- New sections added
- Sections reorganized
- Hierarchy changed

**Minor Increment:** Content updates
- Existing sections modified
- Word counts updated
- No structure changes

### Schema Versions

Current: `2.0`

Schema version tracks metadata format, not report content. Increment when metadata structure changes.

## Cross-References

### Reference Format

Cross-references use bracket notation with section keys:

```markdown
See [REPORT_ID:SECTION:SUBSECTION] for details.

Related: [REPORT_ID:OTHER_SECTION]

With marker: [REPORT_ID:AUTH:OAUTH#configuration]
```

### Scope Rules

| Report Scope | Can Reference |
|--------------|---------------|
| Project | Same project sections + global sections |
| Global | Only global sections |

### Validation

- Linter checks that referenced sections exist
- Warns on broken references
- Verifies scope rules are followed

---

**Specification Version:** 2.0
**Last Updated:** 2025-10-17
