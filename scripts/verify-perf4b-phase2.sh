#!/usr/bin/env bash
# Phase 2 verification for christmas-rush-dashboard_20261103 (PLAN.md
# PERF-4.12, gluon ADR 0027): the generated JSON is current, Grafana's home
# dashboard is the Christmas Rush overview, and the live dashboards check
# passes (7 dashboards in their 1-Overview/2-Services/3-Platform folders,
# every query valid, must-have panels with data). Run with the obs stack up
# and an order placed recently (e.g. bin/run-acceptance --no-open --grep @support).
#   scripts/verify-perf4b-phase2.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GLUON_DIR="$(cd ../.. && pwd)"
GRAFANA="${GRAFANA_URL:-http://localhost:3000}"

echo "== Committed JSON current =="
"$GLUON_DIR/bin/obs-dashboards" --check
echo "ok   no stale dashboards"

echo "== Home dashboard =="
home="$(curl -fsS "$GRAFANA/api/dashboards/home" | python3 -c 'import json,sys; print(json.load(sys.stdin)["dashboard"].get("uid"))')"
[ "$home" = "gluon-christmas-rush" ] || { echo "FAIL: home is $home, expected gluon-christmas-rush"; exit 1; }
echo "ok   home = gluon-christmas-rush"

echo "== Live dashboards check =="
scripts/check-obs-dashboards.sh
echo "PASS: Phase 2 (provisioning + live check) verified"
