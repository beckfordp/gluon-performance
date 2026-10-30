#!/usr/bin/env bash
# Phase 4 (smoke simulation) verification = Performance 1 exit criteria:
# SmokeSimulation green against port-forwarded gluon-local, HTML report
# produced, one trace-id line per service with status 200.
set -euo pipefail
cd "$(dirname "$0")/.."
trap 'scripts/port-forward.sh down > /dev/null' EXIT

scripts/port-forward.sh up
sbt -batch "Gatling/testOnly gluon.perf.SmokeSimulation" < /dev/null \
  | grep -E "^> (Global|request count)|count of failed events"

report=$(ls -td target/gatling/smokesimulation-* | head -1)
[[ -f "$report/index.html" ]] || { echo "FAIL: no HTML report"; exit 1; }
echo "report: $report/index.html"

ok=$(grep -cE 'status=200 trace_id=[0-9a-f]{32}$' target/gatling/trace-ids.log || true)
[[ "$ok" == 8 ]] || { echo "FAIL: $ok/8 trace-linked 200s"; exit 1; }
echo "trace-linked 200s: $ok/8"

echo "PASS: Phase 4 (Performance 1 exit criteria)"
