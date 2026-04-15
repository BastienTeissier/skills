#!/usr/bin/env bash
# parse_trivy.sh - Parse trivy JSON output into a summary + CRITICAL/HIGH findings
#
# Usage: parse_trivy.sh <trivy.json>
#
# Requires: jq

set -euo pipefail

INPUT="${1:?Usage: parse_trivy.sh <trivy.json>}"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install with: brew install jq" >&2
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "ERROR: File not found: $INPUT" >&2
  exit 1
fi

# Extract all findings into a flat array
FINDINGS=$(jq '[
  .Results[]? | .Target as $target | (
    [.Vulnerabilities[]? | {
      type: "vulnerability",
      target: $target,
      id: .VulnerabilityID,
      severity: .Severity,
      pkg: .PkgName,
      installed: .InstalledVersion,
      fixed: (.FixedVersion // "none"),
      title: (.Title // ""),
      description: ((.Description // "")[0:200])
    }] +
    [.Secrets[]? | {
      type: "secret",
      target: $target,
      severity: .Severity,
      rule: .RuleID,
      title: (.Title // ""),
      match: ((.Match // "")[0:100]),
      start_line: .StartLine,
      end_line: .EndLine
    }] +
    [.Misconfigurations[]? | {
      type: "misconfig",
      target: $target,
      severity: .Severity,
      id: .ID,
      title: (.Title // ""),
      description: ((.Description // "")[0:200]),
      resolution: ((.Resolution // "")[0:200])
    }]
  )
] | flatten' "$INPUT")

# Print summary
echo "=== TRIVY SUMMARY ==="
echo "$FINDINGS" | jq -r '
  "Total findings: \(length)",
  "By severity: \(group_by(.severity) | map({key: .[0].severity, value: length}) | from_entries)",
  "By type: \(group_by(.type) | map({key: .[0].type, value: length}) | from_entries)"
'

# Print CRITICAL and HIGH findings
echo ""
echo "=== CRITICAL/HIGH FINDINGS ==="
echo "$FINDINGS" | jq -c '.[] | select(.severity == "CRITICAL" or .severity == "HIGH")'
