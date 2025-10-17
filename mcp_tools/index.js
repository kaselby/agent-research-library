#!/usr/bin/env node

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import { createHash } from 'crypto';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Centralized storage path
const ARL_BASE = path.join(process.env.HOME, '.claude', 'agent_research_library');

/**
 * Get project ID from git root or working directory
 */
async function getProjectId(workingDir) {
  try {
    // Try to get git root
    const {stdout: gitRoot} = await execAsync('git rev-parse --show-toplevel', {cwd: workingDir});
    const rootPath = gitRoot.trim();

    // Hash the git root path to create stable project ID
    return createHash('sha256').update(rootPath).digest('hex').slice(0, 16);
  } catch {
    // Fallback: use directory name + path hash
    const dirName = path.basename(workingDir);
    return createHash('sha256').update(`${dirName}-${workingDir}`).digest('hex').slice(0, 16);
  }
}

/**
 * Get project name from git or directory
 */
async function getProjectName(workingDir) {
  try {
    // Try git remote first
    const {stdout: remote} = await execAsync('git remote get-url origin', {cwd: workingDir});
    return path.basename(remote.trim(), '.git');
  } catch {
    try {
      // Try git root directory name
      const {stdout: gitRoot} = await execAsync('git rev-parse --show-toplevel', {cwd: workingDir});
      return path.basename(gitRoot.trim());
    } catch {
      // Fallback: current directory name
      return path.basename(workingDir);
    }
  }
}

/**
 * Get the project-level research index
 */
async function getProjectIndex(projectId) {
  const projectPath = path.join(ARL_BASE, 'projects', projectId);
  const indexPath = path.join(projectPath, 'index.json');

  try {
    const content = await fs.readFile(indexPath, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return null;
    }
    throw error;
  }
}

/**
 * Get the global research index
 */
async function getGlobalIndex() {
  const globalPath = path.join(ARL_BASE, '_global', 'index.json');

  try {
    const content = await fs.readFile(globalPath, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return null;
    }
    throw error;
  }
}

// ============================================================================
// DISABLED TOOL: check_report_exists
// ============================================================================
// This tool is disabled in favor of the research-report-finder agent, which
// provides intelligent fuzzy search with synonyms. The code is preserved here
// for reference in case we want to re-enable it in the future.
//
// To re-enable:
// 1. Update to new SDK API (see registerTool pattern below)
// 2. Register with: server.registerTool('check_report_exists', ...)
// ============================================================================
/*
async function checkReportExists(args) {
  const workingDir = args.working_directory || process.cwd();
  const topicNormalized = args.topic.toLowerCase().replace(/[^a-z0-9_]/g, '_');

  // Get project ID for this working directory
  const projectId = await getProjectId(workingDir);
  const projectName = await getProjectName(workingDir);

  // Try project-level first
  const projectIndex = await getProjectIndex(projectId);
  if (projectIndex && projectIndex.reports) {
    const found = projectIndex.reports.find(r =>
      r.topic_normalized === topicNormalized ||
      r.topic.toLowerCase() === args.topic.toLowerCase()
    );

    if (found) {
      const reportPath = path.join(ARL_BASE, 'projects', projectId, found.directory);
      return {
        exists: true,
        scope: 'project',
        report_path: reportPath,
        project_id: projectId,
        project_name: projectName,
        topic: found.topic,
        created: found.created,
        updated: found.updated,
        message: `Report found in project "${projectName}": ${found.topic}`
      };
    }
  }

  // Try global
  const globalIndex = await getGlobalIndex();
  if (globalIndex && globalIndex.reports) {
    const found = globalIndex.reports.find(r =>
      r.topic_normalized === topicNormalized ||
      r.topic.toLowerCase() === args.topic.toLowerCase()
    );

    if (found) {
      const globalPath = path.join(ARL_BASE, '_global', found.directory);
      return {
        exists: true,
        scope: 'global',
        report_path: globalPath,
        topic: found.topic,
        created: found.created,
        updated: found.updated,
        message: `Report found (global): ${found.topic}`
      };
    }
  }

  // Not found
  return {
    exists: false,
    topic: args.topic,
    project_id: projectId,
    project_name: projectName,
    message: `No report found for "${args.topic}". You can create one using the report-creator subagent. It will be stored in ~/.claude/agent_research_library/projects/${projectId}/`
  };
}
*/

// Create the MCP server
const server = new McpServer({
  name: 'research-report-tools',
  version: '1.0.0',
});

/**
 * Helper: Count words in text
 */
function countWords(text) {
  return text.trim().split(/\s+/).filter(w => w.length > 0).length;
}

/**
 * Helper: Validate section key format (REPORT_ID:L1:L2:L3)
 */
function validateSectionKey(key, reportId) {
  const parts = key.split(':');

  // Must start with report ID
  if (parts[0] !== reportId) {
    return `Section key "${key}" must start with report ID "${reportId}"`;
  }

  // Must have 2-4 parts (REPORT_ID + 1-3 levels)
  if (parts.length < 2 || parts.length > 4) {
    return `Section key "${key}" must have 2-4 parts (REPORT_ID:L1[:L2[:L3]])`;
  }

  // Each part must be UPPERCASE_WITH_UNDERSCORES
  for (let i = 1; i < parts.length; i++) {
    if (!/^[A-Z][A-Z0-9_]*$/.test(parts[i])) {
      return `Section key part "${parts[i]}" must use UPPERCASE_WITH_UNDERSCORES format`;
    }
  }

  return null; // Valid
}

/**
 * Helper: Extract cross-references from markdown content
 */
function extractCrossReferences(content) {
  const regex = /\[([A-Z][A-Z0-9_:]+)\]/g;
  const refs = [];
  let match;

  while ((match = regex.exec(content)) !== null) {
    // Only capture if it looks like a section key (has at least one colon)
    if (match[1].includes(':')) {
      refs.push(match[1]);
    }
  }

  return [...new Set(refs)]; // Unique refs
}

/**
 * ReportLinterTool - Validate report structure
 */
server.registerTool(
  'lint_report',
  {
    description: 'Validate the structure and formatting of a research report (v2.0 schema). Checks for required files, proper naming conventions, metadata correctness (including type field and markers), section keys, cross-references, and word counts. Validates both leaf (standalone) and composite (directory) sections.',
    inputSchema: {
      report_path: z.string().describe('Absolute path to the report directory to validate')
    }
  },
  async ({ report_path }) => {
    const reportPath = report_path;
    const errors = [];
    const warnings = [];
    const fixes = [];

    try {
      // Check if report directory exists
      await fs.access(reportPath);
    } catch {
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            valid: false,
            errors: [`Report directory not found: ${reportPath}`],
            warnings: [],
            fixes: []
          }, null, 2)
        }]
      };
    }

    // Check for metadata.json
    let metadata;
    let reportId;
    try {
      const metadataPath = path.join(reportPath, 'metadata.json');
      const metadataContent = await fs.readFile(metadataPath, 'utf-8');
      metadata = JSON.parse(metadataContent);

      // Validate required metadata fields
      if (!metadata.topic) errors.push('metadata.json missing "topic" field');
      if (!metadata.topic_normalized) errors.push('metadata.json missing "topic_normalized" field');
      if (!metadata.created) errors.push('metadata.json missing "created" field');
      if (!metadata.scope) errors.push('metadata.json missing "scope" field');
      if (!metadata.id) {
        errors.push('metadata.json missing "id" field (report ID)');
      } else {
        reportId = metadata.id;
      }

      // v2.0: Validate schema version
      if (!metadata.schema_version) {
        warnings.push('metadata.json missing "schema_version" field (should be "2.0" for v2.0 reports)');
      } else if (metadata.schema_version === '1.0') {
        warnings.push('metadata.json uses schema_version "1.0" - consider migrating to v2.0');
      } else if (metadata.schema_version !== '2.0') {
        warnings.push(`metadata.json has unknown schema_version "${metadata.schema_version}" (expected "2.0")`);
      }

      // Validate sections array exists
      if (!metadata.sections || !Array.isArray(metadata.sections)) {
        errors.push('metadata.json missing or invalid "sections" array');
      }

    } catch (error) {
      errors.push('metadata.json not found or invalid JSON');
      return {
        content: [{
          type: 'text',
          text: JSON.stringify({ valid: false, errors, warnings, fixes }, null, 2)
        }]
      };
    }

    // Collect all valid section keys from metadata
    const metadataSectionKeys = new Set();
    const sectionFileMap = new Map(); // key -> file path

    if (metadata.sections) {
      for (const section of metadata.sections) {
        if (section.key) {
          metadataSectionKeys.add(section.key);

          // Validate section key format
          if (reportId) {
            const keyError = validateSectionKey(section.key, reportId);
            if (keyError) {
              errors.push(keyError);
            }
          }

          // v2.0: Validate type field
          if (!section.type) {
            errors.push(`Section "${section.key}" missing required "type" field (must be "leaf" or "composite")`);
          } else if (section.type !== 'leaf' && section.type !== 'composite') {
            errors.push(`Section "${section.key}" has invalid type "${section.type}" (must be "leaf" or "composite")`);
          }

          // v2.0: Validate markers array format if present
          if (section.markers) {
            if (!Array.isArray(section.markers)) {
              errors.push(`Section "${section.key}" has invalid "markers" field (must be an array)`);
            } else {
              for (const marker of section.markers) {
                if (typeof marker !== 'string' || !/^[a-z][a-z0-9-]*$/.test(marker)) {
                  errors.push(`Section "${section.key}" has invalid marker "${marker}" (must be lowercase with hyphens)`);
                }
              }
            }
          }

          // v2.0: Validate word_count format
          if (section.word_count !== undefined) {
            if (section.type === 'leaf') {
              if (typeof section.word_count !== 'number') {
                errors.push(`Section "${section.key}" (leaf) must have word_count as a number`);
              }
            } else if (section.type === 'composite') {
              if (typeof section.word_count === 'number') {
                warnings.push(`Section "${section.key}" (composite) has simple word_count - consider using object format for granular tracking`);
              } else if (typeof section.word_count === 'object') {
                // Validate object format
                if (section.word_count.overview !== undefined && typeof section.word_count.overview !== 'number') {
                  errors.push(`Section "${section.key}" word_count.overview must be a number`);
                }
                if (section.word_count.content !== undefined && typeof section.word_count.content !== 'number') {
                  errors.push(`Section "${section.key}" word_count.content must be a number`);
                }
              }
            }
          }

          // Store file mappings for validation
          if (section.files) {
            // v2.0: Check for content file instead of full
            if (section.files.content) {
              sectionFileMap.set(section.key, section.files.content);
            }
            if (section.files.overview) {
              sectionFileMap.set(`${section.key}:overview`, section.files.overview);
            }
            // Legacy: warn if using old "full" field
            if (section.files.full) {
              warnings.push(`Section "${section.key}" uses deprecated "files.full" field - should be "files.content" in v2.0`);
            }
          }
        }
      }
    }

    // Check for _OVERVIEW.md
    let overviewWordCount = 0;
    try {
      const overviewPath = path.join(reportPath, '_OVERVIEW.md');
      const overviewContent = await fs.readFile(overviewPath, 'utf-8');

      // Validate overview structure
      if (!overviewContent.includes('# ')) {
        warnings.push('_OVERVIEW.md should start with a heading');
      }

      if (overviewContent.length < 100) {
        warnings.push('_OVERVIEW.md seems too short (< 100 characters)');
      }

      // Word count validation for report overview (400-700 words)
      overviewWordCount = countWords(overviewContent);
      if (overviewWordCount < 300) {
        warnings.push(`_OVERVIEW.md has ${overviewWordCount} words (typical: 400-700)`);
      } else if (overviewWordCount > 800) {
        warnings.push(`_OVERVIEW.md has ${overviewWordCount} words (typical: 400-700, max: 1000)`);
      }

    } catch {
      errors.push('_OVERVIEW.md not found');
    }

    // NEW: Collect all cross-references from all markdown files
    const allCrossReferences = new Set();

    // NEW: Track actual section files found on disk
    const actualSectionFiles = new Set();

    // Check for sections directory
    try {
      const sectionsPath = path.join(reportPath, 'sections');
      const sections = await fs.readdir(sectionsPath);

      if (sections.length === 0) {
        warnings.push('sections/ directory is empty');
      }

      // Check each section directory
      for (const section of sections) {
        const sectionPath = path.join(sectionsPath, section);
        const stat = await fs.stat(sectionPath);

        if (stat.isDirectory()) {
          // Check for section naming (should be UPPERCASE_WITH_UNDERSCORES)
          if (!/^[A-Z][A-Z0-9_]*$/.test(section)) {
            warnings.push(`Section "${section}" should use UPPERCASE_WITH_UNDERSCORES naming`);
          }

          // Check for required section files
          const sectionFiles = await fs.readdir(sectionPath);

          if (!sectionFiles.includes('_OVERVIEW.md')) {
            errors.push(`Section "${section}" missing _OVERVIEW.md`);
          } else {
            actualSectionFiles.add(`sections/${section}/_OVERVIEW.md`);

            // Validate _OVERVIEW.md word count (200-400 words)
            try {
              const content = await fs.readFile(path.join(sectionPath, '_OVERVIEW.md'), 'utf-8');
              const wordCount = countWords(content);
              if (wordCount < 200) {
                warnings.push(`Section "${section}"/_OVERVIEW.md has ${wordCount} words (typical: 200-400)`);
              } else if (wordCount > 500) {
                warnings.push(`Section "${section}"/_OVERVIEW.md has ${wordCount} words (typical: 200-400, max: 600)`);
              }

              // Extract cross-references
              const refs = extractCrossReferences(content);
              refs.forEach(ref => allCrossReferences.add(ref));
            } catch {}
          }

          // v2.0: Check for _CONTENT.md (optional in v2.0)
          if (sectionFiles.includes('_CONTENT.md')) {
            actualSectionFiles.add(`sections/${section}/_CONTENT.md`);

            // Validate _CONTENT.md word count (1500-2500 words)
            try {
              const content = await fs.readFile(path.join(sectionPath, '_CONTENT.md'), 'utf-8');
              const wordCount = countWords(content);
              if (wordCount < 1000) {
                warnings.push(`Section "${section}"/_CONTENT.md has ${wordCount} words (typical: 1500-2500)`);
              } else if (wordCount > 3000) {
                warnings.push(`Section "${section}"/_CONTENT.md has ${wordCount} words (typical: 1500-2500, max: 3500)`);
              }

              // Extract cross-references
              const refs = extractCrossReferences(content);
              refs.forEach(ref => allCrossReferences.add(ref));
            } catch {}
          }

          // Legacy: warn if old _FULL.md exists
          if (sectionFiles.includes('_FULL.md')) {
            warnings.push(`Section "${section}" has deprecated _FULL.md file - should be renamed to _CONTENT.md in v2.0`);
            actualSectionFiles.add(`sections/${section}/_FULL.md`);

            // Still validate it for now
            try {
              const content = await fs.readFile(path.join(sectionPath, '_FULL.md'), 'utf-8');
              const refs = extractCrossReferences(content);
              refs.forEach(ref => allCrossReferences.add(ref));
            } catch {}
          }

          // Check for subsection files (should be 800-1500 words)
          for (const file of sectionFiles) {
            if (file.endsWith('.md') && !file.startsWith('_')) {
              const filePath = path.join(sectionPath, file);
              actualSectionFiles.add(`sections/${section}/${file}`);

              try {
                const content = await fs.readFile(filePath, 'utf-8');
                const wordCount = countWords(content);
                if (wordCount < 600) {
                  warnings.push(`Section "${section}"/${file} has ${wordCount} words (typical: 800-1500)`);
                } else if (wordCount > 2000) {
                  warnings.push(`Section "${section}"/${file} has ${wordCount} words (typical: 800-1500, consider section markers if >2000)`);
                }

                // Extract cross-references
                const refs = extractCrossReferences(content);
                refs.forEach(ref => allCrossReferences.add(ref));
              } catch {}
            }
          }
        } else if (stat.isFile() && section.endsWith('.md')) {
          // v2.0: Standalone file (leaf section) - check naming
          if (!/^[A-Z][A-Z0-9_]*\.md$/.test(section)) {
            warnings.push(`Standalone section file "${section}" should use UPPERCASE_WITH_UNDERSCORES naming`);
          }

          actualSectionFiles.add(`sections/${section}`);

          // Validate standalone file word count (1000-2000 words)
          try {
            const content = await fs.readFile(sectionPath, 'utf-8');
            const wordCount = countWords(content);
            if (wordCount < 800) {
              warnings.push(`Standalone section "${section}" has ${wordCount} words (typical: 1000-2000)`);
            } else if (wordCount > 2500) {
              warnings.push(`Standalone section "${section}" has ${wordCount} words (typical: 1000-2000, consider section markers if >2000)`);
            }

            // Extract cross-references
            const refs = extractCrossReferences(content);
            refs.forEach(ref => allCrossReferences.add(ref));
          } catch {}
        }
      }

    } catch {
      errors.push('sections/ directory not found');
    }

    // NEW: Validate cross-references
    for (const ref of allCrossReferences) {
      if (!metadataSectionKeys.has(ref)) {
        errors.push(`Cross-reference [${ref}] points to non-existent section (not in metadata.json)`);
      }
    }

    // NEW: Check for orphaned sections (files exist but not in metadata)
    for (const filePath of actualSectionFiles) {
      let foundInMetadata = false;
      for (const [key, metadataPath] of sectionFileMap) {
        if (metadataPath === filePath) {
          foundInMetadata = true;
          break;
        }
      }

      if (!foundInMetadata) {
        warnings.push(`File "${filePath}" exists but is not registered in metadata.json sections`);
      }
    }

    // NEW: Check for missing files (in metadata but not on disk)
    for (const [key, filePath] of sectionFileMap) {
      const fullPath = path.join(reportPath, filePath);
      try {
        await fs.access(fullPath);
      } catch {
        errors.push(`metadata.json references file "${filePath}" but it doesn't exist`);
      }
    }

    // Generate auto-fixes if applicable
    if (errors.length === 0 && warnings.length > 0) {
      fixes.push('Minor formatting issues detected. These are warnings only and do not require fixes.');
    }

    const valid = errors.length === 0;

    const result = {
      valid,
      errors,
      warnings,
      fixes,
      statistics: {
        overview_word_count: overviewWordCount,
        metadata_sections: metadataSectionKeys.size,
        actual_files: actualSectionFiles.size,
        cross_references: allCrossReferences.size
      },
      message: valid
        ? `Report structure is valid. ${warnings.length} warning(s).`
        : `Report structure has ${errors.length} error(s) and ${warnings.length} warning(s).`
    };

    return {
      content: [{
        type: 'text',
        text: JSON.stringify(result, null, 2)
      }]
    };
  }
);

/**
 * ExtractSectionTool - Extract specific section from markdown using markers
 */
server.registerTool(
  'extract_section',
  {
    description: 'Extract a specific section from a markdown file using section markers. Returns the content between <!-- section:id --> and <!-- /section:id --> markers. If markers not found, returns the entire file.',
    inputSchema: {
      file_path: z.string().describe('Absolute path to the markdown file'),
      section_id: z.string().describe('Section marker ID to extract (e.g., "overview", "architecture", "implementation")')
    }
  },
  async ({ file_path, section_id }) => {
    try {
      // Read the file
      const content = await fs.readFile(file_path, 'utf-8');

      // Build marker patterns
      const startMarker = `<!-- section:${section_id} -->`;
      const endMarker = `<!-- /section:${section_id} -->`;

      // Find start marker
      const startIndex = content.indexOf(startMarker);

      if (startIndex === -1) {
        // Markers not found - check if file is small enough to return whole thing
        const wordCount = countWords(content);

        if (wordCount < 1500) {
          return {
            content: [{
              type: 'text',
              text: JSON.stringify({
                success: true,
                section_found: false,
                fallback: 'full_file',
                message: `Section markers not found. File is ${wordCount} words - returning entire content.`,
                extracted_content: content,
                word_count: wordCount
              }, null, 2)
            }]
          };
        } else {
          return {
            content: [{
              type: 'text',
              text: JSON.stringify({
                success: false,
                section_found: false,
                message: `Section marker "${section_id}" not found in file. File is ${wordCount} words - too large to return without markers.`,
                available_markers: extractAvailableMarkers(content),
                suggestion: 'Use one of the available section markers listed above, or read the full file directly.'
              }, null, 2)
            }]
          };
        }
      }

      // Find end marker
      const endIndex = content.indexOf(endMarker, startIndex);

      if (endIndex === -1) {
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              success: false,
              section_found: true,
              message: `Start marker found but end marker "<!-- /section:${section_id} -->" is missing. Malformed section markers.`,
              suggestion: 'Fix the section markers in the file.'
            }, null, 2)
          }]
        };
      }

      // Extract content between markers (excluding the markers themselves)
      const sectionStart = startIndex + startMarker.length;
      const extractedContent = content.substring(sectionStart, endIndex).trim();

      const wordCount = countWords(extractedContent);

      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            success: true,
            section_found: true,
            section_id: section_id,
            file_path: file_path,
            extracted_content: extractedContent,
            word_count: wordCount,
            message: `Successfully extracted section "${section_id}" (${wordCount} words)`
          }, null, 2)
        }]
      };

    } catch (error) {
      if (error.code === 'ENOENT') {
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              success: false,
              message: `File not found: ${file_path}`
            }, null, 2)
          }]
        };
      }

      return {
        content: [{
          type: 'text',
          text: JSON.stringify({
            success: false,
            message: `Error reading file: ${error.message}`
          }, null, 2)
        }]
      };
    }
  }
);

/**
 * Helper: Extract available section markers from content
 */
function extractAvailableMarkers(content) {
  const markerRegex = /<!-- section:([a-z-]+) -->/g;
  const markers = [];
  let match;

  while ((match = markerRegex.exec(content)) !== null) {
    markers.push(match[1]);
  }

  return markers.length > 0 ? markers : ['No section markers found in file'];
}

// NOTE: check_report_exists tool is disabled - use research-report-finder agent instead
// The agent provides intelligent fuzzy search with synonyms, which is more user-friendly
// Code is kept above for reference but not registered

// Start the server
const transport = new StdioServerTransport();
await server.connect(transport);
