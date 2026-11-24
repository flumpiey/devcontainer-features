#!/usr/bin/env bash
set -euo pipefail
# test/_global/tailscale_stub.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

DATA=/var/lib/orca-server

# AC13: the entrypoint waits for the stub to report Running, then writes the pairing link.
link_after_stub_runs() {
  local _
  for _ in $(seq 120); do
    if [ -s "$DATA/pairing-url.txt" ]; then break; fi
    sleep 1
  done
  grep -q '^orca://pair' "$DATA/pairing-url.txt" &&
    grep -q 'pairing address host\.tail1234\.ts\.net' "$DATA/orca-server.log"
}

# Research D7: the other Feature's entrypoint also ran.
other_entrypoint_ran() { pgrep -x sshd >/dev/null; }

check "pairing link appears after the stub reports Running" link_after_stub_runs
check "the sshd Feature entrypoint also ran" other_entrypoint_ran

reportResults
