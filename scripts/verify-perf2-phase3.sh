#!/usr/bin/env bash
# Performance 2 / Phase 3 (bin/run-perf) verification: an in-cluster smoke run
# via gluon's bin/run-perf succeeds, results land on disk, no Job is left.
set -euo pipefail
cd "$(dirname "$0")/.."
gluon_bin=../../bin/run-perf

log=$(mktemp)
"$gluon_bin" SmokeSimulation < /dev/null | tee "$log"
out=$(sed -n 's/^results: //p' "$log")
[[ -d "$out" ]] || { echo "FAIL: no results dir"; exit 1; }
[[ "$(cat "$out/EXIT_CODE")" == 0 ]] || { echo "FAIL: EXIT_CODE"; exit 1; }
ls "$out"/*/index.html > /dev/null || { echo "FAIL: no report"; exit 1; }
ok=$(grep -cE 'status=200 trace_id=[0-9a-f]{32}$' "$out/trace-ids.log" || true)
[[ "$ok" == 8 ]] || { echo "FAIL: $ok/8 trace-linked 200s"; exit 1; }

sleep 3
left=$(kubectl -n gluon-local get jobs -l app.kubernetes.io/name=gluon-performance -o name)
[[ -z "$left" ]] || { echo "FAIL: jobs left: $left"; exit 1; }
echo "PASS: Performance 2 / Phase 3 (in-cluster 8/8, results at $out, no jobs left)"
