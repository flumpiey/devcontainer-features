#!/usr/bin/env bash
set -euo pipefail
# test/orca-server/control.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib

DATA=/var/lib/orca-server

wait_for() { # wait_for <seconds> <command...>
  local n="$1" _
  shift
  for _ in $(seq "$n"); do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
is_running() { [ "$(orca-server status)" = running ]; }
has_exit_line() { grep -q '^orca-server: orca-ide exited with status' "$DATA/orca-server.log"; }
has_pairing_file() { [ -s "$DATA/pairing-url.txt" ]; }
port_is_open() { (exec 3<>/dev/tcp/127.0.0.1/6768) 2>/dev/null; }

# AC7: status prints running with exit 0, then stopped with exit 3 after stop.
is_stopped() {
  local out rc=0
  out="$(orca-server status)" || rc=$?
  [ "$out" = stopped ] && [ "$rc" = 3 ]
}
status_and_stop() {
  wait_for 90 is_running || return 1
  orca-server stop
  is_stopped
}

# FR-023: with Orca stopped, each form prints nothing on stdout, one error line on stderr, and exits 1.
url_fails_cleanly() {
  local form out rc errf
  errf="$(mktemp)"
  for form in "" "--mobile"; do
    rc=0
    out="$(orca-server url $form 2>"$errf")" || rc=$?
    if [ "$rc" != 1 ] || [ -n "$out" ] || [ "$(wc -l <"$errf")" != 1 ] || ! grep -q '^orca-server: error:' "$errf"; then
      cat "$errf" >&2
      rm -f "$errf"
      return 1
    fi
  done
  rm -f "$errf"
}

# Port in use: Orca exits, the script logs it, status says stopped, nothing restarts it.
port_conflict() {
  sudo -n apt-get update -qq >/dev/null
  sudo -n apt-get install -y -qq python3 >/dev/null
  python3 -m http.server 6768 --bind 0.0.0.0 >/dev/null 2>&1 &
  local listener=$!
  wait_for 15 port_is_open || {
    kill "$listener"
    return 1
  }
  orca-server start
  wait_for 60 has_exit_line || {
    kill "$listener"
    return 1
  }
  kill "$listener"
  is_stopped
}

# Orca crash: the log records the exit and status says stopped.
crash_is_logged() {
  orca-server start
  wait_for 90 is_running || return 1
  kill -KILL "$(<"$DATA/orca-server.pid")"
  wait_for 10 has_exit_line || return 1
  is_stopped
}

has_fresh_link() { grep -q '^orca://pair?code=' "$DATA/pairing-url.txt"; }

# A restart without a rebuild rewrites the file. Orca may print the same unused link again,
# so plant a stale line and expect it to go.
restart_replaces_link() {
  orca-server stop
  printf 'orca://pair?stale\n' >"$DATA/pairing-url.txt"
  orca-server start
  wait_for 90 has_fresh_link
}

check "status and stop report running then stopped" status_and_stop
check "url prints one error and exits 1 when Orca is stopped" url_fails_cleanly
check "a taken port is logged and leaves status stopped" port_conflict
check "an Orca crash is logged" crash_is_logged
check "a restart replaces the pairing link" restart_replaces_link

reportResults
