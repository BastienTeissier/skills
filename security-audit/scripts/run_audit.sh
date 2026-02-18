#!/usr/bin/env bash
# run_audit.sh - Run semgrep and trivy scans on a project directory
# Outputs JSON results to a temporary directory for aggregation
#
# Usage: run_audit.sh <project-path> [output-dir]
#
# Requires: semgrep, trivy

set -euo pipefail

PROJECT_PATH="${1:-.}"
OUTPUT_DIR="${2:-$(mktemp -d)}"

# Resolve to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

mkdir -p "$OUTPUT_DIR"

echo "=== Security Audit ==="
echo "Project: $PROJECT_PATH"
echo "Output:  $OUTPUT_DIR"
echo ""

SEMGREP_OK=true
TRIVY_OK=true

# --- Semgrep ---
echo ">>> Running semgrep..."
if command -v semgrep &>/dev/null; then
    if semgrep ci --json --output "$OUTPUT_DIR/semgrep.json" \
        --no-suppress-errors 2>"$OUTPUT_DIR/semgrep_stderr.log"; then
        echo "    semgrep completed (exit 0)"
    else
        SEMGREP_EXIT=$?
        echo "    semgrep exited with code $SEMGREP_EXIT (results may still be usable)"
        # semgrep ci exits non-zero when findings exist; the JSON is still valid
    fi
else
    echo "    WARNING: semgrep not found, skipping"
    SEMGREP_OK=false
fi

# --- Trivy ---
echo ">>> Running trivy..."
if command -v trivy &>/dev/null; then
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
else
    echo "    WARNING: trivy not found, skipping"
    TRIVY_OK=false
fi

echo ""
echo "=== Scan complete ==="
echo "Results in: $OUTPUT_DIR"
[ -f "$OUTPUT_DIR/semgrep.json" ] && echo "  - semgrep.json ($(wc -c < "$OUTPUT_DIR/semgrep.json") bytes)"
[ -f "$OUTPUT_DIR/trivy.json" ]   && echo "  - trivy.json   ($(wc -c < "$OUTPUT_DIR/trivy.json") bytes)"

if [ "$SEMGREP_OK" = false ] || [ "$TRIVY_OK" = false ]; then
    echo ""
    echo "WARNING: Some tools were not found. Install missing tools:"
    [ "$SEMGREP_OK" = false ] && echo "  brew install semgrep   OR   pip install semgrep"
    [ "$TRIVY_OK" = false ]   && echo "  brew install trivy"
fi
