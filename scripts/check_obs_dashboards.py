"""Grafana dashboards check (see check-obs-dashboards.sh). Stdlib only."""
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

GRAFANA = os.environ.get("GRAFANA_URL", "http://localhost:3000")
# uid -> Grafana folder (ADR 0027: 1-Overview, 2-Services, 3-Platform).
DASHBOARDS = {
    "gluon-christmas-rush": "1-Overview",
    "gluon-service": "2-Services",
    "gluon-checkout": "2-Services",
    "gluon-dispatch": "2-Services",
    "gluon-pods": "3-Platform",
    "gluon-data-stores": "3-Platform",
    "gluon-kafka": "3-Platform",
}
SERVICES = [f"{s}-service" for s in
            ("cart", "catalog", "fulfilment", "inventory", "order", "payment", "user", "notification")]
# Panels that must show data once the platform has had traffic (a smoke or
# acceptance run); the rest (5xx, retries, breakers, DLQ, lag...) are
# legitimately empty until their event happens, so they only have to be valid.
MUST_HAVE_DATA = {
    "gluon-christmas-rush": ["Orders placed /s", "Checkout outcomes /s", "Fulfilment backlog by state",
                             "Uncaptured authorizations (money held)", "Service saturation: CPU % of limit"],
    "gluon-service": ["Request rate by route", "Server latency p50 / p95 / p99", "DB query p95 by operation",
                      "DB pool: in use / pending", "JVM heap used vs max"],
    "gluon-checkout": ["Checkout outcomes /s", "Authorize outcomes /s", "Inventory reservations /s"],
    "gluon-dispatch": ["Fulfilment backlog by state", "Event age at consume p95 (SLO 2 min)",
                       "Outbox → Kafka: Debezium behind source"],
    "gluon-pods": ["CPU (cores) vs limit", "Memory working set vs limit", "CPU throttled %",
                   "JVM heap used by service"],
    "gluon-data-stores": ["Connections by db", "Memory used"],
    "gluon-kafka": ["Connector status", "Debezium connected", "Topic write rate"],
}


def get(path):
    with urllib.request.urlopen(GRAFANA + path, timeout=10) as r:
        return json.load(r)


def prom(expr):
    q = urllib.parse.urlencode({"query": expr})
    try:
        return get(f"/api/datasources/proxy/uid/prometheus/api/v1/query?{q}")
    except urllib.error.HTTPError as e:
        return json.loads(e.read() or b"{}") | {"status": "error"}


def substitute(expr, services):
    return (expr.replace("$__rate_interval", "1m")
            .replace('"$service"', '"order-service"')  # single-select: one real service
            .replace("${service:regex}", "|".join(services))
            .replace("$service", "|".join(services))
            .replace("$pod", ".*"))


def main():
    failures = []
    health = get("/api/health")
    print(f"ok   grafana {health.get('version')} database {health.get('database')}")
    ds = get("/api/datasources/uid/prometheus/health")
    if ds.get("status") != "OK":
        failures.append(f"datasource prometheus: {ds}")
    else:
        print("ok   datasource prometheus healthy")

    for uid, folder in DASHBOARDS.items():
        try:
            found_dash = get(f"/api/dashboards/uid/{uid}")
        except urllib.error.HTTPError:
            failures.append(f"{uid}: dashboard missing")
            continue
        dash = found_dash["dashboard"]
        if found_dash["meta"].get("folderTitle") != folder:
            failures.append(f"{uid}: in folder {found_dash['meta'].get('folderTitle')!r}, expected {folder!r}")
        variables = {v["name"]: v for v in dash.get("templating", {}).get("list", [])}
        services = SERVICES
        if "service" in variables:
            q = urllib.parse.urlencode({"match[]": "http_server_request_duration_seconds_count"})
            found = get(f"/api/datasources/proxy/uid/prometheus/api/v1/label/service/values?{q}")["data"]
            missing = sorted(set(SERVICES) - set(found))
            if missing:
                failures.append(f"{uid}: $service variable lacks {missing}")
            services = found
        panels = [p for p in dash.get("panels", []) if p.get("type") not in ("row", "text")]
        empty_ok, bad = 0, 0
        for p in panels:
            data = False
            for t in p.get("targets", []):
                r = prom(substitute(t.get("expr", ""), services))
                if r.get("status") != "success":
                    failures.append(f"{uid} / {p['title']}: query error {r.get('error')}")
                    bad += 1
                elif r["data"]["result"]:
                    data = True
            if not data:
                empty_ok += 1
                if p["title"] in MUST_HAVE_DATA[uid]:
                    failures.append(f"{uid} / {p['title']}: no data")
        absent = [t for t in MUST_HAVE_DATA[uid] if t not in {p["title"] for p in panels}]
        failures += [f"{uid}: expected panel '{t}' missing" for t in absent]
        print(f"{'ok  ' if not bad else 'FAIL'} {uid}: {len(panels)} panels, {bad} bad queries, "
              f"{empty_ok} without data yet")

    for f in failures:
        print("FAIL", f)
    return 1 if failures else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except urllib.error.URLError as e:
        print(f"FAIL: Grafana unreachable at {GRAFANA} ({e}) — is the stack up (bin/obs up)?")
        sys.exit(1)
