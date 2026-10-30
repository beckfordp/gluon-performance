# Spec: Perf 3b — Observability stack in-cluster (PERF-3.1–3.4)

## Overview
This track deploys Prometheus, Grafana, Elasticsearch, Kibana and Filebeat into
`gluon-local` as an opt-in stack, so a `bin/run-perf` run can be watched live. It's the
second half of gluon PLAN.md Performance 3; Perf 3a (latency buckets, purerest track
`latency-buckets_20261030`) is done. The manifests are plain YAML in gluon
`infra/k8s/observability/`, and `bin/obs up|down` manages them. `bin/k8s-local-up` does
**not** apply them. Image versions match purerest's compose: Prometheus v3.13.3,
Grafana 13.0.2, ES/Kibana/Filebeat 8.19.19.

## Functional Requirements
1. **Prometheus**:
   - `kubernetes_sd_configs` on endpoints in `gluon-local` with a port named `metrics`
     (all 8 services, unchanged chart), plus exporters.
   - ServiceAccount and RBAC to list/watch endpoints, pods and nodes.
   - Scrape interval 5s, retention short (e.g. 2d / 1GB), emptyDir storage.
2. **Pod signals**:
   - kubelet cAdvisor scrape (via the API server node proxy) for container CPU, memory
     and CFS throttling.
   - kube-state-metrics for restarts, limits/requests and OOMKilled reasons.
3. **Postgres + Redis**:
   - One multi-target `postgres_exporter` for the 7 DBs.
   - One multi-target `redis_exporter` for the 3 Redis instances.
4. **Kafka**:
   - `kafka-exporter` for consumer-group lag per topic/partition, which cross-checks
     purekafka's own lag gauge.
   - Kafka Connect/Debezium JMX via the Prometheus JMX exporter javaagent (fetched by an
     initContainer): connector/task status, plus Debezium streaming metrics (e.g.
     MilliSecondsBehindSource) for the outbox→Kafka hop.
5. **Logs**:
   - Elasticsearch single-node (security off, heap 512m) and Kibana.
   - Filebeat as a DaemonSet with kubernetes autodiscover on `gluon-local` pods. It
     decodes JSON lines; non-JSON lines such as span-exporter output are kept as
     `message`. It adds `service.name` from the pod's `app` label and writes to
     `gluon-logs-*`.
   - A one-shot `kibana-setup` Job creates the `gluon-logs` data view, the default index
     and a saved search, idempotently, as purerest's does.
6. **Grafana**:
   - Anonymous admin (local only), with a provisioned Prometheus datasource.
   - purerest.json and purekafka.json ported and templated by a `service` multi-select
     variable. The order→inventory-specific panels are generalised (client duration by
     `server.address`, DB duration/errors by service).
   - A new **Gluon pods** dashboard: CPU vs limit, memory vs limit, throttled %,
     restarts and OOMKills per pod.
   - A new **Gluon infra** dashboard: Postgres connections/tx/locks, Redis
     memory/ops/hit rate, Kafka lag, Connect/Debezium status and lag.
   - Dashboards come from JSON files in the repo, via ConfigMap provisioning.
7. **Access**: `type: LoadBalancer` services, which OrbStack serves on localhost:
   Grafana :3000, Kibana :5601, Prometheus :9092.
8. **`bin/obs up|down|status`**:
   - `up` applies the manifests, waits for ready, runs kibana-setup and prints the URLs.
   - `down` deletes the stack, leaving the services untouched.
   - `status` shows the pods and the stack's memory against budget.
   - Preflight checks match `bin/run-perf`.

## Non-Functional Requirements
- **Budget**: every container has request = limit memory. Stack total ≤ 3Gi, with ES
  ≤1.2Gi. Services + infra + obs + Gatling ≤ 12Gi. The budget is noted in
  `environments/local` (README or a values note).
- No changes to the service code or chart, apart from scrape-related labels if they're
  needed.
- Idempotent: `bin/obs up` twice is harmless.

## Acceptance Criteria
- `scripts/verify-perf3b-*.sh` (in gluon-performance) checks:
  - Prometheus has all 8 services and every exporter `up == 1`.
  - p99 queries return plausible, non-zero values after a smoke run.
  - ES has `gluon-logs-*` docs from all 8 services with `trace_id`.
  - The Kibana data view exists.
  - The Grafana dashboards load with a non-empty `service` variable.
- **Exit criterion (PLAN.md)**: all services are visible in Grafana and Kibana during a
  `bin/run-perf SmokeSimulation` run, and p99 panels show plausible values. The run's
  `validity.txt` stays valid with the stack up.
- `bin/obs down` returns the namespace memory to the pre-`up` total.

## Out of Scope
- Tempo/traces (Perf 5), new business metrics (Perf 4), alerting/Alertmanager,
  persistent volumes, auth.
- Fixing the purerest release.yml plugin issue (purerest backlog).
