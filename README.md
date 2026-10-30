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

### In-cluster runs

Real runs happen in-cluster. The image (`sbt Docker/publishLocal` →
`gluon-performance:latest`, straight into OrbStack's docker) packages the
simulations with Gatling's own launcher. `k8s/perf-job.yaml` runs one simulation
as a Job in `gluon-local`, with 2000m CPU / 1Gi and in-cluster service URLs.
`scripts/render-job.sh <job-name> <simulation> [profile]` fills in the template.

Gluon's `bin/run-perf <simulation> [profile]` drives the whole run: launch,
wait, copy results out, delete the Job. A finished pod can't be `kubectl cp`'d,
so the container waits after the run (`src/universal/bin/run-simulation.sh`):

| File in `/results` | Meaning |
|---|---|
| `EXIT_CODE` | Gatling's exit status: 0 ok, 2 assertions failed, 1 error |
| `DONE` | Written last; the run is over |
| `COPIED` | Touched by `run-perf` after copying; the container exits then, or after `COPY_TIMEOUT` (600s) |

Checks: `scripts/check-image-layout.sh` (staged image contents),
`scripts/check-image-run.sh` (local `docker run` against port-forwards),
`scripts/check-job-manifest.sh` (server-side dry run of the Job).

### Configuration (env vars)

| Variable | Default | Meaning |
|---|---|---|
| `<SERVICE>_URL` (`ORDER_URL`, `PAYMENT_URL`, `INVENTORY_URL`, `USER_URL`, `CATALOG_URL`, `FULFILMENT_URL`, `CART_URL`, `NOTIFICATION_URL`) | `http://localhost:<port>` (18080-18087, matching `scripts/port-forward.sh`) | Service base URL |
| `PERF_PROFILE` | `smoke` | Load profile: `smoke`, `baseline`, `december-ramp`, `black-friday-spike`, `last-posting-day`, `soak` (shapes land in Performance 7) |

Invalid values fail the run at startup, listing every error.
