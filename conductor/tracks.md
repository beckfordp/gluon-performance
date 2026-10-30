# Project Tracks

This file tracks all major tracks for the project.

- [ ] **Track: Performance 3b: Observability stack in-cluster (PERF-3.1–3.4)**
  *Link: [./tracks/obs-stack_20261030/](./tracks/obs-stack_20261030/)*

---


---

## Backlog

Title-only placeholders for future tracks — not yet detailed (no spec/plan, no linked
folder), so `/conductor:implement` cannot pick these up by accident. Source of truth for
scope: gluon `PLAN.md` "Performance". When ready, run `/conductor:newTrack <title>`.

- Performance 7: Christmas load model (feeders, shopper journeys, dispatch bot, injection profiles, cleanup, async latency) — note: Redis pods have 64Mi limits but no `maxmemory`; set per instance (cache vs data) before real load (Perf 2 review)
- Performance 8: Capacity and scaling experiments (knee, scale-out, soak, instrumentation overhead, lag cross-check)
- Performance 9: Resilience experiments (failure sweep, latency injection, recovery, consumer faults, pod kill)
- Performance 10: The Christmas Rush demo (spike, dispatch shortfall, trace walk, combined run)
- Performance 11: Findings, SLOs and regression gates (assertions vs `BASELINES.md`)
