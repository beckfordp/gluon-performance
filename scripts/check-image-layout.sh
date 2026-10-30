#!/usr/bin/env bash
# Asserts the Docker/stage tree has what an in-cluster run needs: simulations
# (Test classes + resources), Gatling, and an entry point that launches
# io.gatling.app.Gatling. A munit suite can't do this: it would have to run
# from inside the very test jar being staged.
set -euo pipefail
cd "$(dirname "$0")/.."

sbt -batch Docker/stage < /dev/null > target/docker-stage.log 2>&1 \
  || { echo "FAIL: Docker/stage (see target/docker-stage.log)"; exit 1; }
# native-packager stages layers (stage/<n>/opt/docker/...): look across all.
libs=(target/docker/stage/*/opt/docker/lib)
launcher=$(ls target/docker/stage/*/opt/docker/bin/gluon-performance 2>/dev/null | head -1 || true)
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

tests_jar=$(find target/docker/stage -path "*/opt/docker/lib/*-tests.jar" | head -1)
check "tests jar staged" '[[ -n "$tests_jar" ]]'
# Listing captured first: grep -q exiting early would SIGPIPE unzip under pipefail.
listing=$([[ -n "$tests_jar" ]] && unzip -l "$tests_jar" || true)
check "SmokeSimulation in tests jar" 'grep -q "gluon/perf/SmokeSimulation.class" <<< "$listing"'
check "logback-test.xml in tests jar" 'grep -q "logback-test.xml" <<< "$listing"'
check "Gatling jars staged" 'ls "${libs[@]}" | grep -q "gatling-charts-highcharts"'
check "launcher uses io.gatling.app.Gatling" '[[ -n "$launcher" ]] && grep -q "io.gatling.app.Gatling" "$launcher"'
check "tests jar on launcher classpath" '[[ -n "$launcher" && -n "$tests_jar" ]] && grep -q "$(basename "$tests_jar")" "$launcher"'

entry=$(find target/docker/stage -path "*/opt/docker/bin/run-simulation.sh" | head -1)
check "run-simulation.sh staged + executable" '[[ -n "$entry" && -x "$entry" ]]'
check "Dockerfile entrypoint is run-simulation.sh" 'grep -q "run-simulation.sh" target/docker/stage/Dockerfile'

[[ $fail == 0 ]] && echo "PASS: image layout" || exit 1
