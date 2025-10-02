#!/usr/bin/env node

import { createSdkMcpServer, tool } from '@modelcontextprotocol/sdk';
import { z } from 'zod';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Find the project root by looking for .git or .claude_research directories
 */
async function findProjectRoot(startPath) {
  let currentPath = startPath;

  while (currentPath !== '/') {
    try {
      // Check for .git directory
      await fs.access(path.join(currentPath, '.git'));
      return currentPath;
    } catch {
      // Not found, try .claude_research
      try {
        await fs.access(path.join(currentPath, '.claude_research'));
        return currentPath;
      } catch {
        // Move up one directory
        currentPath = path.dirname(currentPath);
      }
    }
  }

  return null;
}

/**
 * Get the project-level research index
 */
async function getProjectIndex(projectPath) {
  const indexPath = path.join(projectPath, '.claude_research', 'index.json');

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
  const globalPath = path.join(process.env.HOME, '.claude', 'research_reports', '_global', 'index.json');

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

/**
 * ReportRegistryTool - Check if a research report exists
 */
const reportRegistryTool = tool(
  'check_report_exists',
  'Check if a research report exists for a given topic. Returns the report path if found, or suggests creating one if not found.',
  {
    topic: z.string().describe('The topic or library name to search for (e.g., "acme_api", "authentication_system")'),
    working_directory: z.string().optional().describe('The current working directory (defaults to process.cwd())')
  },
  async (args) => {
    const workingDir = args.working_directory || process.cwd();
    const topicNormalized = args.topic.toLowerCase().replace(/[^a-z0-9_]/g, '_');

    // Try project-level first
    const projectRoot = await findProjectRoot(workingDir);
    if (projectRoot) {
      const projectIndex = await getProjectIndex(projectRoot);
      if (projectIndex && projectIndex.reports) {
        const found = projectIndex.reports.find(r =>
          r.topic_normalized === topicNormalized ||
          r.topic.toLowerCase() === args.topic.toLowerCase()
        );

        if (found) {
          return {
            exists: true,
            scope: 'project',
            report_path: path.join(projectRoot, '.claude_research', found.directory),
            topic: found.topic,
            created: found.created,
            updated: found.updated,
            message: `Report found: ${found.topic}`
          };
        }
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
        const globalPath = path.join(process.env.HOME, '.claude', 'research_reports', '_global', found.directory);
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
      message: `No report found for "${args.topic}". You can create one using the report-creator subagent.`
    };
  }
);

/**
 * ReportLinterTool - Validate report structure
 */
const reportLinterTool = tool(
  'lint_report',
  'Validate the structure and formatting of a research report. Checks for required files, proper naming conventions, and metadata correctness.',
  {
    report_path: z.string().describe('Absolute path to the report directory to validate')
  },
  async (args) => {
    const reportPath = args.report_path;
    const errors = [];
    const warnings = [];
    const fixes = [];

    try {
      // Check if report directory exists
      await fs.access(reportPath);
    } catch {
      return {
        valid: false,
        errors: [`Report directory not found: ${reportPath}`],
        warnings: [],
        fixes: []
      };
    }

    // Check for metadata.json
    let metadata;
    try {
      const metadataPath = path.join(reportPath, 'metadata.json');
      const metadataContent = await fs.readFile(metadataPath, 'utf-8');
      metadata = JSON.parse(metadataContent);

      // Validate required metadata fields
      if (!metadata.topic) errors.push('metadata.json missing "topic" field');
      if (!metadata.topic_normalized) errors.push('metadata.json missing "topic_normalized" field');
      if (!metadata.created) errors.push('metadata.json missing "created" field');
      if (!metadata.scope) errors.push('metadata.json missing "scope" field');

    } catch (error) {
      errors.push('metadata.json not found or invalid JSON');
      return { valid: false, errors, warnings, fixes };
    }

    // Check for _OVERVIEW.md
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

    } catch {
      errors.push('_OVERVIEW.md not found');
    }

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
          }

          if (!sectionFiles.includes('_FULL.md')) {
            errors.push(`Section "${section}" missing _FULL.md`);
          }
        }
      }

    } catch {
      errors.push('sections/ directory not found');
    }

    // Generate auto-fixes if applicable
    if (errors.length === 0 && warnings.length > 0) {
      fixes.push('Minor formatting issues detected. These are warnings only and do not require fixes.');
    }

    const valid = errors.length === 0;

    return {
      valid,
      errors,
      warnings,
      fixes,
      message: valid
        ? `Report structure is valid. ${warnings.length} warning(s).`
        : `Report structure has ${errors.length} error(s) and ${warnings.length} warning(s).`
    };
  }
);

// Create the MCP server
const server = createSdkMcpServer({
  name: 'research-report-tools',
  version: '1.0.0',
  tools: [reportRegistryTool, reportLinterTool]
});

// Start the server
server.listen();
