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
sbt "Gatling/testOnly gluon.perf.SmokeSimulation"
```

HTML reports are written to `target/gatling/`.
