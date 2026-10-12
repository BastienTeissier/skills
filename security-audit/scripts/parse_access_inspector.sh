#!/usr/bin/env bash
# parse_access_inspector.sh - Parse a Committed Inventory (tools/access-inspector/inventory.json) into a summary
# and the endpoints an audit reads first
#
# Usage: parse_access_inspector.sh <inventory.json>
#
# Requires: jq
#
# Reads only fields of the inventory schema, so it works on inventories from any stack.

set -euo pipefail

INPUT="${1:?Usage: parse_access_inspector.sh <inventory.json>}"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install with: brew install jq" >&2
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "ERROR: File not found: $INPUT" >&2
  exit 1
fi

# One compact line per endpoint, with the fields a finding needs
ENDPOINT='{method, path, handler, authentication: .authentication.value, authorization: .authorization.value,
  authn_raw: .authentication.raw, authz_raw: .authorization.raw, dimensions, unknown_reason}'

echo "=== ACCESS INSPECTOR SUMMARY ==="
jq -r '
  def counts(f): .endpoints | group_by(f) | map({key: (.[0] | f | tostring), value: length}) | from_entries;
  "Stack: \(.stack)",
  "Discovery mode: \(.discovery_mode)",
  "Coverage: \(.coverage)\(if .coverage_note then " (\(.coverage_note))" else "" end)",
  "Total endpoints: \(.endpoints | length)",
  "By authentication: \(counts(.authentication.value))",
  "By authorization: \(counts(.authorization.value))",
  "By authentication layer: \(counts(.authentication.layer))",
  "By authorization layer: \(counts(.authorization.layer))",
  (.project_dimensions | keys_unsorted[]) as $d | "By \($d): \(counts(.dimensions[$d]))"
' "$INPUT"

echo ""
echo "=== ANONYMOUS ==="
jq -c ".endpoints[] | select(.authentication.value == \"anonymous\") | $ENDPOINT" "$INPUT"

echo ""
echo "=== OPTIONAL WITHOUT RULE ==="
jq -c ".endpoints[] | select(.authentication.value == \"optional\" and .authorization.value == \"none\") | $ENDPOINT" "$INPUT"

echo ""
echo "=== UNKNOWN (unexplained) ==="
jq -c ".endpoints[] | select((.authentication.value == \"unknown\" or .authorization.value == \"unknown\") and .unknown_reason == null) | $ENDPOINT" "$INPUT"

echo ""
echo "=== ACKNOWLEDGED UNKNOWN ==="
jq -c ".endpoints[] | select(.unknown_reason != null) | $ENDPOINT" "$INPUT"
