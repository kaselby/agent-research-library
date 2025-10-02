# Report Structure Template

This template shows the recommended directory structure for a research report.

## Directory Layout

```
{REPORT_ID}/
├── metadata.json                       # Report metadata (see metadata_template.json)
├── _OVERVIEW.md                        # High-level report overview and TOC
│
└── sections/                           # All report sections
    │
    ├── {L1_SECTION}/                   # Level 1 section (major subsystem)
    │   ├── _FULL.md                    # Complete section content
    │   ├── _OVERVIEW.md                # Section summary and roadmap
    │   ├── {L2_COMPONENT_A}.md         # Level 2 subsection
    │   └── {L2_COMPONENT_B}.md         # Level 2 subsection
    │
    └── {ANOTHER_L1_SECTION}/           # Another L1 section
        ├── _FULL.md
        ├── _OVERVIEW.md
        │
        └── {L2_SUBSECTION}/            # L2 with further breakdown (rare)
            ├── _FULL.md
            ├── _OVERVIEW.md
            └── {L3_COMPONENT}.md       # Level 3 (only if necessary)
```

## File Types

### _OVERVIEW.md
- **Purpose**: High-level summary and navigation
- **Target Size**: 300-500 words
- **Contents**:
  - Executive summary
  - Section roadmap
  - Cross-references to related reports

### _FULL.md
- **Purpose**: Complete section content
- **Target Size**:
  - L1: 2000-4000 words
  - L2: 1000-2000 words (if has children)
- **Contents**:
  - All subsection content combined
  - Comprehensive technical details
  - Code references with file:line notation

### {COMPONENT}.md
- **Purpose**: Specific implementation or variant
- **Target Size**: 600-1000 words
- **Contents**:
  - Focused on single component
  - Implementation details
  - Code references
  - Related section links

## Naming Conventions

### Directories
- Use SCREAMING_SNAKE_CASE
- Descriptive names matching content
- Examples: `CORE_ARCHITECTURE`, `LLM_INTEGRATION`, `ERROR_HANDLING`

### Files
- Reserved names: `_OVERVIEW.md`, `_FULL.md`
- Component files: SCREAMING_SNAKE_CASE with `.md` extension
- Examples: `GROQ.md`, `MESSAGE_MANAGER.md`, `API_ADAPTER.md`

### Section Keys
- Format: `REPORT_ID:L1_SECTION:L2_COMPONENT:L3_DETAIL`
- Always includes report ID prefix
- Hierarchical with colon separators
- Examples:
  - `ACME_API:CORE_ARCHITECTURE`
  - `ACME_API:CORE_ARCHITECTURE:CLIENT_MODEL`
  - `ACME_API:AUTHENTICATION:OAUTH:TOKEN_REFRESH`

## Example Structures

### Simple Report (1 level)
```
SIMPLE_TOPIC/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── MAIN_CONCEPT/
    │   ├── _OVERVIEW.md
    │   └── _FULL.md
    └── USAGE_PATTERNS/
        ├── _OVERVIEW.md
        └── _FULL.md
```

### Moderate Report (2 levels)
```
MODERATE_TOPIC/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── CORE_SYSTEM/
    │   ├── _FULL.md
    │   ├── _OVERVIEW.md
    │   ├── COMPONENT_A.md
    │   └── COMPONENT_B.md
    └── INTEGRATIONS/
        ├── _FULL.md
        ├── _OVERVIEW.md
        ├── PROVIDER_X.md
        └── PROVIDER_Y.md
```

### Complex Report (3 levels)
```
COMPLEX_TOPIC/
├── metadata.json
├── _OVERVIEW.md
└── sections/
    ├── MAJOR_SUBSYSTEM/
    │   ├── _FULL.md
    │   ├── _OVERVIEW.md
    │   │
    │   ├── COMPONENT_GROUP/
    │   │   ├── _FULL.md
    │   │   ├── _OVERVIEW.md
    │   │   ├── IMPL_A.md
    │   │   └── IMPL_B.md
    │   │
    │   └── SIMPLE_COMPONENT.md
    │
    └── ANOTHER_SUBSYSTEM/
        └── ...
```

## Best Practices

1. **Always include _OVERVIEW.md** at each directory level
2. **Create _FULL.md** for any section with children
3. **Keep leaf sections focused** (600-1000 words)
4. **Use hierarchical keys** consistently
5. **Include metadata.json** at report root
6. **Cross-reference** related sections with `[SECTION_KEY]` syntax
7. **Document code locations** with `file.py:line_start-line_end` format
8. **Update timestamps** in metadata when content changes
9. **Maintain key stability** - don't rename keys after creation
10. **Sync to backup** after creation or major updates
