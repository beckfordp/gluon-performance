#!/usr/bin/env bash
# Phase 5 (exit) verification for obs-stack_20261030 (PLAN.md PERF-3.4):
# from a cold `bin/obs up` (budget check passing), a valid smoke run, every
# Phase 2-4 check green, and `bin/obs down` returning the namespace's
# memory to its pre-stack baseline.
#   scripts/verify-perf3b-phase5.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GLUON_DIR="$(cd ../.. && pwd)"
OBS="$GLUON_DIR/bin/obs"

ns_gi() { sed -n 's/^ *namespace: \([0-9.]*\) Gi.*/\1/p'; }

echo "== Cold start: bin/obs down =="
baseline="$("$OBS" down | ns_gi)"
[ -n "$baseline" ] || { echo "FAIL: no namespace memory from bin/obs down"; exit 1; }
echo "ok   baseline namespace ${baseline} Gi"

echo "== bin/obs up (cold; exits 3 if over budget) =="
"$OBS" up | sed -n '/== Memory budget ==/,$p'

echo "== Smoke run (exits 3 if invalid) =="
"$GLUON_DIR/bin/run-perf" SmokeSimulation | sed -n 's/^  RESULT /ok   validity /p'

for phase in 2 3 4; do
  echo "== Phase $phase checks =="
  "scripts/verify-perf3b-phase$phase.sh" | tail -1
done

echo "== bin/obs down =="
after="$("$OBS" down | ns_gi)"
[ "$after" = "$baseline" ] || { echo "FAIL: namespace ${after} Gi after down, baseline ${baseline} Gi"; exit 1; }
echo "ok   namespace back to ${after} Gi"
echo "PASS: Phase 5 (obs stack exit criteria) verified"
