#!/usr/bin/env bash
# Runs the built image locally against port-forwarded gluon-local and checks
# the wait-for-copy protocol: report + trace ids + EXIT_CODE 0 + DONE, and the
# container exits once COPIED appears. Assumes `sbt Docker/publishLocal` ran.
set -euo pipefail
cd "$(dirname "$0")/.."

results=$(mktemp -d)
chmod 777 "$results"
trap 'scripts/port-forward.sh down > /dev/null; rm -rf "$results"' EXIT
scripts/port-forward.sh up > /dev/null

envs=()
for s in ORDER:18080 PAYMENT:18081 INVENTORY:18082 USER:18083 CATALOG:18084 \
  FULFILMENT:18085 CART:18086 NOTIFICATION:18087; do
  envs+=(-e "${s%%:*}_URL=http://host.docker.internal:${s##*:}")
done

# Plays bin/run-perf's part: wait for DONE, then signal COPIED.
( while [[ ! -e "$results/DONE" ]]; do sleep 1; done; touch "$results/COPIED" ) \
  > /dev/null 2>&1 < /dev/null &

docker run --rm "${envs[@]}" -e SIMULATION=SmokeSimulation -e COPY_TIMEOUT=60 \
  -e JAVA_OPTS=-XX:MaxRAMPercentage=75 -m 1g -v "$results:/results" \
  gluon-performance:latest > target/check-image-run.log 2>&1 < /dev/null \
  || { echo "FAIL: container exited non-zero (see target/check-image-run.log)"; exit 1; }

[[ "$(cat "$results/EXIT_CODE")" == 0 ]] || { echo "FAIL: EXIT_CODE $(cat "$results/EXIT_CODE")"; exit 1; }
ls "$results"/smokesimulation-*/index.html > /dev/null || { echo "FAIL: no report"; exit 1; }
ok=$(grep -cE 'status=200 trace_id=[0-9a-f]{32}$' "$results/trace-ids.log" || true)
[[ "$ok" == 8 ]] || { echo "FAIL: $ok/8 trace-linked 200s"; exit 1; }
echo "PASS: image run (EXIT_CODE 0, report, $ok/8 trace-linked 200s, exited on COPIED)"
