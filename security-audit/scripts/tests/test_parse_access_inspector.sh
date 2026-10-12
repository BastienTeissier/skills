#!/usr/bin/env bash
# test_parse_access_inspector.sh - Plain bash tests for parse_access_inspector.sh
#
# Usage: bash scripts/tests/test_parse_access_inspector.sh
#
# fixtures/django-demo-inventory.json is fixtures/django-demo/expected/inventory.json of the all-access-inspector
# repository: a runtime, complete Django inventory with anonymous, optional and acknowledged unknown endpoints.
# Nothing syncs the copy: when that golden file or the inventory schema changes, copy it again and update the
# expected counts below.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PARSE="$HERE/../parse_access_inspector.sh"
INVENTORY="$HERE/fixtures/django-demo-inventory.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILED=0

expect() {  # expect <name> <expected> <actual>
  if [ "$2" == "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1"
    echo "     expected: $2"
    echo "     actual:   $3"
    FAILED=1
  fi
}

section() {  # section <output> <title>: the lines between "=== <title> ===" and the next blank line
  awk -v t="=== $2 ===" '$0 == t {on=1; next} on && $0 == "" {exit} on' <<<"$1"
}

OUT="$(bash "$PARSE" "$INVENTORY")"

expect "summary states the discovery mode" "Discovery mode: runtime" "$(grep '^Discovery mode' <<<"$OUT")"
expect "summary states the coverage" "Coverage: complete" "$(grep '^Coverage' <<<"$OUT")"
expect "summary counts every endpoint" "Total endpoints: 75" "$(grep '^Total endpoints' <<<"$OUT")"
expect "summary counts by authentication" \
  'By authentication: {"anonymous":11,"optional":3,"required":47,"unknown":14}' \
  "$(grep '^By authentication:' <<<"$OUT")"
expect "summary counts by authorization" \
  'By authorization: {"none":30,"rule":25,"unknown":20}' "$(grep '^By authorization:' <<<"$OUT")"
expect "summary counts by authentication layer" \
  'By authentication layer: {"null":2,"class":16,"framework-default":9,"global":39,"method":9}' \
  "$(grep '^By authentication layer' <<<"$OUT")"
expect "summary counts by authorization layer" \
  'By authorization layer: {"null":2,"class":19,"framework-default":9,"global":28,"method":17}' \
  "$(grep '^By authorization layer' <<<"$OUT")"
expect "summary counts by Project Dimension" \
  'By access_tier: {"customer":16,"public":34,"staff":25}' "$(grep '^By access_tier' <<<"$OUT")"

expect "anonymous lists the expected endpoints" \
  "ANY /admin/login/;ANY /admin/support/login/;GET /catalog/status;OPTIONS /catalog/status;ANY /en/about/;ANY /fr/about/;ANY /health/;POST /pages/contact/;ANY /pages/legacy-landing/;ANY /pages/legacy/;ANY /pages/v1/old/" \
  "$(section "$OUT" "ANONYMOUS" | jq -r '"\(.method) \(.path)"' | paste -sd';' -)"
expect "optional without rule lists the catalog" \
  "GET /catalog/products/;HEAD /catalog/products/;OPTIONS /catalog/products/" \
  "$(section "$OUT" "OPTIONAL WITHOUT RULE" | jq -r '"\(.method) \(.path)"' | paste -sd';' -)"
expect "a complete inventory has no unexplained unknown" "" "$(section "$OUT" "UNKNOWN (unexplained)")"
expect "acknowledged unknowns are counted" "20" "$(section "$OUT" "ACKNOWLEDGED UNKNOWN" | wc -l | tr -d ' ')"
expect "acknowledged unknowns carry their reason" "true" \
  "$(section "$OUT" "ACKNOWLEDGED UNKNOWN" | jq -s 'all(.unknown_reason != null)')"

# An unknown without a reason is unexplained, never acknowledged
jq '(.endpoints[] | select(.path == "/graphql/")).unknown_reason = null' "$INVENTORY" >"$TMP/unexplained.json"
OUT="$(bash "$PARSE" "$TMP/unexplained.json")"
expect "an unknown without reason is unexplained" "ANY /graphql/" \
  "$(section "$OUT" "UNKNOWN (unexplained)" | jq -r '"\(.method) \(.path)"')"
expect "an unexplained unknown is not acknowledged" "" \
  "$(section "$OUT" "ACKNOWLEDGED UNKNOWN" | jq -r 'select(.path == "/graphql/") | .path')"

# Only schema fields: any stack, best-effort coverage with its note, no Project Dimension
jq '.stack = "spring" | .discovery_mode = "static" | .coverage = "best-effort"
  | .coverage_note = "routes read from source" | .project_dimensions = {} | .endpoints[].dimensions = {}' \
  "$INVENTORY" >"$TMP/spring.json"
OUT="$(bash "$PARSE" "$TMP/spring.json")"
expect "another stack's inventory parses" "Stack: spring" "$(grep '^Stack' <<<"$OUT")"
expect "best-effort coverage shows its note" "Coverage: best-effort (routes read from source)" \
  "$(grep '^Coverage' <<<"$OUT")"
expect "no dimension line without Project Dimensions" "" "$(grep '^By access_tier' <<<"$OUT" || true)"

expect "a missing inventory is an error" "1" "$(bash "$PARSE" "$TMP/none.json" >/dev/null 2>&1; echo $?)"
jq '.schema_version = "2"' "$INVENTORY" >"$TMP/v2.json"
expect "another schema version is an error" "1" "$(bash "$PARSE" "$TMP/v2.json" >/dev/null 2>&1; echo $?)"

exit "$FAILED"
