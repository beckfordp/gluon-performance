"""Laptop budget check over `kubectl get pods -o json` on stdin (see check-pod-budget.sh)."""
import json
import os
import re
import sys

UNITS = {"Ki": 2**10, "Mi": 2**20, "Gi": 2**30, "": 1}
GATLING = 2**30  # k8s/perf-job.yaml: 1Gi


def mem(quantity):
    n, unit = re.fullmatch(r"(\d+)(Ki|Mi|Gi|)", quantity).groups()
    return int(n) * UNITS[unit]


def main():
    pods = json.load(sys.stdin)["items"]
    budget = float(os.environ.get("BUDGET_GI", "12")) * 2**30
    problems, total, containers = [], 0, 0
    for pod in pods:
        if pod["metadata"].get("labels", {}).get("app.kubernetes.io/name") == "gluon-performance":
            continue  # a Job mid-run; counted below from its template
        for c in pod["spec"]["containers"]:
            containers += 1
            name = f'{pod["metadata"]["name"]}/{c["name"]}'
            res = c.get("resources", {})
            req, lim = res.get("requests", {}), res.get("limits", {})
            if not all(k in d for d in (req, lim) for k in ("cpu", "memory")):
                problems.append(f"{name}: missing requests/limits")
                continue
            if mem(req["memory"]) != mem(lim["memory"]):
                problems.append(f'{name}: memory request {req["memory"]} != limit {lim["memory"]}')
            total += mem(lim["memory"])
    gi = 2**30
    print(f"containers: {containers}")
    print(f"memory limits: {total / gi:.2f} Gi + Gatling {GATLING / gi:.0f} Gi = "
          f"{(total + GATLING) / gi:.2f} Gi (budget {budget / gi:.0f} Gi)")
    if total + GATLING > budget:
        problems.append("over budget")
    for p in problems:
        print("FAIL", p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
