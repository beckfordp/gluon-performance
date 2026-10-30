# Tech Stack — gluon-performance

## Language / runtime
- **Scala 2.13** (latest 2.13.x) — Gatling publishes no Scala 3 artifacts; gatling-kafka-plugin is 2.13-only. Differs from services (Scala 3.9.0)
- JDK 21

## Build
- sbt 1.13.0
- gatling-sbt 4.19.2 (`GatlingPlugin`)
- sbt-scalafmt; scalafmt 3.10.7, `runner.dialect = scala213`

## Load testing
- Gatling 3.16.0 (`gatling-charts-highcharts` + `gatling-test-framework`)
- gatling-kafka-plugin 2.1.2 (`org.galaxio`) — added in PERF-7.6, not Performance 1

## Config
- Env vars via a small typed config object (no pureconfig — not needed for a harness)

## Testing
- munit for helper logic

## Packaging / run
- Container image (sbt-native-packager or plain Dockerfile — decided in PERF-2.1), run as a k8s Job in `gluon-local`, launched by gluon `bin/run-perf`
- Port-forwards for smoke runs only

## CI
- GitHub Actions: temurin 21, `sbt scalafmtCheck Test/scalafmtCheck test Gatling/compile`. No GH_PACKAGES_TOKEN — no purerestlib dependency

## Target
- Local: OrbStack k8s, namespace `gluon-local` (ADR 0002)
