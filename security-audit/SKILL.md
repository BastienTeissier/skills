---
name: security-audit
description: Run a security audit".
---

# Security Auditn

Run security scanners on a project, aggregate findings into a structured report with severity-based prioritization.

Available scanners are defined in the `references/` folder. Each reference file describes a scanner, how to verify/install it, how to run it, and how to interpret its output.

## Workflow

1. **Discover scanners** - Read all files in `<skill-path>/references/` to identify available scanners
2. **Run scanners in parallel** - Launch one subagent per scanner to verify, execute, and collect results
3. **Aggregate results** - Read all JSON outputs and produce a unified report

## Step 1: Discover Scanners

Read every `.md` file in `<skill-path>/references/`. Each file defines one scanner with its verification command, scan script, output files, and report guidelines.

## Step 2: Run Scanners in Parallel

For **each** scanner discovered in Step 1, launch a **separate subagent** (using the Task tool) that:

1. Verifies the scanner is installed (using the verification command from its reference file)
2. If missing, reports the installation instructions and stops
3. Runs the scan script described in the reference file
4. Confirms the output files were created

All scanner subagents **must** run in parallel to minimize total scan time.

Use `/tmp/security-audit` as the output directory for all scanners.

## Step 3: Aggregate Results and Produce Report

Once all subagents complete, read the JSON output files from `/tmp/security-audit/` and produce a unified report.

Also check any `*_stderr.log` files if results look incomplete.

### Report Format

Use the template in `<skill-path>/assets/reporting-template.md` as the base structure for the report.

### Reporting Guidelines

- Group by severity (CRITICAL first, then HIGH)
- Within each severity, group by scanner
- Deduplicate findings that appear in multiple scanners
- Follow scanner-specific report guidelines from the reference files
- Keep descriptions concise - one line per finding unless context is essential
- If no findings at a severity level, state "No [severity] findings" instead of omitting the section
- **After presenting the final report**, use the `AskUserQuestion` tool to propose the user fixes for the critical/high findings, and ask if they want proposal for all findings or just the critical/high ones.
