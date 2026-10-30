#!/usr/bin/env bash
# Phase 2 (config + shared protocol) verification: config/profile/protocol
# suites ran and passed, helper coverage >= 80%.
set -euo pipefail
cd "$(dirname "$0")/.."
log=$(mktemp)

echo "== tests + coverage"
sbt -batch scalafmtCheck Test/scalafmtCheck clean coverage test coverageReport < /dev/null | tee "$log" \
  | grep -E "Passed|Statement coverage"
stmt=$(grep -oE "Statement coverage\.+: [0-9.]+" "$log" | grep -oE "[0-9.]+$")
awk -v s="$stmt" 'BEGIN { exit !(s >= 80) }' || { echo "FAIL: coverage $stmt% < 80%"; exit 1; }
for suite in GluonConfigSuite ProfileSuite ProtocolsSuite; do
  grep -q "gluon.perf.$suite" "$log" || { echo "FAIL: $suite did not run"; exit 1; }
done
sbt -batch clean < /dev/null > /dev/null

echo "PASS: Phase 2 (coverage $stmt%)"
