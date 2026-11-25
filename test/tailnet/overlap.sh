#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/overlap.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# FR-036: while one join runs, a second one logs one line and does nothing.
second_join_stops() {
  install_stub
  join_now TS_AUTH_KEY=test-auth-key TAILSCALE_STUB_SLEEP=5 &
  local first=$!
  sleep 2
  join_now TS_AUTH_KEY=test-auth-key
  wait "$first"
  [ "$(sudo -n grep -c '' "$ARGS")" = 1 ] &&
    sudo -n grep -q 'another join is running' "$LOG"
}

check "an overlapping join stops and only one up call runs" second_join_stops

reportResults
