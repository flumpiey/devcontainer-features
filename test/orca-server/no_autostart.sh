#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/no_autostart.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

DATA=/var/lib/orca-server

orca_pids() { pgrep -f 'index\.js serve' || true; }
cmdline() { tr '\0' ' ' <"/proc/$(<"$DATA/orca-server.pid")/cmdline"; }

# US4/AC3: with autoStart false the entrypoint starts nothing.
nothing_starts() {
  sleep 15
  [ -z "$(orca_pids)" ] && [ "$(orca-server status || true)" = stopped ]
}

# A manual start works. FR-017: mobilePairing false leaves out --mobile-pairing.
manual_start_without_mobile_flag() {
  local _
  orca-server start
  for _ in $(seq 90); do
    if [ "$(orca-server status || true)" = running ]; then break; fi
    sleep 1
  done
  cmdline | grep -q -- '--refuse-public' && ! cmdline | grep -q -- '--mobile-pairing'
}

check "no Orca runs when autoStart is false" nothing_starts
check "a manual start runs Orca without --mobile-pairing" manual_start_without_mobile_flag

reportResults
