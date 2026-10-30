# Plan — Performance 1: Harness scaffold

## Phase 1: Build, CI and remote (PERF-1.1) [checkpoint: 2dded54]
- [x] Task: sbt build — `build.properties`, `plugins.sbt` (gatling-sbt, sbt-scalafmt, sbt-scoverage), `build.sbt` (Scala 2.13, Gatling 3.16.0, munit), `.scalafmt.conf`, `.gitignore` a98f769
- [x] Task: placeholder munit test + `Gatling/compile` passes locally (`sbt scalafmtCheck Test/scalafmtCheck test Gatling/compile`) fcaf4bc
- [x] Task: README (purpose, how to run smoke, link to gluon ADR 0019 / PLAN.md) 9f92f27
- [x] Task: GitHub Actions CI (`.github/workflows/ci.yml`, temurin 21); push; CI green 8688847
- [x] Task: Conductor - User Manual Verification 'Phase 1: Build, CI and remote' (Protocol in workflow.md)

## Phase 2: Config and shared protocol (PERF-1.2) [checkpoint: dbe8f45]
- [x] Task: write failing tests — `GluonConfig` parses env (base URL per service, profile), defaults for port-forward, accumulates errors for invalid URLs/unknown profile e9aae23
- [x] Task: implement `GluonConfig` (pure: `Map[String,String] => Either[::[ConfigError], GluonConfig]`) + `Service` ADT e9aae23
- [x] Task: `Protocols.http` — one shared `HttpProtocol` (no base URL; requests use `GluonConfig.baseUrl`) e632653
- [x] Task: Conductor - User Manual Verification 'Phase 2: Config and shared protocol' (Protocol in workflow.md)

## Phase 3: Trace-linked requests (PERF-1.4)
- [~] Task: write failing tests — `Traceparent.generate` matches W3C format, non-zero ids, unique across calls; `Traceparent.traceId` extracts id
- [ ] Task: implement `Traceparent` + Gatling helper: per-request `traceparent` header from session, trace id logged with request name + status
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Trace-linked requests' (Protocol in workflow.md)

## Phase 4: Smoke simulation (PERF-1.3)
- [ ] Task: `scripts/port-forward.sh up|down` — port-forward all 8 services from `gluon-local` to config-default ports (logs to file, no tail pipes)
- [ ] Task: `SmokeSimulation` — `GET /health/ready` per service, 1 user, trace-linked, `failedRequests.count.is(0)`
- [ ] Task: run against local cluster; confirm HTML report + trace ids in log; README run instructions updated
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Smoke simulation' (Protocol in workflow.md)
