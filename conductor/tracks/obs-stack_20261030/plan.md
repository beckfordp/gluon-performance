# Plan: Perf 3b — Observability stack in-cluster

Testing approach: this is infra, not Scala, so "failing test first" means a check script
that fails before the change and passes after. Each check goes under
`tests/performance/scripts/check-obs-*.sh`. There's a pure helper with bash fixture
tests, as with run-validity.

## Phase 1: Skeleton, budget and bin/obs [checkpoint: 8ec30a8]
- [x] Task: `bin/lib/obs-budget.sh` + `bin/test/obs-budget-test.sh` (fixture tests
      first). It sums container memory limits from `kubectl get pods -o json` for the
      obs stack and for the namespace, and fails if the stack is over 3Gi or the total is
      over 11Gi (12Gi minus Gatling's 1Gi). gluon f1a1721
- [x] Task: `infra/k8s/observability/` skeleton: a kustomization or directory apply, a
      common `app.kubernetes.io/part-of: gluon-obs` label (so `down` deletes by label),
      and a budget note in `environments/local/README.md`. gluon c00ba21
- [x] Task: `bin/obs up|down|status`: preflight, apply, wait, URLs, budget check.
      `scripts/check-obs-cli.sh` first; it fails on usage and preflight cases. gluon 1bd924c, perf 81c9b22
- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md).
      `scripts/verify-perf3b-phase1.sh` 8ec30a8

## Phase 2: Prometheus + exporters (PERF-3.1) [checkpoint: 067f6ad]
- [x] Task: `check-obs-targets.sh` first: it queries `/api/v1/targets` and requires each
      expected job to be `up`. 7b174a5
- [x] Task: Prometheus Deployment, ServiceAccount/RBAC, ConfigMap (k8s SD on `metrics`
      port, cAdvisor via node proxy, exporter jobs) and a LoadBalancer on :9092. gluon 2db74c7
      Deviation: OrbStack's kubelet cAdvisor exports no container series (Docker via
      cri-dockerd), so a cAdvisor DaemonSet in raw-cgroup mode instead: least privilege
      (user's choice): unprivileged, nobody, read-only, only /sys/fs/cgroup mounted.
      Pod-level series keyed by `pod_uid`. Also: 6 Postgres, not 7 (cart has none).
- [x] Task: kube-state-metrics (namespace-scoped RBAC). gluon 8e0bd5e
- [x] Task: postgres_exporter (multi-target, 6 DBs, credentials from the existing
      secrets) and redis_exporter (multi-target, 3 instances). gluon 5903bc3
- [x] Task: kafka-exporter, plus the Kafka Connect JMX exporter javaagent (initContainer
      + JMX rules for connect and Debezium). This edits `local-infra/kafka-connect.yaml`,
      the one change outside obs/. The agent is inert when Prometheus isn't scraping. gluon f8a2868
      Found: connect-configs/connect-status had cleanup.policy=delete, so a Connect
      restart failed; altered to compact on the live broker. Root cause open (follow-up).
- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md).
      `verify-perf3b-phase2.sh`: all targets up, a smoke run, then non-zero p99 via
      `histogram_quantile` per service. 067f6ad

## Phase 3: Logs — ES, Kibana, Filebeat (PERF-3.2)
- [x] Task: `check-obs-logs.sh` first: ES `gluon-logs-*` holds docs for all 8
      `service.name` values, at least one with `trace_id`, and the Kibana data view
      `gluon-logs` exists. 72e99d9 (trace_id parsed from span-exporter lines:
      app code logs nothing on /health/ready, the smoke's only endpoint)
- [x] Task: Elasticsearch (single-node, heap 512m, limit ≤1.2Gi) and Kibana
      (LoadBalancer :5601). gluon 0c70a57
- [x] Task: Filebeat DaemonSet (RBAC, hostPath /var/log/containers, autodiscover on
      gluon-local, JSON decode, service.name from the `app` label). gluon 8c577cb
      Also dissects span-exporter lines into trace_id/span_id/span_name.
- [~] Task: The kibana-setup Job (data view, default index, saved search), run by
      `bin/obs up`.
- [ ] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md).
      `verify-perf3b-phase3.sh`

## Phase 4: Grafana + dashboards (PERF-3.3)
- [ ] Task: `check-obs-dashboards.sh` first. Through the Grafana API it checks that the
      datasource is healthy and that the 4 dashboards exist, and runs each panel's
      queries for a non-empty `service` variable.
- [ ] Task: Grafana (anonymous admin, datasource and dashboard provisioning via
      ConfigMaps from the repo JSON) and a LoadBalancer on :3000.
- [ ] Task: Port purerest.json and purekafka.json with `service` templating and
      generalised panels.
- [ ] Task: New "Gluon pods" dashboard (CPU/mem vs limit, throttled %, restarts,
      OOMKills).
- [ ] Task: New "Gluon infra" dashboard (Postgres, Redis, Kafka lag, Connect/Debezium).
- [ ] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md).
      `verify-perf3b-phase4.sh`

## Phase 5: Exit criteria + docs (PERF-3.4)
- [ ] Task: The full exit check, `verify-perf3b-phase5.sh`:
      - `bin/obs up` from cold, with the budget check passing.
      - `bin/run-perf SmokeSimulation` exits 0, with validity valid.
      - All Phase 2–4 checks green.
      - `bin/obs down` returns memory to the baseline.
      - A Grafana screenshot for the user (browser) is a manual extra.
- [ ] Task: Docs: gluon-performance README ("Watching a run"), the `environments/local`
      budget table, and a CHANGELOG/PLAN tick (outside the track).
- [ ] Task: Conductor - User Manual Verification 'Phase 5' (Protocol in workflow.md)

## Risks
- Kibana memory: 8.x wants about 700Mi–1Gi. If it OOMs, raise its limit and drop
  Prometheus retention.
- cAdvisor via the API server proxy on OrbStack needs a check; the fallback is a direct
  kubelet :10250 scrape with a token.
- The Connect JMX agent's jar download needs network at startup; pin the version and use
  a Maven Central URL.
- The Filebeat hostPath layout on OrbStack needs a check (`/var/log/containers` symlinks
  into `/var/log/pods`).
