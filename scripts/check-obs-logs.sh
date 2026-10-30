#!/usr/bin/env bash
# Log pipeline check (PLAN.md PERF-3.2): Filebeat has shipped gluon-local
# container logs to Elasticsearch's gluon-logs-* indices for all 8 services,
# each with trace-linked documents (`trace_id`, parsed from the span
# exporter's lines, so even a smoke run's /health/ready calls are findable
# by the trace ids Gatling logs), and Kibana has the gluon-logs data view.
# Run with the stack up (gluon bin/obs up) and some traffic behind it.
#   scripts/check-obs-logs.sh
set -euo pipefail

NAMESPACE="gluon-local"
KIBANA="${KIBANA_URL:-http://localhost:5601}"

# Elasticsearch has no LoadBalancer; query it from inside its own pod.
es() { # <path> [json body]
  kubectl -n "$NAMESPACE" exec deploy/elasticsearch -- \
    curl -fsS -H 'Content-Type: application/json' "http://localhost:9200$1" ${2:+-d "$2"}
}

result="$(es '/gluon-logs-*/_search?size=0' '{
  "aggs": {"svc": {"terms": {"field": "service.name", "size": 50},
    "aggs": {"traced": {"filter": {"exists": {"field": "trace_id"}}}}}}}')" || {
  echo "FAIL: Elasticsearch query failed — is the stack up (bin/obs up)?" >&2
  exit 1
}

failures=0
for svc in cart catalog fulfilment inventory order payment user notification; do
  read -r docs traced <<< "$(jq -r --arg s "$svc-service" '
    [.aggregations.svc.buckets[] | select(.key == $s)][0]
    | "\(.doc_count // 0) \(.traced.doc_count // 0)"' <<< "$result")"
  if [ "${docs:-0}" -gt 0 ] && [ "${traced:-0}" -gt 0 ]; then
    echo "ok   $svc-service $docs docs, $traced with trace_id"
  else
    echo "FAIL $svc-service ${docs:-0} docs, ${traced:-0} with trace_id"
    failures=$((failures + 1))
  fi
done

if curl -fsS "$KIBANA/api/data_views/data_view/gluon-logs" > /dev/null 2>&1; then
  echo "ok   Kibana data view gluon-logs"
else
  echo "FAIL Kibana data view gluon-logs missing"
  failures=$((failures + 1))
fi

[ "$failures" = 0 ] && echo "PASS: log pipeline" || { echo "$failures check(s) failing"; exit 1; }
