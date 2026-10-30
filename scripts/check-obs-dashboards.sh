#!/usr/bin/env bash
# Grafana dashboards check (PLAN.md PERF-3.3): the Prometheus datasource is
# healthy; the 4 provisioned dashboards (gluon-red, gluon-kafka, gluon-pods,
# gluon-infra) exist; every panel query is valid PromQL against the live
# Prometheus (via Grafana's datasource proxy, with $service = all services);
# the `service` variable resolves to all 8 services; and a core set of
# panels shows data. Run with the stack up and a smoke run behind it.
#   scripts/check-obs-dashboards.sh
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -I scripts/check_obs_dashboards.py
echo "PASS: Grafana dashboards"
