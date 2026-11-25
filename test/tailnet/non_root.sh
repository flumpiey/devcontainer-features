#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/non_root.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# FR-028: the scenario sets containerUser to vscode. The entrypoint, run as that user, joins through sudo.
joins_through_sudo() {
  [ "$(id -u)" -ne 0 ] || return 1
  install_stub
  TS_AUTH_KEY=test-auth-key bash "$ENTRY" true
  local _
  for _ in $(seq 60); do
    if [ -s "$ARGS" ]; then break; fi
    sleep 1
  done
  [ -s "$ARGS" ] &&
    wait_for_log 'joined as' &&
    [ "$(stat -c '%U' "$LOG")" = root ]
}

check "a non-root entrypoint user joins through sudo" joins_through_sudo

reportResults
