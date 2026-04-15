# Trivy

## Overview

Trivy is a comprehensive security scanner that detects vulnerabilities, secrets, and misconfigurations in filesystems, container images, and infrastructure-as-code.

## Installation

```bash
brew install trivy
```

## Verification

```bash
trivy --version
```

## Scan Script

Run the bundled script to execute trivy and produce JSON output:

```bash
bash <skill-path>/scripts/run_trivy.sh <project-path> <output-dir>
```

This runs `trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --format json` for vulnerability, secret, and misconfiguration scanning.

## Output

- `<output-dir>/trivy.json` - JSON findings
- `<output-dir>/trivy_stderr.log` - stderr for diagnostics

## Parse Output

Run the bundled parse script to extract a summary and CRITICAL/HIGH findings:

```bash
bash <skill-path>/scripts/parse_trivy.sh <output-dir>/trivy.json
```

Requires: `jq`

Output sections:
- `=== TRIVY SUMMARY ===` — total count, breakdown by severity and type
- `=== CRITICAL/HIGH FINDINGS ===` — one JSON object per line for each CRITICAL/HIGH finding

## Report Guidelines

- Include the affected package and fixed version when available
- Include CVE IDs for vulnerability findings
- Group findings by severity (CRITICAL first, then HIGH)
- Keep descriptions concise - one line per finding unless context is essential
