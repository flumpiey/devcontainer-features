#!/usr/bin/env bash
set -euo pipefail
# test/tailnet/no_sudo.sh
# shellcheck source=/dev/null
source dev-container-features-test-lib
# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# FR-028: a non-root entrypoint user with no sudo on PATH gets one error line on the container output, no join, and still reaches exec.
no_sudo_message() {
  [ "$(id -u)" -ne 0 ] || return 1
  install_stub
  # PATH holds only id, so command -v sudo finds nothing. The command to exec has an absolute path.
  local bin out
  bin="$(mktemp -d)"
  ln -s "$(command -v id)" "$bin/id"
  out="$(PATH="$bin" /bin/bash "$ENTRY" /bin/echo reached 2>&1)"
  rm -rf "$bin"
  [ "$(grep -c 'sudo is missing' <<<"$out")" = 1 ] &&
    grep -qx 'reached' <<<"$out" &&
    [ ! -s "$ARGS" ]
}

check "no sudo gives one error line, no join, and the entrypoint still reaches exec" no_sudo_message

reportResults
