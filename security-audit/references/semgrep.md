# Semgrep

## Overview

Semgrep is a static analysis (SAST) tool that scans source code for security vulnerabilities, bugs, and code standard violations using pattern-based rules.

## Installation

```bash
brew install semgrep
# or
pip install semgrep
```

## Verification

```bash
semgrep --version
```

## Scan Script

Run the bundled script to execute semgrep and produce JSON output:

```bash
bash <skill-path>/scripts/run_semgrep.sh <project-path> <output-dir>
```

This runs `semgrep ci --json` for static analysis. If `semgrep ci` fails due to missing CI config, fall back to:

```bash
semgrep scan --json --output <output-dir>/semgrep.json <project-path>
```

## Output

- `<output-dir>/semgrep.json` - JSON findings
- `<output-dir>/semgrep_stderr.log` - stderr for diagnostics

## Report Guidelines

- Include the rule ID and link to rule documentation if available
- Group findings by severity (CRITICAL first, then HIGH)
- Keep descriptions concise - one line per finding unless context is essential
