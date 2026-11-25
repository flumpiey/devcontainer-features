#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/key_refused.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# FR-006: when Tailscale refuses the key or the tag, the error goes to the log, the key file is removed and the container runs on.
refusal_is_logged() {
  install_stub
  join_now TAILSCALE_STUB_MODE=refuse TS_AUTH_KEY=test-auth-key
  sudo -n grep -q 'error: tailscale up failed with exit 1.*not permitted' "$LOG" &&
    ! sudo -n test -e "$RUN/authkey" &&
    ! sudo -n grep -q 'test-auth-key' "$LOG"
}

check "a refused tag is logged with the Tailscale error and no key" refusal_is_logged

reportResults
