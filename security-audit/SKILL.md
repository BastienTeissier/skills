---
name: security-audit
description: Run a security audit".
---

# Security Audit

Run security scanners on a project, aggregate findings into a structured report with severity-based prioritization.

Available scanners are defined in the `references/` folder. Each reference file describes a scanner, how to verify/install it, how to run it, and how to interpret its output.

## Workflow

1. **Discover scanners** - Read all files in `<skill-path>/references/` to identify available scanners
2. **Load baseline** - Locate and read the existing baseline file, or ask the user where to create one
3. **Run scanners in parallel** - Launch one subagent per scanner to verify, execute, and collect results
4. **Aggregate results** - Read all JSON outputs, compare with baseline, and produce a unified report
5. **Update baseline** - Ask the user which new findings to ignore, then update the baseline file

## Step 1: Discover Scanners

Read every `.md` file in `<skill-path>/references/`. Each file defines one scanner with its verification command, scan script, output files, and report guidelines.

## Step 2: Load Baseline

Look for an existing baseline file in the project:

1. Search for a file named `security-baseline.md` in the project root and common locations (e.g. `.github/`, `docs/`, `.security/`)
2. If **found**, read it and keep its contents for comparison in Step 4
3. If **not found**, use the `AskUserQuestion` tool to ask the user where they want the baseline file to be stored (suggest reasonable defaults like `<project-root>/security-baseline.md` or `<project-root>/.github/security-baseline.md`)

The baseline file follows the format defined in `<skill-path>/assets/baseline-template.md`.

## Step 3: Run Scanners in Parallel

For **each** scanner discovered in Step 1, launch a **separate subagent** (using the Task tool) that:

1. Verifies the scanner is installed (using the verification command from its reference file)
2. If missing, reports the installation instructions and stops
3. Runs the scan script described in the reference file
4. Confirms the output files were created

All scanner subagents **must** run in parallel to minimize total scan time.

Use `/tmp/security-audit` as the output directory for all scanners.

## Step 4: Aggregate Results and Produce Report

Once all subagents complete, read the JSON output files from `/tmp/security-audit/` and produce a unified report.

Also check any `*_stderr.log` files if results look incomplete.

### Baseline Comparison

Compare scan results against the baseline loaded in Step 2:

- **New findings**: present in scan results but absent from the baseline — these are the actionable items
- **Baselined findings**: present in both scan results and baseline — summarize in a table for user review
- **Resolved findings**: present in baseline but no longer detected — flag for removal from baseline

### Report Format

Use the template in `<skill-path>/assets/reporting-template.md` as the base structure for the report.

### Reporting Guidelines

- Group by severity (CRITICAL first, then HIGH)
- Within each severity, group by scanner
- Deduplicate findings that appear in multiple scanners
- Follow scanner-specific report guidelines from the reference files
- Keep descriptions concise - one line per finding unless context is essential
- If no findings at a severity level, state "No [severity] findings" instead of omitting the section
- Only list **new findings** (not in baseline) in the Critical/High Findings sections
- **After presenting the final report**, use the `AskUserQuestion` tool to propose the user fixes for the critical/high findings, and ask if they want proposals for all findings or just the critical/high ones

## Step 5: Update Baseline

After the report is presented:

1. Use the `AskUserQuestion` tool to ask the user which **new findings** (if any) they want to add to the baseline as accepted/ignored. For each finding they choose to baseline, ask for a justification reason.
2. Remove **resolved findings** from the baseline (findings no longer detected by any scanner).
3. Write the updated baseline file using the format from `<skill-path>/assets/baseline-template.md`.

The baseline file must **always** include for each ignored finding:
- Scanner source, severity, file location, rule/CVE
- The reason why it was ignored
- Who accepted the risk
- The date it was added
