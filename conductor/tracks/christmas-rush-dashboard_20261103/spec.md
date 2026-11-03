# Spec: Perf 4b — Dashboard architecture + Christmas Rush (PERF-4.12)

## Overview
Perf 4 adds many journey/runtime metrics (service tracks `journey-telemetry_20261103` +
purerest 0.8.1). One 31-panel dashboard can't show them well. So the scope widens from a
single dashboard to a small, organised **dashboard set**, built as code. It follows industry
practice (gluon ADR 0027): symptoms (RED) at the top and causes (USE) below, a 3-level
drill-down, templated dashboards instead of copies, and a panel budget per level. **Errors
come first:** today's RED dashboard only shows 5xx, which never fire at smoke load.

## Functional Requirements
1. **Generator (gluon, `infra/k8s/observability/dashboards/`)**: Python + Grafana
   Foundation SDK (pinned), run by `bin/obs-dashboards [--check]`. Writes JSON into
   `config/grafana/dashboards/<folder>/`. `--check` fails if the committed JSON is stale.
2. **Seven dashboards in three Grafana folders**:
   - `1-Overview`: **Christmas Rush** `gluon-christmas-rush` (≤12 panels): demand,
     checkout outcomes/latency vs SLO, error % by service, event age vs SLO, dispatch vs
     arrival, backlog, money held, saturation.
   - `2-Services`: **Service** `gluon-service` (`$service`, ≤20; replaces `gluon-red`);
     **Checkout & payments** `gluon-checkout`; **Dispatch & async flow** `gluon-dispatch`.
   - `3-Platform`: **Pods & runtime** `gluon-pods`; **Data stores** `gluon-data-stores`
     (replaces `gluon-infra`); **Kafka & Debezium** `gluon-kafka`.
3. **Navigation**: every dashboard has a header dropdown of all gluon dashboards (keeps the
   time range and variables). Per-service series on the overview data-link to the Service
   dashboard (`var-service`); pod series data-link to Pods & runtime (`var-pod`). Overview
   rows have panel links to their L1 dashboard.
4. **Self-describing**: each dashboard has a description, a collapsed **About this
   dashboard** row (purpose, when to use it, how to read it, research links), and a
   **Guide** header link to `docs/observability/dashboards.md` (gluon) at its section.
5. **Provisioning**: one ConfigMap per folder, mounted as subdirectories, provider
   `foldersFromFilesStructure: true`. Grafana's home dashboard becomes the overview.
6. **Checks**: generator unit tests (budgets, unique uids, links resolve, every dashboard
   has a description + About + Guide); `scripts/check_obs_dashboards.py` covers the 7 uids
   (valid queries; must-have panels have data after traffic).

## Acceptance Criteria
- `bin/obs-dashboards --check` and the generator tests pass.
- All 7 dashboards load in their folders; every query is valid; must-have panels show data
  after a `bin/run-acceptance` run; data links land on the Service/Pods dashboards with
  the variable set.

## Out of Scope
- Alert rules and SLO burn-rate tooling (PERF-11; Pyrra is a candidate), exemplars and
  Tempo links (Perf 5).
