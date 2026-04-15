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
elif command -v docker &>/dev/null; then
    echo "    trivy CLI not found, falling back to docker (aquasec/trivy)..."
    if docker run --rm -v "$PROJECT_PATH:/src" -v "$OUTPUT_DIR:/out" \
        aquasec/trivy fs --scanners vuln,secret,misconfig \
        --severity HIGH,CRITICAL --format json --output /out/trivy.json \
        /src 2>"$OUTPUT_DIR/trivy_stderr.log"; then
        echo "    trivy (docker) completed (exit 0)"
    else
        TRIVY_EXIT=$?
        echo "    trivy (docker) exited with code $TRIVY_EXIT"
    fi
else
    echo "ERROR: trivy not found and docker is not available."
    echo "Install trivy: brew install trivy"
    echo "Or install docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "Results in: $OUTPUT_DIR"
[ -f "$OUTPUT_DIR/trivy.json" ] && echo "  - trivy.json ($(wc -c < "$OUTPUT_DIR/trivy.json") bytes)"
