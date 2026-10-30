#!/usr/bin/env bash
# Performance 2 / Phase 4 (pod limits) verification: budget check passes,
# services run with the budgeted JVM heap, an in-cluster smoke run is green,
# and no container restarted or was OOM-killed.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/check-pod-budget.sh

pod=$(kubectl -n gluon-local get pod -l app=order-service -o jsonpath='{.items[0].metadata.name}')
opts=$(kubectl -n gluon-local exec "$pod" -- printenv JAVA_OPTS)
[[ "$opts" == *MaxRAMPercentage=40* ]] || { echo "FAIL: order-service JAVA_OPTS=$opts"; exit 1; }
echo "order-service JAVA_OPTS: $opts"

../../bin/run-perf SmokeSimulation < /dev/null | grep -E "^== Done"

kubectl -n gluon-local get pods -o json | python3 -I scripts/pod_restarts.py
echo "PASS: Performance 2 / Phase 4"
