# Spec: Perf 4b — Christmas Rush dashboard (PERF-4.12)

## Overview
One overview dashboard over the journey telemetry added in Perf 4 (service tracks
`journey-telemetry_20261103` + purerest 0.8.1). It's the screen the Christmas Rush demo
runs on (Q13–Q15), and it puts **errors** up front: today's RED dashboard only shows 5xx,
which never fire at smoke load, so a reader can't see failures happening.

## Functional Requirements
1. `infra/k8s/observability/config/grafana/dashboards/gluon-christmas-rush.json` (gluon),
   uid `gluon-christmas-rush`, added to the kustomize configMapGenerator. Rows:
   - **Demand & outcomes:** order arrival rate (`orders_placed`), checkout outcomes
     stacked, checkout p50/p95/p99 vs 1.5s SLO line, checkout success %.
   - **Errors:** HTTP error % by service (4xx and 5xx separately, vs 1% SLO), 5xx by route,
     payment declines/capture failures, inventory insufficient, DLQ publishes, stream
     restarts, email errors.
   - **Resilience:** HTTP + Kafka breaker state timeline, retry rate by outcome.
   - **Async flow:** consumer lag by group, event age p95 by group (vs 2 min SLO),
     Debezium ms behind source (the outbox hop, PERF-4.9).
   - **Dispatch (people backlog):** fulfilment backlog by state, oldest age by state,
     dispatch rate vs order arrival rate, step duration p95, order time-in-state p95.
   - **Money held:** uncaptured authorizations count and oldest age.
   - **Capacity:** pod CPU and memory % of limit, throttling, DB pool in-use/pending and
     wait p95, JVM heap, cats-effect CPU starvation.
2. `scripts/check_obs_dashboards.py` checks the new dashboard (valid queries; arrival,
   outcomes and backlog must have data after traffic).

## Acceptance Criteria
- Dashboard loads in Grafana; every panel query is valid; must-have panels show data after
  a `bin/run-acceptance` run.

## Out of Scope
- Alert rules (PERF-11.4), exemplars/Tempo links (Perf 5).
