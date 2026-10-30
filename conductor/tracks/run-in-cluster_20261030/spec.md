# Spec — Performance 2: Run in-cluster

Source: gluon `PLAN.md` "Performance 2", ADR 0019 §2. Repos: `tests/performance` (image, Job), `gluon` (`bin/run-perf`, pod limits).

## Overview
Run simulations as a k8s Job inside `gluon-local` (port-forwards bottleneck results); tight explicit pod limits so pods saturate before the host; run-validity checks recorded with every report.

## Functional Requirements
- **PERF-2.1 Image + Job** (perf repo)
  - sbt-native-packager `Docker/publishLocal` → `gluon-performance:latest` on `eclipse-temurin:21-jre` (same as services); mappings add Test classes, Test resources and Test dependency jars — simulations stay in `src/test`
  - Entrypoint: `io.gatling.app.Gatling -s <SIMULATION> -rf /results`, PERF_PROFILE + `<SERVICE>_URL=http://<svc>:8080` from Job env
  - Wait-for-copy: after the run, writes `/results/EXIT_CODE` (Gatling exit status) + `/results/DONE`, then waits ≤ 10 min for `/results/COPIED` before exiting
  - Job manifest template `k8s/perf-job.yaml`: `pullPolicy: Never`, `backoffLimit: 0`, resources 2000m/1Gi (request = limit), `-XX:MaxRAMPercentage=75`
- **PERF-2.2 `bin/run-perf <simulation> [profile]`** (gluon)
  - Builds image if missing (`--build` forces), applies Job with unique name, waits for DONE, copies `/results` → `tests/performance/target/gatling-k8s/<sim>-<timestamp>/`, touches COPIED, deletes Job
  - Exits with the simulation's exit code (assertion failure fails the script); Job deleted on Ctrl-C/error
- **PERF-2.3 Pod limits** (gluon)
  - Chart default: request 250m/384Mi, limit 500m/384Mi; new `javaOpts` value (default `-XX:MaxRAMPercentage=40` — amended 2026-10-30 from 75%: services measured at 100–180Mi off-heap, so 75% of 384Mi would OOM) → `JAVA_OPTS`
  - local-infra: Postgres 256Mi/500m, Redis 64Mi/100m, Kafka 1Gi/1000m, Kafka Connect 1Gi/1000m, Apicurio 512Mi/500m, Apicurio UI 128Mi/200m; memory request = limit; one-shot Jobs (Debezium register, outbox-cleanup) small limits
  - Redeploy; every pod Ready and within limits
- **PERF-2.4 Run validity** (gluon `bin/run-perf`)
  - During the run, a sampler container in the OrbStack VM records every 5s: VM CPU% (`/proc/stat`), memory PSI (`/proc/pressure/memory`), swap (`/proc/meminfo`); Gatling pod throttling from its cgroup `cpu.stat` (start vs end); mains power via `pmset -g batt`; top-5 host CPU processes (informational)
  - Writes `validity.txt` (raw numbers + PASS/INVALID per rule) next to the report; invalid run flagged loudly with a distinct exit code from an assertion failure
  - Evaluation logic is a pure-ish shell function tested against fixture sample files

## Thresholds (from PLAN.md rules)
VM CPU p95 < 80%; memory: MemAvailable min ≥ 10% of MemTotal (amended 2026-10-30: OrbStack kernel has no PSI); swap used doesn't grow (≤ 1MB); throttled periods < 5% of the Gatling pod's periods, SKIP under 600 periods (amended: a short run's ratio is JVM start-up noise); on AC power at start and end.

## Non-Functional
- Laptop budget holds: all limits fit ~12 GB inside the 16 GB VM
- `bin/run-perf` follows bin/ conventions: set -euo pipefail, orbstack context check, background processes logged to files, no pipes to tail, hard cleanup

## Acceptance Criteria
- `bin/run-perf SmokeSimulation` → in-cluster run, 8/8 OK, report + `validity.txt` on local disk, Job deleted
- Every gluon-local pod has explicit requests/limits; platform healthy after redeploy (smoke green)
- Validity evaluation tests pass for a PASS fixture and each INVALID rule

## Out of Scope
Observability stack (Performance 3); real load profiles (Performance 7); scale-out; CI running in-cluster.
