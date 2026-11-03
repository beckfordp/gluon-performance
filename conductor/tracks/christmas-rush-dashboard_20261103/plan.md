# Plan: Perf 4b — Dashboard architecture + Christmas Rush

## Phase 1: Decision + generator
- [x] Task: gluon ADR 0027 (dashboard architecture, Foundation SDK) (gluon 764d9f6)
- [ ] Task: Write failing generator tests (budgets, uids, links, About/Guide)
- [ ] Task: Generator + 7 dashboards + `bin/obs-dashboards [--check]`
- [ ] Task: Guide `docs/observability/dashboards.md`
- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: Provisioning + live check
- [ ] Task: Write failing check: `check_obs_dashboards.py` covers the 7 uids
- [ ] Task: Per-folder ConfigMaps + provider `foldersFromFilesStructure`, home = overview; retire gluon-red/gluon-infra JSON; `bin/obs up`
- [ ] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)
