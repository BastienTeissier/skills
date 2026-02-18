---
name: security-audit
description: Run a security audit on a project using semgrep and trivy, then aggregate and analyze findings. Use when the user asks to audit, scan, or check a project for security vulnerabilities, secrets, misconfigurations, or code issues. Triggers on requests like "run a security audit", "scan this project for vulnerabilities", "check for security issues", "find secrets in the codebase", or "security review".
---

# Security Audit

Run semgrep (SAST) and trivy (vuln/secret/misconfig) on a project, aggregate findings into a structured report with severity-based prioritization.

## Workflow

1. **Verify tools** - Confirm `semgrep` and `trivy` are installed
2. **Run scans** - Execute `scripts/run_audit.sh <project-path> <output-dir>`
3. **Read results** - Parse the JSON outputs
4. **Produce report** - Aggregate findings into the report format below

## Step 1: Verify Tools

Check that both tools are available:

```bash
semgrep --version
trivy --version
```

If missing, tell the user how to install:
- semgrep: `brew install semgrep` or `pip install semgrep`
- trivy: `brew install trivy`

Do NOT proceed until both are available.

## Step 2: Run Scans

Execute the bundled scan script. It runs both tools and writes JSON output:

```bash
bash <skill-path>/scripts/run_audit.sh <project-path> /tmp/security-audit
```

This runs:
- `semgrep ci --json` for static analysis
- `trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --format json` for vulnerabilities, secrets, and misconfigurations

If `semgrep ci` fails due to missing CI config, fall back to:
```bash
semgrep scan --json --output /tmp/security-audit/semgrep.json <project-path>
```

## Step 3: Read Results

Read the JSON files:
- `/tmp/security-audit/semgrep.json` - semgrep findings
- `/tmp/security-audit/trivy.json` - trivy findings

Also check stderr logs if results look incomplete:
- `/tmp/security-audit/semgrep_stderr.log`
- `/tmp/security-audit/trivy_stderr.log`

## Step 4: Produce Report

Aggregate all findings into this format:

```
# Security Audit Report

**Project:** <path>
**Date:** <date>
**Tools:** semgrep <version>, trivy <version>

## Summary

| Severity | Semgrep | Trivy Vulns | Trivy Secrets | Trivy Misconfig | Total |
|----------|---------|-------------|---------------|-----------------|-------|
| CRITICAL |   X     |     X       |      X        |       X         |   X   |
| HIGH     |   X     |     X       |      X        |       X         |   X   |

## Critical Findings

### [Finding title from tool output]
- **Source:** semgrep|trivy
- **Severity:** CRITICAL
- **File:** path/to/file:line
- **Rule/CVE:** rule-id or CVE-ID
- **Description:** what was found
- **Recommendation:** how to fix

(repeat for each critical finding)

## High Findings

(same format as critical)

## Next Steps

Prioritized list of remediation actions based on findings.
```

**Reporting guidelines:**
- Group by severity (CRITICAL first, then HIGH)
- Within each severity, group by tool (semgrep findings, then trivy)
- Deduplicate findings that appear in both tools
- For trivy vulns, include the affected package and fixed version when available
- For semgrep, include the rule ID and link to rule documentation if available
- Keep descriptions concise - one line per finding unless context is essential
- If no findings at a severity level, state "No [severity] findings" instead of omitting the section
