#!/usr/bin/env bash
# Phase 2 verification for obs-stack_20261030 (PLAN.md PERF-3.1): with the
# stack up, every scrape job is healthy; after a smoke run, every service's
# p99 server latency (histogram_quantile over the LatencyBuckets buckets,
# PERF-3.0) is non-zero and plausible (< 10s, the top bucket).
#   scripts/verify-perf3b-phase2.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GLUON_DIR="$(cd ../.. && pwd)"
PROM="${PROM_URL:-http://localhost:9092}"

echo "== bin/obs up =="
"$GLUON_DIR/bin/obs" up > /dev/null
echo "== Targets =="
scripts/check-obs-targets.sh | tail -1

echo "== Smoke run =="
"$GLUON_DIR/bin/run-perf" SmokeSimulation > /dev/null
# Two scrape intervals, so the run's last requests are in Prometheus.
sleep 10

echo "== p99 per service =="
query='histogram_quantile(0.99, sum by (service, le) (rate(http_server_request_duration_seconds_bucket[5m])))'
result="$(curl -fsS "$PROM/api/v1/query" --data-urlencode "query=$query")"
failures=0
for svc in cart catalog fulfilment inventory order payment user notification; do
  v="$(jq -r --arg s "$svc-service" '.data.result[] | select(.metric.service == $s) | .value[1]' <<< "$result")"
  if [ -n "$v" ] && awk -v v="$v" 'BEGIN { exit !(v > 0 && v < 10) }'; then
    printf "ok   %s-service p99 %.3fs\n" "$svc" "$v"
  else
    echo "FAIL $svc-service p99 '${v:-missing}'"
    failures=$((failures + 1))
  fi
done
[ "$failures" = 0 ] || { echo "$failures service(s) without a plausible p99"; exit 1; }
echo "PASS: Phase 2 (Prometheus + exporters) verified"
