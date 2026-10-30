#!/usr/bin/env bash
# Validates the rendered Job against the live API server (no Job is created)
# and checks render-job.sh rejects unsafe input.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/render-job.sh perf-manifest-check SmokeSimulation baseline \
  | kubectl apply --dry-run=server -f -
rendered=$(scripts/render-job.sh perf-manifest-check SmokeSimulation baseline)
grep -q '\${' <<< "$rendered" && { echo "FAIL: unrendered placeholder"; exit 1; }
grep -q 'value: "baseline"' <<< "$rendered" || { echo "FAIL: profile not rendered"; exit 1; }

for bad in "Bad Name|X" "perf-x|Smoke;rm" "perf-x|SmokeSimulation|Smoke/Profile"; do
  IFS='|' read -r job sim profile <<< "$bad"
  if scripts/render-job.sh "$job" "$sim" ${profile:+"$profile"} > /dev/null 2>&1; then
    echo "FAIL: accepted unsafe input '$bad'"; exit 1
  fi
done
echo "PASS: Job manifest"
