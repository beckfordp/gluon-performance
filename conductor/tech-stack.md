# Tech Stack — gluon-performance

## Language / runtime
- **Scala 2.13** (latest 2.13.x) — Gatling publishes no Scala 3 artifacts; gatling-kafka-plugin is 2.13-only. Differs from services (Scala 3.9.0)
- JDK 21

## Build
- sbt 1.13.0
- gatling-sbt 4.19.2 (`GatlingPlugin`)
- sbt-scalafmt; scalafmt 3.10.7, `runner.dialect = scala213source3`
- scalac: `-Xsource:3 -Xsource-features:case-apply-copy-access -Xlint -Wunused:_` (Scala-3-leaning syntax/semantics on 2.13)
- sbt-scoverage 2.4.4
- Layout: pure helpers in `src/main` (coverage-measured, >80% gate); simulations + Gatling DSL glue (`Traced`) in `src/test`. Gatling deps Compile-scoped for the helpers

## Load testing
- Gatling 3.16.0 (`gatling-charts-highcharts` + `gatling-test-framework`)
- gatling-kafka-plugin 2.1.2 (`org.galaxio`) — added in PERF-7.6, not Performance 1

## Config
- Env vars via a small typed config object (no pureconfig — not needed for a harness)

## Logging
- logback (ships with Gatling), configured by `src/test/resources/logback-test.xml`: root WARN; `gluon.perf.trace` INFO → console + `target/gatling/trace-ids.log`

## Testing
- munit for helper logic; Gatling DSL builders tested via `GatlingConfiguration.loadForTest()`

## Packaging / run
- Container image (sbt-native-packager or plain Dockerfile — decided in PERF-2.1), run as a k8s Job in `gluon-local`, launched by gluon `bin/run-perf`
- Port-forwards for smoke runs only: `scripts/port-forward.sh up|down`, ports 18080–18087 (matching gshop's where they overlap)

## CI
- GitHub Actions: temurin 21, `sbt scalafmtCheck Test/scalafmtCheck test Gatling/compile`. No GH_PACKAGES_TOKEN — no purerestlib dependency

## Target
- Local: OrbStack k8s, namespace `gluon-local` (ADR 0002)
