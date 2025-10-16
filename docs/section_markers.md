# Section Markers Documentation

## Overview

Section markers enable partial loading of content from larger markdown files, improving context efficiency when querying research reports. They use HTML comments that don't render in markdown viewers.

## Marker Format

```markdown
<!-- section:section-id -->
## Section Title
Content for this section...
<!-- /section:section-id -->
```

## Rules and Guidelines

### Marker IDs
- Use lowercase, hyphenated format (e.g., `core-concepts`, `api-reference`)
- Keep IDs short but descriptive
- Must be unique within the file
- Should match the section's conceptual purpose, not necessarily the header text

### When to Use Markers
- **Required**: Files >2000 words
- **Recommended**: Files 1500-2000 words
- **Optional**: Files 1000-1500 words
- **Not needed**: Files <1000 words (always loaded fully)

### Content Size
- Each marked section should be 200-500 words
- Sections can be nested if needed
- Don't create markers for trivial content (<100 words)

## Examples

### Basic Usage
```markdown
# Authentication System

<!-- section:overview -->
## Overview
The authentication system provides secure user authentication using JWT tokens
with OAuth2 support. It integrates with multiple identity providers and supports
both session-based and token-based authentication strategies.
<!-- /section:overview -->

<!-- section:architecture -->
## Core Architecture
The system is built on three main components:
1. **Token Manager**: Handles JWT creation, validation, and refresh
2. **Provider Interface**: Abstracts OAuth provider differences
3. **Session Store**: Manages active user sessions

Each component is designed for high availability...
<!-- /section:architecture -->

<!-- section:configuration -->
## Configuration
Configure the authentication system through environment variables...
<!-- /section:configuration -->
```

### Nested Sections (Advanced)
```markdown
<!-- section:api -->
## API Reference

<!-- section:api.auth -->
### Authentication Endpoints
POST /auth/login - User login
POST /auth/logout - User logout
<!-- /section:api.auth -->

<!-- section:api.tokens -->
### Token Management
POST /auth/refresh - Refresh access token
GET /auth/validate - Validate current token
<!-- /section:api.tokens -->

<!-- /section:api -->
```

## Section References

To reference a specific section within a file:

- Full file: `REPORT_ID:SECTION:SUBSECTION`
- Specific marker: `REPORT_ID:SECTION:SUBSECTION#marker-id`
- Nested marker: `REPORT_ID:SECTION:SUBSECTION#parent.child`

Examples:
- `ACME_API:AUTH:JWT_HANDLER#configuration`
- `WEB_FRAMEWORK:CORE_SYSTEM:ROUTING#middleware`

## Extraction Algorithm

The section extraction tool follows this priority:

1. **Exact marker match**: Find `<!-- section:marker-id -->` boundaries
2. **Header fallback**: Find `## Header` matching the marker ID
3. **Line range fallback**: Use cached line numbers from metadata
4. **Full file fallback**: Return entire file if section not found

## Metadata Storage

Section information is stored in the report's metadata.json:

```json
{
  "key": "REPORT_ID:SECTION:SUBSECTION",
  "path": "sections/SECTION/SUBSECTION.md",
  "markers": [
    {
      "id": "overview",
      "title": "Overview",
      "lines": [10, 45],
      "words": 250
    },
    {
      "id": "architecture",
      "title": "Core Architecture",
      "lines": [46, 120],
      "words": 450
    }
  ]
}
```

## Best Practices

1. **Logical boundaries**: Align markers with conceptual sections, not arbitrary word counts
2. **Consistent naming**: Use the same ID pattern throughout the report
3. **Update metadata**: Keep line numbers in sync when editing
4. **Test extraction**: Verify markers work before finalizing
5. **Avoid over-segmentation**: Don't create markers for every subsection
6. **Document markers**: List available markers in _OVERVIEW.md files

## Implementation Notes

- Markers are preserved during file edits
- Line numbers in metadata are hints, not authoritative
- Extraction tools should gracefully handle missing markers
- Validators should check marker syntax and uniqueness