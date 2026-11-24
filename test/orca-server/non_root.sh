#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/non_root.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

DATA=/var/lib/orca-server

# Edge case: with containerUser set, the entrypoint itself runs as the remote user and starts Orca directly.
orca_runs_as_remote_user() {
  local _
  for _ in $(seq 90); do
    if [ "$(orca-server status || true)" = running ]; then break; fi
    sleep 1
  done
  [ "$(ps -o user= -p "$(<"$DATA/orca-server.pid")")" = "$(id -un)" ] && [ "$(id -u)" -ne 0 ]
}

check "Orca starts as the non-root container user" orca_runs_as_remote_user
check "the entrypoint logged start and exec" grep -q 'entrypoint: exec' "$DATA/orca-server.log"

reportResults
