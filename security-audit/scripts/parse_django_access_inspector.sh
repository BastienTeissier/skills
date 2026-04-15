#!/usr/bin/env bash
# parse_django_access_inspector.sh - Parse Django Access Inspector JSON output
#
# Usage: parse_django_access_inspector.sh <django-access-inspector.json>
#
# Requires: jq

set -euo pipefail

INPUT="${1:?Usage: parse_django_access_inspector.sh <django-access-inspector.json>}"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install with: brew install jq" >&2
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "ERROR: File not found: $INPUT" >&2
  exit 1
fi

# Summary counts
echo "=== DJANGO ACCESS INSPECTOR SUMMARY ==="
jq -r '
  "Authenticated endpoints: \(.views.authenticated // {} | keys | length)",
  "Unauthenticated endpoints: \(.views.unauthenticated // {} | keys | length)",
  "Unchecked views: \(.unchecked_views // [] | length)",
  "Model admin views: \(.model_admin_views // [] | length)"
' "$INPUT"

# AllowAny endpoints (authenticated but with AllowAny permission)
echo ""
echo "=== ALLOW_ANY ENDPOINTS ==="
jq -r '
  .views.authenticated // {} | to_entries[]
  | select(.value.permission_classes | index("AllowAny"))
  | "\(.key): permissions=\(.value.permission_classes | join(",")) auth=\(.value.authentication_classes | join(","))"
' "$INPUT"

# Unauthenticated endpoints
echo ""
echo "=== UNAUTHENTICATED ENDPOINTS ==="
jq -r '.views.unauthenticated // {} | keys[]' "$INPUT"

# Unchecked views
echo ""
echo "=== UNCHECKED VIEWS ==="
jq -c '.unchecked_views // [] | .[]' "$INPUT"
