#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/key_unset.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# AC2, FR-007: exactly one log line names the variable, and no join runs. The arguments are variable settings to add to the join.
one_line_and_no_join() {
  install_stub
  join_now "$@"
  [ "$(sudo -n grep -c 'TS_AUTH_KEY' "$LOG")" = 1 ] &&
    sudo -n grep -q 'TS_AUTH_KEY is unset or empty' "$LOG" &&
    [ ! -s "$ARGS" ]
}

# AC2 at container start: the container started and this shell opened. The entrypoint ended its own join with at most one line that names the variable.
auto_run_ended_cleanly() {
  wait_idle
  [ "$(sudo -n grep -c 'TS_AUTH_KEY' "$LOG")" -le 1 ]
}

check "the container start did not block and the log has at most one line naming the variable" auto_run_ended_cleanly
check "an unset variable gives one log line and no join" one_line_and_no_join
check "an empty variable gives one log line and no join" one_line_and_no_join TS_AUTH_KEY=

reportResults
