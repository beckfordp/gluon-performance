#!/usr/bin/env bash
# Phase 1 (build, CI, remote) verification: local build green, remote set,
# latest CI run on main green.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== local build"
sbt -batch scalafmtCheck Test/scalafmtCheck test Gatling/compile < /dev/null

echo "== remote"
url=$(git remote get-url origin)
[[ "$url" == *beckfordp/gluon-performance* ]] || { echo "FAIL: origin is $url"; exit 1; }
echo "origin: $url"

echo "== latest CI run on main"
read -r status conclusion < <(gh run list --branch main --workflow CI --limit 1 \
  --json status,conclusion -q '.[0] | "\(.status) \(.conclusion)"')
[[ "$status" == "completed" && "$conclusion" == "success" ]] \
  || { echo "FAIL: CI $status/$conclusion"; exit 1; }
echo "CI: $status/$conclusion"

echo "PASS: Phase 1"
