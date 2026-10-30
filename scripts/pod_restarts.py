"""Fails if any container in `kubectl get pods -o json` (stdin) restarted or was OOM-killed."""
import json
import sys

bad = []
for pod in json.load(sys.stdin)["items"]:
    for s in pod["status"].get("containerStatuses", []):
        reason = s.get("lastState", {}).get("terminated", {}).get("reason")
        if s["restartCount"] or reason == "OOMKilled":
            bad.append(f'{pod["metadata"]["name"]} restarts={s["restartCount"]} last={reason}')
for b in bad:
    print("FAIL", b)
print("no restarts / OOMKilled" if not bad else f"{len(bad)} container(s) restarted")
sys.exit(1 if bad else 0)
