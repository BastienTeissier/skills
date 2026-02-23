# Security Audit Report

**Project:** <path>
**Date:** <date>
**Scanners used:** <list of scanners that ran successfully>
**Baseline file:** <path to baseline file, or "None">

## Baseline Status

### Resolved (no longer detected)

| Rule/CVE | Scanner | Previously in |
|----------|---------|---------------|
| ...      | ...     | ...           |

These entries can be removed from the baseline.

### Currently Baselined

| Rule/CVE | Severity | File | Reason | Date |
|----------|----------|------|--------|------|
| ...      | ...      | ...  | ...    | ...  |

> Review these entries — if any should now be fixed, let me know.

## Summary

| Severity | <scanner-1> | <scanner-2> | ... | Total | Baselined |
|----------|-------------|-------------|-----|-------|-----------|
| CRITICAL |      X      |      X      | ... |   X   |     X     |
| HIGH     |      X      |      X      | ... |   X   |     X     |

## Critical Findings

### [Finding title from tool output]
- **Source:** <scanner-name>
- **Severity:** CRITICAL
- **File:** path/to/file:line
- **Rule/CVE:** rule-id or CVE-ID
- **Description:** what was found
- **Recommendation:** how to fix

(repeat for each critical finding)

## High Findings

(same format as critical)

## Next Steps

Prioritized list of remediation actions based on new findings.
