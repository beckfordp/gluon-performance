#!/usr/bin/env bash
# Phase 1 verification for obs-stack_20261030 (PLAN.md PERF-3.4 groundwork):
# budget helper fixtures, bin/obs CLI checks, the kustomization builds, and
# bin/obs status/up/down run cleanly against gluon-local.
#   scripts/verify-perf3b-phase1.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GLUON_DIR="$(cd ../.. && pwd)"

echo "== obs-budget fixtures =="
"$GLUON_DIR/bin/test/obs-budget-test.sh" | tail -1
echo "== bin/obs CLI =="
scripts/check-obs-cli.sh | tail -1
echo "== kustomization builds =="
kubectl kustomize "$GLUON_DIR/infra/k8s/observability" > /dev/null && echo "PASS: kubectl kustomize"
echo "== bin/obs against gluon-local =="
for cmd in status up down; do
  "$GLUON_DIR/bin/obs" "$cmd" > /dev/null
  echo "PASS: bin/obs $cmd"
done
echo "PASS: Phase 1 (skeleton, budget, bin/obs) verified"
