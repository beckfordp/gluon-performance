# Spec — Performance 1: Harness scaffold

Source: gluon `PLAN.md` "Performance 1", ADR 0019.

## Goal
Buildable, CI-checked Gatling harness with env-driven config, trace-linked requests, and a smoke simulation green against the local cluster.

## Requirements
- **PERF-1.1** — sbt 1.13.0 + gatling-sbt 4.19.2, Scala 2.13, Gatling 3.16.0; scalafmt 3.10.7; `.gitignore`; README; GitHub Actions CI (`scalafmtCheck Test/scalafmtCheck test Gatling/compile`); remote `beckfordp/gluon-performance` (public)
- **PERF-1.2** — typed config from env: base URL per service (8 services: catalog, cart, user, order, payment, inventory, fulfilment, notification), profile name; defaults = `http://localhost:<port>` for port-forward smoke runs; invalid env → clear error, not exception soup. One shared `HttpProtocol` (JSON accept, no caching, no warm-up)
- **PERF-1.3** — `SmokeSimulation`: `GET /health/ready` on every service, 1 user, assertion `global.failedRequests.count.is(0)`
- **PERF-1.4** — every request carries a fresh W3C `traceparent` (`00-<32 hex>-<16 hex>-01`, non-zero ids); trace id stored in session and logged per request (request name, status, trace id) so a slow request can be found in Tempo

## Non-goals
In-cluster Job (Performance 2); real journeys/feeders (Performance 7); perf assertions/baselines (Performance 11); Kafka plugin.

## Acceptance
- CI green on `main`
- Helpers (config, traceparent) unit-tested, >80% coverage on helper code
- `sbt "Gatling/testOnly *SmokeSimulation"` against port-forwarded `gluon-local` → 0 failures, HTML report under `target/gatling/`
- Report request → trace id visible in run log

## Risks
- Gatling's Scala DSL on 2.13 vs scala-fp.md (Scala 3 oriented) — styleguide applied pragmatically, per product-guidelines
- Port-forwarding 8 services for smoke — helper script; port mapping must match config defaults
