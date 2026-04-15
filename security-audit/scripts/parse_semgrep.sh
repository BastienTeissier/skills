#!/usr/bin/env bash
# parse_semgrep.sh - Parse semgrep JSON output into a summary + CRITICAL/HIGH findings
#
# Usage: parse_semgrep.sh <semgrep.json>
#
# Requires: jq
#
# Semgrep severity mapping: ERROR -> HIGH, WARNING -> MEDIUM, INFO -> LOW

set -euo pipefail

INPUT="${1:?Usage: parse_semgrep.sh <semgrep.json>}"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install with: brew install jq" >&2
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "ERROR: File not found: $INPUT" >&2
  exit 1
fi

SEVERITY_MAP='{"ERROR":"HIGH","WARNING":"MEDIUM","INFO":"LOW"}'

# Extract all findings with normalized severity
FINDINGS=$(jq --argjson smap "$SEVERITY_MAP" '[
  .results[]? | {
    rule: .check_id,
    severity: .extra.severity,
    severity_normalized: ($smap[.extra.severity] // .extra.severity),
    file: .path,
    start_line: .start.line,
    end_line: .end.line,
    message: ((.extra.message // "")[0:200]),
    cve: (.extra.metadata["sca-vuln-database-identifier"] // "N/A"),
    cwe: (.extra.metadata.cwe // []),
    owasp: (.extra.metadata.owasp // [])
  }
]' "$INPUT")

# Print summary
echo "=== SEMGREP SUMMARY ==="
echo "$FINDINGS" | jq -r '
  "Total findings: \(length)",
  "By severity (normalized): \(group_by(.severity_normalized) | map({key: .[0].severity_normalized, value: length}) | from_entries)"
'

# Print CRITICAL and HIGH findings
echo ""
echo "=== CRITICAL/HIGH FINDINGS ==="
echo "$FINDINGS" | jq -c '.[] | select(.severity_normalized == "CRITICAL" or .severity_normalized == "HIGH")'
