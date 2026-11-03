#!/usr/bin/env bash
# Phase 1 verification for christmas-rush-dashboard_20261103 (PLAN.md
# PERF-4.12, gluon ADR 0027): the dashboard generator's tests pass (7
# dashboards in 3 folders, panel budgets, links resolve, every dashboard has a
# description + About row + Guide link) and the committed JSON is current.
#   scripts/verify-perf4b-phase1.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GLUON_DIR="$(cd ../.. && pwd)"

echo "== Generator tests (bin/obs-dashboards --test) =="
"$GLUON_DIR/bin/obs-dashboards" --test 2>&1 | tail -3

echo "== Committed JSON current (bin/obs-dashboards --check) =="
"$GLUON_DIR/bin/obs-dashboards" --check
echo "ok   no stale dashboards"

echo "== Guide present =="
[ -s "$GLUON_DIR/docs/observability/dashboards.md" ] || { echo "FAIL: guide missing"; exit 1; }
echo "ok   docs/observability/dashboards.md"
echo "PASS: Phase 1 (dashboard generator) verified"
