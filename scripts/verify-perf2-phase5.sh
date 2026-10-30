#!/usr/bin/env bash
# Performance 2 / Phase 5 (run validity) verification: fixture tests for the
# evaluation pass, and a real in-cluster smoke run writes validity.txt next to
# its report, judged valid, with no sampler container or Job left behind.
set -euo pipefail
cd "$(dirname "$0")/.."

../../bin/test/run-validity-test.sh | tail -1

log=$(mktemp)
code=0
../../bin/run-perf SmokeSimulation < /dev/null > "$log" 2>&1 || code=$?
out=$(sed -n 's/^results: *//p' "$log")
[[ "$code" == 0 ]] || { cat "$log"; echo "FAIL: run-perf exited $code"; exit 1; }
[[ -f "$out/validity.txt" ]] || { echo "FAIL: no validity.txt"; exit 1; }
grep -q "^RESULT valid" "$out/validity.txt" || { cat "$out/validity.txt"; echo "FAIL: run not valid"; exit 1; }
sed 's/^/  /' "$out/validity.txt"

sleep 3
[[ -z "$(docker ps -aq --filter name=perf-sampler)" ]] || { echo "FAIL: sampler container left"; exit 1; }
[[ -z "$(kubectl -n gluon-local get jobs -l app.kubernetes.io/name=gluon-performance -o name)" ]] \
  || { echo "FAIL: job left"; exit 1; }
echo "PASS: Performance 2 / Phase 5"
