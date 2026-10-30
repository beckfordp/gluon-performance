#!/usr/bin/env bash
# Laptop budget check (gluon PLAN.md "Demo, not capacity", PERF-2.3): every
# running container in gluon-local has explicit CPU/memory requests and
# limits, memory request = limit, and memory limits plus the Gatling Job's
# (k8s/perf-job.yaml) fit the 12 Gi budget inside the 16 GB OrbStack VM.
# The observability stack (Performance 3) adds its own share later;
# BUDGET_GI overrides the ceiling.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl -n gluon-local get pods --field-selector=status.phase=Running -o json \
  | python3 -I scripts/pod_budget.py
echo "PASS: pod budget"
