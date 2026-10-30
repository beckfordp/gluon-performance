#!/usr/bin/env bash
# Prometheus target check (PLAN.md PERF-3.1): every expected scrape job has
# its full set of targets, all healthy. Run with the stack up (gluon
# bin/obs up); Prometheus is on OrbStack's LoadBalancer at localhost:9092.
#   scripts/check-obs-targets.sh
set -euo pipefail

PROM="${PROM_URL:-http://localhost:9092}"

# job -> expected number of targets
EXPECTED="
gluon-services 8
cadvisor 1
kube-state-metrics 1
postgres 6
redis 3
kafka-exporter 1
kafka-connect 1
prometheus 1
"

targets="$(curl -fsS "$PROM/api/v1/targets?state=active")" || {
  echo "FAIL: Prometheus unreachable at $PROM — is the stack up (bin/obs up)?" >&2
  exit 1
}

failures=0
while read -r job want; do
  [ -n "$job" ] || continue
  read -r up total <<< "$(jq -r --arg j "$job" '
    [.data.activeTargets[] | select(.labels.job == $j)]
    | "\(map(select(.health == "up")) | length) \(length)"' <<< "$targets")"
  if [ "$total" = "$want" ] && [ "$up" = "$want" ]; then
    echo "ok   $job $up/$want up"
  else
    echo "FAIL $job $up/$total up, want $want"
    jq -r --arg j "$job" '.data.activeTargets[] | select(.labels.job == $j and .health != "up")
      | "       \(.scrapeUrl): \(.lastError)"' <<< "$targets"
    failures=$((failures + 1))
  fi
done <<< "$EXPECTED"

[ "$failures" = 0 ] && echo "PASS: Prometheus targets" || { echo "$failures job(s) failing"; exit 1; }
