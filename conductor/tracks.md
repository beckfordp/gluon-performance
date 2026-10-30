# Project Tracks

This file tracks all major tracks for the project.

---


---

## Backlog

Title-only placeholders for future tracks — not yet detailed (no spec/plan, no linked
folder), so `/conductor:implement` cannot pick these up by accident. Source of truth for
scope: gluon `PLAN.md` "Performance". When ready, run `/conductor:newTrack <title>`.

- Performance 2: Run in-cluster (k8s Job image; with gluon `bin/run-perf`, pod limits, run-validity capture)
- Performance 7: Christmas load model (feeders, shopper journeys, dispatch bot, injection profiles, cleanup, async latency)
- Performance 8: Capacity and scaling experiments (knee, scale-out, soak, instrumentation overhead, lag cross-check)
- Performance 9: Resilience experiments (failure sweep, latency injection, recovery, consumer faults, pod kill)
- Performance 10: The Christmas Rush demo (spike, dispatch shortfall, trace walk, combined run)
- Performance 11: Findings, SLOs and regression gates (assertions vs `BASELINES.md`)
