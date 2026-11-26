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

# FR-030: with autoStart false, show does not wait. It prints one error line and exits 0.
show_does_not_wait() {
  local start="$SECONDS" out
  out="$(orca-server show 2>&1)" || return 1
  [ $((SECONDS - start)) -lt 5 ] && grep -q '^orca-server: error: Orca is not ready' <<<"$out"
}

# FR-030: showPairingOnAttach false silences the attach call only. mobilePairing false leaves out the QR code.
show_respects_options() {
  local _ out
  for _ in $(seq 90); do
    if [ -s /var/lib/orca-server/pairing-url.txt ]; then break; fi
    sleep 1
  done
  [ -z "$(orca-server show --attach 2>&1)" ] || return 1
  out="$(orca-server show)"
  grep -q '^orca://pair' <<<"$out" && ! grep -q '▄' <<<"$out"
}

check "no Orca runs when autoStart is false" nothing_starts
check "show does not wait when nothing starts Orca" show_does_not_wait
check "a manual start runs Orca without --mobile-pairing" manual_start_without_mobile_flag
check "show respects showPairingOnAttach and mobilePairing" show_respects_options

reportResults
