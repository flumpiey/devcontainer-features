#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/daemon_down.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# FR-006: with tailscaled not answering, the join logs the failure and does not call up.
failure_is_logged() {
  install_stub
  join_now TAILSCALE_STUB_MODE=down TS_AUTH_KEY=test-auth-key
  sudo -n grep -q 'tailscaled did not answer' "$LOG" && [ ! -s "$ARGS" ]
}

# Constitution VI: the entrypoint reaches exec "$@" at once, while the join still waits in the background.
entrypoint_does_not_block() {
  local start="$SECONDS" out
  install_stub
  out="$(sudo -n env TAILSCALE_STUB_MODE=down TS_AUTH_KEY=test-auth-key bash "$ENTRY" echo reached)"
  [ "$out" = reached ] && [ $((SECONDS - start)) -lt 10 ]
}

check "tailscaled not answering is logged and no join runs" failure_is_logged
check "the entrypoint reaches exec at once" entrypoint_does_not_block

reportResults
