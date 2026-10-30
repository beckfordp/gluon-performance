# Product Guidelines — gluon-performance

## Code conventions
Canonical: [`code_styleguides/scala-fp.md`](./code_styleguides/scala-fp.md), applied pragmatically to the Gatling DSL — simulations are Gatling's imperative-DSL classes; helpers (config, feeders, traceparent, profiles) are pure, typed, unit-tested. No null/var/partial functions in helpers.

## Simulation conventions
- **Open model only** (arrival-rate injection); closed-model needs a written justification
- Profiles are **multiples of measured `baseline`**, never hard-coded req/s; absolute ceiling ~50 checkouts/s
- Env-driven config (base URLs, profile); one shared `HttpProtocol`
- Every request carries a generated `traceparent`; trace id logged
- Every simulation asserts (min. `failedRequests`); perf assertions from `BASELINES.md` (PERF-11.3)
- Simulations clean up after themselves — demo data unchanged after a run
- Unique throwaway test data (customers/orders), never shared demo accounts

## Experiments
- `experiments/<id>.md`: setup, profile, questions answered (Qn), dashboard screenshots, findings
- Each run 3×, report median; spread > 15% = noise
- Record run-validity checks; discard failed runs

## Testing
- munit for helper logic; smoke simulation as integration check
- `sbt scalafmtCheck Test/scalafmtCheck test Gatling/compile` before every commit (CI enforces)
