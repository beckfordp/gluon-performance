# Project Tracks

This file tracks all major tracks for the project.


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
- Obs stack startup race: bin/obs up — Filebeat starts before ES ready (backoff delays logs ~2min); Grafana wedges on first boot (health probe 1s timeouts, sqlite lock, panels never load; pod restart fixes)
