#!/usr/bin/env bash
# run_trivy.sh - Run trivy scan on a project directory
# Outputs JSON results for aggregation
#
# Usage: run_trivy.sh <project-path> [output-dir]
#
# Requires: trivy

set -euo pipefail

PROJECT_PATH="${1:-.}"
OUTPUT_DIR="${2:-$(mktemp -d)}"

# Resolve to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

mkdir -p "$OUTPUT_DIR"

echo ">>> Running trivy..."

if ! command -v trivy &>/dev/null; then
    echo "ERROR: trivy not found. Install with: brew install trivy"
    exit 1
fi

if trivy fs \
    --scanners vuln,secret,misconfig \
    --severity HIGH,CRITICAL \
    --format json \
    --output "$OUTPUT_DIR/trivy.json" \
    "$PROJECT_PATH" 2>"$OUTPUT_DIR/trivy_stderr.log"; then
    echo "    trivy completed (exit 0)"
else
    TRIVY_EXIT=$?
    echo "    trivy exited with code $TRIVY_EXIT"
fi

echo "Results in: $OUTPUT_DIR"
[ -f "$OUTPUT_DIR/trivy.json" ] && echo "  - trivy.json ($(wc -c < "$OUTPUT_DIR/trivy.json") bytes)"
