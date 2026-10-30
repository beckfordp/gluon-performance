#!/usr/bin/env bash
# Phase 4 verification for obs-stack_20261030 (PLAN.md PERF-3.3): with the
# stack up and a smoke run's traffic in Prometheus, Grafana's datasource is
# healthy and all 4 dashboards' queries are valid, with the core panels
# (RED, pods, infra) showing data for every service.
#   scripts/verify-perf3b-phase4.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GLUON_DIR="$(cd ../.. && pwd)"

echo "== bin/obs up =="
"$GLUON_DIR/bin/obs" up > /dev/null

echo "== Smoke run =="
"$GLUON_DIR/bin/run-perf" SmokeSimulation > /dev/null
# Two scrape intervals, so rate() over the smoke window has 2+ samples.
sleep 30

echo "== Dashboards =="
scripts/check-obs-dashboards.sh
echo "PASS: Phase 4 (Grafana) verified"
