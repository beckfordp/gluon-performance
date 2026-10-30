#!/usr/bin/env bash
# Phase 3 verification for obs-stack_20261030 (PLAN.md PERF-3.2): with the
# stack up, a smoke run's requests are findable in Elasticsearch by the
# trace ids Gatling logged (the Gatling report -> Kibana link), and the log
# pipeline check passes for all 8 services.
#   scripts/verify-perf3b-phase3.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GLUON_DIR="$(cd ../.. && pwd)"

echo "== bin/obs up =="
"$GLUON_DIR/bin/obs" up > /dev/null

echo "== Smoke run =="
out="$("$GLUON_DIR/bin/run-perf" SmokeSimulation)"
results="$(sed -n 's/^results: *//p' <<< "$out")"
trace_id="$(grep -o 'trace_id=[0-9a-f]*' "$results/trace-ids.log" | head -1 | cut -d= -f2)"
[ -n "$trace_id" ] || { echo "FAIL: no trace id in $results/trace-ids.log"; exit 1; }

echo "== Gatling trace $trace_id in Elasticsearch =="
hits=0
for _ in $(seq 1 12); do
  hits="$(kubectl -n gluon-local exec deploy/elasticsearch -- \
    curl -fsS "http://localhost:9200/gluon-logs-*/_count?q=trace_id:$trace_id" | jq -r .count)"
  [ "$hits" -gt 0 ] && break
  sleep 5
done
[ "$hits" -gt 0 ] || { echo "FAIL: trace $trace_id not in gluon-logs-* after 60s"; exit 1; }
echo "ok   $hits doc(s) for trace $trace_id"

echo "== Log pipeline =="
scripts/check-obs-logs.sh
echo "PASS: Phase 3 (logs) verified"
