#!/usr/bin/env bash
# Image entrypoint (PERF-2.1): run one simulation, then hand its results to
# bin/run-perf via the wait-for-copy protocol, since a finished pod can't be
# `kubectl cp`'d from:
#   /results/EXIT_CODE  Gatling's exit status (0 ok, 2 assertions failed, 1 error)
#   /results/DONE       written last; run-perf polls for it
#   /results/COPIED     run-perf touches it after copying; we exit then, or
#                       after COPY_TIMEOUT seconds regardless
#
# Env: SIMULATION (class name, e.g. SmokeSimulation or gluon.perf.SmokeSimulation),
#      RESULTS_DIR (default /results), COPY_TIMEOUT (default 600),
#      PERF_PROFILE and <SERVICE>_URL (read by GluonConfig).
set -uo pipefail

: "${SIMULATION:?SIMULATION must name a simulation class}"
results="${RESULTS_DIR:-/results}"
copy_timeout="${COPY_TIMEOUT:-600}"
[[ "$SIMULATION" == *.* ]] || SIMULATION="gluon.perf.$SIMULATION"
# Read by logback-test.xml, so trace ids land next to the report.
export TRACE_LOG="${TRACE_LOG:-$results/trace-ids.log}"

mkdir -p "$results"
"$(dirname "$0")/gluon-performance" -s "$SIMULATION" -rf "$results"
code=$?
echo "$code" > "$results/EXIT_CODE"
touch "$results/DONE"
echo "simulation exited $code; waiting up to ${copy_timeout}s for $results/COPIED"

waited=0
while [[ ! -e "$results/COPIED" && $waited -lt $copy_timeout ]]; do
  sleep 2
  waited=$((waited + 2))
done
exit "$code"
