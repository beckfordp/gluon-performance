# Plan — Performance 2: Run in-cluster

Gluon-repo commits need user approval (prompting on there); perf-repo commits automatic (prompting off).

## Phase 1: Container image (PERF-2.1, perf repo) [checkpoint: aca99f9]
- [x] Task: add sbt-native-packager 1.11.1; enable JavaAppPackaging + DockerPlugin (base `eclipse-temurin:21-jre`, image `gluon-performance:latest`, mainClass `io.gatling.app.Gatling`); mappings add `Test/exportedProducts` + Test dependency jars to `lib/` and the script classpath 5d93ebd
- [x] Task: write failing check (was `ImageLayoutSuite`; now `scripts/check-image-layout.sh`) — staged `Docker/stage` tree contains SmokeSimulation class jar, logback-test.xml, Gatling jars; entry script references `io.gatling.app.Gatling` 5d93ebd
- [x] Task: `src/universal/bin/run-simulation.sh` (was `src/docker/entrypoint.sh`) — runs Gatling `-s $SIMULATION -rf /results`, writes EXIT_CODE + DONE, waits ≤ `COPY_TIMEOUT` (600s) for COPIED; trace log path configurable (`TRACE_LOG`, default target/gatling/trace-ids.log, `/results/trace-ids.log` in-cluster) 6701766
- [x] Task: local check — `docker run` the image with `<SERVICE>_URL` at host port-forwards; report + EXIT_CODE + DONE appear ec93bad
- [x] Task: Conductor - User Manual Verification 'Phase 1: Container image' (Protocol in workflow.md)

## Phase 2: Job manifest (PERF-2.1, perf repo) [checkpoint: 21acda0]
- [x] Task: `k8s/perf-job.yaml` template (+ `scripts/render-job.sh`) (`${JOB_NAME}`, `${SIMULATION}`, `${PERF_PROFILE}`) — pullPolicy Never, backoffLimit 0, ttlSecondsAfterFinished 600, emptyDir `/results`, resources 2000m/1Gi request=limit, JAVA_OPTS MaxRAMPercentage=75, in-cluster `<SERVICE>_URL`s 0c7a782
- [x] Task: `kubectl apply --dry-run=server` check script + README in-cluster section 2bba8c8
- [x] Task: Conductor - User Manual Verification 'Phase 2: Job manifest' (Protocol in workflow.md)

## Phase 3: bin/run-perf (PERF-2.2, gluon) [checkpoint: 2124712]
- [x] Task: `bin/run-perf <simulation> [profile] [--build]` — preflight (orbstack context, namespace, image present), Job name `perf-<sim>-<ts>`, apply, wait for pod Running then poll for DONE, kubectl cp `/results` → `tests/performance/target/gatling-k8s/<sim>-<ts>/`, touch COPIED, delete Job; trap deletes Job on error/interrupt; exit with EXIT_CODE gluon@c76367a
- [x] Task: run `bin/run-perf SmokeSimulation` in-cluster — 8/8 OK, report on disk, Job gone gluon@c76367a
- [x] Task: Conductor - User Manual Verification 'Phase 3: bin/run-perf' (Protocol in workflow.md)

## Phase 4: Pod limits (PERF-2.3, gluon) [checkpoint: b7389f3]
- [x] Task: chart — default resources 250m/384Mi request, 500m/384Mi limit; `javaOpts` value → `JAVA_OPTS` env in deployment.yaml; `helm template` check (javaOpts 40%, not 75%: measured 100–180Mi off-heap — user decision) gluon@30171cb
- [x] Task: local-infra manifests — resources per budget on every container (Postgres ×6, Redis ×3, Kafka, Kafka Connect, Apicurio + UI, one-shot Jobs) + heap env for Kafka/Connect/Apicurio gluon@d18b184
- [x] Task: budget check script — sums memory limits across `gluon-local` pods (≤ 12 Gi), every container has requests + limits b7e090c
- [x] Task: redeploy (`bin/k8s-local-up`), all pods Ready, no OOMKilled after smoke run; re-register Debezium connectors if needed (k8s-local-up fix: gluon@7fd1bf3)
- [x] Task: Conductor - User Manual Verification 'Phase 4: Pod limits' (Protocol in workflow.md)

## Phase 5: Run validity (PERF-2.4, gluon)
- [x] Task: write failing fixture tests `bin/test/run-validity-test.sh` — PASS fixture + one INVALID fixture each for CPU p95, memory (MemAvailable; PSI unavailable), swap growth, throttling, battery power (+ short-run SKIP, unplugged mid-run, sparse samples, missing cpu.stat) gluon@a71dfdf
- [x] Task: `bin/lib/run-validity.sh` — `evaluate <samples-dir>` → validity.txt + exit status (0 valid, 3 invalid) gluon@a71dfdf
- [x] Task: sampler — background `docker run --rm alpine` loop (no --pid=host needed) logging every 5s; Gatling pod `cpu.stat` start/end; pmset/top capture; wired into bin/run-perf with hard cleanup; exit 3 when invalid (assertion failure keeps Gatling's code) gluon@0865003
- [x] Task: run `bin/run-perf SmokeSimulation` — validity.txt next to report, all PASS (throttling SKIP: run < 600 periods) gluon@0865003
- [ ] Task: Conductor - User Manual Verification 'Phase 5: Run validity' (Protocol in workflow.md)
