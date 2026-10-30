# Initial Concept

Gatling perf harness — per ADR 0019 and gluon PLAN.md "Performance": Gatling (sbt) load + latency simulations against gluon-local, Christmas-rush load model, experiments.

# Product — gluon-performance

## Purpose
Gatling load and latency harness for the Gluon platform (ADR 0019). Answers the questions someone provisioning, scaling and supporting Gluon would ask (Q1–Q17 in gluon `PLAN.md` "Performance"), driven by one scenario: **the Christmas rush** — spiky demand, dispatch team falling behind.

## Users
- The consultant (solo) — runs experiments, gives the ~15 min Christmas Rush demo
- Demo audience — sees thresholds/bottlenecks surface on Grafana / Tempo / Kibana

## Goals
- Generate realistic, open-model load against `gluon-local` from an in-cluster k8s Job
- Make every request traceable (W3C `traceparent`, trace id logged)
- Measure async latency (`POST /orders` → `Confirmed`) via a Kafka consumer in the simulation
- Named experiments (capacity, scaling, soak, resilience), each written up in `experiments/<id>.md` with the questions it answers
- Regression gates: p95/p99/error-rate assertions against committed `BASELINES.md`

## Non-goals
- Production capacity claims — numbers are **relative**, single-node OrbStack demo (ADR 0015)
- Functional correctness — that's the acceptance suite and `verify-*.sh`

## Scope (from gluon PLAN.md; units owned by this repo)
Performance 1 (scaffold), 2 (in-cluster Job, with gluon `bin/run-perf`), 7 (Christmas load model + dispatch bot), 8 (capacity/scaling), 9 (resilience), 10 (demo), 11 (assertions/baselines)

## Constraints
Laptop budget, run-validity rules, 3× repeat + median, demo SLOs — all per gluon `PLAN.md`. Host saturating before pods = invalid run.
