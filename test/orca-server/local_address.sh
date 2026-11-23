#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/local_address.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

DATA=/var/lib/orca-server
LOG="$DATA/orca-server.log"
# Orca runs as `orca-ide .../index.js serve ...`, so match the argument list.
orca_pids() { pgrep -f 'index\.js serve' || true; }

serves_http() {
  local code
  for _ in $(seq 90); do
    code="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:6768/ || true)"
    if [ "$code" -ge 200 ] && [ "$code" -lt 500 ]; then return 0; fi
    sleep 1
  done
  echo "no HTTP answer in 90 s, last code $code" >&2
  return 1
}

stamp() { sed -n "s/^orca-server: \([0-9T:.Z-]*\) entrypoint: $1\$/\1/p" "$LOG"; }

# AC5: the entrypoint reaches exec within 2 s of its start line.
entrypoint_within_2s() {
  local start exec_at
  start="$(date -d "$(stamp start)" +%s%N)"
  exec_at="$(date -d "$(stamp exec)" +%s%N)"
  [ $((exec_at - start)) -le 2000000000 ]
}

# AC16: Orca refuses public peers.
refuses_public() { tr '\0' ' ' <"/proc/$(<"$DATA/orca-server.pid")/cmdline" | grep -q -- '--refuse-public'; }

# AC8, T043: the process runs as the remote user, not root, and no DISPLAY is set (research D5).
runs_as_remote_user() {
  local want
  want="$(</usr/local/share/orca-server/remote-user)"
  [ "$(id -un)" = "$want" ] && [ "$(ps -o user= -p "$(<"$DATA/orca-server.pid")")" = "$want" ] && [ -z "${DISPLAY:-}" ]
}

# FR-027: a second start adds no process.
second_start_adds_nothing() {
  local before after
  before="$(orca_pids | wc -l)"
  orca-server start
  after="$(orca_pids | wc -l)"
  [ "$before" -ge 1 ] && [ "$before" = "$after" ]
}

check "Orca answers HTTP within 90 s" serves_http
check "entrypoint exec within 2 s" entrypoint_within_2s
check "Orca refuses public peers" refuses_public
check "Orca runs as the remote user with no DISPLAY" runs_as_remote_user
check "second start adds no process" second_start_adds_nothing

reportResults
