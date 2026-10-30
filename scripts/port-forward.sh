#!/usr/bin/env bash
# Port-forward every Gluon service from gluon-local to the harness's default
# ports (see src/main/scala/gluon/perf/Service.scala). For smoke runs only:
# port-forwards bottleneck real load (ADR 0019).
#
#   scripts/port-forward.sh up     start all, wait until each port accepts
#   scripts/port-forward.sh down   stop all
set -euo pipefail
cd "$(dirname "$0")/.."

NAMESPACE="${NAMESPACE:-gluon-local}"
STATE_DIR=target/port-forward
SERVICES=(
  "order-service 18080"
  "payment-service 18081"
  "inventory-service 18082"
  "user-service 18083"
  "catalog-service 18084"
  "fulfilment-service 18085"
  "cart-service 18086"
  "notification-service 18087"
)

down() {
  [[ -d "$STATE_DIR" ]] || return 0
  for pidfile in "$STATE_DIR"/*.pid; do
    [[ -e "$pidfile" ]] || continue
    pid=$(cat "$pidfile")
    kill "$pid" 2>/dev/null || true
    sleep 0.2
    kill -9 "$pid" 2>/dev/null || true
    rm -f "$pidfile"
  done
  echo "port-forwards stopped"
}

up() {
  down > /dev/null
  mkdir -p "$STATE_DIR"
  for entry in "${SERVICES[@]}"; do
    read -r svc port <<< "$entry"
    nohup kubectl -n "$NAMESPACE" port-forward "svc/$svc" "$port:8080" \
      > "$STATE_DIR/$svc.log" 2>&1 < /dev/null &
    echo $! > "$STATE_DIR/$svc.pid"
  done
  for entry in "${SERVICES[@]}"; do
    read -r svc port <<< "$entry"
    for _ in $(seq 1 50); do
      nc -z localhost "$port" 2>/dev/null && break
      sleep 0.2
    done
    nc -z localhost "$port" 2>/dev/null \
      || { echo "FAIL: $svc not reachable on :$port (see $STATE_DIR/$svc.log)"; down; exit 1; }
    echo "$svc -> localhost:$port"
  done
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  *) echo "usage: $0 up|down" >&2; exit 2 ;;
esac
