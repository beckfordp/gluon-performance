# Plan: Perf 4b — Dashboard architecture + Christmas Rush

## Phase 1: Decision + generator
- [x] Task: gluon ADR 0027 (dashboard architecture, Foundation SDK) (gluon 764d9f6)
- [x] Task: Write failing generator tests (budgets, uids, links, About/Guide) (gluon d49ba79)
- [x] Task: Generator + 7 dashboards + `bin/obs-dashboards [--check]` (gluon 1e7d1c9)
- [x] Task: Guide `docs/observability/dashboards.md` (gluon c058030)
- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md) (a034184, scripts/verify-perf4b-phase1.sh PASS)

## Phase 2: Provisioning + live check
- [x] Task: Write failing check: `check_obs_dashboards.py` covers the 7 uids (16f898e)
- [x] Task: Per-folder ConfigMaps + provider `foldersFromFilesStructure`, home = overview; retire gluon-red/gluon-infra JSON; `bin/obs up` (gluon a67f103; panel fixes 32786fe)
- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md) (cfb845f, scripts/verify-perf4b-phase2.sh PASS)
