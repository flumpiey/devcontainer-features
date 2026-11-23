#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/no_tailscale.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

LOG=/var/lib/orca-server/orca-server.log

error_lines() { grep -c '^orca-server: error:' "$LOG" || true; }

# AC6: wait ends, one error line, no Orca process, container still up (this script runs in it).
one_error_and_no_orca() {
  local _
  for _ in $(seq 60); do
    if [ "$(error_lines)" -ge 1 ]; then break; fi
    sleep 1
  done
  [ "$(error_lines)" = 1 ] && ! pgrep -f 'index\.js serve' >/dev/null
}

check "one error line and no Orca process" one_error_and_no_orca

reportResults
