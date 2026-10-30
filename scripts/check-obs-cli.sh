#!/usr/bin/env bash
# CLI check for gluon bin/obs (PERF-3.4): usage errors exit 2 with usage
# text, and preflight refuses a wrong kubectl context or an unreachable
# cluster before touching anything. Uses a throwaway KUBECONFIG, so the real
# cluster is never contacted.
#   scripts/check-obs-cli.sh
set -euo pipefail
cd "$(dirname "$0")/.."

OBS="../../bin/obs"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0

kubeconfig() { # <file> <context-name>
  cat > "$1" <<KCFG
apiVersion: v1
kind: Config
clusters: [{name: c, cluster: {server: "https://127.0.0.1:1"}}]
users: [{name: u, user: {token: x}}]
contexts: [{name: $2, context: {cluster: c, user: u}}]
current-context: $2
KCFG
}
kubeconfig "$work/other" other
kubeconfig "$work/orbstack" orbstack

expect() { # <name> <exit> <text in stderr> <args...>
  local name="$1" want="$2" text="$3" got=0 err
  shift 3
  err="$("$OBS" "$@" 2>&1 >/dev/null)" || got=$?
  if [ "$got" != "$want" ] || ! grep -qF -- "$text" <<< "$err"; then
    echo "FAIL $name: exit $got (want $want), stderr: $err"
    failures=$((failures + 1))
    return
  fi
  echo "ok   $name"
}

expect "no command" 2 "usage: bin/obs up|down|status"
expect "unknown command" 2 "usage: bin/obs up|down|status" sideways
expect "too many args" 2 "usage: bin/obs up|down|status" up now
expect "help" 2 "usage: bin/obs up|down|status" -h
KUBECONFIG="$work/other" expect "wrong context" 1 "kubectl context is not 'orbstack'" up
KUBECONFIG="$work/orbstack" expect "unreachable cluster" 1 "namespace gluon-local missing" status

[ "$failures" = 0 ] && echo "PASS: bin/obs CLI" || { echo "$failures failure(s)"; exit 1; }
