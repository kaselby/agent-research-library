# Report Structure Template

This template shows the flexible, hierarchical structure for research reports that enables efficient context loading.

## Core Principles

1. **Flexible Depth**: Each branch can have different depths (1-3 levels max) based on natural complexity
2. **True Modularity**: Every file is independently loadable with clear boundaries
3. **Progressive Disclosure**: Start with overviews, drill down only as needed
4. **No Forced Structure**: Don't create artificial subdivisions where they don't exist

## Directory Layout

```
{REPORT_ID}/
├── metadata.json                       # Enhanced section registry with tree structure
├── _OVERVIEW.md                        # Report-level overview (300-500 words)
│
└── sections/                           # All report sections
    │
    ├── SIMPLE_TOPIC.md                # Simple topics are just files (1000-2000 words)
    │
    ├── MODERATE_TOPIC/                # Topics with natural subdivisions
    │   ├── _OVERVIEW.md               # Section overview & navigation (200-400 words)
    │   ├── _CONTENT.md                # Main section content (1500-2500 words)
    │   ├── SUBTOPIC_A.md              # Focused subsection (800-1500 words)
    │   └── SUBTOPIC_B.md              # Another subsection
    │
    └── COMPLEX_TOPIC/                 # Complex hierarchical topic
        ├── _OVERVIEW.md               # High-level overview
        ├── _CONTENT.md                # Core concepts (optional if fully decomposed)
        │
        ├── SUBSYSTEM_A/               # Major subsystem
        │   ├── _OVERVIEW.md
        │   ├── _CONTENT.md
        │   ├── COMPONENT_1.md         # Specific component
        │   └── COMPONENT_2.md
        │
        └── SUBSYSTEM_B.md             # Simple subsystem (just a file)
```

## File Types

### Report-Level _OVERVIEW.md
- **Purpose**: High-level report summary and navigation
- **Target Size**: 300-500 words
- **Location**: Report root
- **Contents**:
  - Executive summary of entire report
  - Major sections overview
  - Cross-references to related reports

### Section _OVERVIEW.md
- **Purpose**: Section navigation and summary
- **Target Size**: 200-400 words
- **Location**: Section directories
- **Contents**:
  - Section purpose and scope
  - Subsection roadmap (if applicable)
  - Key concepts preview

### _CONTENT.md
- **Purpose**: Main section content (replaces _FULL.md)
- **Target Size**: 1500-2500 words
- **Location**: Section directories (optional if fully decomposed)
- **Contents**:
  - Core technical content for this level
  - Detailed implementation
  - Code references with file:line notation
  - NOT a duplicate of child content

### Standalone .md Files
- **Purpose**: Self-contained topics or focused subsections
- **Target Size**: 800-1500 words (2000 words max for top-level)
- **Contents**:
  - Complete coverage of specific topic
  - Can include section markers for partial loading
  - Code references
  - Related section links

## Section Markers for Partial Loading

For files >1500 words, use HTML comment markers to enable partial content loading:

```markdown
<!-- section:overview -->
## Overview
This component handles authentication for all API requests...
(content continues)
<!-- /section:overview -->

<!-- section:architecture -->
## Core Architecture
The architecture consists of three main layers...
(content continues)
<!-- /section:architecture -->
```

**Guidelines:**
- Use lowercase, hyphenated section IDs (e.g., `core-concepts`, `api-reference`)
- Place markers around logical content units (200-500 words each)
- Small files (<1500 words) don't need markers - always loaded fully
- Markers are optional but recommended for files >2000 words

## Naming Conventions

### Directories
- Use SCREAMING_SNAKE_CASE
- Descriptive names matching content
- Examples: `CORE_ARCHITECTURE`, `LLM_INTEGRATION`, `ERROR_HANDLING`

### Files
- Reserved names: `_OVERVIEW.md`, `_CONTENT.md`
- Component files: SCREAMING_SNAKE_CASE with `.md` extension
- Examples: `AUTHENTICATION.md`, `MESSAGE_MANAGER.md`, `API_ADAPTER.md`

### Section Keys
- Format: `REPORT_ID:PATH:TO:SECTION[#marker]`
- Always includes report ID prefix
- Hierarchical with colon separators
- Optional `#marker` for subsection within file
- Examples:
  - `ACME_API:AUTHENTICATION` (standalone file)
  - `ACME_API:CORE_SYSTEM:ARCHITECTURE` (nested section)
  - `ACME_API:CORE_SYSTEM:CLIENT#overview` (specific marker in file)
  - `ACME_API:INTEGRATIONS:PROVIDER_X` (component in moderate section)

## Example Structures

### Minimal Report (flat structure)
```
SIMPLE_LIBRARY/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── INSTALLATION.md           # 1000 words
    ├── CORE_CONCEPTS.md          # 1500 words
    └── API_REFERENCE.md          # 1800 words
```

### Mixed-Depth Report (natural hierarchy)
```
WEB_FRAMEWORK/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── GETTING_STARTED.md        # Simple standalone topic
    │
    ├── CORE_SYSTEM/              # Complex topic with subsections
    │   ├── _OVERVIEW.md
    │   ├── _CONTENT.md           # Core system concepts
    │   ├── ROUTING.md            # 1200 words
    │   ├── MIDDLEWARE.md         # 1000 words
    │   └── CONTROLLERS.md        # 1400 words
    │
    ├── DATABASE/                 # Moderate complexity
    │   ├── _OVERVIEW.md
    │   ├── ORM_BASICS.md         # 1500 words
    │   └── MIGRATIONS.md         # 800 words
    │
    └── DEPLOYMENT.md             # Simple standalone topic
```

### Complex Report (3 levels, only where needed)
```
CLOUD_PLATFORM/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── ARCHITECTURE.md           # Top-level standalone
    │
    ├── COMPUTE/
    │   ├── _OVERVIEW.md
    │   ├── _CONTENT.md
    │   │
    │   ├── CONTAINERS/           # Needs further breakdown
    │   │   ├── _OVERVIEW.md
    │   │   ├── DOCKER.md
    │   │   └── KUBERNETES.md
    │   │
    │   ├── SERVERLESS.md        # Simple subsection
    │   └── VMS.md               # Simple subsection
    │
    └── NETWORKING/
        ├── _OVERVIEW.md
        ├── LOAD_BALANCERS.md
        └── CDN.md
```

## Best Practices

1. **Let structure emerge naturally** - Don't force subdivisions where they don't exist
2. **Use _OVERVIEW.md** for directories, standalone .md for simple topics
3. **Avoid _CONTENT.md** if section is fully decomposed into subsections
4. **Target word counts**:
   - Standalone files: 800-1500 words (2000 max for top-level)
   - _CONTENT.md: 1500-2500 words
   - _OVERVIEW.md: 200-400 words (sections), 300-500 words (report)
5. **Add section markers** for files >1500 words to enable partial loading
6. **Use hierarchical keys** consistently (REPORT:SECTION:SUBSECTION)
7. **Document code locations** with `file.py:line_start-line_end` format
8. **Cross-reference** related sections with `[SECTION_KEY]` syntax
9. **Maximum depth**: 3 levels (use sparingly)
10. **Maintain key stability** - don't rename keys after creation
