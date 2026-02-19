#!/usr/bin/env bash
# run_semgrep.sh - Run semgrep scan on a project directory
# Outputs JSON results for aggregation
#
# Usage: run_semgrep.sh <project-path> [output-dir]
#
# Requires: semgrep

set -euo pipefail

PROJECT_PATH="${1:-.}"
OUTPUT_DIR="${2:-$(mktemp -d)}"

# Resolve to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

mkdir -p "$OUTPUT_DIR"

echo ">>> Running semgrep..."

if ! command -v semgrep &>/dev/null; then
    echo "ERROR: semgrep not found. Install with: brew install semgrep  OR  pip install semgrep"
    exit 1
fi

if semgrep ci --json --output "$OUTPUT_DIR/semgrep.json" \
    --no-suppress-errors 2>"$OUTPUT_DIR/semgrep_stderr.log"; then
    echo "    semgrep completed (exit 0)"
else
    SEMGREP_EXIT=$?
    echo "    semgrep exited with code $SEMGREP_EXIT (results may still be usable)"
    # semgrep ci exits non-zero when findings exist; the JSON is still valid
fi

echo "Results in: $OUTPUT_DIR"
[ -f "$OUTPUT_DIR/semgrep.json" ] && echo "  - semgrep.json ($(wc -c < "$OUTPUT_DIR/semgrep.json") bytes)"
