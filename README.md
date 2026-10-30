# gluon-performance

Gatling load and latency harness for the [Gluon](https://github.com/beckfordp/gluon)
platform. It answers the provisioning, scaling and support questions in Gluon's
`PLAN.md` "Performance" section, driven by one scenario: the Christmas rush.
See [ADR 0019](https://github.com/beckfordp/gluon/blob/main/docs/adr/0019-gatling-performance-harness.md)
for why Gatling.

Numbers come from a single-node local OrbStack cluster. They are **relative, demo
numbers**, not production capacity claims.

## Prerequisites

- sbt / JDK 21
- The Gluon platform deployed to the local OrbStack cluster (namespace `gluon-local`)

No GitHub Packages token is needed. This harness depends on nothing published
from `beckfordp/purerest`.

## Layout

- `src/main/scala/gluon/perf/`: pure helpers (config, traceparent, protocol),
  unit-tested and coverage-measured
- `src/test/scala/gluon/perf/`: Gatling simulations and munit suites
- `conductor/`: product, tech stack, workflow and tracks

## Build and test

```
sbt scalafmtCheck Test/scalafmtCheck test Gatling/compile
```

## Running a simulation

Smoke runs go through port-forwards (Performance 1). Real runs happen in-cluster as a
k8s Job via Gluon's `bin/run-perf` (Performance 2), since port-forwards bottleneck
results.

```
scripts/port-forward.sh up                          # all 8 services -> localhost:18080-18087
sbt "Gatling/testOnly gluon.perf.SmokeSimulation"
scripts/port-forward.sh down
```

- HTML report: `target/gatling/<simulation>-<timestamp>/index.html`
- Trace ids: `target/gatling/trace-ids.log`, one line per request
  (`trace request="..." status=... trace_id=...`). Look a slow request up by
  `trace_id` in the services' span logs (Tempo from Performance 5).

### Configuration (env vars)

| Variable | Default | Meaning |
|---|---|---|
| `<SERVICE>_URL` (`ORDER_URL`, `PAYMENT_URL`, `INVENTORY_URL`, `USER_URL`, `CATALOG_URL`, `FULFILMENT_URL`, `CART_URL`, `NOTIFICATION_URL`) | `http://localhost:<port>` (18080-18087, matching `scripts/port-forward.sh`) | Service base URL |
| `PERF_PROFILE` | `smoke` | Load profile: `smoke`, `baseline`, `december-ramp`, `black-friday-spike`, `last-posting-day`, `soak` (shapes land in Performance 7) |

Invalid values fail the run at startup, listing every error.
