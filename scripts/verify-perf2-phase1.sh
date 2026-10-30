#!/usr/bin/env bash
# Performance 2 / Phase 1 (container image) verification: unit tests green,
# image layout correct, image runs the smoke simulation end to end.
set -euo pipefail
cd "$(dirname "$0")/.."

sbt -batch scalafmtCheck Test/scalafmtCheck test Docker/publishLocal < /dev/null \
  | grep -E "Passed|Built image"
scripts/check-image-layout.sh
scripts/check-image-run.sh
echo "PASS: Performance 2 / Phase 1"
