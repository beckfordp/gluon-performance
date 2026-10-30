#!/usr/bin/env bash
# Phase 3 (trace-linked requests) verification: traceparent/trace-log suites
# ran and passed, and the Traced DSL helper compiles with the simulations.
# Live trace ids in a run are checked by verify-phase4.sh (smoke run).
set -euo pipefail
cd "$(dirname "$0")/.."
log=$(mktemp)

sbt -batch scalafmtCheck Test/scalafmtCheck test Gatling/compile < /dev/null | tee "$log" | grep -E "Passed"
for suite in TraceparentSuite TraceLogSuite; do
  grep -q "gluon.perf.$suite" "$log" || { echo "FAIL: $suite did not run"; exit 1; }
done
grep -q 'logger name="gluon.perf.trace"' src/test/resources/logback-test.xml \
  || { echo "FAIL: trace logger not configured"; exit 1; }

echo "PASS: Phase 3"
