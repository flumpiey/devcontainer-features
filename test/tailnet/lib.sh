#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/lib.sh
# Helpers for the tailnet tests. Source it after dev-container-features-test-lib.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG=/var/log/tailnet.log
ARGS=/var/log/tailscale-stub.args
RUN=/run/tailnet
SHARE=/usr/local/share/tailnet
ENTRY=$SHARE/entrypoint.sh

# The container runs the real entrypoint at start. Wait until that join has ended, so a hand-made join does not meet its lock.
wait_idle() {
  local _
  for _ in $(seq 120); do
    if sudo -n test -e "$RUN/lock"; then break; fi
    sleep 1
  done
  sudo -n flock -w 120 "$RUN/lock" true
}

# The stub goes in /usr/local/sbin. It comes before /usr/local/bin, where the real tailscale is, in PATH and in the sudo path.
install_stub() {
  wait_idle
  sudo -n install -m 0755 "$HERE/stub/tailscale" /usr/local/sbin/tailscale
  sudo -n rm -f "$ARGS" /var/tmp/tailscale-stub-state
}

# join_now <NAME=value>...: run one join by hand, as root, with these variables added.
join_now() { sudo -n env "$@" bash "$ENTRY" --join; }

# The text after --hostname= on the last recorded `tailscale up` call.
last_hostname() { sed -n 's/.*--hostname=\([^ ]*\).*/\1/p' "$ARGS" | tail -n 1; }

# wait_for_log <regex>: the log gets a matching line within 120 seconds.
wait_for_log() {
  local _
  for _ in $(seq 120); do
    if sudo -n grep -q -- "$1" "$LOG" 2>/dev/null; then return 0; fi
    sleep 1
  done
  return 1
}

# The folder name that the harness gave the workspace.
workspace_name() { basename /workspaces/*; }
