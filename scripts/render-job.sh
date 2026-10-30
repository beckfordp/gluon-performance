#!/usr/bin/env bash
# Renders k8s/perf-job.yaml to stdout.
#   scripts/render-job.sh <job-name> <simulation> [profile]
set -euo pipefail
cd "$(dirname "$0")/.."

job="${1:?usage: $0 <job-name> <simulation> [profile]}"
sim="${2:?usage: $0 <job-name> <simulation> [profile]}"
profile="${3:-smoke}"

# Validated so the sed substitution below can't be broken by the inputs.
[[ "$job" =~ ^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$ ]] || { echo "invalid job name: $job" >&2; exit 2; }
[[ "$sim" =~ ^[A-Za-z_][A-Za-z0-9_.]*$ ]] || { echo "invalid simulation: $sim" >&2; exit 2; }
[[ "$profile" =~ ^[a-z][a-z0-9-]*$ ]] || { echo "invalid profile: $profile" >&2; exit 2; }
label=$(tr '[:upper:]' '[:lower:]' <<< "${sim##*.}")

sed -e "s/\${JOB_NAME}/$job/g" \
    -e "s/\${SIMULATION_LABEL}/$label/g" \
    -e "s/\${SIMULATION}/$sim/g" \
    -e "s/\${PERF_PROFILE}/$profile/g" \
    k8s/perf-job.yaml
