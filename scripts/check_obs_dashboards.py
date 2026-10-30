"""Grafana dashboards check (see check-obs-dashboards.sh). Stdlib only."""
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

GRAFANA = os.environ.get("GRAFANA_URL", "http://localhost:3000")
DASHBOARDS = ["gluon-red", "gluon-kafka", "gluon-pods", "gluon-infra"]
SERVICES = [f"{s}-service" for s in
            ("cart", "catalog", "fulfilment", "inventory", "order", "payment", "user", "notification")]
# Panels that must show data once the platform has had any traffic (a smoke
# run); the rest (retries, breakers, DLQ, lag...) are legitimately empty
# until their event happens, so they only have to be valid queries.
MUST_HAVE_DATA = {
    "gluon-red": ["Request Rate (by service, route)", "Server Duration p50 / p95 / p99 (by service)",
                  "DB Query Duration p95 (by service, operation)"],
    "gluon-pods": ["CPU (cores) vs limit", "Memory working set vs limit", "CPU throttled %"],
    "gluon-infra": ["Postgres: connections (by db)", "Redis: memory used", "Connect: connector status",
                    "Debezium: connected"],
    "gluon-kafka": [],
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

    for uid in DASHBOARDS:
        try:
            dash = get(f"/api/dashboards/uid/{uid}")["dashboard"]
        except urllib.error.HTTPError:
            failures.append(f"{uid}: dashboard missing")
            continue
        variables = {v["name"]: v for v in dash.get("templating", {}).get("list", [])}
        services = SERVICES
        if "service" in variables:
            q = urllib.parse.urlencode({"match[]": "http_server_request_duration_seconds_count"})
            found = get(f"/api/datasources/proxy/uid/prometheus/api/v1/label/service/values?{q}")["data"]
            missing = sorted(set(SERVICES) - set(found))
            if missing:
                failures.append(f"{uid}: $service variable lacks {missing}")
            services = found
        panels = [p for p in dash.get("panels", []) if p.get("type") != "row"]
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
