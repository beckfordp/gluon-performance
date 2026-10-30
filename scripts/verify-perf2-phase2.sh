#!/usr/bin/env bash
# Performance 2 / Phase 2 (Job manifest) verification: rendered Job accepted by
# the API server, unsafe input rejected, README documents the in-cluster run.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/check-job-manifest.sh
grep -q "### In-cluster runs" README.md || { echo "FAIL: README section missing"; exit 1; }
echo "PASS: Performance 2 / Phase 2"
